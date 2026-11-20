import {
  providerConfiguration,
  providerFetch,
} from "../_shared/provider_mode.ts";
import { createClient } from "@supabase/supabase-js";
import { corsHeaders, json } from "../_shared/http.ts";
import { isSchedulerRequest } from "../_shared/scheduler_auth.ts";
import {
  CheckoutSnapshot,
  expireCheckoutSafely,
} from "../_shared/paymongo_expiry.ts";
Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }
  try {
    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const { data: secret, error: secretError } = await admin.from(
      "internal_scheduler_tokens",
    )
      .select("token").eq("name", "checkout_expiry").single();
    if (secretError || !isSchedulerRequest(request.headers, secret?.token)) {
      return json({ error: "Scheduler authentication required" }, 401);
    }
    const { data: config, error: configError } = await admin.from(
      "service_configuration",
    ).select(
      "paymongo_mode,live_payments_enabled",
    ).eq("singleton", true).single();
    if (configError) throw configError;
    const key = Deno.env.get("PAYMONGO_TEST_SECRET_KEY") ?? "";
    providerConfiguration(
      config?.paymongo_mode,
      config?.live_payments_enabled,
      key,
      Deno.env.get("PAYMONGO_LIVE_SECRET_KEY") ?? "",
    );
    const claim = crypto.randomUUID();
    const { data: jobs, error: claimError } = await admin.rpc(
      "claim_checkout_expiries",
      {
        p_claim_id: claim,
        p_limit: 20,
      },
    );
    if (claimError) throw claimError;
    let processed = 0;
    for (const job of jobs ?? []) {
      let outcome: "expired" | "paid" | "processing" | "retry" = "retry";
      try {
        const jobProvider = providerConfiguration(
          job.mode,
          config?.live_payments_enabled,
          key,
          Deno.env.get("PAYMONGO_LIVE_SECRET_KEY") ?? "",
        );
        if (!/^cs_[A-Za-z0-9_-]+$/.test(job.checkout_id)) {
          throw new Error("Invalid stored checkout identifier");
        }
        if (job.status === "paid") outcome = "paid";
        else {outcome = await expireCheckoutSafely({
            expire: async () => {
              const response = await providerFetch(
                jobProvider,
                "https://api.paymongo.com/v1/checkout_sessions/" +
                  job.checkout_id + "/expire",
                {
                  method: "POST",
                  headers: { Authorization: "Basic " + btoa(key + ":") },
                  signal: AbortSignal.timeout(10000),
                },
              );
              return {
                ok: response.ok,
                status: response.status,
                body: await response.json() as CheckoutSnapshot,
              };
            },
            retrieve: async () => {
              const response = await providerFetch(
                jobProvider,
                "https://api.paymongo.com/v1/checkout_sessions/" +
                  job.checkout_id,
                {
                  headers: { Authorization: "Basic " + btoa(key + ":") },
                  signal: AbortSignal.timeout(10000),
                },
              );
              if (!response.ok) throw new Error("Checkout retrieval failed");
              return await response.json();
            },
            recordPaid: async (payment) => {
              const { error } = await admin.rpc(
                "process_paymongo_payment_event_in_mode",
                {
                  p_provider_event_id: "expiry:" + job.payment_id + ":paid:" +
                    payment.id,
                  p_event_type: "checkout_session.payment.paid",
                  p_resource_id: job.checkout_id,
                  p_checkout_id: job.checkout_id,
                  p_provider_payment_id: payment.id,
                  p_amount_centavos: payment.attributes.amount,
                  p_currency: payment.attributes.currency,
                  p_provider_status: "paid",
                  p_error_code: null,
                  p_error_message: null,
                  p_paid_at: new Date(
                    (payment.attributes.paid_at ?? Date.now() / 1000) * 1000,
                  )
                    .toISOString(),
                  p_payload: { source: "checkout_expiry_reconciliation" },
                  p_correlation_id: claim,
                  p_mode: jobProvider.mode,
                },
              );
              if (error) throw error;
            },
          });}
      } catch {
        outcome = "retry";
      }
      const { error } = await admin.rpc("finish_checkout_expiry", {
        p_payment_id: job.payment_id,
        p_claim_id: claim,
        p_outcome: outcome,
      });
      if (error) throw error;
      processed++;
    }
    return json({ processed });
  } catch {
    return json({
      error: "Checkout expiry is unavailable; queued work remains retryable",
    }, 503);
  }
});

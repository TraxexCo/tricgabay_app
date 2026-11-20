import {
  providerConfiguration,
  providerFetch,
} from "../_shared/provider_mode.ts";
import { createClient } from "@supabase/supabase-js";
import { corsHeaders, json } from "../_shared/http.ts";
import { refundReconciliationEventId } from "../_shared/paymongo_refund.ts";
import { canReconcilePayment } from "../_shared/edge_authorization.ts";

type ProviderPayment = {
  id: string;
  attributes?: {
    amount?: number;
    currency?: string;
    status?: string;
    paid_at?: number;
    refunds?: unknown[];
  };
};
const providerError = (payload: Record<string, unknown>): string => {
  const errors = payload.errors as
    | Array<{ detail?: string; code?: string }>
    | undefined;
  return errors?.[0]?.detail ?? errors?.[0]?.code ??
    "PayMongo status could not be retrieved.";
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }
  const correlationId = crypto.randomUUID();
  try {
    const url = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const authHeader = request.headers.get("Authorization") ?? "";
    const userClient = createClient(url, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const admin = createClient(url, serviceKey);
    const { data: modeSettings, error: modeError } = await admin.from(
      "service_configuration",
    ).select("paymongo_mode,live_payments_enabled").eq("singleton", true)
      .single();
    if (modeError) throw modeError;

    const { data: { user } } = await userClient.auth.getUser();
    if (!user) return json({ error: "Authentication required." }, 401);
    const { booking_id } = await request.json();
    const { data: booking } = await userClient.from("bookings")
      .select("id,tourist_id,driver_id,payment_method").eq("id", booking_id)
      .maybeSingle();
    if (!booking || booking.payment_method !== "paymongo") {
      return json({ error: "Online-payment booking not found." }, 404);
    }
    const touristOwner = booking.tourist_id === user.id;
    const { data: financeAllowed } = touristOwner
      ? { data: false }
      : await userClient.rpc("has_admin_capability", {
        p_capability: "finance",
      });
    if (
      !canReconcilePayment({
        userId: user.id,
        touristId: booking.tourist_id,
        financeAllowed: financeAllowed === true,
      })
    ) {
      return json({ error: "You cannot access this payment." }, 403);
    }
    const { data: payment } = await userClient.from("payments")
      .select("id,amount_centavos,provider_checkout_id,status,provider_mode")
      .eq(
        "booking_id",
        booking_id,
      )
      .eq("provider", "paymongo").order("created_at", { ascending: false })
      .limit(1).maybeSingle();
    if (!payment?.provider_checkout_id) {
      return json(
        { error: "No PayMongo checkout exists for this booking." },
        409,
      );
    }

    const providerConfigurationForRequest = providerConfiguration(
      payment.provider_mode,
      modeSettings.live_payments_enabled,
      Deno.env.get("PAYMONGO_TEST_SECRET_KEY") ?? "",
      Deno.env.get("PAYMONGO_LIVE_SECRET_KEY") ?? "",
    );
    const paymongoKey = providerConfigurationForRequest.secretKey;
    const response = await providerFetch(
      providerConfigurationForRequest,
      `https://api.paymongo.com/v1/checkout_sessions/${
        encodeURIComponent(payment.provider_checkout_id)
      }`,
      {
        headers: {
          Authorization: `Basic ${btoa(`${paymongoKey}:`)}`,
          Accept: "application/json",
        },
        signal: AbortSignal.timeout(15_000),
      },
    );
    const provider = await response.json() as Record<string, unknown>;
    if (!response.ok) {
      const detail = providerError(provider);
      await admin.from("payments").update({
        provider_error_message: detail,
        last_reconciled_at: new Date().toISOString(),
      }).eq("id", payment.id);
      return json({
        error: "PayMongo status could not be retrieved.",
        retryable: response.status >= 500,
        correlation_id: correlationId,
      }, 502);
    }
    const session = provider.data as { attributes?: Record<string, unknown> };
    const attributes = session.attributes ?? {};
    const candidates = (attributes.payments as ProviderPayment[] | undefined) ??
      [];
    const paid = candidates.find((candidate) =>
      candidate.attributes?.status === "paid"
    );
    if (paid) {
      const paidAttributes = paid.attributes ?? {};
      const { data: transition, error: transitionError } = await admin.rpc(
        "process_paymongo_payment_event_in_mode",
        {
          p_provider_event_id: `reconcile:${payment.id}:paid:${paid.id}`,
          p_event_type: "checkout_session.payment.paid",
          p_resource_id: payment.provider_checkout_id,
          p_checkout_id: payment.provider_checkout_id,
          p_provider_payment_id: paid.id,
          p_amount_centavos: paidAttributes.amount,
          p_currency: paidAttributes.currency,
          p_provider_status: "paid",
          p_error_code: null,
          p_error_message: null,
          p_paid_at: new Date(
            (paidAttributes.paid_at ?? Date.now() / 1000) * 1000,
          ).toISOString(),
          p_payload: {
            source: "reconciliation",
            checkout_id: payment.provider_checkout_id,
            payment_id: paid.id,
            provider_status: paidAttributes.status ?? "paid",
            amount: paidAttributes.amount ?? null,
            currency: paidAttributes.currency ?? null,
          },
          p_correlation_id: correlationId,
          p_mode: providerConfigurationForRequest.mode,
        },
      );
      if (transitionError) throw transitionError;
      const transitionResult =
        (transition as { result?: string } | null)?.result ?? "";
      if (transitionResult.startsWith("rejected_")) {
        return json({
          error:
            "Payment requires administrator review because provider details did not match.",
        }, 409);
      }
      const refunds = Array.isArray(paidAttributes.refunds)
        ? paidAttributes.refunds
        : [];
      let reconciledRefunds = 0;
      for (const refund of refunds) {
        const eventId = refundReconciliationEventId(refund);
        if (!eventId) continue;
        const { error: refundError } = await admin.rpc(
          "process_paymongo_refund_event_in_mode",
          {
            p_provider_event_id: eventId,
            p_event_type: "payment.refund.updated",
            p_refunds: [refund],
            p_payload: {
              source: "reconciliation",
              provider_payment_id: paid.id,
            },
            p_correlation_id: correlationId,
            p_mode: providerConfigurationForRequest.mode,
          },
        );
        if (refundError) throw refundError;
        reconciledRefunds++;
      }
      return json({
        status: "paid",
        refunds_reconciled: reconciledRefunds,
        message: reconciledRefunds > 0
          ? "Payment and refund status confirmed directly with PayMongo."
          : "Payment confirmed directly with PayMongo.",
      });
    }
    const providerStatus = String(
      attributes.payment_status ?? attributes.status ?? "processing",
    );
    const failed = ["failed", "expired", "cancelled"].includes(providerStatus);
    const localStatus = failed ? "failed" : "processing";
    const { error: transitionError } = await admin.rpc(
      "process_paymongo_payment_event_in_mode",
      {
        p_provider_event_id: `reconcile:${payment.id}:${providerStatus}`,
        p_event_type: failed ? "payment.failed" : "payment.processing",
        p_resource_id: payment.provider_checkout_id,
        p_checkout_id: payment.provider_checkout_id,
        p_provider_payment_id: null,
        p_amount_centavos: null,
        p_currency: null,
        p_provider_status: providerStatus,
        p_error_code: null,
        p_error_message: null,
        p_paid_at: null,
        p_payload: {
          source: "reconciliation",
          checkout_id: payment.provider_checkout_id,
          provider_status: providerStatus,
        },
        p_correlation_id: correlationId,
        p_mode: providerConfigurationForRequest.mode,
      },
    );
    if (transitionError) throw transitionError;
    return json({
      status: localStatus,
      provider_status: providerStatus,
      message: failed
        ? "PayMongo reports that this checkout was not completed. You can start a new checkout."
        : "Payment is not confirmed yet. Complete checkout or try again shortly.",
    });
  } catch (_) {
    console.error(`[${correlationId}] PayMongo reconciliation failed`);
    return json({
      error: "Payment reconciliation failed.",
      correlation_id: correlationId,
    }, 500);
  }
});

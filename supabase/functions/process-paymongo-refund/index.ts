import {
  providerConfiguration,
  providerFetch,
} from "../_shared/provider_mode.ts";
import { createClient } from "@supabase/supabase-js";
import { corsHeaders, json } from "../_shared/http.ts";
import {
  classifyPayMongoRefundResponse,
  payMongoRefundIdempotencyKey,
} from "../_shared/paymongo_refund.ts";
import { parseRefundRequest } from "../_shared/refund_request.ts";

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
    const { data: financeAllowed, error: capabilityError } = await userClient
      .rpc(
        "has_admin_capability",
        { p_capability: "finance" },
      );
    if (capabilityError || financeAllowed !== true) {
      return json({ error: "Finance administrator access required." }, 403);
    }

    const refundRequest = parseRefundRequest(await request.json());
    if (!refundRequest) {
      return json({
        error: "A valid booking, refund amount, and reason are required.",
        correlation_id: correlationId,
      }, 400);
    }
    const { data: modePayment, error: modePaymentError } = await userClient
      .from("payments").select("provider_mode").eq(
        "booking_id",
        refundRequest.bookingId,
      ).eq("provider", "paymongo").order("paid_at", { ascending: false }).limit(
        1,
      ).single();
    if (modePaymentError) throw modePaymentError;
    const providerConfigurationForRequest = providerConfiguration(
      modePayment.provider_mode,
      modeSettings.live_payments_enabled,
      Deno.env.get("PAYMONGO_TEST_SECRET_KEY") ?? "",
      Deno.env.get("PAYMONGO_LIVE_SECRET_KEY") ?? "",
    );
    const paymongoKey = providerConfigurationForRequest.secretKey;
    const { data: reservation, error: reserveError } = await userClient.rpc(
      "reserve_paymongo_refund",
      {
        p_booking_id: refundRequest.bookingId,
        p_amount_centavos: refundRequest.amountCentavos,
        p_reason: refundRequest.reason,
      },
    );
    if (reserveError?.code === "42501") {
      return json({ error: "Finance administrator access required." }, 403);
    }
    if (reserveError) {
      return json({
        error: "The refund could not be reserved in its current state.",
        correlation_id: correlationId,
      }, 409);
    }

    const payload = {
      data: {
        attributes: {
          amount: reservation.amount_centavos,
          payment_id: reservation.provider_payment_id,
          reason: "requested_by_customer",
          notes: `Tric-Gabay: ${refundRequest.reason}`.slice(0, 255),
        },
      },
    };
    let response: Response;
    let provider: unknown;
    try {
      response = await providerFetch(
        providerConfigurationForRequest,
        "https://api.paymongo.com/v1/refunds",
        {
          method: "POST",
          headers: {
            Authorization: `Basic ${btoa(`${paymongoKey}:`)}`,
            "Content-Type": "application/json",
            Accept: "application/json",
            "Idempotency-Key": payMongoRefundIdempotencyKey(
              reservation.refund_id,
            ),
          },
          body: JSON.stringify(payload),
          signal: AbortSignal.timeout(15_000),
        },
      );
      provider = await response.json();
    } catch (_) {
      // A timeout does not prove that PayMongo rejected the refund. Keep the
      // reservation processing so a duplicate request cannot refund twice.
      await admin.rpc("finalize_paymongo_refund", {
        p_refund_id: reservation.refund_id,
        p_provider_refund_id: null,
        p_provider_status: "network_unknown",
        p_status: "processing",
        p_failure_reason: null,
        p_metadata: { correlation_id: correlationId },
      });
      return json({
        error:
          "The provider outcome is not confirmed yet. Reconcile this refund before retrying.",
        retryable: true,
        correlation_id: correlationId,
      }, 503);
    }
    const outcome = classifyPayMongoRefundResponse(response.ok, provider);
    if (outcome.kind === "definitive_failure") {
      await admin.rpc("finalize_paymongo_refund", {
        p_refund_id: reservation.refund_id,
        p_provider_refund_id: null,
        p_provider_status: "rejected",
        p_status: "failed",
        p_failure_reason: outcome.failureReason,
        p_metadata: {
          correlation_id: correlationId,
          provider_status: "rejected",
        },
      });
      return json({
        error: "PayMongo rejected the refund request.",
        provider_status: "rejected",
        test_mode: providerConfigurationForRequest.mode === "test",
        correlation_id: correlationId,
        note:
          "PayMongo currently executes refunds only for live transactions; this test-mode request was not recorded as completed.",
      }, 422);
    }
    if (outcome.kind === "ambiguous") {
      await admin.rpc("finalize_paymongo_refund", {
        p_refund_id: reservation.refund_id,
        p_provider_refund_id: null,
        p_provider_status: outcome.providerStatus,
        p_status: "processing",
        p_failure_reason: null,
        p_metadata: {
          correlation_id: correlationId,
          provider_status: outcome.providerStatus,
        },
      });
      return json({
        error:
          "The provider outcome is not confirmed yet. Reconcile this refund before retrying.",
        retryable: true,
        correlation_id: correlationId,
      }, 503);
    }
    const { error: finalizeError } = await admin.rpc(
      "finalize_paymongo_refund",
      {
        p_refund_id: reservation.refund_id,
        p_provider_refund_id: outcome.providerRefundId,
        p_provider_status: outcome.providerStatus,
        p_status: outcome.localStatus,
        p_failure_reason: null,
        p_metadata: {
          correlation_id: correlationId,
          provider_refund_id: outcome.providerRefundId,
          provider_status: outcome.providerStatus,
        },
      },
    );
    if (finalizeError) throw finalizeError;
    return json({
      refund_id: reservation.refund_id,
      provider_refund_id: outcome.providerRefundId,
      status: outcome.localStatus,
      message: outcome.localStatus === "succeeded"
        ? "PayMongo confirmed the refund."
        : "Refund sent to PayMongo and is being processed.",
    }, outcome.localStatus === "succeeded" ? 200 : 202);
  } catch (_) {
    console.error(`[${correlationId}] PayMongo refund processing failed`);
    return json({
      error: "Refund processing failed.",
      correlation_id: correlationId,
    }, 500);
  }
});

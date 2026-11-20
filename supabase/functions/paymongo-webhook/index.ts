import { requireEnabledMode, webhookMode } from "../_shared/provider_mode.ts";
import { createClient } from "@supabase/supabase-js";
import { json } from "../_shared/http.ts";
import { verifyPayMongoSignature } from "../_shared/paymongo_webhook_auth.ts";
import { providerPaymentIdForRefundResource } from "../_shared/paymongo_refund.ts";

type JsonObject = Record<string, unknown>;
type ProviderPayment = {
  id?: string;
  attributes?: {
    status?: string;
    amount?: number;
    currency?: string;
    paid_at?: number;
  };
};

const object = (value: unknown): JsonObject | null =>
  value !== null && typeof value === "object" && !Array.isArray(value)
    ? value as JsonObject
    : null;

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }
  const correlationId = crypto.randomUUID();
  const raw = await request.text();
  try {
    const payload = object(JSON.parse(raw));
    const event = object(payload?.data);
    const eventAttributes = object(event?.attributes);
    const resource = object(eventAttributes?.data);
    if (typeof eventAttributes?.livemode !== "boolean") {
      return json({ error: "Invalid webhook mode" }, 400);
    }
    const mode = webhookMode(eventAttributes.livemode);
    const webhookSecret = Deno.env.get(
      mode === "test"
        ? "PAYMONGO_TEST_WEBHOOK_SECRET"
        : "PAYMONGO_LIVE_WEBHOOK_SECRET",
    ) ?? "";
    if (
      !await verifyPayMongoSignature(
        raw,
        request.headers.get("Paymongo-Signature") ?? "",
        webhookSecret,
        mode,
      )
    ) {
      return json({
        error: "Invalid webhook signature",
        correlation_id: correlationId,
      }, 401);
    }
    const eventId = typeof event?.id === "string" ? event.id : "";
    const eventType = typeof eventAttributes?.type === "string"
      ? eventAttributes.type
      : "";
    if (
      !payload || !event || !eventAttributes || !resource || !eventId ||
      !eventType
    ) {
      return json({
        error: "Invalid webhook event",
        correlation_id: correlationId,
      }, 400);
    }
    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: modeSettings, error: modeError } = await admin.from(
      "service_configuration",
    ).select("live_payments_enabled").eq("singleton", true).single();
    if (modeError) {
      throw modeError;
    }
    requireEnabledMode(mode, modeSettings.live_payments_enabled);
    const attributes = object(resource.attributes) ?? {};
    let result: JsonObject | null = null;

    if (eventType === "checkout_session.payment.paid") {
      const payments = Array.isArray(attributes.payments)
        ? attributes.payments as ProviderPayment[]
        : [];
      const paid = payments.find((candidate) =>
        candidate.attributes?.status === "paid"
      );
      const paidAt = paid?.attributes?.paid_at;
      const { data, error } = await admin.rpc(
        "process_paymongo_payment_event_in_mode",
        {
          p_provider_event_id: eventId,
          p_event_type: eventType,
          p_resource_id: String(resource.id ?? ""),
          p_checkout_id: String(resource.id ?? ""),
          p_provider_payment_id: paid?.id ?? null,
          p_amount_centavos: paid?.attributes?.amount ?? null,
          p_currency: paid?.attributes?.currency ?? null,
          p_provider_status: paid?.attributes?.status ?? null,
          p_error_code: null,
          p_error_message: null,
          p_paid_at: typeof paidAt === "number"
            ? new Date(paidAt * 1000).toISOString()
            : null,
          p_payload: {
            source: "webhook",
            resource_id: String(resource.id ?? ""),
            payment_id: paid?.id ?? null,
            provider_status: paid?.attributes?.status ?? null,
            amount: paid?.attributes?.amount ?? null,
            currency: paid?.attributes?.currency ?? null,
          },
          p_correlation_id: correlationId,
          p_mode: mode,
        },
      );
      if (error) throw error;
      result = object(data);
    } else if (eventType === "payment.failed") {
      const failure = object(attributes.last_payment_error);
      const { data, error } = await admin.rpc(
        "process_paymongo_payment_event_in_mode",
        {
          p_provider_event_id: eventId,
          p_event_type: eventType,
          p_resource_id: String(resource.id ?? ""),
          p_checkout_id: typeof attributes.checkout_session_id === "string"
            ? attributes.checkout_session_id
            : null,
          p_provider_payment_id: String(resource.id ?? ""),
          p_amount_centavos: null,
          p_currency: null,
          p_provider_status: "failed",
          p_error_code: typeof attributes.failure_code === "string"
            ? attributes.failure_code
            : typeof failure?.code === "string"
            ? failure.code
            : null,
          p_error_message: typeof failure?.message === "string"
            ? failure.message
            : null,
          p_paid_at: null,
          p_payload: {
            source: "webhook",
            resource_id: String(resource.id ?? ""),
            checkout_id: typeof attributes.checkout_session_id === "string"
              ? attributes.checkout_session_id
              : null,
            provider_status: "failed",
          },
          p_correlation_id: correlationId,
          p_mode: mode,
        },
      );
      if (error) throw error;
      result = object(data);
    } else if (
      eventType === "payment.refunded" || eventType === "payment.refund.updated"
    ) {
      const refunds = Array.isArray(attributes.refunds)
        ? attributes.refunds
        : [resource];
      const providerPaymentId = providerPaymentIdForRefundResource(resource);
      const { data, error } = await admin.rpc(
        "process_paymongo_refund_event_in_mode",
        {
          p_provider_event_id: eventId,
          p_event_type: eventType,
          p_refunds: refunds,
          p_payload: {
            source: "webhook",
            resource_id: String(resource.id ?? ""),
            provider_payment_id: providerPaymentId,
            refund_ids: refunds.map((refund) => object(refund)?.id ?? null)
              .filter(Boolean),
          },
          p_correlation_id: correlationId,
          p_mode: mode,
        },
      );
      if (error) throw error;
      result = object(data);
    } else {
      const { data, error } = await admin.rpc(
        "process_paymongo_payment_event_in_mode",
        {
          p_provider_event_id: eventId,
          p_event_type: eventType,
          p_resource_id: String(resource.id ?? ""),
          p_checkout_id: null,
          p_provider_payment_id: null,
          p_amount_centavos: null,
          p_currency: null,
          p_provider_status: null,
          p_error_code: null,
          p_error_message: null,
          p_paid_at: null,
          p_payload: {
            source: "webhook",
            resource_id: String(resource.id ?? ""),
          },
          p_correlation_id: correlationId,
          p_mode: mode,
        },
      );
      if (error) throw error;
      result = object(data);
    }

    return json({
      received: true,
      result: result?.result ?? "processed",
      correlation_id: correlationId,
    });
  } catch (_) {
    console.error(`[${correlationId}] PayMongo webhook processing failed`);
    return json({
      error: "Webhook processing failed",
      correlation_id: correlationId,
    }, 500);
  }
});

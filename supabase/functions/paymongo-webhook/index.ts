import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { json, message } from "../_shared/http.ts";

async function requireSuccess<T>(
  request: PromiseLike<{ data: T; error: unknown }>,
): Promise<T> {
  const result = await request;
  if (result.error) throw result.error;
  return result.data;
}

function bytesToHex(bytes: ArrayBuffer): string {
  return [...new Uint8Array(bytes)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let result = 0;
  for (let i = 0; i < a.length; i++) result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return result === 0;
}

async function verifySignature(raw: string, header: string, secret: string): Promise<boolean> {
  const parts = Object.fromEntries(header.split(",").map((part) => part.trim().split("=", 2)));
  const timestamp = parts.t;
  const testSignature = parts.te;
  if (!timestamp || !testSignature) return false;
  if (Math.abs(Date.now() / 1000 - Number(timestamp)) > 300) return false;
  const key = await crypto.subtle.importKey(
    "raw", new TextEncoder().encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"],
  );
  const signed = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(`${timestamp}.${raw}`));
  return timingSafeEqual(bytesToHex(signed), testSignature);
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);
  const raw = await request.text();
  try {
    const webhookSecret = Deno.env.get("PAYMONGO_TEST_WEBHOOK_SECRET") ?? "";
    const signature = request.headers.get("Paymongo-Signature") ?? "";
    if (!webhookSecret || !(await verifySignature(raw, signature, webhookSecret))) {
      return json({ error: "Invalid webhook signature" }, 401);
    }
    const payload = JSON.parse(raw);
    const event = payload.data;
    if (event.attributes.livemode) return json({ error: "Live events are rejected by this test deployment." }, 409);

    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const eventType = event.attributes.type as string;
    const resource = event.attributes.data;
    const { error: eventError } = await admin.from("payment_webhook_events").insert({
      provider_event_id: event.id,
      event_type: eventType,
      livemode: false,
      payload,
    });
    if (eventError?.code === "23505") return json({ received: true, duplicate: true });
    if (eventError) throw eventError;

    try {
      const attributes = resource.attributes ?? {};
      if (eventType === "checkout_session.payment.paid") {
        const paidPayment = (attributes.payments ?? []).find(
          (candidate: { attributes?: { status?: string } }) => candidate.attributes?.status === "paid",
        );
        const payment = await requireSuccess(admin.from("payments")
          .select("id, booking_id, amount_centavos")
          .eq("provider_checkout_id", resource.id)
          .maybeSingle());
        const paidAttributes = paidPayment?.attributes ?? {};
        const amountMatches = paidAttributes.amount === payment?.amount_centavos;
        const currencyMatches = paidAttributes.currency === "PHP";
        if (payment && paidPayment && amountMatches && currencyMatches) {
          await requireSuccess(admin.from("payments").update({
            provider_payment_id: paidPayment.id,
            provider_status: "paid",
            provider_error_code: null,
            provider_error_message: null,
            provider_metadata: resource,
            last_reconciled_at: new Date().toISOString(),
            status: "paid",
            paid_at: new Date((paidAttributes.paid_at ?? event.attributes.created_at) * 1000).toISOString(),
          }).eq("id", payment.id));
          await requireSuccess(
            admin.from("bookings").update({ payment_status: "paid" }).eq("id", payment.booking_id),
          );
        } else if (payment) {
          await requireSuccess(admin.from("payments").update({
            provider_status: "amount_mismatch",
            provider_error_message: "Webhook amount or currency did not match the fixed fare.",
            provider_metadata: resource,
            last_reconciled_at: new Date().toISOString(),
          }).eq("id", payment.id));
          await requireSuccess(admin.from("bookings").update({ payment_status: "under_review" }).eq("id", payment.booking_id));
        }
      } else if (eventType === "payment.failed") {
        const checkoutId = attributes.checkout_session_id;
        let paymentQuery = admin.from("payments").select("id, booking_id");
        paymentQuery = checkoutId
          ? paymentQuery.eq("provider_checkout_id", checkoutId)
          : paymentQuery.eq("provider_payment_id", resource.id);
        const payment = await requireSuccess(paymentQuery.maybeSingle());
        if (payment) {
          const failure = attributes.last_payment_error ?? attributes.failure_code ?? null;
          await requireSuccess(admin.from("payments").update({
            status: "failed",
            provider_status: "failed",
            provider_error_code: typeof failure === "string" ? failure : failure?.code ?? null,
            provider_error_message: typeof failure === "string" ? null : failure?.message ?? null,
            provider_metadata: resource,
            last_reconciled_at: new Date().toISOString(),
          }).eq("id", payment.id));
          await requireSuccess(
            admin.from("bookings").update({ payment_status: "failed" }).eq("id", payment.booking_id),
          );
        }
      } else if (eventType === "payment.refunded" || eventType === "payment.refund.updated") {
        const refunds = attributes.refunds ?? [resource];
        for (const providerRefund of refunds) {
          const providerStatus = providerRefund.attributes?.status ?? providerRefund.status ?? "processing";
          const status = providerStatus === "succeeded" || providerStatus === "refunded" ? "succeeded" :
            providerStatus === "failed" ? "failed" : "processing";
          const { data: refund } = await admin.from("refunds").select("id")
            .eq("provider_refund_id", providerRefund.id).maybeSingle();
          if (refund) {
            await requireSuccess(admin.rpc("finalize_paymongo_refund", {
              p_refund_id: refund.id,
              p_provider_refund_id: providerRefund.id,
              p_provider_status: providerStatus,
              p_status: status,
              p_failure_reason: providerRefund.attributes?.failure_reason ?? null,
              p_metadata: providerRefund,
            }));
          }
        }
      }
      return json({ received: true });
    } catch (processingError) {
      // Release the idempotency reservation so PayMongo's retry can safely
      // process an event that failed after it was first recorded.
      await admin.from("payment_webhook_events").delete().eq("provider_event_id", event.id);
      throw processingError;
    }
  } catch (error) {
    return json({ error: message(error) }, 500);
  }
});

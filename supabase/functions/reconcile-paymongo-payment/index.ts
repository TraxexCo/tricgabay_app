import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, json, message } from "../_shared/http.ts";

type ProviderPayment = { id: string; attributes?: { amount?: number; currency?: string; status?: string; paid_at?: number } };
const providerError = (payload: Record<string, unknown>): string => {
  const errors = payload.errors as Array<{ detail?: string; code?: string }> | undefined;
  return errors?.[0]?.detail ?? errors?.[0]?.code ?? "PayMongo status could not be retrieved.";
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);
  try {
    const url = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const paymongoKey = Deno.env.get("PAYMONGO_TEST_SECRET_KEY") ?? "";
    if (!paymongoKey.startsWith("sk_test_")) return json({ error: "PayMongo test credentials are not configured." }, 503);
    const authHeader = request.headers.get("Authorization") ?? "";
    const userClient = createClient(url, anonKey, { global: { headers: { Authorization: authHeader } } });
    const admin = createClient(url, serviceKey);
    const { data: { user } } = await userClient.auth.getUser();
    if (!user) return json({ error: "Authentication required." }, 401);
    const { booking_id } = await request.json();
    const { data: booking } = await userClient.from("bookings")
      .select("id,tourist_id,driver_id,payment_method").eq("id", booking_id).maybeSingle();
    if (!booking || booking.payment_method !== "paymongo") return json({ error: "Online-payment booking not found." }, 404);
    const { data: profile } = await userClient.from("profiles").select("role,status").eq("id", user.id).single();
    const participant = booking.tourist_id === user.id || booking.driver_id === user.id;
    if (!participant && !(profile?.role === "admin" && profile?.status === "active")) {
      return json({ error: "You cannot access this payment." }, 403);
    }
    const { data: payment } = await userClient.from("payments")
      .select("id,amount_centavos,provider_checkout_id,status").eq("booking_id", booking_id)
      .eq("provider", "paymongo").order("created_at", { ascending: false }).limit(1).maybeSingle();
    if (!payment?.provider_checkout_id) return json({ error: "No PayMongo checkout exists for this booking." }, 409);

    const response = await fetch(
      `https://api.paymongo.com/v1/checkout_sessions/${encodeURIComponent(payment.provider_checkout_id)}`,
      { headers: { Authorization: `Basic ${btoa(`${paymongoKey}:`)}`, Accept: "application/json" } },
    );
    const provider = await response.json() as Record<string, unknown>;
    if (!response.ok) {
      const detail = providerError(provider);
      await admin.from("payments").update({ provider_error_message: detail, last_reconciled_at: new Date().toISOString() }).eq("id", payment.id);
      return json({ error: detail, retryable: response.status >= 500 }, 502);
    }
    const session = provider.data as { attributes?: Record<string, unknown> };
    const attributes = session.attributes ?? {};
    const candidates = (attributes.payments as ProviderPayment[] | undefined) ?? [];
    const paid = candidates.find((candidate) => candidate.attributes?.status === "paid");
    const now = new Date().toISOString();
    if (paid) {
      const paidAttributes = paid.attributes ?? {};
      if (paidAttributes.amount !== payment.amount_centavos || paidAttributes.currency !== "PHP") {
        await admin.from("payments").update({
          provider_status: "amount_mismatch", provider_error_message: "Provider amount or currency did not match the fixed fare.",
          last_reconciled_at: now, provider_metadata: provider,
        }).eq("id", payment.id);
        return json({ error: "Payment requires administrator review because the provider amount did not match." }, 409);
      }
      const { error: paymentError } = await admin.from("payments").update({
        provider_payment_id: paid.id, provider_status: "paid", provider_error_code: null,
        provider_error_message: null, last_reconciled_at: now, provider_metadata: provider,
        status: "paid", paid_at: new Date((paidAttributes.paid_at ?? Date.now() / 1000) * 1000).toISOString(),
      }).eq("id", payment.id);
      if (paymentError) throw paymentError;
      const { error: bookingError } = await admin.from("bookings").update({ payment_status: "paid" }).eq("id", booking_id);
      if (bookingError) throw bookingError;
      return json({ status: "paid", message: "Payment confirmed directly with PayMongo." });
    }
    const providerStatus = String(attributes.payment_status ?? attributes.status ?? "processing");
    const failed = ["failed", "expired", "cancelled"].includes(providerStatus);
    const localStatus = failed ? "failed" : "processing";
    await admin.from("payments").update({ provider_status: providerStatus, provider_error_code: null,
      provider_error_message: null, last_reconciled_at: now, provider_metadata: provider, status: localStatus }).eq("id", payment.id);
    await admin.from("bookings").update({ payment_status: localStatus }).eq("id", booking_id);
    return json({
      status: localStatus, provider_status: providerStatus,
      message: failed ? "PayMongo reports that this checkout was not completed. You can start a new checkout."
        : "Payment is not confirmed yet. Complete checkout or try again shortly.",
    });
  } catch (error) {
    return json({ error: message(error) }, 500);
  }
});

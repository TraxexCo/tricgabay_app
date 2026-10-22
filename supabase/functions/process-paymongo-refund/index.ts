import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, json, message } from "../_shared/http.ts";

const payMongoStatus = (value: string): "processing" | "succeeded" | "failed" => {
  if (["succeeded", "refunded"].includes(value)) return "succeeded";
  if (["failed", "cancelled"].includes(value)) return "failed";
  return "processing";
};

const providerError = (payload: Record<string, unknown>): string => {
  const errors = payload.errors as Array<{ detail?: string; code?: string }> | undefined;
  return errors?.[0]?.detail ?? errors?.[0]?.code ?? "PayMongo did not accept the refund request.";
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);
  try {
    const url = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const paymongoKey = Deno.env.get("PAYMONGO_TEST_SECRET_KEY") ?? "";
    if (!paymongoKey.startsWith("sk_test_")) {
      return json({ error: "PayMongo test credentials are not configured." }, 503);
    }
    const authHeader = request.headers.get("Authorization") ?? "";
    const userClient = createClient(url, anonKey, { global: { headers: { Authorization: authHeader } } });
    const admin = createClient(url, serviceKey);
    const { data: { user } } = await userClient.auth.getUser();
    if (!user) return json({ error: "Authentication required." }, 401);
    const { data: profile } = await userClient.from("profiles").select("role,status").eq("id", user.id).single();
    if (profile?.role !== "admin" || profile?.status !== "active") return json({ error: "Admin access required." }, 403);

    const { booking_id, amount_centavos, reason } = await request.json();
    if (!Number.isInteger(amount_centavos) || amount_centavos <= 0 || String(reason).trim().length < 5) {
      return json({ error: "A valid refund amount and reason are required." }, 400);
    }
    const { data: reservation, error: reserveError } = await userClient.rpc("reserve_paymongo_refund", {
      p_booking_id: booking_id,
      p_amount_centavos: amount_centavos,
      p_reason: String(reason).trim(),
    });
    if (reserveError) return json({ error: reserveError.message }, 409);

    const payload = { data: { attributes: {
      amount: reservation.amount_centavos,
      payment_id: reservation.provider_payment_id,
      reason: "requested_by_customer",
      notes: `Tric-Gabay: ${String(reason).trim()}`.slice(0, 255),
    } } };
    let response: Response;
    let provider: Record<string, unknown>;
    try {
      response = await fetch("https://api.paymongo.com/v1/refunds", {
        method: "POST",
        headers: {
          Authorization: `Basic ${btoa(`${paymongoKey}:`)}`,
          "Content-Type": "application/json",
          Accept: "application/json",
          "Idempotency-Key": `tricgabay-refund-${reservation.refund_id}`,
        },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(15_000),
      });
      provider = await response.json();
    } catch (error) {
      const detail = `PayMongo could not be reached: ${message(error)}`;
      await admin.rpc("finalize_paymongo_refund", {
        p_refund_id: reservation.refund_id, p_provider_refund_id: null,
        p_provider_status: "network_error", p_status: "failed",
        p_failure_reason: detail, p_metadata: {},
      });
      return json({ error: detail, retryable: true }, 503);
    }
    if (!response.ok) {
      const detail = providerError(provider);
      await admin.rpc("finalize_paymongo_refund", {
        p_refund_id: reservation.refund_id, p_provider_refund_id: null,
        p_provider_status: "rejected", p_status: "failed",
        p_failure_reason: detail, p_metadata: provider,
      });
      return json({
        error: detail, provider_status: "rejected", test_mode: true,
        note: "PayMongo currently executes refunds only for live transactions; this test-mode request was not recorded as completed.",
      }, 422);
    }
    const resource = provider.data as { id: string; attributes?: Record<string, unknown> };
    const rawStatus = String(resource.attributes?.status ?? "processing");
    const status = payMongoStatus(rawStatus);
    const { error: finalizeError } = await admin.rpc("finalize_paymongo_refund", {
      p_refund_id: reservation.refund_id, p_provider_refund_id: resource.id,
      p_provider_status: rawStatus, p_status: status, p_failure_reason: null,
      p_metadata: provider,
    });
    if (finalizeError) throw finalizeError;
    return json({
      refund_id: reservation.refund_id, provider_refund_id: resource.id, status,
      message: status === "succeeded" ? "PayMongo confirmed the refund." : "Refund sent to PayMongo and is being processed.",
    }, status === "succeeded" ? 200 : 202);
  } catch (error) {
    return json({ error: message(error) }, 500);
  }
});

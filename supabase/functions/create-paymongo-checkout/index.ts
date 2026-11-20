import {
  providerConfiguration,
  providerFetch,
} from "../_shared/provider_mode.ts";
import { createClient } from "@supabase/supabase-js";
import { corsHeaders, json } from "../_shared/http.ts";
import {
  CheckoutFlowError,
  resolvePayMongoCheckout,
} from "../_shared/paymongo_checkout.ts";

class PayMongoRequestError extends Error {
  constructor(public readonly retryable: boolean) {
    super("PayMongo checkout request failed");
  }
}

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

    const providerConfigurationForRequest = providerConfiguration(
      modeSettings.paymongo_mode,
      modeSettings.live_payments_enabled,
      Deno.env.get("PAYMONGO_TEST_SECRET_KEY") ?? "",
      Deno.env.get("PAYMONGO_LIVE_SECRET_KEY") ?? "",
    );
    const paymongoKey = providerConfigurationForRequest.secretKey;
    const { data: { user }, error: authError } = await userClient.auth
      .getUser();
    if (authError || !user) {
      return json({ error: "Authentication required." }, 401);
    }

    const { booking_id } = await request.json();
    const { data: booking, error: bookingError } = await userClient
      .from("bookings")
      .select(
        "id, reference_code, tourist_id, quoted_amount_centavos, payment_method, payment_status, status, payment_expires_at",
      )
      .eq("id", booking_id)
      .single();
    if (bookingError || !booking || booking.tourist_id !== user.id) {
      return json({ error: "Booking not found." }, 404);
    }
    if (booking.payment_method !== "paymongo") {
      return json({
        error: "This booking is not configured for online payment.",
      }, 409);
    }
    if (
      booking.status !== "payment_pending" || !booking.payment_expires_at ||
      new Date(booking.payment_expires_at).getTime() <= Date.now()
    ) {
      return json({ error: "This booking can no longer be paid online." }, 409);
    }
    if (booking.payment_status === "paid") {
      return json({ error: "This booking is already paid." }, 409);
    }

    const { data: existing, error: existingError } = await admin
      .from("payments")
      .select(
        "id, provider_checkout_id, checkout_url, status, amount_centavos, provider_mode",
      )
      .eq("booking_id", booking.id)
      .eq("provider", "paymongo")
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();
    if (existingError) throw existingError;
    const returnUrl = Deno.env.get("APP_PAYMENT_RETURN_URL") ??
      "tricgabay://payment-return";
    const payload = {
      data: {
        attributes: {
          billing: {
            name: user.user_metadata?.full_name ?? "Tric-Gabay tourist",
            email: user.email,
          },
          cancel_url: `${returnUrl}?booking=${booking.id}&result=cancelled`,
          success_url: `${returnUrl}?booking=${booking.id}&result=processing`,
          description: `Tric-Gabay booking ${booking.reference_code}`,
          line_items: [{
            amount: booking.quoted_amount_centavos,
            currency: "PHP",
            description: "Fixed tour fare",
            name: `Booking ${booking.reference_code}`,
            quantity: 1,
          }],
          payment_method_types: ["card", "gcash", "paymaya"],
          reference_number: booking.reference_code,
          send_email_receipt: true,
          show_description: true,
          show_line_items: true,
        },
      },
    };
    if (
      existing &&
      existing.provider_mode !== providerConfigurationForRequest.mode
    ) {
      return json({
        error: "The checkout mode changed. Review this booking before payment.",
      }, 409);
    }
    const result = await resolvePayMongoCheckout({
      bookingId: booking.id,
      amountCentavos: booking.quoted_amount_centavos,
      existing,
      createProviderCheckout: async (idempotencyKey) => {
        const response = await providerFetch(
          providerConfigurationForRequest,
          "https://api.paymongo.com/v1/checkout_sessions",
          {
            method: "POST",
            headers: {
              Authorization: `Basic ${btoa(`${paymongoKey}:`)}`,
              "Content-Type": "application/json",
              Accept: "application/json",
              "Idempotency-Key": idempotencyKey,
            },
            body: JSON.stringify(payload),
            signal: AbortSignal.timeout(15_000),
          },
        );
        const paymongo: unknown = await response.json();
        if (!response.ok) {
          console.error(
            `[${correlationId}] PayMongo checkout creation rejected (${response.status})`,
          );
          throw new PayMongoRequestError(response.status >= 500);
        }
        return paymongo;
      },
      persistCheckout: async (checkout) => {
        const { data: recorded, error: recordError } = await admin.rpc(
          "record_paymongo_checkout",
          {
            p_booking_id: booking.id,
            p_provider_checkout_id: checkout.id,
            p_checkout_url: checkout.checkoutUrl,
            p_amount_centavos: booking.quoted_amount_centavos,
          },
        );
        if (recordError) throw recordError;
        return recorded;
      },
    });
    return json(result);
  } catch (error) {
    if (error instanceof CheckoutFlowError) {
      console.error(`[${correlationId}] ${error.kind}`);
      return json(
        { error: error.message, correlation_id: correlationId },
        error.kind === "provider_result_invalid" ? 502 : 409,
      );
    }
    if (error instanceof PayMongoRequestError) {
      return json({
        error: "PayMongo could not create checkout.",
        retryable: error.retryable,
        correlation_id: correlationId,
      }, 502);
    }
    console.error(`[${correlationId}] Checkout persistence failed`);
    return json({
      error: "Checkout could not be completed.",
      correlation_id: correlationId,
    }, 500);
  }
});

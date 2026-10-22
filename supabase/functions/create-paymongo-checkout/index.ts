import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, json, message } from "../_shared/http.ts";

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
    const userClient = createClient(url, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const admin = createClient(url, serviceKey);
    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) return json({ error: "Authentication required." }, 401);

    const { booking_id } = await request.json();
    const { data: booking, error: bookingError } = await userClient
      .from("bookings")
      .select("id, reference_code, tourist_id, quoted_amount_centavos, payment_method, payment_status, status")
      .eq("id", booking_id)
      .single();
    if (bookingError || !booking || booking.tourist_id !== user.id) {
      return json({ error: "Booking not found." }, 404);
    }
    if (booking.payment_method !== "paymongo") {
      return json({ error: "This booking is not configured for online payment." }, 409);
    }
    if (!["pending", "accepted"].includes(booking.status)) {
      return json({ error: "This booking can no longer be paid online." }, 409);
    }
    if (booking.payment_status === "paid") {
      return json({ error: "This booking is already paid." }, 409);
    }

    const { data: existing } = await admin
      .from("payments")
      .select("provider_checkout_id, checkout_url, status")
      .eq("booking_id", booking.id)
      .in("status", ["checkout_created", "processing"])
      .maybeSingle();
    if (existing?.checkout_url) {
      return json({ checkout_url: existing.checkout_url, reused: true });
    }

    const returnUrl = Deno.env.get("APP_PAYMENT_RETURN_URL") ?? "tricgabay://payment-return";
    const payload = {
      data: {
        attributes: {
          billing: { name: user.user_metadata?.full_name ?? "Tric-Gabay tourist", email: user.email },
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
    const response = await fetch("https://api.paymongo.com/v1/checkout_sessions", {
      method: "POST",
      headers: {
        Authorization: `Basic ${btoa(`${paymongoKey}:`)}`,
        "Content-Type": "application/json",
        Accept: "application/json",
        "Idempotency-Key": `tricgabay-checkout-${booking.id}`,
      },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(15_000),
    });
    const paymongo = await response.json();
    if (!response.ok) {
      return json({ error: "PayMongo could not create checkout.", provider: paymongo.errors }, 502);
    }
    const checkout = paymongo.data;
    const checkoutUrl = checkout.attributes.checkout_url;
    const { error: insertError } = await admin.from("payments").insert({
      booking_id: booking.id,
      provider: "paymongo",
      provider_mode: "test",
      provider_checkout_id: checkout.id,
      checkout_url: checkoutUrl,
      amount_centavos: booking.quoted_amount_centavos,
      status: "checkout_created",
    });
    if (insertError) {
      // Another request may have completed while PayMongo was responding.
      // Return the authoritative stored checkout instead of surfacing a false
      // failure or encouraging the tourist to create another payment session.
      const { data: raced } = await admin
        .from("payments")
        .select("checkout_url")
        .eq("booking_id", booking.id)
        .in("status", ["checkout_created", "processing"])
        .maybeSingle();
      if (raced?.checkout_url) {
        return json({ checkout_url: raced.checkout_url, reused: true });
      }
      throw insertError;
    }
    const { error: statusError } = await admin.from("bookings")
      .update({ payment_status: "checkout_created" }).eq("id", booking.id);
    if (statusError) throw statusError;
    return json({ checkout_url: checkoutUrl, reused: false });
  } catch (error) {
    return json({ error: message(error) }, 500);
  }
});

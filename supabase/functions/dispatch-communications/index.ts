import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, json, message } from "../_shared/http.ts";

type Delivery = {
  id: string;
  recipient_id: string;
  booking_id?: string;
  channel: "email" | "push";
  template_key: string;
  destination?: string;
  subject?: string;
  title: string;
  body: string;
  route_path?: string;
  safe_preview: string;
};

const encodeUrl = (bytes: Uint8Array): string =>
  btoa(String.fromCharCode(...bytes)).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
const encodeText = (value: string): string => encodeUrl(new TextEncoder().encode(value));
const escapeHtml = (value: unknown): string => String(value ?? "")
  .replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;")
  .replaceAll('"', "&quot;").replaceAll("'", "&#039;");
const peso = (centavos: unknown): string =>
  `₱${(Number(centavos ?? 0) / 100).toLocaleString("en-PH", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

function emailHtml(delivery: Delivery, booking: Record<string, unknown> | null): string {
  const logoUrl = Deno.env.get("APP_LOGO_URL") ??
    "https://xcsrjuqzwequmeqzedzd.supabase.co/storage/v1/object/public/app-assets/tric-gabay-logo.png";
  const reference = booking?.reference_code ?? delivery.booking_id?.slice(0, 8).toUpperCase() ?? "—";
  const pickup = booking?.pickup_address ?? "Open the app for trip details";
  const fare = booking ? peso(booking.quoted_amount_centavos) : "—";
  const scheduled = booking?.scheduled_at
    ? new Date(String(booking.scheduled_at)).toLocaleString("en-PH", { timeZone: "Asia/Manila", dateStyle: "medium", timeStyle: "short" })
    : "On demand";
  return `<!doctype html><html><head><meta name="viewport" content="width=device-width"><meta charset="utf-8"></head>
  <body style="margin:0;background:#f4f7fb;font-family:Arial,sans-serif;color:#101828">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f4f7fb;padding:28px 12px"><tr><td align="center">
      <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:620px;background:#ffffff;border-radius:24px;overflow:hidden;box-shadow:0 12px 32px rgba(8,42,92,.10)">
        <tr><td style="background:#072d6f;padding:26px 32px"><table role="presentation" width="100%"><tr>
          <td width="70"><img src="${escapeHtml(logoUrl)}" width="58" height="58" alt="Tric-Gabay" style="display:block;border-radius:50%;background:white"></td>
          <td><div style="color:#ffffff;font-size:23px;font-weight:800">TRIC-GABAY</div><div style="color:#c7d7f5;font-size:13px;margin-top:3px">Bustos tours, guided with care</div></td>
        </tr></table></td></tr>
        <tr><td style="padding:34px 32px 18px"><div style="display:inline-block;background:#eef4ff;color:#0b4db8;border-radius:999px;padding:7px 12px;font-size:12px;font-weight:700;text-transform:uppercase;letter-spacing:.6px">${escapeHtml(delivery.template_key.replaceAll("_", " "))}</div>
          <h1 style="font-size:27px;line-height:1.25;margin:18px 0 10px">${escapeHtml(delivery.title)}</h1>
          <p style="font-size:16px;line-height:1.65;color:#475467;margin:0">${escapeHtml(delivery.body)}</p>
        </td></tr>
        <tr><td style="padding:12px 32px 22px"><table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#f8fafc;border:1px solid #e4e7ec;border-radius:16px;padding:18px">
          <tr><td style="color:#667085;font-size:12px;padding:5px 0">BOOKING</td><td align="right" style="font-weight:700">${escapeHtml(reference)}</td></tr>
          <tr><td style="color:#667085;font-size:12px;padding:5px 0">FIXED FARE</td><td align="right" style="font-weight:700">${escapeHtml(fare)}</td></tr>
          <tr><td style="color:#667085;font-size:12px;padding:5px 0">PICKUP</td><td align="right" style="font-weight:700;max-width:320px">${escapeHtml(pickup)}</td></tr>
          <tr><td style="color:#667085;font-size:12px;padding:5px 0">SCHEDULE</td><td align="right" style="font-weight:700">${escapeHtml(scheduled)}</td></tr>
        </table></td></tr>
        <tr><td align="center" style="padding:0 32px 34px"><div style="background:#0b4db8;color:#fff;padding:14px 24px;border-radius:14px;font-weight:700">Open Tric-Gabay to view details</div>
          <p style="font-size:12px;line-height:1.5;color:#98a2b3;margin:20px 0 0">For your privacy, sensitive trip details are available only after signing in. Never share your pickup code.</p>
        </td></tr>
      </table><div style="color:#98a2b3;font-size:11px;padding:18px">Automated service email from Tric-Gabay · Bustos, Bulacan</div>
    </td></tr></table></body></html>`;
}

function pemBytes(pem: string): Uint8Array {
  const compact = pem.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\s/g, "");
  return Uint8Array.from(atob(compact), (c) => c.charCodeAt(0));
}

async function firebaseAccessToken(service: Record<string, string>): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const unsigned = `${encodeText(JSON.stringify({ alg: "RS256", typ: "JWT" }))}.${encodeText(JSON.stringify({
    iss: service.client_email,
    sub: service.client_email,
    aud: "https://oauth2.googleapis.com/token",
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    iat: now,
    exp: now + 3600,
  }))}`;
  const key = await crypto.subtle.importKey(
    "pkcs8", pemBytes(service.private_key), { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"],
  );
  const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned));
  const assertion = `${unsigned}.${encodeUrl(new Uint8Array(signature))}`;
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion }),
  });
  const data = await response.json();
  if (!response.ok || !data.access_token) throw new Error(data.error_description ?? "Firebase authorization failed.");
  return data.access_token;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);
  try {
    const url = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const authHeader = request.headers.get("Authorization") ?? "";
    const userClient = createClient(url, anonKey, { global: { headers: { Authorization: authHeader } } });
    const admin = createClient(url, serviceKey);
    const { data: { user } } = await userClient.auth.getUser();
    if (!user) return json({ error: "Authentication required." }, 401);
    const { data: profile } = await userClient.from("profiles").select("status").eq("id", user.id).single();
    if (profile?.status !== "active") return json({ error: "Active account required." }, 403);

    const brevoKey = Deno.env.get("BREVO_API_KEY") ?? "";
    const emailFrom = Deno.env.get("EMAIL_FROM") ?? "";
    const emailFromName = Deno.env.get("EMAIL_FROM_NAME") ?? "Tric-Gabay";
    const firebaseRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON") ?? "";
    const configuredChannels: string[] = [];
    if (brevoKey && emailFrom) configuredChannels.push("email");
    if (firebaseRaw) configuredChannels.push("push");
    if (!configuredChannels.length) {
      return json({ error: "Email and push providers are not configured yet.", requires: ["BREVO_API_KEY + EMAIL_FROM", "FIREBASE_SERVICE_ACCOUNT_JSON"] }, 503);
    }
    const body = await request.json().catch(() => ({}));
    const limit = Math.max(1, Math.min(Number(body.limit ?? 20), 50));
    const { data: jobs, error: claimError } = await admin.rpc("claim_message_deliveries", {
      p_limit: limit, p_channels: configuredChannels,
    });
    if (claimError) throw claimError;
    const service = firebaseRaw ? JSON.parse(firebaseRaw) as Record<string, string> : null;
    const accessToken = service ? await firebaseAccessToken(service) : null;
    const results: Array<Record<string, unknown>> = [];

    for (const delivery of (jobs ?? []) as Delivery[]) {
      try {
        if (delivery.channel === "email") {
          const { data: booking } = delivery.booking_id
            ? await admin.from("bookings").select("reference_code,quoted_amount_centavos,pickup_address,scheduled_at").eq("id", delivery.booking_id).maybeSingle()
            : { data: null };
          const response = await fetch("https://api.brevo.com/v3/smtp/email", {
            method: "POST",
            headers: { "api-key": brevoKey, "Content-Type": "application/json", accept: "application/json" },
            body: JSON.stringify({
              sender: { name: emailFromName, email: emailFrom },
              to: [{ email: delivery.destination }],
              subject: delivery.subject,
              htmlContent: emailHtml(delivery, booking),
              headers: { "X-Tric-Gabay-Delivery-ID": delivery.id },
            }),
          });
          const data = await response.json();
          if (!response.ok) throw new Error(data.message ?? "Email provider rejected the message.");
          await admin.rpc("finish_message_delivery", { p_id: delivery.id, p_success: true, p_provider_message_id: data.messageId, p_error: null, p_skip: false });
          results.push({ id: delivery.id, channel: "email", status: "sent" });
        } else {
          const { data: tokens } = await admin.from("push_tokens").select("token").eq("profile_id", delivery.recipient_id).is("revoked_at", null);
          if (!tokens?.length) {
            await admin.rpc("finish_message_delivery", { p_id: delivery.id, p_success: false, p_provider_message_id: null, p_error: "No active device token.", p_skip: true });
            results.push({ id: delivery.id, channel: "push", status: "skipped" });
            continue;
          }
          let sent = 0;
          for (const row of tokens) {
            const response = await fetch(`https://fcm.googleapis.com/v1/projects/${service!.project_id}/messages:send`, {
              method: "POST",
              headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "application/json" },
              body: JSON.stringify({ message: {
                token: row.token,
                notification: { title: delivery.title, body: delivery.safe_preview },
                data: { route_path: delivery.route_path ?? "", notification_id: delivery.id },
                android: { priority: "high", notification: { channel_id: "tric_gabay_updates", visibility: "PRIVATE" } },
              } }),
            });
            const data = await response.json();
            if (response.ok) sent++;
            else if ([400, 404].includes(response.status)) {
              await admin.from("push_tokens").update({ revoked_at: new Date().toISOString() }).eq("token", row.token);
            }
          }
          if (!sent) throw new Error("No registered device accepted the push message.");
          await admin.rpc("finish_message_delivery", { p_id: delivery.id, p_success: true, p_provider_message_id: `${sent} device(s)`, p_error: null, p_skip: false });
          results.push({ id: delivery.id, channel: "push", status: "sent", devices: sent });
        }
      } catch (error) {
        const detail = message(error).slice(0, 1000);
        await admin.rpc("finish_message_delivery", { p_id: delivery.id, p_success: false, p_provider_message_id: null, p_error: detail, p_skip: false });
        results.push({ id: delivery.id, channel: delivery.channel, status: "failed", error: detail });
      }
    }
    return json({ processed: results.length, configured_channels: configuredChannels, results });
  } catch (error) {
    return json({ error: message(error) }, 500);
  }
});

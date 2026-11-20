import { createClient } from "npm:@supabase/supabase-js@2.118.0";
import { localApiUrl } from "./local_database.ts";
const encode = (value: unknown) =>
  btoa(JSON.stringify(value)).replaceAll("+", "-").replaceAll("/", "_")
    .replaceAll("=", "");
export async function localToken(subject: string): Promise<string> {
  localApiUrl();
  const secret = Deno.env.get("LOCAL_JWT_SECRET") ?? "";
  if (secret.length < 32) {
    throw new Error("The isolated stack JWT secret is required");
  }
  const data = `${encode({ alg: "HS256", typ: "JWT" })}.${
    encode({
      sub: subject,
      role: "authenticated",
      aud: "authenticated",
      iss: "supabase",
      exp: Math.floor(Date.now() / 1000) + 3600,
    })
  }`;
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(data),
  );
  return `${data}.${
    btoa(String.fromCharCode(...new Uint8Array(signature))).replaceAll("+", "-")
      .replaceAll("/", "_").replaceAll("=", "")
  }`;
}
export async function localClient(subject?: string) {
  const token = subject
    ? await localToken(subject)
    : Deno.env.get("LOCAL_SUPABASE_ANON_KEY")!;
  return createClient(localApiUrl(), Deno.env.get("LOCAL_SUPABASE_ANON_KEY")!, {
    accessToken: async () => token,
    auth: { persistSession: false, autoRefreshToken: false },
    realtime: { timeout: 30000 },
  });
}
export function localAdmin() {
  return createClient(
    localApiUrl(),
    Deno.env.get("LOCAL_SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false, autoRefreshToken: false } },
  );
}
export const logDirectory = () =>
  Deno.env.get("VALIDATION_LOG_DIR") ?? ".audit-output/batch4";

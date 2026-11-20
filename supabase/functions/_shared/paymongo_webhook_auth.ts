function bytesToHex(bytes: ArrayBuffer): string {
  return [...new Uint8Array(bytes)].map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let result = 0;
  for (let index = 0; index < a.length; index++) {
    result |= a.charCodeAt(index) ^ b.charCodeAt(index);
  }
  return result === 0;
}

export async function verifyPayMongoSignature(
  raw: string,
  header: string,
  secret: string,
  mode: "test" | "live",
  nowSeconds = Date.now() / 1000,
): Promise<boolean> {
  const parts = Object.fromEntries(
    header.split(",").map((part) => part.trim().split("=", 2)),
  );
  const timestamp = parts.t;
  const testSignature = mode === "test" ? parts.te : parts.li;
  if (
    !secret || !timestamp || !testSignature ||
    !Number.isFinite(Number(timestamp))
  ) return false;
  if (Math.abs(nowSeconds - Number(timestamp)) > 300) return false;
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signed = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(`${timestamp}.${raw}`),
  );
  return timingSafeEqual(bytesToHex(signed), testSignature);
}

export const verifyPayMongoTestSignature = (
  raw: string,
  header: string,
  secret: string,
  nowSeconds = Date.now() / 1000,
): Promise<boolean> =>
  verifyPayMongoSignature(raw, header, secret, "test", nowSeconds);

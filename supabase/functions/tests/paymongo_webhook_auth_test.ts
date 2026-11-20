import { assert, assertEquals } from "@std/assert";
import { verifyPayMongoTestSignature } from "../_shared/paymongo_webhook_auth.ts";

async function sign(
  raw: string,
  timestamp: number,
  secret: string,
): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const result = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(`${timestamp}.${raw}`),
  );
  return [...new Uint8Array(result)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

Deno.test("accepts a current valid PayMongo test signature", async () => {
  const raw = '{"data":{"id":"evt_test"}}';
  const timestamp = 1_800_000_000;
  const secret = "test-webhook-secret";
  const signature = await sign(raw, timestamp, secret);
  assert(
    await verifyPayMongoTestSignature(
      raw,
      `t=${timestamp},te=${signature}`,
      secret,
      timestamp,
    ),
  );
});

Deno.test("rejects invalid, live-only, and stale signatures", async () => {
  const raw = '{"data":{"id":"evt_test"}}';
  const timestamp = 1_800_000_000;
  const secret = "test-webhook-secret";
  const signature = await sign(raw, timestamp, secret);
  assertEquals(
    await verifyPayMongoTestSignature(
      raw,
      `t=${timestamp},te=bad`,
      secret,
      timestamp,
    ),
    false,
  );
  assertEquals(
    await verifyPayMongoTestSignature(
      raw,
      `t=${timestamp},li=${signature}`,
      secret,
      timestamp,
    ),
    false,
  );
  assertEquals(
    await verifyPayMongoTestSignature(
      raw,
      `t=${timestamp},te=${signature}`,
      secret,
      timestamp + 301,
    ),
    false,
  );
});

import { assertEquals, assertRejects, assertThrows } from "@std/assert";
import {
  providerConfiguration,
  providerFetch,
  requireEnabledMode,
  webhookMode,
} from "../_shared/provider_mode.ts";
import { verifyPayMongoSignature } from "../_shared/paymongo_webhook_auth.ts";
import { healthCheckHandler } from "../_shared/health_check.ts";

Deno.test("live flag defaults closed and credentials cannot cross modes", () => {
  for (const flag of [undefined, false, "true", 1]) {
    assertThrows(() => requireEnabledMode("live", flag));
  }
  assertEquals(requireEnabledMode("test", false), "test");
  assertEquals(requireEnabledMode("live", true), "live");
  assertThrows(() =>
    providerConfiguration("test", false, "sk_live_fixture", "")
  );
  assertThrows(() =>
    providerConfiguration("live", true, "", "sk_test_fixture")
  );
  assertThrows(() => webhookMode(undefined));
  assertEquals(webhookMode(false), "test");
  assertEquals(webhookMode(true), "live");
});

Deno.test("injected checkout and refund responses use mode credentials and reject crossed responses", async () => {
  const calls: string[] = [];
  for (const mode of ["test", "live"] as const) {
    const config = providerConfiguration(
      mode,
      mode === "live",
      "sk_test_fixture",
      "sk_live_fixture",
    );
    for (const endpoint of ["checkout_sessions", "refunds"]) {
      const send = ((_url: string | URL | Request, init?: RequestInit) => {
        calls.push(new Headers(init?.headers).get("authorization")!);
        return Promise.resolve(
          Response.json({
            data: {
              id: "synthetic",
              attributes: { livemode: mode === "live" },
            },
          }),
        );
      }) as typeof fetch;
      const response = await providerFetch(
        config,
        `https://api.paymongo.com/v1/${endpoint}`,
        { method: "POST" },
        send,
      );
      assertEquals(response.status, 200);
      assertEquals(calls.at(-1), `Basic ${btoa(`sk_${mode}_fixture:`)}`);
    }
    await assertRejects(() =>
      providerFetch(
        config,
        "https://api.paymongo.com/v1/refunds",
        {},
        (() =>
          Promise.resolve(
            Response.json({
              data: { attributes: { livemode: mode !== "live" } },
            }),
          )) as typeof fetch,
      )
    );
    await assertRejects(() =>
      providerFetch(
        config,
        "https://untrusted.example/v1/refunds",
        {},
        (() => {
          throw new Error("Transport must not run");
        }) as typeof fetch,
      )
    );
  }
  assertEquals(calls.length, 4);
});

Deno.test("webhook HMAC signature is bound to raw payload, mode and timestamp", async () => {
  const timestamp = 1800000000,
    raw = '{"data":{"id":"synthetic-event"}}',
    secret = "synthetic-webhook-signing-fixture";
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const bytes = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(`${timestamp}.${raw}`),
  );
  const digest = [...new Uint8Array(bytes)].map((b) =>
    b.toString(16).padStart(2, "0")
  ).join("");
  for (const mode of ["test", "live"] as const) {
    const header = `t=${timestamp},${mode === "test" ? "te" : "li"}=${digest}`;
    assertEquals(
      await verifyPayMongoSignature(raw, header, secret, mode, timestamp),
      true,
    );
    assertEquals(
      await verifyPayMongoSignature(
        raw,
        header,
        secret,
        mode === "test" ? "live" : "test",
        timestamp,
      ),
      false,
    );
    assertEquals(
      await verifyPayMongoSignature(raw + " ", header, secret, mode, timestamp),
      false,
    );
    assertEquals(
      await verifyPayMongoSignature(raw, header, secret, mode, timestamp + 301),
      false,
    );
  }
});

Deno.test("health check authenticates before collection, reports degradation and hides errors", async () => {
  const secret = "synthetic-local-monitor-fixture-32-characters";
  let calls = 0;
  const handler = healthCheckHandler(secret, () => {
    calls++;
    return Promise.resolve({ failed_payments: 0, blocked_expiry: 0 });
  });
  const request = () =>
    new Request("http://localhost/health-check", {
      headers: { "x-tricgabay-monitor": secret },
    });
  assertEquals(
    (await handler(new Request("http://localhost/health-check"))).status,
    401,
  );
  assertEquals(calls, 0);
  const good = await handler(request());
  assertEquals(good.status, 200);
  assertEquals(good.headers.get("cache-control"), "no-store");
  assertEquals(
    (await healthCheckHandler(
      secret,
      () => Promise.resolve({ blocked_expiry: 1 }),
    )(request())).status,
    503,
  );
  const bad = await healthCheckHandler(secret, () => {
    throw new Error("private database details");
  })(request());
  assertEquals(await bad.json(), { status: "unavailable" });
  assertEquals(
    (await handler(
      new Request("http://localhost/health-check", { method: "POST" }),
    )).status,
    405,
  );
  assertEquals(
    (await healthCheckHandler("", () => Promise.resolve({}))(request())).status,
    401,
  );
});

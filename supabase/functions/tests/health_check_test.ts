import { assertEquals } from "@std/assert";
import { healthCheckHandler } from "../_shared/health_check.ts";

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

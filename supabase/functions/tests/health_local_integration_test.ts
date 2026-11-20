import { assertEquals, assertExists } from "@std/assert";
import { createClient } from "@supabase/supabase-js";
import { healthCheckHandler } from "../_shared/health_check.ts";
const url = Deno.env.get("LOCAL_SUPABASE_URL") ?? "",
  key = Deno.env.get("LOCAL_SUPABASE_SERVICE_ROLE_KEY") ?? "";
Deno.test({
  name:
    "health handler serves authenticated HTTP against real local database metrics",
  ignore: !url || !key,
  async fn() {
    if (!/^http:\/\/(127\.0\.0\.1|localhost):\d+$/.test(url)) {
      throw new Error("Loopback database only");
    }
    const admin = createClient(url, key, { auth: { persistSession: false } }),
      secret = crypto.randomUUID() + crypto.randomUUID();
    let collections = 0;
    const handler = healthCheckHandler(secret, async () => {
      collections++;
      const { data, error } = await admin.rpc("collect_operations_health");
      if (error) throw error;
      return data;
    });
    const server = Deno.serve({
      hostname: "127.0.0.1",
      port: 0,
      onListen: () => {},
    }, handler);
    try {
      const address = `http://127.0.0.1:${server.addr.port}/health-check`;
      const unauthorized = await fetch(address);
      assertEquals(unauthorized.status, 401);
      await unauthorized.body?.cancel();
      assertEquals(collections, 0);
      const response = await fetch(address, {
        headers: { "x-tricgabay-monitor": secret },
      });
      const data = await response.json();
      assertExists(data.metrics);
      assertEquals(
        response.status,
        Object.values(data.metrics as Record<string, number>).some((n) => n > 0)
          ? 503
          : 200,
      );
      assertEquals(Object.keys(data.metrics).sort(), [
        "blocked_expiry",
        "cron_failures",
        "failed_payments",
        "notification_failures",
        "stale_online_drivers",
      ]);
      assertEquals(collections, 1);
    } finally {
      await server.shutdown();
    }
  },
});

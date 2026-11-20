import { assertEquals, assertRejects, assertThrows } from "@std/assert";
import { expireCheckoutSafely, requireTestProviderMode } from "../_shared/paymongo_expiry.ts";
Deno.test("provider expiry success is acknowledged only from an expired snapshot", async () => {
  const result = await expireCheckoutSafely({
    expire: async () => ({
      ok: true,
      status: 200,
      body: { data: { attributes: { status: "expired" } } },
    }),
    retrieve: () => {
      throw new Error("unexpected retrieval");
    },
    recordPaid: () => {
      throw new Error("unexpected payment");
    },
  });
  assertEquals(result, "expired");
});
Deno.test("already expired 400 is resolved by retrieval", async () => {
  const result = await expireCheckoutSafely({
    expire: async () => ({ ok: false, status: 400, body: {} }),
    retrieve: async () => ({ data: { attributes: { status: "expired" } } }),
    recordPaid: () => {
      throw new Error("unexpected payment");
    },
  });
  assertEquals(result, "expired");
});
Deno.test("paid 400 reconciles money before acknowledging the job", async () => {
  let recorded = 0;
  const result = await expireCheckoutSafely({
    expire: async () => ({ ok: false, status: 400, body: {} }),
    retrieve: async () => ({
      data: {
        attributes: {
          status: "active",
          payments: [{
            id: "pay_fixture",
            attributes: { status: "paid", amount: 10000, currency: "PHP" },
          }],
        },
      },
    }),
    recordPaid: async () => {
      recorded++;
    },
  });
  assertEquals(result, "paid");
  assertEquals(recorded, 1);
});
Deno.test("processing 400 never invents provider expiry", async () => {
  const result = await expireCheckoutSafely({
    expire: async () => ({ ok: false, status: 400, body: {} }),
    retrieve: async () => ({
      data: {
        attributes: {
          status: "active",
          payments: [{
            id: "pay_fixture",
            attributes: { status: "processing", amount: 10000, currency: "PHP" },
          }],
        },
      },
    }),
    recordPaid: () => {
      throw new Error("unexpected payment");
    },
  });
  assertEquals(result, "processing");
});
Deno.test("provider errors remain retryable", async () => {
  const result = await expireCheckoutSafely({
    expire: async () => ({ ok: false, status: 503, body: {} }),
    retrieve: () => {
      throw new Error("unexpected retrieval");
    },
    recordPaid: () => {
      throw new Error("unexpected payment");
    },
  });
  assertEquals(result, "retry");
});
Deno.test("persistence failure does not acknowledge paid outcome", async () => {
  await assertRejects(() =>
    expireCheckoutSafely({
      expire: async () => ({ ok: false, status: 400, body: {} }),
      retrieve: async () => ({
        data: {
          attributes: {
            payments: [{
              id: "pay_fixture",
              attributes: { status: "paid", amount: 10000, currency: "PHP" },
            }],
          },
        },
      }),
      recordPaid: async () => {
        throw new Error("database unavailable");
      },
    })
  );
});
Deno.test("live mode and live credentials cannot use the test pipeline", () => {
  assertThrows(() => requireTestProviderMode("live", "sk_test_fixture"));
  assertThrows(() => requireTestProviderMode("test", "sk_live_fixture"));
  requireTestProviderMode("test", "sk_test_fixture");
});

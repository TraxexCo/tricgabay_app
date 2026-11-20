import { assertEquals } from "@std/assert";
import {
  CheckoutFlowError,
  checkoutIdempotencyKey,
  isTrustedPayMongoCheckout,
  parsePayMongoCheckout,
  resolvePayMongoCheckout,
} from "../_shared/paymongo_checkout.ts";

const bookingId = "62000000-0000-4000-8000-000000000001";
const amountCentavos = 12500;

const providerResource = (id = "cs_test_fault_injection") => ({
  data: {
    id,
    attributes: { checkout_url: `https://checkout.paymongo.com/${id}#client-key` },
  },
});

class TwoPartyBarrier {
  #arrivals = 0;
  #release!: () => void;
  #ready = new Promise<void>((resolve) => this.#release = resolve);

  async arrive(): Promise<void> {
    this.#arrivals += 1;
    if (this.#arrivals === 2) this.#release();
    await this.#ready;
  }
}

class FakeIdempotentProvider {
  readonly requests: string[] = [];
  readonly resources = new Map<string, unknown>();
  underlyingCreations = 0;
  loseNextResponse = false;
  barrier: TwoPartyBarrier | null = null;

  async create(key: string): Promise<unknown> {
    this.requests.push(key);
    if (this.barrier) await this.barrier.arrive();
    let resource = this.resources.get(key);
    if (!resource) {
      resource = providerResource(`cs_test_${this.underlyingCreations + 1}`);
      this.resources.set(key, resource);
      this.underlyingCreations += 1;
    }
    if (this.loseNextResponse) {
      this.loseNextResponse = false;
      throw new Error("simulated response loss after provider commit");
    }
    return resource;
  }
}

const runCheckout = <T>(options: {
  provider: FakeIdempotentProvider;
  persist: Parameters<typeof resolvePayMongoCheckout<T>>[0]["persistCheckout"];
  existing?: Parameters<typeof resolvePayMongoCheckout<T>>[0]["existing"];
}) =>
  resolvePayMongoCheckout<T>({
    bookingId,
    amountCentavos,
    existing: options.existing ?? null,
    createProviderCheckout: (key) => options.provider.create(key),
    persistCheckout: options.persist,
  });

Deno.test("checkout idempotency is stable for the booking business operation", () => {
  assertEquals(checkoutIdempotencyKey(bookingId), `tricgabay-checkout-${bookingId}-initial`);
  assertEquals(checkoutIdempotencyKey(bookingId), checkoutIdempotencyKey(bookingId));
  const failedPaymentId = "64000000-0000-4000-8000-000000000001";
  assertEquals(
    checkoutIdempotencyKey(bookingId, failedPaymentId),
    `tricgabay-checkout-${bookingId}-after-${failedPaymentId}`,
  );
});

Deno.test("lost provider response retries the same attempt and persists once", async () => {
  const provider = new FakeIdempotentProvider();
  provider.loseNextResponse = true;
  let persisted = 0;
  const persist = (checkout: { id: string; checkoutUrl: string }) => {
    persisted += 1;
    return Promise.resolve({ provider_checkout_id: checkout.id });
  };
  let failed = false;
  try {
    await runCheckout({ provider, persist });
  } catch {
    failed = true;
  }
  assertEquals(failed, true);
  const result = await runCheckout({ provider, persist });
  assertEquals(provider.requests[0], provider.requests[1]);
  assertEquals(provider.underlyingCreations, 1);
  assertEquals(persisted, 1);
  assertEquals(result, { provider_checkout_id: "cs_test_1" });
});

Deno.test("local persistence failure reuses the provider result on retry", async () => {
  const provider = new FakeIdempotentProvider();
  let attempts = 0;
  const persist = (checkout: { id: string }) => {
    attempts += 1;
    if (attempts === 1) return Promise.reject(new Error("simulated database failure"));
    return Promise.resolve(checkout.id);
  };
  await runCheckout({ provider, persist }).catch(() => undefined);
  const result = await runCheckout({ provider, persist });
  assertEquals(provider.requests[0], provider.requests[1]);
  assertEquals(provider.underlyingCreations, 1);
  assertEquals(attempts, 2);
  assertEquals(result, "cs_test_1");
});

Deno.test("two concurrent initial requests converge on one provider and local record", async () => {
  const provider = new FakeIdempotentProvider();
  provider.barrier = new TwoPartyBarrier();
  let storedId: string | null = null;
  let localRows = 0;
  let tail = Promise.resolve();
  const persist = async (checkout: { id: string }) => {
    const previous = tail;
    let release!: () => void;
    tail = new Promise<void>((resolve) => release = resolve);
    await previous;
    try {
      if (storedId === null) {
        storedId = checkout.id;
        localRows += 1;
      } else if (storedId !== checkout.id) {
        throw new Error("conflicting provider identity");
      }
      return storedId;
    } finally {
      release();
    }
  };
  const results = await Promise.all([
    runCheckout({ provider, persist }),
    runCheckout({ provider, persist }),
  ]);
  assertEquals(provider.requests[0], provider.requests[1]);
  assertEquals(provider.underlyingCreations, 1);
  assertEquals(localRows, 1);
  assertEquals(results, ["cs_test_1", "cs_test_1"]);
});

Deno.test("concurrent failed-checkout replacements share the failed-row attempt anchor", async () => {
  const provider = new FakeIdempotentProvider();
  provider.barrier = new TwoPartyBarrier();
  const existing = {
    id: "64000000-0000-4000-8000-000000000001",
    provider_checkout_id: "cs_test_failed",
    checkout_url: "https://checkout.paymongo.com/cs_test_failed",
    status: "failed",
    amount_centavos: amountCentavos,
  };
  const results = await Promise.all([
    runCheckout({ provider, existing, persist: (checkout) => Promise.resolve(checkout.id) }),
    runCheckout({ provider, existing, persist: (checkout) => Promise.resolve(checkout.id) }),
  ]);
  assertEquals(provider.requests[0], provider.requests[1]);
  assertEquals(
    provider.requests[0],
    checkoutIdempotencyKey(bookingId, existing.id),
  );
  assertEquals(provider.underlyingCreations, 1);
  assertEquals(results, ["cs_test_1", "cs_test_1"]);
});

Deno.test("an active checkout is reused without a provider or persistence call", async () => {
  const provider = new FakeIdempotentProvider();
  let persisted = 0;
  const result = await runCheckout({
    provider,
    existing: {
      id: "64000000-0000-4000-8000-000000000001",
      provider_checkout_id: "cs_test_active",
      checkout_url: "https://checkout.paymongo.com/cs_test_active",
      status: "processing",
      amount_centavos: amountCentavos,
    },
    persist: () => {
      persisted += 1;
      return Promise.resolve(null);
    },
  });
  assertEquals(result, {
    checkout_url: "https://checkout.paymongo.com/cs_test_active",
    reused: true,
  });
  assertEquals(provider.requests.length, 0);
  assertEquals(persisted, 0);
});

Deno.test("provider ambiguity remains stable across a simulated app restart", async () => {
  const provider = new FakeIdempotentProvider();
  provider.loseNextResponse = true;
  await runCheckout({ provider, persist: () => Promise.resolve("unexpected") }).catch(() =>
    undefined
  );
  // A new orchestration call has no in-memory client state; only the provider's
  // idempotency cache and the stable booking operation key survive.
  const result = await runCheckout({
    provider,
    persist: (checkout) => Promise.resolve(checkout.id),
  });
  assertEquals(provider.requests[0], provider.requests[1]);
  assertEquals(provider.underlyingCreations, 1);
  assertEquals(result, "cs_test_1");
});

Deno.test("stored identity and terminal-state conflicts fail before provider access", async () => {
  for (
    const existing of [
      {
        id: "64000000-0000-4000-8000-000000000001",
        provider_checkout_id: "cs_test_bad",
        checkout_url: "https://evil.test/cs_test_bad",
        status: "processing",
        amount_centavos: amountCentavos,
      },
      {
        id: "64000000-0000-4000-8000-000000000002",
        provider_checkout_id: "cs_test_paid",
        checkout_url: "https://checkout.paymongo.com/cs_test_paid",
        status: "paid",
        amount_centavos: amountCentavos,
      },
    ]
  ) {
    const provider = new FakeIdempotentProvider();
    let kind = "";
    try {
      await runCheckout({ provider, existing, persist: () => Promise.resolve(null) });
    } catch (error) {
      if (error instanceof CheckoutFlowError) kind = error.kind;
    }
    assertEquals(kind.length > 0, true);
    assertEquals(provider.requests.length, 0);
  }
});

Deno.test("accepts the documented PayMongo checkout HTTPS origin", () => {
  assertEquals(
    parsePayMongoCheckout({
      data: {
        id: "cs_test_ABC123",
        attributes: { checkout_url: "https://checkout.paymongo.com/cs_test_ABC123#client-key" },
      },
    }),
    {
      id: "cs_test_ABC123",
      checkoutUrl: "https://checkout.paymongo.com/cs_test_ABC123#client-key",
    },
  );
});

Deno.test("rejects malformed IDs, untrusted hosts, credentials, ports and non-HTTPS URLs", () => {
  const invalid = [
    ["bad", "https://checkout.paymongo.com/value"],
    ["cs_valid", "http://checkout.paymongo.com/value"],
    ["cs_valid", "https://checkout.paymongo.com.evil.test/value"],
    ["cs_valid", "https://checkout.paymongo.com@evil.test/value"],
    ["cs_valid", "https://user@checkout.paymongo.com/value"],
    ["cs_valid", "https://checkout.paymongo.com:444/value"],
    ["cs_valid", "not-a-url"],
  ];
  for (const [id, url] of invalid) assertEquals(isTrustedPayMongoCheckout(id, url), false);
});

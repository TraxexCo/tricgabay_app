export type PayMongoCheckout = {
  id: string;
  checkoutUrl: string;
};

export type ExistingPayMongoPayment = {
  id: string;
  provider_checkout_id: unknown;
  checkout_url: unknown;
  status: string;
  amount_centavos: number;
};

export class CheckoutFlowError extends Error {
  constructor(
    public readonly kind:
      | "stored_checkout_invalid"
      | "payment_state_requires_review"
      | "provider_result_invalid",
    message: string,
  ) {
    super(message);
    this.name = "CheckoutFlowError";
  }
}

const checkoutIdPattern = /^cs_[A-Za-z0-9_-]+$/;
const checkoutHost = "checkout.paymongo.com";

export const checkoutIdempotencyKey = (
  bookingId: string,
  previousFailedPaymentId?: string,
): string =>
  previousFailedPaymentId
    ? `tricgabay-checkout-${bookingId}-after-${previousFailedPaymentId}`
    : `tricgabay-checkout-${bookingId}-initial`;

export const parsePayMongoCheckout = (value: unknown): PayMongoCheckout | null => {
  if (value === null || typeof value !== "object" || Array.isArray(value)) return null;
  const data = (value as Record<string, unknown>).data;
  if (data === null || typeof data !== "object" || Array.isArray(data)) return null;
  const record = data as Record<string, unknown>;
  const attributes = record.attributes;
  if (attributes === null || typeof attributes !== "object" || Array.isArray(attributes)) {
    return null;
  }
  const id = record.id;
  const checkoutUrl = (attributes as Record<string, unknown>).checkout_url;
  if (typeof id !== "string" || typeof checkoutUrl !== "string") return null;
  if (!checkoutIdPattern.test(id)) return null;
  try {
    const parsed = new URL(checkoutUrl);
    if (
      parsed.protocol !== "https:" || parsed.hostname !== checkoutHost ||
      parsed.username !== "" || parsed.password !== "" || parsed.port !== ""
    ) return null;
  } catch {
    return null;
  }
  return { id, checkoutUrl };
};

export const isTrustedPayMongoCheckout = (
  providerCheckoutId: unknown,
  checkoutUrl: unknown,
): boolean =>
  parsePayMongoCheckout({
    data: { id: providerCheckoutId, attributes: { checkout_url: checkoutUrl } },
  }) !== null;

/**
 * Coordinates the retry-sensitive provider/persistence boundary. The injected
 * functions make transport loss and database failures deterministic in tests,
 * while production still performs the real PayMongo request and authoritative
 * PostgreSQL RPC. A result is never returned until persistence succeeds.
 */
export const resolvePayMongoCheckout = async <T>(options: {
  bookingId: string;
  amountCentavos: number;
  existing: ExistingPayMongoPayment | null;
  createProviderCheckout: (idempotencyKey: string) => Promise<unknown>;
  persistCheckout: (checkout: PayMongoCheckout) => Promise<T>;
}): Promise<T | { checkout_url: string; reused: true }> => {
  const { bookingId, amountCentavos, existing } = options;
  if (existing) {
    if (
      existing.amount_centavos !== amountCentavos ||
      !isTrustedPayMongoCheckout(existing.provider_checkout_id, existing.checkout_url)
    ) {
      throw new CheckoutFlowError(
        "stored_checkout_invalid",
        "Stored checkout requires administrator review.",
      );
    }
    if (["checkout_created", "processing"].includes(existing.status)) {
      return { checkout_url: existing.checkout_url as string, reused: true };
    }
    if (existing.status !== "failed") {
      throw new CheckoutFlowError(
        "payment_state_requires_review",
        "Existing payment state requires administrator review.",
      );
    }
  }

  const rawCheckout = await options.createProviderCheckout(
    checkoutIdempotencyKey(bookingId, existing?.id),
  );
  const checkout = parsePayMongoCheckout(rawCheckout);
  if (!checkout) {
    throw new CheckoutFlowError(
      "provider_result_invalid",
      "PayMongo returned an invalid checkout result.",
    );
  }
  return await options.persistCheckout(checkout);
};

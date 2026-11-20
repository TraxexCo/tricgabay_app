export type PaidCheckoutPayment = {
  id: string;
  attributes: { status: string; amount: number; currency: string; paid_at?: number };
};
export type CheckoutSnapshot = {
  data?: { attributes?: { status?: string; payments?: PaidCheckoutPayment[] } };
};
export async function expireCheckoutSafely(options: {
  expire: () => Promise<{ ok: boolean; status: number; body: CheckoutSnapshot }>;
  retrieve: () => Promise<CheckoutSnapshot>;
  recordPaid: (payment: PaidCheckoutPayment) => Promise<void>;
}): Promise<"expired" | "paid" | "processing" | "retry"> {
  const result = await options.expire();
  let snapshot = result.body;
  if (!result.ok) {
    if (result.status !== 400) return "retry";
    snapshot = await options.retrieve();
  }
  const attributes = snapshot.data?.attributes;
  const paid = attributes?.payments?.find((p) => p.attributes?.status === "paid");
  if (paid) {
    await options.recordPaid(paid);
    return "paid";
  }
  if (attributes?.status === "expired") return "expired";
  if (attributes?.payments?.some((p) => ["pending", "processing"].includes(p.attributes?.status))) {
    return "processing";
  }
  return "retry";
}
export function requireTestProviderMode(mode: unknown, key: string): void {
  if (mode !== "test" || !key.startsWith("sk_test_")) {
    throw new Error("Provider mode is not enabled or credentials do not match");
  }
}

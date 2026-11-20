export type RefundLocalStatus = "processing" | "succeeded" | "failed";

export type RefundProviderOutcome =
  | {
    kind: "accepted";
    providerRefundId: string;
    providerStatus: string;
    localStatus: RefundLocalStatus;
  }
  | {
    kind: "definitive_failure";
    providerStatus: "rejected";
    failureReason: string;
  }
  | {
    kind: "ambiguous";
    providerStatus: "malformed_response";
  };

type JsonObject = Record<string, unknown>;

const object = (value: unknown): JsonObject | null =>
  value !== null && typeof value === "object" && !Array.isArray(value) ? value as JsonObject : null;

export const payMongoRefundStatus = (value: string): RefundLocalStatus => {
  if (["succeeded", "refunded"].includes(value)) return "succeeded";
  if (["failed", "cancelled"].includes(value)) return "failed";
  return "processing";
};

export const payMongoRefundIdempotencyKey = (refundId: string): string =>
  `tricgabay-refund-${refundId}`;

export function classifyPayMongoRefundResponse(
  responseOk: boolean,
  payload: unknown,
): RefundProviderOutcome {
  const body = object(payload) ?? {};
  if (!responseOk) {
    const errors = Array.isArray(body.errors) ? body.errors : [];
    const first = object(errors[0]);
    const detail = typeof first?.detail === "string"
      ? first.detail
      : typeof first?.code === "string"
      ? first.code
      : "PayMongo did not accept the refund request.";
    return {
      kind: "definitive_failure",
      providerStatus: "rejected",
      failureReason: detail,
    };
  }

  const resource = object(body.data);
  const providerRefundId = typeof resource?.id === "string" ? resource.id.trim() : "";
  if (!providerRefundId) {
    // A 2xx response without a provider identifier cannot safely prove whether
    // a refund exists. Keep the reservation locked for reconciliation.
    return { kind: "ambiguous", providerStatus: "malformed_response" };
  }
  const attributes = object(resource?.attributes);
  const providerStatus = typeof attributes?.status === "string" ? attributes.status : "processing";
  return {
    kind: "accepted",
    providerRefundId,
    providerStatus,
    localStatus: payMongoRefundStatus(providerStatus),
  };
}

export function providerPaymentIdForRefundResource(
  resourceValue: unknown,
): string | null {
  const resource = object(resourceValue);
  const attributes = object(resource?.attributes);
  const explicitPaymentId = typeof attributes?.payment_id === "string"
    ? attributes.payment_id.trim()
    : "";
  if (explicitPaymentId) return explicitPaymentId;

  const resourceId = typeof resource?.id === "string" ? resource.id.trim() : "";
  const isPaymentResource = resource?.type === "payment" ||
    Array.isArray(attributes?.refunds);
  return isPaymentResource && resourceId ? resourceId : null;
}

export function refundReconciliationEventId(
  refundValue: unknown,
): string | null {
  const refund = object(refundValue);
  const attributes = object(refund?.attributes);
  const id = typeof refund?.id === "string" ? refund.id.trim() : "";
  if (!id) return null;
  const status = typeof attributes?.status === "string" ? attributes.status : "processing";
  const updatedAt = typeof attributes?.updated_at === "number" ||
      typeof attributes?.updated_at === "string"
    ? String(attributes.updated_at)
    : "unknown";
  return `reconcile:refund:${id}:${status}:${updatedAt}`;
}

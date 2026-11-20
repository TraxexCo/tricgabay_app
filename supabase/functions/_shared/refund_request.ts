export type RefundRequest = {
  bookingId: string;
  amountCentavos: number;
  reason: string;
};

const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export function parseRefundRequest(value: unknown): RefundRequest | null {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    return null;
  }
  const input = value as Record<string, unknown>;
  const bookingId = input.booking_id;
  const amountCentavos = input.amount_centavos;
  const reason = input.reason;
  if (
    typeof bookingId !== "string" || !uuid.test(bookingId) ||
    typeof amountCentavos !== "number" ||
    !Number.isSafeInteger(amountCentavos) || amountCentavos <= 0 ||
    typeof reason !== "string"
  ) return null;
  const normalizedReason = reason.trim();
  if (normalizedReason.length < 5 || normalizedReason.length > 500) return null;
  return {
    bookingId,
    amountCentavos,
    reason: normalizedReason,
  };
}

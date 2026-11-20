import { assertEquals } from "@std/assert";
import { parseRefundRequest } from "../_shared/refund_request.ts";

const bookingId = "20000000-0000-4000-8000-000000000001";

Deno.test("accepts and normalizes a valid refund request", () => {
  assertEquals(
    parseRefundRequest({
      booking_id: bookingId,
      amount_centavos: 5000,
      reason: "  Approved cancellation refund  ",
    }),
    {
      bookingId,
      amountCentavos: 5000,
      reason: "Approved cancellation refund",
    },
  );
});

Deno.test("rejects missing, malformed, fractional, and oversized refund input", () => {
  assertEquals(
    parseRefundRequest({ booking_id: bookingId, amount_centavos: 5000 }),
    null,
  );
  assertEquals(
    parseRefundRequest({
      booking_id: "not-a-uuid",
      amount_centavos: 5000,
      reason: "Valid reason",
    }),
    null,
  );
  assertEquals(
    parseRefundRequest({
      booking_id: bookingId,
      amount_centavos: 1.5,
      reason: "Valid reason",
    }),
    null,
  );
  assertEquals(
    parseRefundRequest({
      booking_id: bookingId,
      amount_centavos: 5000,
      reason: "x".repeat(501),
    }),
    null,
  );
});

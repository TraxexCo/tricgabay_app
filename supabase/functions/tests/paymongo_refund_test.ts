import { assertEquals } from "@std/assert";
import {
  classifyPayMongoRefundResponse,
  payMongoRefundIdempotencyKey,
  providerPaymentIdForRefundResource,
  refundReconciliationEventId,
} from "../_shared/paymongo_refund.ts";

Deno.test("classifies confirmed and processing refund responses", () => {
  assertEquals(
    classifyPayMongoRefundResponse(true, {
      data: { id: "ref_success", attributes: { status: "succeeded" } },
    }),
    {
      kind: "accepted",
      providerRefundId: "ref_success",
      providerStatus: "succeeded",
      localStatus: "succeeded",
    },
  );
  assertEquals(
    classifyPayMongoRefundResponse(true, {
      data: { id: "ref_pending", attributes: { status: "pending" } },
    }),
    {
      kind: "accepted",
      providerRefundId: "ref_pending",
      providerStatus: "pending",
      localStatus: "processing",
    },
  );
});

Deno.test("distinguishes definitive rejection from ambiguous malformed success", () => {
  assertEquals(
    classifyPayMongoRefundResponse(false, {
      errors: [{ code: "refund_not_allowed", detail: "Refund was rejected" }],
    }),
    {
      kind: "definitive_failure",
      providerStatus: "rejected",
      failureReason: "Refund was rejected",
    },
  );
  assertEquals(
    classifyPayMongoRefundResponse(true, {
      data: { attributes: { status: "pending" } },
    }),
    { kind: "ambiguous", providerStatus: "malformed_response" },
  );
});

Deno.test("keeps provider idempotency stable across retries", () => {
  const refundId = "50000000-0000-4000-8000-000000000001";
  assertEquals(
    payMongoRefundIdempotencyKey(refundId),
    payMongoRefundIdempotencyKey(refundId),
  );
  assertEquals(
    payMongoRefundIdempotencyKey(refundId),
    `tricgabay-refund-${refundId}`,
  );
});

Deno.test("extracts payment identity from payment and refund resources", () => {
  assertEquals(
    providerPaymentIdForRefundResource({
      id: "pay_parent",
      type: "payment",
      attributes: { refunds: [] },
    }),
    "pay_parent",
  );
  assertEquals(
    providerPaymentIdForRefundResource({
      id: "ref_child",
      type: "refund",
      attributes: { payment_id: "pay_parent" },
    }),
    "pay_parent",
  );
});

Deno.test("reconciliation event identity changes when provider state changes", () => {
  const pending = {
    id: "ref_1",
    attributes: { status: "pending", updated_at: 100 },
  };
  const succeeded = {
    id: "ref_1",
    attributes: { status: "succeeded", updated_at: 200 },
  };
  assertEquals(
    refundReconciliationEventId(pending),
    "reconcile:refund:ref_1:pending:100",
  );
  assertEquals(
    refundReconciliationEventId(succeeded),
    "reconcile:refund:ref_1:succeeded:200",
  );
});

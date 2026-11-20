import { assertEquals } from "@std/assert";
import {
  canManuallyDispatchCommunications,
  canReconcilePayment,
} from "../_shared/edge_authorization.ts";

Deno.test("manual communication dispatch requires an active operations administrator", () => {
  assertEquals(
    canManuallyDispatchCommunications({ activeAccount: true, operationsAllowed: true }),
    true,
  );
  assertEquals(
    canManuallyDispatchCommunications({ activeAccount: true, operationsAllowed: false }),
    false,
  );
  assertEquals(
    canManuallyDispatchCommunications({ activeAccount: false, operationsAllowed: true }),
    false,
  );
});

Deno.test("only the tourist owner or a finance administrator may reconcile payment", () => {
  assertEquals(
    canReconcilePayment({ userId: "tourist", touristId: "tourist", financeAllowed: false }),
    true,
  );
  assertEquals(
    canReconcilePayment({ userId: "finance", touristId: "tourist", financeAllowed: true }),
    true,
  );
  assertEquals(
    canReconcilePayment({ userId: "driver", touristId: "tourist", financeAllowed: false }),
    false,
  );
});

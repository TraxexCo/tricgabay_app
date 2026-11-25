import { assert, assertFalse } from "@std/assert";
import { isSchedulerRequest } from "../_shared/scheduler_auth.ts";

Deno.test("scheduler authentication requires a long exact secret", () => {
  const token = "0123456789abcdef0123456789abcdef";
  assert(
    isSchedulerRequest(new Headers({ "x-tricgabay-scheduler": token }), token),
  );
  assertFalse(
    isSchedulerRequest(
      new Headers({ "x-tricgabay-scheduler": "short" }),
      token,
    ),
  );
  assertFalse(
    isSchedulerRequest(
      new Headers({ "x-tricgabay-scheduler": `${token}x` }),
      token,
    ),
  );
  assertFalse(isSchedulerRequest(new Headers(), token));
  assertFalse(
    isSchedulerRequest(new Headers({ "x-tricgabay-scheduler": token }), null),
  );
});

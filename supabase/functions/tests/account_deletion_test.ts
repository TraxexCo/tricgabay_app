import { assertEquals, assertRejects } from "@std/assert";
import { deleteAccountSteps } from "../_shared/account_deletion.ts";

Deno.test("account deletion does not delete identity before private storage and sessions", async () => {
  const events: string[] = [];
  const step = (name: string) => async () => {
    events.push(name);
  };
  await deleteAccountSteps({
    prepare: step("prepare"),
    eraseStorage: step("storage"),
    revokeSessions: step("revoke"),
    deleteIdentity: step("identity"),
    finish: step("finish"),
  });
  assertEquals(events, ["prepare", "storage", "revoke", "identity", "finish"]);
});
for (const failure of ["prepare", "storage", "revoke", "identity", "finish"]) {
  Deno.test(`account deletion stops safely at ${failure} failure`, async () => {
    const events: string[] = [];
    const step = (name: string) => async () => {
      events.push(name);
      if (name === failure) throw new Error("interrupted");
    };
    await assertRejects(() =>
      deleteAccountSteps({
        prepare: step("prepare"),
        eraseStorage: step("storage"),
        revokeSessions: step("revoke"),
        deleteIdentity: step("identity"),
        finish: step("finish"),
      })
    );
    assertEquals(events.at(-1), failure);
  });
}

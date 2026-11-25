import { assertEquals, assertExists, assertNotEquals } from "@std/assert";
import { createClient } from "@supabase/supabase-js";

const url = Deno.env.get("LOCAL_SUPABASE_URL") ?? "";
const anonKey = Deno.env.get("LOCAL_SUPABASE_ANON_KEY") ?? "";
const serviceKey = Deno.env.get("LOCAL_SUPABASE_SERVICE_ROLE_KEY") ?? "";
const enabled = Boolean(url && anonKey && serviceKey);

Deno.test({
  name: "local auth creates, restores, suspends, rejects duplicates, and switches accounts",
  ignore: !enabled,
  async fn() {
    const admin = createClient(url, serviceKey, { auth: { persistSession: false } });
    const client = createClient(url, anonKey, { auth: { persistSession: false } });
    const suffix = crypto.randomUUID();
    const firstEmail = `auth-first-${suffix}@test.local`;
    const secondEmail = `auth-second-${suffix}@test.local`;
    const password = "Local-only-test-password-42!";
    const createdIds: string[] = [];
    let avatarPath = "";
    try {
      for (const email of [firstEmail, secondEmail]) {
        const { data, error } = await admin.auth.admin.createUser({
          email,
          password,
          email_confirm: true,
          user_metadata: { full_name: "Local Auth", requested_role: "tourist" },
        });
        if (error) throw error;
        assertExists(data.user);
        createdIds.push(data.user.id);
      }

      const invalid = await client.auth.signInWithPassword({
        email: firstEmail,
        password: "wrong-password",
      });
      assertExists(invalid.error);

      const first = await client.auth.signInWithPassword({ email: firstEmail, password });
      if (first.error) throw first.error;
      assertEquals(first.data.user?.id, createdIds[0]);
      const restored = await client.auth.getSession();
      assertEquals(restored.data.session?.user.id, createdIds[0]);

      const { data: effectiveRole, error: roleError } = await client.rpc(
        "current_profile_role",
      );
      if (roleError) throw roleError;
      assertEquals(effectiveRole, "tourist");

      const { data: visibleProfiles, error: visibleError } = await client.from("profiles")
        .select("id").in("id", createdIds);
      if (visibleError) throw visibleError;
      assertEquals(visibleProfiles.map((profile) => profile.id), [createdIds[0]]);

      avatarPath = `${createdIds[0]}/avatars/${crypto.randomUUID()}.jpg`;
      const avatarBytes = new Uint8Array([0xff, 0xd8, 0xff, 0xd9]);
      const ownUpload = await client.storage.from("profile-images").upload(
        avatarPath,
        avatarBytes,
        { contentType: "image/jpeg", upsert: false },
      );
      if (ownUpload.error) throw ownUpload.error;
      const ownDownload = await client.storage.from("profile-images").download(avatarPath);
      if (ownDownload.error) throw ownDownload.error;
      assertEquals((await ownDownload.data.arrayBuffer()).byteLength, avatarBytes.byteLength);

      const duplicate = await admin.auth.admin.createUser({
        email: firstEmail,
        password,
        email_confirm: true,
      });
      assertExists(duplicate.error);

      const { error: suspendError } = await admin.from("profiles").update({ status: "suspended" })
        .eq("id", createdIds[0]);
      if (suspendError) throw suspendError;
      const { data: suspended, error: profileError } = await admin.from("profiles")
        .select("status").eq("id", createdIds[0]).single();
      if (profileError) throw profileError;
      assertEquals(suspended.status, "suspended");

      await client.auth.signOut();
      const second = await client.auth.signInWithPassword({ email: secondEmail, password });
      if (second.error) throw second.error;
      assertNotEquals(second.data.user?.id, createdIds[0]);
      assertEquals(second.data.user?.id, createdIds[1]);

      const crossAccountRead = await client.storage.from("profile-images").download(avatarPath);
      assertExists(crossAccountRead.error);
      const crossAccountWrite = await client.storage.from("profile-images").upload(
        `${createdIds[0]}/avatars/foreign.jpg`,
        avatarBytes,
        { contentType: "image/jpeg", upsert: false },
      );
      assertExists(crossAccountWrite.error);
    } finally {
      await client.auth.signOut();
      if (avatarPath) await admin.storage.from("profile-images").remove([avatarPath]);
      for (const id of createdIds) await admin.auth.admin.deleteUser(id);
    }
  },
});

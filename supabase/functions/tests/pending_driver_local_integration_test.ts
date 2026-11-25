import { assertEquals, assertExists } from "@std/assert";
import { createClient } from "@supabase/supabase-js";

const url = Deno.env.get("LOCAL_SUPABASE_URL") ?? "";
const anonKey = Deno.env.get("LOCAL_SUPABASE_ANON_KEY") ?? "";
const serviceKey = Deno.env.get("LOCAL_SUPABASE_SERVICE_ROLE_KEY") ?? "";

Deno.test({
  name: "pending driver confirms email, signs in, uploads real documents and remains restricted",
  ignore: !(url && anonKey && serviceKey),
  async fn() {
    if (!/^http:\/\/(127\.0\.0\.1|localhost):\d+$/.test(url)) {
      throw new Error("This integration test only runs against loopback Supabase.");
    }
    const admin = createClient(url, serviceKey, { auth: { persistSession: false } });
    const client = createClient(url, anonKey, { auth: { persistSession: false } });
    const email = `pending-driver-${crypto.randomUUID()}@test.local`;
    const password = "Local-driver-only-password-42!";
    let userId = "";
    const paths: string[] = [];
    try {
      const notice = await client.rpc("get_privacy_notice");
      if (notice.error) throw notice.error;
      const version = notice.data.version;
      assertExists(version);
      const signup = await client.auth.signUp({
        email,
        password,
        options: {
          data: {
            full_name: "Pending Driver",
            phone: "+639171234567",
            requested_role: "driver",
            privacy_notice_version: version,
          },
        },
      });
      if (signup.error) throw signup.error;
      assertExists(signup.data.user);
      userId = signup.data.user.id;
      // This assertion fails if anyone disables email confirmations to make the test pass.
      assertEquals(signup.data.session, null);
      const premature = await client.auth.signInWithPassword({ email, password });
      assertExists(premature.error);

      // Confirm this synthetic email using a real Auth token, without external email delivery.
      const link = await admin.auth.admin.generateLink({ type: "signup", email, password });
      if (link.error) throw link.error;
      const verified = await client.auth.verifyOtp({
        token_hash: link.data.properties.hashed_token,
        type: "signup",
      });
      if (verified.error) throw verified.error;
      assertExists(verified.data.session);
      await client.auth.signOut();
      const login = await client.auth.signInWithPassword({ email, password });
      if (login.error) throw login.error;
      assertEquals(login.data.user.id, userId);
      const profile = await client.from("profiles").select("role,status").eq("id", userId).single();
      if (profile.error) throw profile.error;
      assertEquals(profile.data, { role: "driver", status: "pending" });
      const consent = await client.rpc("record_own_privacy_consent", { p_version: version });
      if (consent.error) throw consent.error;
      for (const file of ["license.jpg", "vehicle-registration.jpg"]) {
        const name = `${userId}/${file}`;
        if (file === "license.jpg") {
          // Match storage_client 2.8.1's Flutter multipart encoding, including
          // its empty filename; the second document exercises binary upload.
          const body = new FormData();
          body.append("cacheControl", "0");
          body.append(
            "",
            new Blob([new Uint8Array([0xff, 0xd8, 0xff, 0xd9])], { type: "image/jpeg" }),
            "",
          );
          const response = await fetch(`${url}/storage/v1/object/driver-documents/${name}`, {
            method: "POST",
            headers: {
              apikey: anonKey,
              Authorization: `Bearer ${login.data.session!.access_token}`,
              "x-upsert": "true",
            },
            body,
          });
          assertEquals(response.status, 200);
          await response.body?.cancel();
          paths.push(name);
          continue;
        }
        const upload = await client.storage.from("driver-documents").upload(
          name,
          new Uint8Array([0xff, 0xd8, 0xff, 0xd9]),
          { contentType: "image/jpeg", upsert: true },
        );
        if (upload.error) throw upload.error;
        paths.push(name);
      }
      const expires = new Date(Date.now() + 366 * 86400000).toISOString().slice(0, 10);
      const submit = await client.rpc("submit_driver_application", {
        p_plate_number: "LOCAL 123",
        p_franchise_number: "LOCAL-FRANCHISE",
        p_license_expires_on: expires,
        p_franchise_expires_on: expires,
        p_passenger_capacity: 3,
        p_accepts_accessibility_requests: true,
        p_license_document_path: paths[0],
        p_vehicle_document_path: paths[1],
      });
      if (submit.error) throw submit.error;
      const application = await client.from("driver_profiles").select("approval_status,is_online")
        .eq("profile_id", userId).single();
      if (application.error) throw application.error;
      assertEquals(application.data, { approval_status: "pending", is_online: false });
      const online = await client.rpc("set_driver_online", { p_online: true });
      assertExists(online.error);
      const after = await admin.from("driver_profiles").select("is_online")
        .eq("profile_id", userId).single();
      if (after.error) throw after.error;
      assertEquals(after.data.is_online, false);
    } finally {
      await client.auth.signOut();
      if (paths.length) await admin.storage.from("driver-documents").remove(paths);
      if (userId) await admin.auth.admin.deleteUser(userId);
    }
  },
});

import { createClient } from "@supabase/supabase-js";
import { corsHeaders, json } from "../_shared/http.ts";
import { deleteAccountSteps } from "../_shared/account_deletion.ts";

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const admin = createClient(Deno.env.get("SUPABASE_URL")!, serviceKey);
  const token = (request.headers.get("Authorization") ?? "").replace(/^Bearer /, "");
  try {
    const body = await request.json();
    if (
      body.confirmation !== "DELETE" || typeof body.request_id !== "string" ||
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
        body.request_id,
      )
    ) {
      return json({ error: "Confirm the deletion request" }, 400);
    }
    const worker = token === serviceKey;
    let userId: string;
    if (worker) {
      const { data, error } = await admin.from("account_deletion_requests").select("user_id")
        .eq("user_id", body.user_id).maybeSingle();
      if (error || !data) return json({ error: "Pending deletion not found" }, 404);
      userId = data.user_id;
    } else {
      const { data: { user }, error } = await admin.auth.getUser(token);
      if (error || !user) return json({ error: "Authentication required" }, 401);
      userId = user.id; // Never accept an interactive caller's target user ID.
    }
    async function eraseFolder(bucket: string, prefix: string): Promise<void> {
      for (let attempt = 0; attempt < 1000; attempt++) {
        const { data, error } = await admin.storage.from(bucket).list(prefix, { limit: 100 });
        if (error) throw error;
        if (!data?.length) return;
        for (const entry of data.filter((entry) => entry.id === null)) {
          await eraseFolder(bucket, `${prefix}/${entry.name}`);
        }
        const paths = data.filter((entry) => entry.id !== null).map((entry) =>
          `${prefix}/${entry.name}`
        );
        if (paths.length) {
          const { error: removeError } = await admin.storage.from(bucket).remove(paths);
          if (removeError) throw removeError;
        }
      }
      throw new Error("Storage cleanup remains pending");
    }
    await deleteAccountSteps({
      prepare: async () => {
        const { error } = await admin.rpc("prepare_account_deletion", {
          p_user_id: userId,
          p_request_id: body.request_id,
        });
        if (error) throw error;
      },
      eraseStorage: async () => {
        await eraseFolder("driver-documents", userId);
        await eraseFolder("profile-images", userId);
      },
      revokeSessions: async () => {
        if (!worker) {
          const { error } = await admin.auth.admin.signOut(token, "global");
          if (error) throw error;
        }
      },
      deleteIdentity: async () => {
        const { error } = await admin.auth.admin.deleteUser(userId);
        if (error && error.status !== 404) throw error;
      },
      finish: async () => {
        const { error } = await admin.rpc("finish_account_deletion", { p_user_id: userId });
        if (error) throw error;
      },
    });
    return json({ deleted: true });
  } catch {
    // No provider response, identifier, free-form text or credential enters logs.
    return json({
      error:
        "Deletion could not be completed. Finish active trips first; interrupted cleanup remains recoverable by support.",
    }, 409);
  }
});

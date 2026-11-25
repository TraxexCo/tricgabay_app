import { createClient } from "@supabase/supabase-js";
import { healthCheckHandler } from "../_shared/health_check.ts";

Deno.serve(
  healthCheckHandler(Deno.env.get("HEALTHCHECK_TOKEN") ?? "", async () => {
    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const { data, error } = await admin.rpc("collect_operations_health");
    if (error) throw error;
    return data;
  }),
);

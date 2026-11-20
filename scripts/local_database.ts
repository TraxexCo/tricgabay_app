export const container = Deno.env.get("LOCAL_DB_CONTAINER") ??
  "supabase_db_tricgabay_batch4_isolated";
if (!/^supabase_db_tricgabay_batch4_[a-z0-9_]+$/.test(container)) {
  throw new Error("Only an isolated Batch 4 database is allowed.");
}

export async function sql(query: string, allowError = false): Promise<string> {
  const child = new Deno.Command("docker", {
    args: [
      "exec",
      "-i",
      container,
      "psql",
      "-X",
      "-q",
      "-A",
      "-t",
      "-v",
      "ON_ERROR_STOP=1",
      "-U",
      "supabase_admin",
      "-d",
      "postgres",
    ],
    stdin: "piped",
    stdout: "piped",
    stderr: "piped",
  }).spawn();
  // Drain both output pipes while feeding a large catalog test script. Waiting
  // for stdin to finish first can deadlock when PostgreSQL fills stdout.
  const outputPromise = child.output();
  const writer = child.stdin.getWriter();
  await writer.write(new TextEncoder().encode(query));
  await writer.close();
  const result = await outputPromise;
  const output = new TextDecoder().decode(result.stdout),
    error = new TextDecoder().decode(result.stderr);
  if (!result.success && !allowError) {
    throw new Error(`Local PostgreSQL command failed: ${error.slice(-2000)}`);
  }
  return output.trim();
}
export function literal(value: unknown): string {
  return "'" + String(value).replaceAll("'", "''") + "'";
}
export function localApiUrl(): string {
  const url = Deno.env.get("LOCAL_SUPABASE_URL") ?? "";
  if (!/^http:\/\/(127\.0\.0\.1|localhost):\d+$/.test(url)) {
    throw new Error("Only a loopback Supabase API is allowed.");
  }
  return url;
}

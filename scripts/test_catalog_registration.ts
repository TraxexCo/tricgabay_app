import { sql } from "./local_database.ts";
async function mustFail(message: string) {
  const result = await new Deno.Command(Deno.execPath(), {
    args: [
      "run",
      "--allow-run=docker",
      "--allow-read",
      "--allow-write",
      "--allow-env",
      "scripts/test_catalog_access.ts",
    ],
    stdout: "piped",
    stderr: "piped",
  }).output();
  const error = new TextDecoder().decode(result.stderr);
  if (result.success || !error.includes(message)) {
    throw new Error(`Expected catalog rejection: ${message}`);
  }
}
try {
  await sql("create table public.batch4_unregistered_probe(id integer);");
  await mustFail("No expected-access rule for new relation");
} finally {
  await sql("drop table if exists public.batch4_unregistered_probe;");
}
try {
  await sql(
    "create function public.batch4_unfixed_definer_probe()returns integer language sql security definer as 'select 1';",
  );
  await mustFail("SECURITY DEFINER has no fixed search_path");
} finally {
  await sql("drop function if exists public.batch4_unfixed_definer_probe();");
}
console.log(
  "CATALOG_NEGATIVE_PASS unregistered_table_rejected=true unfixed_definer_rejected=true",
);

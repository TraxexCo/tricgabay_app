import { literal, sql } from "./local_database.ts";
import { logDirectory } from "./local_api.ts";
const stage = Deno.args.find((arg) => ["before", "after"].includes(arg));
if (!stage) throw new Error("Specify before or after");
if (Deno.args.includes("--seed")) {
  const count = Number(
    await sql(
      "select count(*) from public.bookings where id::text like 'c4300000-%'",
    ),
  );
  if (count !== 0) {
    throw new Error(
      "Benchmark fixture already exists: reset the isolated stack to re-seed",
    );
  }
  const result = await sql(
    await Deno.readTextFile("scripts/fixtures/performance.sql"),
  );
  console.log(`PERFORMANCE_SEED bookings=${result.split(/\r?\n/).at(-1)}`);
}
const owner = "c4100000-0000-4000-8000-000000000001",
  driver = "c4100000-0000-4000-8000-000000000101";
const admin = "c4100000-0000-4000-8000-000000000200";
await sql(
  `update public.profiles set role='admin' where id='${admin}';insert into public.admin_capabilities(profile_id,capability)values('${admin}','operations')on conflict do nothing;`,
);
const active =
  "status in ('payment_pending','scheduled','pending','accepted','replacement_pending','ongoing')";
const ordering = "order by created_at desc,id desc limit 50";
const queries = [
  {
    name: "tourist_history",
    actor: owner,
    filter: stage === "after" ? `tourist_id='${owner}'` : "true",
  },
  {
    name: "driver_history",
    actor: driver,
    filter: stage === "after" ? `driver_id='${driver}'` : "true",
  },
  {
    name: "tourist_active",
    actor: owner,
    filter: (stage === "after" ? `tourist_id='${owner}' and ` : "") + active,
  },
  {
    name: "driver_active",
    actor: driver,
    filter:
      (stage === "after"
        ? `(driver_id='${driver}' or status='pending') and `
        : "") + active,
  },
  { name: "admin_history", actor: admin, filter: "true" },
  { name: "admin_active", actor: admin, filter: active },
];
const results = [];
const baselineIndexes = Deno.args.includes("--baseline-indexes");
if (baselineIndexes && stage !== "before") {
  throw new Error("Baseline indexes are only valid for before");
}
const indexNames = [
  "bookings_created_id_idx",
  "bookings_tourist_created_id_idx",
  "bookings_driver_created_id_idx",
  "bookings_active_created_id_idx",
  "bookings_driver_active_created_id_idx",
];
let restoreIndexes = "";
if (baselineIndexes) {
  const migration = await Deno.readTextFile(
    "supabase/migrations/202611030016_batch4_booking_list_performance.sql",
  );
  restoreIndexes = [...migration.matchAll(/create index [\s\S]*?;/g)].map(
    (match) => match[0],
  ).join("\n");
  if (
    !indexNames.every((name) =>
      restoreIndexes.includes(`create index ${name} `)
    )
  ) throw new Error("Unexpected performance index definition");
  await sql(
    "begin;" + indexNames.map((name) =>
      `drop index public.${name};`
    ).join("\n") + "commit;",
  );
}
try {
  for (const query of queries) {
    const text =
        `select * from public.bookings where ${query.filter} ${ordering}`,
      runs = [];
    for (let n = 0; n < 4; n++) {
      const output = await sql(
        `begin;set local role authenticated;select set_config('request.jwt.claim.role','authenticated',true);select set_config('request.jwt.claim.sub',${
          literal(query.actor)
        },true);explain(analyze,buffers,format json) ${text};rollback;`,
      );
      const plan = JSON.parse(output.slice(output.indexOf("[")))[0];
      runs.push(plan);
    }
    const warm = runs.slice(1).map((p) => p["Execution Time"]).sort((a, b) =>
      a - b
    );
    results.push({
      name: query.name,
      sql: text,
      actor: query.actor,
      median_ms: warm[1],
      cold_ms: runs[0]["Execution Time"],
      plans: runs,
    });
  }
} finally {
  if (baselineIndexes) await sql("begin;" + restoreIndexes + "commit;");
}
const totalBookings = Number(await sql("select count(*) from public.bookings"));
await Deno.mkdir(logDirectory(), { recursive: true });
await Deno.writeTextFile(
  `${logDirectory()}/performance-${stage}.json`,
  JSON.stringify(
    {
      stage,
      bookings: 100000,
      total_database_bookings: totalBookings,
      migration_016_indexes_during_measurement: !baselineIndexes,
      results,
      limits: [
        "Base booking list SQL under actual authenticated RLS. Nested PostgREST child hydration, network and device rendering are separate.",
        "One cold and three warm executions; median of warm executions reported.",
        "Synthetic terminal booking INSERT bypasses triggers only during fixture creation.",
        "After stage includes explicit participant filters plus measured indexes; comparisons do not isolate each change.",
      ],
    },
    null,
    2,
  ),
);
for (const result of results) {
  console.log(
    `EXPLAIN_${stage.toUpperCase()} query=${result.name} median_ms=${
      result.median_ms.toFixed(3)
    } cold_ms=${result.cold_ms.toFixed(3)}`,
  );
}

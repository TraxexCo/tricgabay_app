import { literal, sql } from "./local_database.ts";
import {
  actors,
  publicDefiners,
  relationRule,
  rpcAllowed,
  rpcArguments,
  rpcPreparation,
} from "./security/access_rules.ts";

type Catalog = { relations: any[]; functions: any[]; buckets: any[] };
const destination = Deno.env.get("VALIDATION_LOG_DIR") ??
  ".audit-output/batch4";
await Deno.mkdir(destination, { recursive: true });
const actual: Catalog = JSON.parse(
  await sql(await Deno.readTextFile("scripts/security/catalog.sql")),
);
if (
  await sql(
    "select has_schema_privilege('anon','public','CREATE') or has_schema_privilege('authenticated','public','CREATE')",
  ) !== "f"
) {
  throw new Error(
    "Untrusted users can create objects on the definer search_path",
  );
}
const snapshotPath = "supabase/security/authorization_catalog.json";
const bucketNames = [
  "app-assets",
  "driver-documents",
  "driver-gcash-qr",
  "gcash-receipts",
  "profile-images",
  "tourist-spots",
];
for (const relation of actual.relations) relationRule(relation.key);
for (const bucket of actual.buckets) {
  if (!bucketNames.includes(bucket.key)) {
    throw new Error(`No expected access entry for bucket ${bucket.key}`);
  }
}
for (const fn of actual.functions) {
  if (fn.definer && !fn.search_path) {
    throw new Error(`SECURITY DEFINER has no fixed search_path: ${fn.key}`);
  }
  if (fn.definer && fn.privileges.anon && !publicDefiners.has(fn.name)) {
    throw new Error(`Unexpected anonymous definer: ${fn.key}`);
  }
  if (
    fn.schema === "public" && !fn.extension && fn.result !== "trigger" &&
    fn.privileges.authenticated
  ) rpcAllowed(fn.name, actors[1]);
}
if (Deno.args.includes("--update-catalog")) {
  await Deno.mkdir("supabase/security", { recursive: true });
  await Deno.writeTextFile(
    snapshotPath,
    JSON.stringify(actual, null, 2) + "\n",
  );
  console.log("CATALOG_SNAPSHOT_UPDATED review_required=true");
} else {
  const expected: Catalog = JSON.parse(await Deno.readTextFile(snapshotPath));
  for (const category of ["relations", "functions", "buckets"] as const) {
    const expectedMap = new Map(
      expected[category].map((entry: any) => [entry.key, entry]),
    );
    for (const entry of actual[category]) {
      if (!expectedMap.has(entry.key)) {
        throw new Error(
          `New ${category} object has no expected-access entry: ${entry.key}`,
        );
      }
      if (
        JSON.stringify(expectedMap.get(entry.key)) !== JSON.stringify(entry)
      ) throw new Error(`Catalog security contract changed: ${entry.key}`);
      expectedMap.delete(entry.key);
    }
    if (expectedMap.size) {
      throw new Error(
        `Expected objects disappeared: ${[...expectedMap.keys()].join(", ")}`,
      );
    }
  }
}
if (Deno.args.includes("--catalog-only")) {
  console.log(
    `CATALOG_REBUILD_MATCH relations=${actual.relations.length} functions=${actual.functions.length} buckets=${actual.buckets.length}`,
  );
  Deno.exit(0);
}
const applicationTables = actual.relations.filter((r) =>
  r.key.startsWith("public.") && r.kind === "r" &&
  r.key !== "public.spatial_ref_sys"
).map((r) => r.key);
const fingerprint = `select md5(concat_ws('|',${
  [...applicationTables, "storage.objects"].map((table) =>
    `(select coalesce(jsonb_agg(to_jsonb(t) order by to_jsonb(t)::text)::text,'[]') from ${table} t)`
  ).join(",")
}))`;
const fixture = await Deno.readTextFile("scripts/fixtures/authorization.sql");
let script =
  `begin isolation level repeatable read;set local search_path=public,extensions;${fixture}
create function pg_temp.matrix_fingerprint() returns text language sql as $hash$${fingerprint}$hash$;
create function pg_temp.matrix_probe(db_role text,subject text,command text,preparation text default '',check_changes boolean default true) returns jsonb
language plpgsql as $probe$
declare answer jsonb;value jsonb;before_hash text;after_hash text;as_role text;
begin
 begin
  if preparation<>'' then execute preparation; end if;
  if check_changes then before_hash:=pg_temp.matrix_fingerprint(); end if;
  execute format('set local role %I',db_role);
  perform set_config('request.jwt.claim.role',db_role,true);
  perform set_config('request.jwt.claim.sub',subject,true);
  as_role:=current_user;
  execute command into value;
  reset role;
  if check_changes then after_hash:=pg_temp.matrix_fingerprint(); end if;
  answer:=jsonb_build_object('state','00000','value',value,'changed',coalesce(before_hash<>after_hash,false),'as_role',as_role);
  raise exception using errcode='ZX001',message='rollback probe';
 exception when sqlstate 'ZX001' then null;
 when others then answer:=jsonb_build_object('state',sqlstate,'error',sqlerrm,'changed',false);
 end;
 return answer;
end $probe$;
`;
type Case = {
  key: string;
  actor: string;
  kind: string;
  expected: any;
  sql: string;
  preparation?: string;
  allowed?: boolean;
  upstream?: boolean;
  checkChanges?: boolean;
};
const cases: Case[] = [];
function add(test: Case) {
  cases.push(test);
  const actor = actors.find((a) => a.name === test.actor)!;
  script += `select 'MATRIX|'||${
    literal(cases.length - 1)
  }||'|'||pg_temp.matrix_probe(${literal(actor.dbRole)},${literal(actor.id)},${
    literal(test.sql)
  },${literal(test.preparation ?? "")},${test.checkChanges ?? false})::text;\n`;
}
// Capture synthetic fixture rows as JSON inside this transaction; no real user
// data or scheduler tokens are exported. Every mutation is rolled back by probe.
for (const relation of actual.relations) {
  const key = relation.key;
  for (const group of [1, 2]) {
    const rule = relationRule(key, group);
    for (const actor of actors) {
      const readable = relation.privileges[actor.dbRole].select;
      add({
        key: `${key}:read:${group}`,
        actor: actor.name,
        kind: "read",
        expected: readable
          ? (rule.rowless ? 0 : (rule.read(actor) ? 1 : 0))
          : "denied",
        sql: `select to_jsonb(count(*)) from ${key} where ${rule.where}`,
      });
    }
  }
  const rule = relationRule(key);
  const columns = relation.columns.filter((c: any) =>
    !c.generated && !c.identity
  );
  const writableColumn = rule.updateColumn ?? columns[0]?.name;
  const rowless = rule.rowless || !writableColumn;
  const columnList = columns.map((c: any) => `"${c.name}"`).join(",");
  // Source row is materialized as a literal by the owner into the test SQL.
  // A SELECT under the tested role would mask INSERT checks through SELECT RLS.
  script +=
    `create temp table if not exists matrix_rows(object_key text primary key,row_data jsonb);\n`;
  script += `insert into matrix_rows select ${
    literal(key)
  },to_jsonb(t) from ${key} t where ${rule.where} limit 1 on conflict do nothing;\n`;
  for (const actor of actors) {
    const access = relation.privileges[actor.dbRole];
    const insertAllowed = rule.insert?.(actor) ?? false;
    // matrix_probe receives the owner-materialized INSERT expression through
    // format; the JSON row is never looked up under the tested identity.
    const insertCommand = rowless
      ? `insert into ${key} default values returning to_jsonb(1)`
      : `insert into ${key}(${columnList}) select ${
        columns.map((c: any) => `x."${c.name}"`).join(",")
      } from jsonb_populate_record(null::${key},%L::jsonb)x returning to_jsonb(1)`;
    if (rowless) {
      add({
        key: `${key}:insert`,
        actor: actor.name,
        kind: "write",
        expected: insertAllowed ? "allowed" : "denied",
        sql: insertCommand,
      });
    } else {
      const index = cases.length;
      cases.push({
        key: `${key}:insert`,
        actor: actor.name,
        kind: "write",
        expected: insertAllowed ? "allowed" : "denied",
        sql: insertCommand,
      });
      script += `select 'MATRIX|'||${
        literal(index)
      }||'|'||pg_temp.matrix_probe(${literal(actor.dbRole)},${
        literal(actor.id)
      },format(${
        literal(insertCommand)
      },coalesce((select row_data from matrix_rows where object_key=${
        literal(key)
      }),'{}'::jsonb)),'',false)::text;\n`;
    }
    for (const operation of ["update", "delete"] as const) {
      const granted = operation === "update" && rule.updateColumn
        ? actor.dbRole === "authenticated"
        : access[operation];
      const allowed = rule[operation]?.(actor) ?? false;
      const expected = allowed ? "allowed" : (!granted ? "denied" : "no_rows");
      const command = operation === "update"
        ? (writableColumn
          ? `with changed as(update ${key} set "${writableColumn}"=${
            writableColumn === "read_at" ? "now()" : `"${writableColumn}"`
          } where ${rule.where} returning 1) select to_jsonb(count(*)) from changed`
          : `update ${key} set _missing=1`)
        : `with changed as(delete from ${key} where ${rule.where} returning 1) select to_jsonb(count(*)) from changed`;
      add({
        key: `${key}:${operation}`,
        actor: actor.name,
        kind: "write",
        expected,
        sql: command,
      });
    }
  }
}
let nonRpc = 0, rpcInvocations = 0;
for (const fn of actual.functions) {
  const nonCallable = fn.result === "trigger" ||
    /\b(internal|cstring|anyelement|anyarray|anycompatible|anynonarray)\b/.test(
      fn.argtypes + " " + fn.result,
    );
  if (nonCallable) nonRpc++;
  for (const actor of actors) {
    add({
      key: `${fn.key}:execute-privilege`,
      actor: actor.name,
      kind: "privilege",
      expected: fn.privileges[actor.dbRole],
      sql: `select to_jsonb(has_function_privilege(current_user,${
        literal(fn.key)
      },'EXECUTE'))`,
    });
    if (nonCallable) continue;
    const explicit = fn.schema === "public" && !fn.extension
      ? rpcArguments(fn.name, actor)
      : undefined;
    const args = explicit ??
      (fn.argtypes
        ? fn.argtypes.split(", ").map((type: string) => {
          // STRICT functions with constant NULLs can be folded to NULL before an
          // EXECUTE check. Use non-NULL arguments when probing revoked helpers.
          if (fn.strict && !fn.privileges[actor.dbRole]) {
            if (
              /^(text|character varying)$/.test(type)
            ) return `'matrix_nonexistent'::${type}`;
            if (type === "boolean") return "false";
            if (
              /^(integer|smallint|bigint|double precision|real|numeric)$/.test(
                type,
              )
            ) return `0::${type}`;
          }
          return `null::${type}`;
        })
        : []);
    const name = `${fn.schema}."${fn.name}"`;
    const upstream = fn.schema === "storage" || !!fn.extension;
    const allowed = fn.privileges[actor.dbRole] &&
      (upstream || rpcAllowed(fn.name, actor));
    add({
      key: `${fn.key}:invoke`,
      actor: actor.name,
      kind: "rpc",
      expected: fn.privileges[actor.dbRole] ? "semantic" : "denied",
      allowed,
      upstream,
      sql:
        `select coalesce(jsonb_agg(to_jsonb(result)),'[]'::jsonb) from ${name}(${
          args.join(",")
        }) result`,
      preparation: upstream ? "" : rpcPreparation(fn.name),
      checkChanges: !upstream || fn.volatility === "v",
    });
    rpcInvocations++;
  }
}
script += "rollback;";
const result = await sql(script);
const outcomes = result.split(/\r?\n/).filter((line) =>
  line.startsWith("MATRIX|")
).map((line) => {
  const split = line.indexOf("|", 7);
  return {
    index: Number(line.slice(7, split)),
    outcome: JSON.parse(line.slice(split + 1)),
  };
});
if (outcomes.length !== cases.length) {
  throw new Error(
    `Incomplete matrix output: ${outcomes.length}/${cases.length}`,
  );
}
const neutral = (value: any): boolean =>
  value == null || value === false || value === 0 || value === "" ||
  (Array.isArray(value)
    ? value.every(neutral)
    : typeof value === "object" && Object.values(value).every(neutral));
const failures: any[] = [];
const observations: any[] = [];
for (const { index, outcome } of outcomes) {
  const test = cases[index];
  let pass = false;
  if (test.kind === "privilege") {
    pass = outcome.state === "00000" && outcome.value === test.expected;
  } else if (test.kind === "read") {
    pass = test.expected === "denied"
      ? outcome.state === "42501"
      : outcome.state === "00000" && Number(outcome.value) === test.expected;
  } else if (test.kind === "write") {
    if (test.expected === "allowed") {
      pass = (outcome.state === "00000" && Number(outcome.value) >= 1) ||
        ["23505", "23503"].includes(outcome.state);
    } else if (test.expected === "no_rows") {
      pass = (outcome.state === "00000" && Number(outcome.value) === 0) ||
        outcome.state === "42501";
    } else pass = ["42501", "55000", "0A000"].includes(outcome.state);
  } else if (test.expected === "denied") pass = outcome.state === "42501";
  else if (test.upstream) {
    pass = !outcome.changed &&
      (outcome.state === "00000" ||
        [
          "22004",
          "22023",
          "22P02",
          "22012",
          "XX000",
          "0A000",
          "42804",
          "42846",
          "23502",
          "P0001",
          "42501",
          "42P01",
          "3F000",
          "22003",
        ].includes(outcome.state));
  } else if (test.allowed) {
    pass = outcome.state === "00000" ||
      (outcome.state === "P0001" &&
        !/capability required|administrator access required|active .*account required|authentication required|pending driver account required/i
          .test(outcome.error));
  } else {pass = outcome.state === "42501" || (outcome.state === "P0001") ||
      (outcome.state === "00000" && !outcome.changed &&
        neutral(outcome.value));}
  if (!pass) {
    failures.push({
      case: test.key,
      actor: test.actor,
      expected: test.expected,
      allowed: test.allowed,
      outcome,
    });
  }
  observations.push({ case: test.key, actor: test.actor, pass, outcome });
}
await Deno.writeTextFile(
  `${destination}/authorization-matrix.json`,
  JSON.stringify(
    {
      summary: {
        actors: actors.length,
        relations: actual.relations.length,
        functions: actual.functions.length,
        buckets: actual.buckets.length,
        cases: cases.length,
        rpcInvocations,
        catalogOnlyFunctions: nonRpc,
        failures: failures.length,
      },
      limits: [
        "Trigger and PostgreSQL internal/polymorphic support routines are catalog-only: they are not SQL/PostgREST RPCs.",
        "Upstream computational routines use typed NULL arguments; mathematical correctness is not tested.",
        "Permitted application RPC business-rule refusals are distinct from permission denial; workflow success paths also have pgTAP tests.",
        "Storage HTTP bucket authorization has a separate real API matrix.",
      ],
      failures,
      observations,
    },
    null,
    2,
  ),
);
const definers = actual.functions.filter((fn) => fn.definer).map((fn) => ({
  function: fn.key,
  search_path: fn.search_path,
  execute: fn.privileges,
  all_effective_execute_roles: fn.execute_roles,
  public_execute: fn.public_execute,
  flag: !fn.search_path
    ? "MISSING_SEARCH_PATH"
    : fn.privileges.anon && !publicDefiners.has(fn.name)
    ? "UNEXPECTED_ANON"
    : null,
}));
await Deno.writeTextFile(
  `${destination}/security-definer-snapshot.json`,
  JSON.stringify(definers, null, 2),
);
console.log(
  `AUTHORIZATION_MATRIX actors=${actors.length} relations=${actual.relations.length} functions=${actual.functions.length} buckets=${actual.buckets.length} cases=${cases.length} rpc_invocations=${rpcInvocations} catalog_only_functions=${nonRpc} failures=${failures.length}`,
);
console.log(
  `SECURITY_DEFINER_SNAPSHOT functions=${definers.length} missing_search_path=${
    definers.filter((d) => !d.search_path).length
  } unexpected_anon=${
    definers.filter((d) => d.flag === "UNEXPECTED_ANON").length
  }`,
);
if (failures.length) {
  console.error(JSON.stringify(failures.slice(0, 20), null, 2));
  Deno.exit(1);
}

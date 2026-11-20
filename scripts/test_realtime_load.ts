import { sql } from "./local_database.ts";
import { localClient, logDirectory } from "./local_api.ts";
import type {
  RealtimeChannel,
  SupabaseClient,
} from "npm:@supabase/supabase-js@2.118.0";

const pairs = Number(Deno.env.get("LOAD_DRIVER_COUNT") ?? 30),
  rounds = Number(Deno.env.get("LOAD_ROUNDS") ?? 20);
const roundDelay = Number(Deno.env.get("LOAD_ROUND_DELAY_MS") ?? 1500);
if (
  !Number.isInteger(pairs) || pairs < 2 || pairs > 100 ||
  !Number.isInteger(rounds) || rounds < 2 || rounds > 100
) throw new Error("Load size outside local safety bounds");
const people = Array.from(
  { length: pairs },
  () => ({
    tourist: crypto.randomUUID(),
    driver: crypto.randomUUID(),
    booking: crypto.randomUUID(),
  }),
);
const fare = crypto.randomUUID(), policy = crypto.randomUUID();
let seed =
  `begin;select set_config('request.jwt.claim.role','service_role',true);insert into public.fare_revisions(id,custom_fare_centavos,reason,is_current)values('${fare}',10000,'Synthetic load fare',false);insert into public.cancellation_policies(id,terms,is_current)values('${policy}','Synthetic load policy',false);`;
for (const p of people) {
  seed += `
insert into auth.users(id,email,raw_user_meta_data)values('${p.tourist}','load-${p.tourist}@example.test','{"full_name":"Synthetic load tourist"}'),('${p.driver}','load-${p.driver}@example.test','{"full_name":"Synthetic load driver","requested_role":"driver"}');
update public.profiles set status='active' where id='${p.driver}';
insert into public.driver_profiles(profile_id,plate_number,franchise_number,approval_status,is_online,last_seen_at,license_expires_on,franchise_expires_on,vehicle_inspection_expires_on,service_area_name,service_area_latitude,service_area_longitude,service_area_radius_km)values('${p.driver}','LOAD-${p.driver}','FR-${p.driver}','approved',true,now(),current_date+365,current_date+365,current_date+365,'Synthetic load area',14.9571,120.9188,15);
insert into public.bookings(id,tourist_id,driver_id,fare_revision_id,cancellation_policy_id,quoted_amount_centavos,payment_method,payment_status,status,pickup_address,pickup_latitude,pickup_longitude,pickup_code_hash)values('${p.booking}','${p.tourist}','${p.driver}','${fare}','${policy}',10000,'cash','unpaid','ongoing','Synthetic load pickup',14.9571,120.9188,crypt('2468',gen_salt('bf')));
insert into public.driver_locations(driver_id,latitude,longitude,heading,recorded_at)values('${p.driver}',14.9571,120.9188,0,now());`;
}
await sql(seed + "commit;");
const clients: SupabaseClient[] = [],
  channels: RealtimeChannel[] = [],
  received = new Set<string>(),
  duplicates: string[] = [],
  errors: string[] = [];
const channelErrors: string[] = [];
const warmupSubscriptions = new Set<string>();
let warmupDeliveries = 0, warmupExpected = 0, warmupAttempts = 0;
const snapshots: unknown[] = [];
const statistics = async () =>
  JSON.parse(
    await sql(
      `select jsonb_build_object('commits',xact_commit,'rollbacks',xact_rollback,'blocks_read',blks_read,'blocks_hit',blks_hit,'tuples_returned',tup_returned,'tuples_fetched',tup_fetched,'tuples_inserted',tup_inserted,'tuples_updated',tup_updated,'active_connections',(select count(*) from pg_stat_activity where datname='postgres')) from pg_stat_database where datname='postgres'`,
    ),
  );
async function subscribe(index: number, party: "tourist" | "driver") {
  const p = people[index], client = await localClient(p[party]);
  clients.push(client);
  const channel = client.channel(`synthetic-${p.booking}-${party}`).on(
    "postgres_changes",
    {
      event: "UPDATE",
      schema: "public",
      table: "driver_locations",
      filter: `driver_id=eq.${p.driver}`,
    },
    (payload) => {
      if (payload.new.driver_id !== p.driver) {
        errors.push("cross-user payload");
        return;
      }
      if (payload.new.heading === 350) {
        warmupDeliveries++;
        warmupSubscriptions.add(`${index}:${party}`);
        return;
      }
      const key = `${index}:${party}:${payload.new.heading}`;
      if (received.has(key)) duplicates.push(key);
      received.add(key);
    },
  );
  channels.push(channel);
  await new Promise<void>((resolve, reject) => {
    const timer = setTimeout(
      () => reject(new Error("Subscribe timeout")),
      35000,
    );
    channel.subscribe((status) => {
      if (status === "SUBSCRIBED") {
        clearTimeout(timer);
        resolve();
      }
      if (status === "CHANNEL_ERROR" || status === "TIMED_OUT") {
        channelErrors.push(`${index}:${party}:${status}`);
        clearTimeout(timer);
        reject(new Error(`Subscribe ${status}`));
      }
    });
  });
  return client;
}
const drivers: SupabaseClient[] = [], tourists: SupabaseClient[] = [];
try {
  for (let i = 0; i < pairs; i++) {
    tourists.push(await subscribe(i, "tourist"));
    drivers.push(await subscribe(i, "driver"));
  }
  // SUBSCRIBED is a channel acknowledgment, not a delivery barrier for every
  // cold replication subscription. Establish readiness with measured canaries.
  for (
    let attempt = 0;
    attempt < 3 && warmupSubscriptions.size < pairs * 2;
    attempt++
  ) {
    warmupAttempts++;
    const pending = people.map((_, index) => index).filter((index) =>
      !warmupSubscriptions.has(`${index}:driver`) ||
      !warmupSubscriptions.has(`${index}:tourist`)
    );
    warmupExpected += pending.length * 2;
    await Promise.all(pending.map(async (index) => {
      const { error } = await drivers[index].rpc(
        "publish_driver_location_with_flags",
        {
          p_latitude: 14.9571,
          p_longitude: 120.9188,
          p_accuracy: 5,
          p_heading: 350,
          p_speed: 0,
          p_recorded_at: new Date().toISOString(),
          p_is_mocked: false,
        },
      );
      if (error) throw error;
    }));
    const deadline = Date.now() + 15000;
    while (warmupSubscriptions.size < pairs * 2 && Date.now() < deadline) {
      await new Promise((resolve) => setTimeout(resolve, 100));
    }
  }
  if (warmupSubscriptions.size !== pairs * 2) {
    throw new Error("Replication delivery readiness failed");
  }
  await new Promise((resolve) => setTimeout(resolve, 2000));
  const before = await statistics(), start = performance.now();
  for (let round = 1; round <= rounds; round++) {
    await Promise.all(drivers.map(async (client) => {
      const { error } = await client.rpc("publish_driver_location_with_flags", {
        p_latitude: 14.9571 + round / 100000,
        p_longitude: 120.9188,
        p_accuracy: 5,
        p_heading: round,
        p_speed: 0,
        p_recorded_at: new Date().toISOString(),
        p_is_mocked: false,
      });
      if (error) throw error;
    }));
    if (round % 5 === 0) snapshots.push(await statistics());
    if (roundDelay > 0) await new Promise((r) => setTimeout(r, roundDelay));
  }
  const publishMs = performance.now() - start,
    expected = pairs * rounds * 2,
    deadline = Date.now() + 45000;
  while (received.size < expected && Date.now() < deadline) {
    await new Promise((r) => setTimeout(r, 100));
  }
  const after = await statistics();
  const missing: string[] = [];
  for (let i = 0; i < pairs; i++) {
    for (const party of ["tourist", "driver"]) {
      for (let round = 1; round <= rounds; round++) {
        const key = `${i}:${party}:${round}`;
        if (!received.has(key)) missing.push(key);
      }
    }
  }
  const loadReceived = expected - missing.length;
  const stale: string[] = [];
  for (let i = 0; i < pairs; i++) {
    for (const client of [drivers[i], tourists[i]]) {
      const { data, error } = await client.from("driver_locations").select(
        "heading",
      ).eq("driver_id", people[i].driver).single();
      if (error) {
        throw error;
      }
      if (data.heading !== rounds) stale.push(people[i].driver);
    }
  }
  // Realtime does not replay messages missed while disconnected. Re-subscribe,
  // then SELECT the authoritative row: this is the client's catch-up contract.
  await tourists[0].removeAllChannels();
  await tourists[0].realtime.disconnect();
  for (let heading = 101; heading <= 103; heading++) {
    const { error } = await drivers[0].rpc(
      "publish_driver_location_with_flags",
      {
        p_latitude: 14.958,
        p_longitude: 120.9188,
        p_accuracy: 5,
        p_heading: heading,
        p_speed: 0,
        p_recorded_at: new Date().toISOString(),
        p_is_mocked: false,
      },
    );
    if (error) throw error;
  }
  let caughtUp = -1;
  const reconnected = tourists[0].channel(`reconnect-${people[0].booking}`);
  await new Promise<void>((resolve, reject) => {
    const timer = setTimeout(
      () => reject(new Error("Reconnect timeout")),
      35000,
    );
    reconnected.subscribe(async (status) => {
      if (status === "SUBSCRIBED") {
        const { data, error } = await tourists[0].from("driver_locations")
          .select("heading").eq("driver_id", people[0].driver).single();
        clearTimeout(timer);
        if (error) reject(error);
        else {
          caughtUp = data.heading;
          resolve();
        }
      }
    });
  });
  const report = {
    pairs,
    connections: pairs * 2,
    rounds,
    round_delay_ms: roundDelay,
    warmup: {
      attempts: warmupAttempts,
      expected_deliveries: warmupExpected,
      actual_deliveries: warmupDeliveries,
      ready_subscriptions: warmupSubscriptions.size,
    },
    published_updates: pairs * rounds,
    expected_deliveries: expected,
    unique_deliveries: loadReceived,
    dropped_updates: missing.length,
    missing,
    channel_errors: channelErrors,
    duplicates: duplicates.length,
    unauthorized_payloads: errors.length,
    stale_final_rows: stale.length,
    publish_ms: publishMs,
    database: { before, after, snapshots },
    reconnect: {
      updates_while_disconnected: 3,
      authoritative_heading: caughtUp,
      passed: caughtUp === 103,
    },
    limitations: [
      "Local synthetic stress intentionally bypasses normal Flutter location throttling.",
      "Counts cover acknowledged subscriptions and a 45-second delivery deadline, not production capacity.",
      "Database counters include local background jobs; no hosted/provider service was called.",
    ],
  };
  await Deno.mkdir(logDirectory(), { recursive: true });
  await Deno.writeTextFile(
    `${logDirectory()}/realtime-load.json`,
    JSON.stringify(report, null, 2),
  );
  console.log(
    `REALTIME_LOAD connections=${pairs * 2} published=${
      pairs * rounds
    } expected=${expected} received=${report.unique_deliveries} dropped=${report.dropped_updates} duplicates=${duplicates.length} stale_final_rows=${stale.length} publish_ms=${
      publishMs.toFixed(1)
    }`,
  );
  console.log(
    `REALTIME_RECONNECT missed=3 authoritative_heading=${caughtUp} passed=${
      caughtUp === 103
    }`,
  );
  if (
    report.dropped_updates || duplicates.length || errors.length ||
    stale.length || caughtUp !== 103
  ) throw new Error("Realtime validation failed");
} finally {
  await Promise.all(clients.map((client) => client.removeAllChannels()));
  await Promise.all(clients.map((client) => client.realtime.disconnect()));
}

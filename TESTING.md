# Testing and reproduction

Use Flutter 3.44.6 / Dart 3.12.2, Deno 2, Docker and PowerShell 7. The runner pins Supabase CLI 2.121.0 and pglast 7.22. All database scripts refuse linked or incorrectly named workspaces and target `supabase_db_tricgabay_batch4_isolated` only. Never run validation reset commands against a hosted database.

## Commands

From the repository root:

```powershell
flutter pub get
flutter gen-l10n
flutter analyze --no-pub
flutter test --no-pub
pwsh -NoProfile -File scripts/check_sql.ps1
pwsh -NoProfile -File scripts/start_local_validation.ps1
pwsh -NoProfile -File scripts/validate_database.ps1
deno run --allow-run=docker --allow-read --allow-write=.audit-output --allow-env scripts/test_catalog_access.ts
deno run --allow-run --allow-env scripts/test_catalog_registration.ts
pwsh -NoProfile -File scripts/run_local_integrations.ps1
pwsh -NoProfile -File scripts/test_android_configuration.ps1
deno run --allow-read=pubspec.lock,supabase/functions/deno.lock --allow-write=.audit-output --allow-net=api.osv.dev scripts/scan_dependencies.ts
```

`validate_database.ps1` copies the current full chain, resets the task-owned local database, applies the managed extension-owner bootstrap, parses SQL, executes every pgTAP suite, proves three races with overlapping PostgreSQL locks, and verifies deletion resumption in independently committed sessions. Its output logs live in `.audit-output/batch4` unless `-LogDirectory` is supplied. Startup logs contain disposable local keys and must never be published as artifacts.

Run pgTAP before committed concurrency/API/load/benchmark fixtures. Several legacy suites assert fixture-wide counts. The standalone pgTAP runner now refuses a database containing bookings, with a reset instruction; this prevents misleading failures from running it after load tests.

The normal catalog command compares the saved contract and does not update it. Only after reviewing intentional catalog changes run the same command with `--update-catalog`. The negative test proves rejection of a new unregistered table and an unfixed SECURITY DEFINER function, then removes only those test objects.

`run_local_integrations.ps1` obtains loopback-only credentials in memory, runs Deno tests including actual Auth/Storage/HTTP health, then the Storage matrix and Realtime load. It clears credential environment variables afterward. The 30-driver/30-tourist default sends 600 updates to 60 subscriptions at 1.5-second rounds, below the isolated tenant's 100-message/second cap. Each location update has two expected deliveries. Measured warm-up canaries establish delivery readiness before workload counting; the report retains warm-up attempts/counts separately. A cold acknowledged subscription previously missed its first event. After disconnecting a tourist the test publishes three updates and proves an authoritative SELECT catches up on reconnection. `LOAD_DRIVER_COUNT`, `LOAD_ROUNDS`, `LOAD_ROUND_DELAY_MS` change the stress profile within bounds. Faster runs can exceed Realtime's limit and deliberately fail the loss assertion; retain their counts rather than treating them as successful delivery tests.

## Performance

The fixture creates exactly 100,000 terminal bookings across 200 synthetic accounts. Bulk insertion temporarily disables workflow triggers/FK triggers inside a transaction to avoid synthetic notifications, not to verify booking creation. CHECK/unique constraints and indexes remain enforced. Normal RLS is enabled for every EXPLAIN query. Existing eight-character reference collisions were observed during the initial seed; migration 016 lengthens future references.

The final controlled comparison uses the same seeded database: `before --baseline-indexes` temporarily removes only the five migration 016 indexes, measures the original query shape and restores those exact indexes in a finally block. The `after` run then measures the actual participant filter, including a driver's unassigned pending offers. There is one cold and three warm executions per query; JSON retains plans and buffers. Do not label a final-index run `before` without that flag. This diagnostic mutates indexes only in the strictly guarded disposable stack; never copy the procedure to a live database.

```powershell
# On the final isolated schema:
$env:VALIDATION_LOG_DIR='.audit-output/batch4'
deno run --allow-run=docker --allow-env --allow-read=scripts/fixtures/performance.sql --allow-write=.audit-output scripts/run_performance.ts after --seed
deno run --allow-run=docker --allow-env --allow-read=supabase/migrations/202611030016_batch4_booking_list_performance.sql --allow-write=.audit-output scripts/run_performance.ts before --baseline-indexes
deno run --allow-run=docker --allow-env --allow-write=.audit-output scripts/run_performance.ts after
```

The fixture refuses re-seeding an existing benchmark. Reset only the disposable stack for a new seed. EXPLAIN covers base booking lists under RLS; PostgREST nested hydration, network latency and device rendering are not included.

## Verification boundaries

The Batch 4 report contains exact command results and migration status. Local checks cover Flutter behavior/widgets, SQL contracts, concurrent sessions, real local Auth/Storage/Realtime, injected provider responses, HTTP health, scans, workflow syntax and Android build/configuration checks. GitHub workflows are manual drafts: no hosted CI execution was performed. History scanning is completed with findings, not a green secret gate.

Untested on a real device/provider: GPS/foreground behavior under OEM battery management, reinstall recovery, actual dialer/share sheet, App Links/domain association, real notifications, payment browser/webhook/refund timing, hosted quotas/pause/recovery and signed store distribution. See RELEASE_CHECKLIST.md.

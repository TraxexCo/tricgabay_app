# Batch 3 local database and worker operations

These instructions were exercised only against the isolated Docker project
`tricgabay_batch3_isolated`. No hosted database or function was changed.
The database scripts reject linked workspaces and non-Batch-3 container names.

## Reproduce the database checks

From this checkout in PowerShell, with Docker running:

```powershell
$workspace = Join-Path $env:TEMP 'tricgabay-batch3-isolated'
New-Item -ItemType Directory -Force -Path $workspace | Out-Null
npx --yes supabase@2.121.0 init --workdir $workspace
```

For a newly initialized workspace, set `project_id` in its
`supabase/config.toml` to `tricgabay_batch3_isolated`. Set
`[auth.email] enable_confirmations = true`. Do not change the SMS setting.
Copy this checkout's migration files into that workspace's
`supabase/migrations/` before the first start. On an existing workspace, inspect
its configuration first; do not initialize over it or reuse a linked project.

```powershell
Copy-Item -Path supabase/migrations/*.sql -Destination (Join-Path $workspace 'supabase/migrations/')
npx --yes supabase@2.121.0 start --workdir $workspace --exclude studio,imgproxy,realtime,postgres-meta,edge-runtime,logflare,vector,supavisor
pwsh -NoProfile -File scripts/check_sql.ps1
pwsh -NoProfile -File scripts/validate_database.ps1 -Workspace $workspace
```

The validator **resets this isolated database**, copies the current migration
chain, applies each file, parses all migration and pgTAP SQL, runs every pgTAP
suite, then runs the real-session concurrency and committed-deletion retry
harness. Run it before integration tests: the concurrency fixtures commit data
and affect audience counts if individual pgTAP files are run afterward without
another reset. Logs default to `C:/Users/Prince/.codex/artifacts/tricgabay-batch3/`.

Postgres, Auth, Storage, the API gateway and PostgREST are real services.
PostGIS, pgcrypto, pg_cron, pg_net and Vault come from the local Supabase stack.
There are no Auth/Storage schema stubs. Realtime and Edge Runtime are excluded;
these checks do not prove real Realtime reconnects or hosted function delivery.

## Real local Auth and Storage integration

Keep the following values in process memory. Do not print or commit them:

```powershell
$status = npx --yes supabase@2.121.0 status --workdir $workspace --output json 2>$null | ConvertFrom-Json
$env:LOCAL_SUPABASE_URL = $status.API_URL
$env:LOCAL_SUPABASE_ANON_KEY = $status.ANON_KEY
$env:LOCAL_SUPABASE_SERVICE_ROLE_KEY = $status.SERVICE_ROLE_KEY
deno test --config supabase/functions/deno.json --allow-env --allow-read --allow-net supabase/functions/tests
```

The pending-driver test requires email confirmation to be enabled. It checks
that signup has no session, unconfirmed login fails, and a real Auth verification
token permits login. It uploads two synthetic document objects to real Storage,
submits the application, and verifies the pending driver still cannot go online.
Email confirmation uses a token generated for a synthetic local address, not an
external mailbox. Synthetic identities and objects are cleaned up afterward.

## Interrupted account deletion

The durable `account_deletion_requests` row survives preparation. Financial facts
remain attached to a disconnected participant. The `delete-account` handler
accepts service-role recovery only for a user already present in that table.
It repeats preparation safely, removes that user's document/avatar folders,
deletes the Auth identity and finishes the request. A failed step leaves the
request available for another run.

The checked-in runner only accepts HTTP loopback endpoints:

```powershell
pwsh -NoProfile -File scripts/resume_account_deletions.ps1 -BaseUrl $env:LOCAL_SUPABASE_URL -DryRun
```

To run actual cleanup locally, serve the checkout's `delete-account` function
against the isolated project's Auth/Storage/database, then run the same command
without `-DryRun`. This HTTP cleanup path was not served or exercised in Batch 3;
the orchestration unit tests and independent committed database retry were run.
The dry run only reads requests at least 120 seconds old.

For a future deployed installation, an operator can run the following from a
trusted scheduler every five minutes. Set `SUPABASE_URL` and
`SUPABASE_SERVICE_ROLE_KEY` using the scheduler's secret store; keep that key off
client devices. The `delete-account` function must already be deployed. This is
an operations recipe, **not an installed or tested hosted schedule**:

```powershell
$base = $env:SUPABASE_URL.TrimEnd('/')
$headers = @{ apikey=$env:SUPABASE_SERVICE_ROLE_KEY; Authorization="Bearer $env:SUPABASE_SERVICE_ROLE_KEY" }
$cutoff = [Uri]::EscapeDataString([DateTime]::UtcNow.AddMinutes(-2).ToString('o'))
$pending = Invoke-RestMethod -Headers $headers -Uri "$base/rest/v1/account_deletion_requests?select=user_id,request_id&prepared_at=lt.$cutoff"
foreach ($item in $pending) {
  $body = @{user_id=$item.user_id;request_id=$item.request_id;confirmation='DELETE'} | ConvertTo-Json
  $result = Invoke-RestMethod -Method Post -Headers $headers -ContentType 'application/json' -Uri "$base/functions/v1/delete-account" -Body $body
  if ($result.deleted -ne $true) { throw 'Deletion remains pending; retry and investigate.' }
}
```

On an HTTP error, retain the durable request and retry the next run. Alert the
operator on repeated failures; inspect counts/age without logging personal text
or credentials. Do not bypass a financial-integrity or active-trip refusal.

## Provider checkout expiry

Migration `202611030010` queues checkout expiry when a payment-pending booking
is cancelled. A one-minute pg_cron job invokes the worker through pg_net. The
invoker deliberately does nothing until Vault contains BOTH:

- `tric_gabay_checkout_expiry_url`: the installation's exact HTTPS
  `https://PROJECT.supabase.co/functions/v1/expire-paymongo-checkouts` URL.
- `tric_gabay_anon_key`: its gateway key.

The worker also needs `PAYMONGO_TEST_SECRET_KEY` in its function secrets. It
authenticates the private `checkout_expiry` scheduler token and requires database
`service_configuration.paymongo_mode = 'test'` and an `sk_test_` key. Live mode
fails closed. No Vault worker URL was configured and no provider API was called
in this batch. Deployment and secret configuration remain owner operations.

The worker calls PayMongo's explicit expire endpoint. On an already-paid session,
it retrieves and records the payment before acknowledging the job; the database
then marks the cancelled booking as refund-required. Processing/error outcomes
retry after one minute. Claims last two minutes; after ten unsuccessful claims,
work is blocked for operator review. Inspect `checkout_expiry_requests` for
`state`, `attempts` and `last_result`; after resolving the cause, an operator may
reset a blocked row's state to `queued`, attempts to zero and next-attempt time
to now. Never mark it expired without provider confirmation.

Expiry is asynchronous, so the late-payment database guard remains necessary.
An actual provider-side expiration/refund was not tested. PayMongo documents
the [expire endpoint](https://docs.paymongo.com/reference/expire-a-checkout-session)
and [checkout lifecycle](https://docs.paymongo.com/docs/payment-channels-key-concepts).

## Driver heartbeat and mock-location review

`expire-stale-online-drivers` runs every minute. The configurable
`service_configuration.stale_heartbeat_seconds` defaults to 120 and accepts
30–3600 seconds. Detection can take up to one extra scheduler interval. It
changes availability; it does not cancel an assigned trip. The SQL test verifies
old/missing/fresh heartbeats, threshold changes and the scheduled job.

The flagged location RPC stores `Position.isMocked`, creates an admin operational
alert (at most once per driver per five minutes), and keeps the driver eligible.
This is a review signal, not spoofing prevention; a modified client can lie.

## Stop only this isolated stack

```powershell
npx --yes supabase@2.121.0 stop --project-id tricgabay_batch3_isolated --no-backup
```

This does not stop another project. Saved verification logs remain available.

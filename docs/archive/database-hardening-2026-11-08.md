# Connected database fixes — November 8, 2026

Applied to the existing tric-gabay project `xcsrjuqzwequmeqzedzd`, following the
owner's explicit request to fix the connected database. No commit/push, plan
upgrade, password change, payment-provider call or APK rebuild was performed.

## Implemented

PostGIS 3.3.7 moved from API-exposed `public` to non-exposed `extensions` using
Supabase's supported rebuild procedure. Application tables store numeric
coordinates; there were no geometry/geography table columns. The migration
preserves spatial references and restores both GiST expression indexes. DROP
EXTENSION uses RESTRICT: an unexpected dependency aborts the transaction.
Matching/arrival functions now resolve `extensions`; notification UUID parsing
and announcement audit helpers have explicit fixed search paths.

Hosted managed grants were not falsely reported as revoked. Supabase's managed
owner prevents postgres from revoking them. API isolation is the hosted fix;
extra owner-level revokes run only in the isolated local bootstrap.

The project was restarted to clear cached PostGIS lookups and returned Healthy.
Schema, data and role dumps were completed before deployment and are private
local artifacts. Existing test accounts/passwords were preserved. Verification
sign-ins revoke only their own session (`scope=local`), preserving phone sessions.

## Verification — tested

| Migration | Isolated full chain | Hosted |
| --- | --- | --- |
| Existing 52 through 202611030016 | PASS | Already installed; retained |
| 202611080001_postgis_api_isolation | PASS | Applied, recorded, verified |

All 53 local migration versions match the hosted migration table. Counts before
and after: auth users 3, profiles 3, bookings 0, spots 29, packages 3, storage
objects 3. No persistent test booking was created.

Exact final command-result lines (all successful commands exited 0):

```text
FULL_CHAIN_PASS migrations=53 clean_database=true storage_auth=real_services realtime=true managed_owner_bootstrap=true
SQL_PARSE_PASS files=80 pglast=v7.22
PGTAP_RESULT suites=21 assertions=345 failed_suites=0
AUTHORIZATION_MATRIX actors=13 relations=53 functions=150 buckets=4 cases=7007 rpc_invocations=1612 catalog_only_functions=26 failures=0
SECURITY_DEFINER_SNAPSHOT functions=120 missing_search_path=0 unexpected_anon=0
CONCURRENCY_PASS races=3 observed_lock_overlap=3
DELETION_RESUME_PASS independent_committed_sessions=2 ledger_facts_unchanged=true
POSTGIS_API_ISOLATION_PASS public_table_http=404 extensions_schema_http=406 public_extent_rpc_http=404
HOSTED_SIGNIN_PASS role=tourist active=true catalog=29 bookings_read=true notice_version=2026-11-03
HOSTED_SIGNIN_PASS role=driver active=true catalog=29 bookings_read=true notice_version=2026-11-03
HOSTED_OPERATIONS_HEALTH {"cron_failures":0,"blocked_expiry":0,"failed_payments":0,"stale_online_drivers":0,"notification_failures":0}
HOSTED_SIGNIN_PASS role=admin active=true catalog=29 bookings_read=true notice_version=2026-11-03
CASH_WORKFLOW_PASS online,heartbeat,create,replay,offer,accept,arrival,pickup_code,start,stop,complete,cash_confirmation,ledger; test changes rolled back
HOSTED_MIGRATIONS_PASS installed=53 local=53 missing=0 unexpected=0
HOSTED_ADVISOR kind=security-final total=71 errors=0 warnings=71
HOSTED_ADVISOR kind=performance-after total=38 errors=0 warnings=38
```

The new nine-assertion pgTAP suite checks extension isolation, absent public
table/extent RPCs, restored indexes, geography distance, pickup geofence, fixed
helper paths, unchanged notification parsing and matching/arrival resolution.
The authorization suite ran locally, not against hosted user data. Its snapshot
change was reviewed: only three PostGIS relations and 721 PostGIS functions
leave public; exactly five application function definitions change; buckets
and other relation security contracts are unchanged.

The hosted cash workflow uses SQL JWT simulation and rolls back; hosted HTTP
sign-ins separately verify real Auth tokens, role/profile, notice and catalog
access. This does not prove physical-device navigation or GPS/push behavior.

### Commands and raw evidence

Private evidence root:
`C:/Users/Prince/.codex/artifacts/tricgabay-db-hardening`.
The complete replacement ZIP contains only the changed repository files, with
no database backups or credentials.

```powershell
npx --yes supabase@2.121.0 db dump --linked --file <evidence>/before-schema.sql
npx --yes supabase@2.121.0 db dump --linked --data-only --use-copy --file <evidence>/before-data-private.sql
npx --yes supabase@2.121.0 db dump --linked --role-only --file <evidence>/before-roles-private.sql
pwsh -NoProfile -File scripts/start_local_validation.ps1 -LogDirectory <evidence>/local
pwsh -NoProfile -File scripts/validate_database.ps1 -LogDirectory <evidence>/local-validation -SkipConcurrency
deno run --allow-run=docker --allow-read --allow-write --allow-env scripts/test_catalog_access.ts --update-catalog --catalog-only
deno run --allow-run=docker --allow-read --allow-write --allow-env scripts/test_catalog_access.ts
pwsh -NoProfile -File scripts/test_database_concurrency.ps1 -LogDirectory <evidence>/concurrency
npx --yes supabase@2.121.0 db push --linked --dry-run
npx --yes supabase@2.121.0 db push --linked --yes
npx --yes supabase@2.121.0 db advisors --linked --type security --level warn --output json
npx --yes supabase@2.121.0 db advisors --linked --type performance --level warn --output json
pwsh -NoProfile -File <evidence>/verify-hosted.ps1
npx --yes supabase@2.121.0 db query --linked --file C:/Users/Prince/.codex/artifacts/tricgabay-phone-testing/cash-workflow-smoke.sql --output json
npx --yes supabase@2.121.0 db query --linked --file C:/Users/Prince/.codex/artifacts/tricgabay-connected-db-check/readiness.sql --output json
```

`VALIDATION_LOG_DIR` pointed to `<evidence>/catalog` for the catalog commands.
Raw deployment, dump, advisor, SQL, HTTP, pgTAP and concurrency results are saved
there. During restart, the first HTTP attempt returned 503; the final attempt
passed after recovery. An initial test harness array-count assertion failed
because PowerShell wrapped the REST array; the harness was corrected and all
roles passed. Neither initial failed attempt is represented as a passing run.

## Audit corrections

- Owner-level REVOKE statements do not fix hosted Supabase-managed grants.
  Previous local owner-bootstrap success did not establish hosted hardening.
- Unnamed PostGIS extent arguments prevent ordinary direct PostgREST invocation;
  SQL EXECUTE permission alone was not proof of a working anonymous HTTP RPC.
- Security findings fell from one ERROR and 80 WARN to zero ERROR and 71 WARN.
  The remaining 70 function advisories concern intentionally callable
  application RPCs/predicates, not 70 demonstrated authorization bypasses.
- The previously failed performance-advisor connection now succeeds. It reports
  31 per-row Auth/RLS initialization warnings and seven overlapping permissive
  policy warnings. These remain performance tuning work; they are not evidence
  of failed sign-in or an authorization bypass. No broad policy rewrite was
  made merely to remove advisory counts.

## Untested

Physical-phone navigation, background GPS, push receipt, native permissions,
PayMongo checkout/webhook/refund round trips and a backup restore drill were
not exercised in this database fix. Earlier app tests are not rerun claims.

## Not done / owner decisions

- Supabase's Email provider UI confirms leaked-password screening requires Pro
  or above. No subscription purchase was made. Decide whether to upgrade.
- Supply the real verified password-reset HTTPS domain and association setup.
- Verify and enter five local emergency agency numbers through the admin UI.
- The General settings page reports that `operations_health` depends on
  `cron.job_run_details`, blocking a future PostgreSQL platform upgrade. The
  current server is operational. Before any future upgrade, use a tested
  drop/recreate runbook for this view and dependent routines; do not drop the
  monitoring view during normal service just to dismiss the upgrade notice.
- Decide timing for the 38 performance advisories, provider validation and
  physical-device testing. Live payments remain disabled in test mode.

This is a verified fix of the identified database permission/path problems,
not a claim that the entire application has no remaining bugs.

References: [Supabase PostGIS remediation](https://supabase.com/kb/troubleshooting/security-advisor-flags-spatial_ref_sys-and-other-postgis-objects-in-the-public-schema-f9d408),
[password security and plan availability](https://supabase.com/docs/guides/auth/password-security).

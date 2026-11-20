# Tric-Gabay Batch 3 validation report

**Validation completed:** 2026-10-24 (Asia/Manila)  
**Branch / baseline commit:** `master` / `be032162bdbbd740292bca29444fe4e52978ec08`  
**Scope:** Isolated local validation only. No hosted Supabase project, remote
database, deployed Edge Function, real PayMongo operation, Git commit, push, or
merge was performed.

## Readiness assessment

**PASS — the backend is ready for migration review, not deployment.**

A fresh local Supabase stack was started on Docker Desktop. The database was
rebuilt from zero during correction and again for final verification. All 31
migrations applied in chronological order. All 79 pgTAP assertions, independent
two-connection concurrency checks, Edge Function checks, 10 Deno tests, 49
Flutter tests, static analysis, formatting, and the Android debug build passed.

The remaining work is the separately gated operational testing phase: real
email/FCM delivery, Android process-death and background-location behavior,
physical predictive Back, a two-device trip, Crashlytics visibility, signed
release gates, backup restoration, and any explicitly approved PayMongo test
environment exercise.

## 1. Environment and tools

| Tool or environment | Result |
|---|---|
| Windows | **PASS** — Windows 11 Home Single Language, build 26200, 64-bit |
| Disk | **PASS** — approximately 152.88 GB free before setup |
| Memory / virtualization | **PASS** — 15.2 GB RAM; firmware virtualization and hypervisor available |
| WSL | **PASS** — 3.0.3.0, WSL 2 default, kernel 6.18.54.1-1 |
| Docker Desktop | **PASS** — official 4.96.3 per-user installation; engine 29.9.2 |
| Flutter / Dart | **PASS** — Flutter 3.44.6 stable / Dart 3.12.2 stable |
| Java | **PASS** — Temurin OpenJDK 17.0.20 |
| Git | **PASS** — 2.55.0.windows.2 |
| Node.js / npm | **PASS** — Node 26.4.0 / npm 11.17.0 |
| Deno | **PASS** — 2.9.8, official per-user installation |
| Supabase CLI | **PASS** — 2.122.0 through the official npm distribution |
| Physical Android devices | **NOT TESTED** — belongs to the next operational phase |

WSL and Virtual Machine Platform were enabled only after explicit approval and
the required restart. Docker Desktop was installed from its official installer
after verifying SHA-256
`3d8adad4f6c86583e0b00ea19a76197c51ccf5c83437c9ed775b739756452507`.
No Docker account sign-in was required.

## 2. Isolation and existing-work protection

- The local stack used the repository's Supabase configuration and containers
  named for `tricgabay`.
- Every destructive database command specified `--local`; no remote reset,
  migration, or deployment command was issued.
- The database was the Supabase CLI instance on the local Docker engine.
  Generated local keys were redacted from captured output.
- Only synthetic `@test.local` identities, bookings, payments, and refunds were
  used. No PayMongo secret was used and no request was sent to PayMongo.
- Existing uncommitted application work was preserved. Nothing was reset,
  cleaned, stashed, discarded, committed, pushed, or merged.
- The Supabase CLI's generated `.branches/_current_branch` marker was removed
  after validation; no project source was removed.

## 3. Migration chain — **PASS**

The requested baseline contained 27 migrations. Batch 2 added the refund
timeout reconciliation migration, and executed validation found two production
defects requiring forward-only corrections. The final tree contains **31
migrations**, ending with:

- `202610230011_refund_timeout_reconciliation.sql`
- `202610230012_financial_ledger_trigger_enum_safety.sql`
- `202610230013_admin_rpc_execute_privileges.sql`
- `202610230014_environment_scoped_communications_dispatcher.sql`

`supabase db reset --local --no-seed` recreated the database and applied all 31
migrations successfully in order. No earlier migration was rewritten or
skipped. The final reset completed with exit code 0.

## 4. Database and pgTAP — **PASS: 79 / 79**

| Suite | Assertions | Result |
|---|---:|---|
| `001_schema_contracts.sql` | 19 | **PASS** |
| `002_financial_security.sql` | 31 | **PASS** |
| `003_capability_rls.sql` | 13 | **PASS** |
| `004_refund_reconciliation.sql` | 16 | **PASS** |

The suites validate refund authorization and rejection, direct RPC privilege
restrictions, monotonic payment/refund transitions, duplicate event
idempotency, exactly-one ledger records, retryable unknown events, amount and
currency review behavior, capability-specific data access, owner-only avatar
access, timeout recovery, late provider-ID binding, and authoritative refund
success/failure reconciliation.

### Final ACL and policy inspection — **PASS**

Runtime catalog queries confirmed:

- anonymous grants on internal administrator implementations: `0`;
- anonymous grants on administrator capability wrappers: `0`;
- anonymous execution of `reserve_paymongo_refund`: `false`;
- service-role execution of `process_paymongo_refund_event`: `true`;
- expected RLS policies are installed across application and storage tables.

## 5. Independent concurrency — **PASS**

Two finance-authorized PostgreSQL connections attempted the same synthetic
refund reservation simultaneously. One succeeded and the competing transaction
was rejected. The final state contained one refund and one `refund_requested`
audit event.

Two service-role connections then submitted the same authoritative provider
event simultaneously. One returned `applied_refund`; one returned `duplicate`.
The final state contained one provider event, one refund ledger entry, and a
single `succeeded` refund.

This verifies local database lock/constraint behavior. Provider-side
idempotency is separately covered by the deterministic Deno test; no provider
call was made.

## 6. Edge Function and Deno validation

| Check | Result |
|---|---|
| Deno formatting | **PASS** — 12 files checked after canonical formatting |
| Deno lint | **PASS** — 12 files |
| Deno type-check | **PASS** — three handlers and four test modules |
| Deno Edge/shared tests | **PASS** — 10 / 10 |
| Secret literal scan | **PASS** — no PayMongo or Supabase secret key found; one historical public anonymous client JWT is documented below |
| Sensitive error/log scan | **PASS** — no raw caught/provider details or keys exposed by affected handlers |

Type-checked handlers were `paymongo-webhook`, `process-paymongo-refund`, and
`reconcile-paymongo-payment`. Tests cover response classification, malformed
responses, stable refund idempotency, provider identity extraction,
reconciliation event identity, webhook signatures, refund input, and scheduler
authentication.

## 7. Refund timeout and reconciliation scenarios

| Scenario | Result | Evidence |
|---|---|---|
| Definitive provider rejection | **PASS** | Mocked Deno classification |
| Accepted request followed by client timeout | **PASS** | Mock plus DB `processing` state |
| Ambiguous result cannot yet reconcile | **PASS** | Locked intermediate state; no blind resubmission |
| Later reconciliation confirms success | **PASS** | Isolated pgTAP and concurrency tests |
| Later reconciliation confirms failure | **PASS** | Isolated pgTAP test |
| Retry after timeout | **PASS** | Stable idempotency key; duplicate reservation rejected |
| Two concurrent refund reservations | **PASS** | Independent local connections |
| Duplicate while original is processing | **PASS** | pgTAP and concurrency tests |
| Malformed/incomplete response | **PASS** | Mocked as ambiguous, never success |
| Reconciliation request times out/fails | **PASS (mock/design)** | Safe retryable path; no real HTTP failure injection |
| Real PayMongo sandbox refund | **NOT TESTED** | Outside this local-only batch |

## 8. Confirmed defects and corrections

### B3-01 — timed-out refund could not bind a later provider update

**Severity:** P0 financial integrity  
**Status:** **Corrected and runtime-verified.**

The webhook searched only by a provider refund ID that is absent when the
create-refund response times out. Reconciliation now uses provider payment
identity and amount to bind exactly one locked processing refund. It is
authoritative and retries do not create a second provider operation.

### B3-02 — shared ledger trigger mixed two enum types

**Severity:** P0 financial integrity  
**Status:** **Corrected by migration `202610230012`; runtime-verified.**

The shared trigger compared `NEW.status` to payment values before safely
branching by source table. On refund insert PostgreSQL tried to coerce `paid`
into `refund_status`, aborting valid reservations. The replacement branches on
`TG_TABLE_NAME` first and performs only table-specific enum comparisons.

### B3-03 — stale anonymous grants survived administrator function renames

**Severity:** P1 least-privilege hardening  
**Status:** **Corrected by migration `202610230013`; runtime-verified.**

Renamed internal functions retained historical `anon` execute grants, while
new wrappers retained default public execution. Implementations are now
unavailable to public, anonymous, and authenticated callers; guarded wrappers
are available only to authenticated application callers. Catalog assertions
prevent regression.

### B3-04 — regression fixtures no longer matched the hardened schema

**Severity:** Test defect  
**Status:** **Corrected.**

The financial test created several pending bookings for one tourist, correctly
violating the one-live-booking constraint. Synthetic tourists are now isolated
per scenario. Storage tests using unsupported nested data-modifying syntax and
direct deletion now verify runtime update isolation and the installed
owner-path delete policy without weakening Supabase's storage guard.

### B3-05 — local scheduler contacted a hard-coded hosted endpoint

**Severity:** P1 environment isolation  
**Status:** **Corrected by migration `202610230014`; runtime-verified.**

The prior scheduler migration embedded the hosted Edge Function URL and its
public anonymous gateway key. During the first local run it made 11 rejected
HTTP requests (`401`); no hosted data changed, but an isolated local stack must
not contact a hosted project. The final dispatcher reads its environment's URL
and public gateway key from Supabase Vault and safely returns `NULL` when they
are absent. After the final clean rebuild, an explicit invocation produced no
queued request and `net._http_response` remained empty. The historical JWT is
a public client credential, not a secret, but the final function no longer uses
that embedded value.

## 9. Flutter and Android gates

| Check | Result |
|---|---|
| Dart formatting | **PASS** — 101 files checked, 0 changed |
| `dart analyze` | **PASS** — no issues found |
| Full Flutter suite | **PASS** — 49 / 49 |
| Focused avatar and Android Back suite | **PASS** — 7 / 7 |
| Android debug build | **PASS** — `build/app/outputs/flutter-apk/app-debug.apk`, 288,345,131 bytes |
| `git diff --check` | **PASS** — no whitespace errors; LF-to-CRLF notices only |

Expected Firebase platform-channel unavailability was logged during desktop
tests. The Android build emitted non-fatal future compatibility warnings for
Mapbox/Share Plus applying the Kotlin Gradle Plugin and Android SDK XML tool
version skew. These are maintenance risks, not current build failures.

## 10. Exact validation commands

```text
npx --yes supabase@latest start
npx --yes supabase@latest db reset --local --no-seed
npx --yes supabase@latest test db --local supabase/tests
docker exec supabase_db_tricgabay psql ...  # local ACL/RLS and concurrency harness
deno fmt <affected Edge/shared/test directories>
deno fmt --check <affected Edge/shared/test directories>
deno lint <affected Edge/shared/test directories>
deno check --allow-import=esm.sh,deno.land <affected handlers and tests>
deno test --allow-import=deno.land supabase/functions/tests
dart format --output=none --set-exit-if-changed lib test
dart analyze
flutter test
flutter test test/image_upload_validator_test.dart test/navigation_back_test.dart
flutter build apk --debug
git diff --check
git status --short --branch
```

Flutter was invoked through the SDK's Dart executable and
`flutter_tools.snapshot` because its Windows batch wrapper stalled in the
sandbox. The result is equivalent to the listed Flutter command.

## 11. Git state and change summary

- Branch: `master`
- Baseline commit: `be032162bdbbd740292bca29444fe4e52978ec08`
- Staged files: none
- Existing application/UI/security remediation remains uncommitted and
  preserved.
- Batch 3 adds refund response/idempotency/reconciliation helpers and tests,
  migrations `202610230011` through `202610230014`, pgTAP security coverage,
  late refund-ID binding, safe errors, and this evidence report.
- No secrets are recorded here or intentionally stored in source.

## 12. Remaining risks and approval gate

The local backend is ready for human migration review. It is **not approved for
remote migration or deployment**.

Still outside this batch and not evidence-backed here:

1. actual PayMongo test-environment HTTP behavior and webhook delivery;
2. actual SMTP/email and FCM delivery/retry behavior;
3. process-death recovery, background location, and live two-device tracking;
4. physical Android predictive Back and accessibility validation;
5. Crashlytics/performance visibility and operational alert delivery;
6. signed release gates and backup/restore rehearsal.

Stop here. Do not deploy, link/reset a hosted database, or begin operational
testing without explicit approval.

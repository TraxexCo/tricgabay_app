# Tric-Gabay Batch 7 cross-system hardening report

Date: 2026-10-24  
Scope: cross-system consistency, end-to-end authorization, recovery, migration reproducibility, and local release evidence  
Repository state: the existing dirty worktree was preserved; no commit, push, merge, deployment, hosted-project mutation, production credential, real payment, email, push delivery, or physical-device action was performed

## 1. Executive result

Batch 7 found and corrected five concrete cross-boundary gaps:

1. Any active authenticated account could invoke the global communications dispatcher, which then processed service-role queue work.
2. PayMongo checkout creation wrote the payment and booking state in two independent database requests and exposed raw provider/database errors.
3. An assigned driver could invoke payment reconciliation even though financial reconciliation belongs to the tourist owner or finance administration.
4. Several scheduler, dispatch, metric-refresh, trigger-only, and retired functions retained broader execute grants than their intended trust boundary.
5. A lost response after successful booking creation could be presented as a failure, leaving the client without the one-time pickup code and encouraging a blind retry.

The fixes are narrow: they preserve existing fares, cancellation/refund rules, booking transitions, RLS policies, and provider state machines. A fresh local database applied all 35 migrations and passed 113/113 pgTAP assertions. Flutter passed static analysis and 88/88 tests. Deno passed formatting, lint, 16 deterministic tests, one isolated local Auth integration test, and frozen type checks for all five Edge Functions. A debug APK was produced successfully.

These results do **not** establish production readiness. Physical Android behavior, real PayMongo test-mode callbacks, Brevo/FCM delivery, hosted Supabase configuration, deployment, backup/restore, production signing, and unresolved product policies remain unverified or deliberately deferred.

## 2. Actual stack, trust boundaries, and authoritative state

### Repository technologies identified

- Flutter/Dart mobile application with Riverpod and GoRouter.
- Supabase Flutter client, Supabase Auth, PostgREST/RPC, Realtime, and Storage.
- PostgreSQL migrations, PL/pgSQL functions/triggers, pgTAP, RLS, and Storage policies.
- Deno TypeScript Supabase Edge Functions.
- PayMongo test-mode checkout, webhook, reconciliation, and refund workflows.
- Firebase Messaging, Crashlytics, and Performance Monitoring clients.
- Brevo email delivery from the communications worker.
- Mapbox and Geolocator for maps, routing presentation, and device positions.
- Android Gradle/Kotlin build configuration and GitHub Actions YAML.

### Trust and authority map

| Boundary | Authoritative owner | Non-authoritative consumers | Security consequence |
|---|---|---|---|
| Identity/session | Supabase Auth token plus active `profiles`/driver approval state | Flutter route and shell visibility | Client role checks improve UX only; every mutation must be rejected again by Edge/SQL/RLS |
| Booking/trip/fare/cancellation | PostgreSQL rows, constraints, locked RPC transitions, snapshotted revision IDs | Flutter state and offline snapshot | Cached or in-memory state never authorizes a transition and critical writes are not queued for replay |
| PayMongo settlement/refund | Authenticated provider event/reconciliation, committed through monotonic SQL functions and ledger triggers | Checkout page, Flutter status, notifications | A redirect or client enum cannot mark money paid/refunded |
| Checkout local commit | `record_paymongo_checkout` service-role RPC | Checkout Edge Function | Payment row and booking payment status now commit in one transaction |
| Communications | PostgreSQL notification/delivery queue and current lease token | Brevo/FCM and Flutter notification UI | Delivery failure cannot alter booking or financial truth |
| Driver position | Device sensor supplies a sample; `publish_driver_location` validates and commits accepted current/history state | Tourist/driver/admin maps | UI coordinates and cached positions are not authority; terminal state tears tracking down |
| Images | Storage object plus `profiles.avatar_path` reference and Storage owner policies | Cached image/UI | Upload succeeds before profile mutation; deletion is owner- and reference-checked |
| Administrator capability | Active profile plus `admin_capabilities`, enforced in database/Storage and Edge Functions | Hidden/disabled UI actions | Stale visible controls do not retain authority after revocation |

### Security-reference limitation

The installed `security-best-practices` skill was used only as general TypeScript security context for the Deno Edge Function review. Its available framework references did not include Deno, Flutter/Dart, PostgreSQL, Supabase Auth/RLS/Storage, or PayMongo. No claim is made that a dedicated framework reference for those technologies was consulted. Findings for those layers come from repository inspection, local ACL/RLS introspection, migration execution, pgTAP, and conservative established principles such as least privilege, server authority, transactionality, fail-closed authorization, bounded diagnostics, and idempotency.

## 3. Findings, evidence, and corrections

### B7-01 — High: global communications worker callable by ordinary accounts

**Reproduction evidence:** `dispatch-communications` accepted any authenticated user with an active profile, created a service-role client, and claimed the global delivery queue. `BackendRepository.rpc`, push registration, and refund completion called it after routine user actions.

**Risk:** a tourist or driver could cause unrelated users' queued email/push work to be processed, consume provider quotas, and amplify traffic. They could not select or read arbitrary queue payloads through RLS, but they crossed a service-role operational boundary.

**Correction:**

- Removed all ordinary-client dispatcher invocations.
- Kept scheduled dispatch independent through the private scheduler token.
- Required an active administrator with the `operations` capability for any manual invocation.
- Returned a bounded correlation ID on worker-level failures rather than raw exceptions.
- Added pure TypeScript authorization tests.
- Reasserted service-role-only execution for queue claim/finalization RPCs.

### B7-02 — Critical: checkout local state could split across two writes

**Reproduction evidence:** after PayMongo returned a checkout, the Edge Function inserted `payments`, then separately updated `bookings.payment_status`. A failure between those requests left contradictory local state. A retry could return the stored URL without healing the booking. Provider errors and the catch path could return raw provider/database details.

**Correction:**

- Added service-role-only `record_paymongo_checkout`.
- The RPC locks the booking, validates method/state/fixed amount, reuses an existing authoritative checkout, inserts the payment, and updates booking status in one transaction.
- The existing stable PayMongo idempotency key remains unchanged.
- Replaced raw provider/database diagnostics with a generic message, retryability indicator where known, and correlation ID.
- Added pgTAP coverage for ACLs, valid atomic commit, one-row retry, exact amount, eligible booking state, and zero partial writes after rejection.

**Boundary retained:** the external PayMongo request cannot be part of the PostgreSQL transaction. A provider-success/database-unavailable outcome therefore remains reconcilable through the stable provider idempotency key and a later retry; it is not falsely called an atomic distributed transaction.

### B7-03 — High: driver participant could reconcile tourist payment

**Reproduction evidence:** `reconcile-paymongo-payment` authorized either booking participant, so the assigned driver could trigger a provider lookup and service-role financial transition.

**Correction:** reconciliation now permits only the booking's tourist owner or an active finance-capable administrator. The rule is isolated in a pure helper with tourist/finance/driver cases. Database payment transitions remain service-role-only and monotonic.

### B7-04 — High: final function ACLs did not consistently match intended roles

**Reproduction evidence:** fresh local `pg_proc.proacl` inspection showed direct anonymous/authenticated execute grants on privileged or internal functions after later `CREATE OR REPLACE` operations. Particularly important examples were message claims/finalization, refund finalization, scheduled reminders, direct driver-offer generation, metric refresh, trigger handlers, and a retired test-refund function. Some functions also checked `auth.role()` internally, but ACLs still exposed unnecessary entry points; scheduled reminders and offer generation had no caller-role check because they were designed for internal invocation.

**Correction:** the forward migration explicitly reasserts final grants:

- service role only: checkout commit, communications claim/finalization, refund finalization, scheduled reminders;
- authenticated plus internal capability/ownership checks: pickup-code recovery and administrator capability operations;
- no API-role execution: trigger handlers, reliability refresh, direct ranked-offer generation, and retired test-refund entry point.

Owner-executed triggers and database-owned scheduled calls continue to work. pgTAP verifies the important ACLs, and a post-migration ACL query confirmed the intended final entries.

### B7-05 — High: ambiguous booking success could lose the pickup credential

**Reproduction evidence:** the Flutter repository treated every non-response from `create_booking_with_schedule` as failure. The server may already have committed the booking, while the plaintext pickup code exists only in that lost response and its hash in PostgreSQL.

**Correction:**

- Known PostgREST/database validation errors still propagate normally.
- After a transport-style failure, the client performs an authoritative booking read and never blindly replays creation.
- If the one active tourist booking exists, the owner-only `recover_booking_pickup_code` RPC rotates the credential, clears prior failed-attempt/lock state, records an audit event, and returns the new code for secure local storage.
- If authority cannot be reached, the client explicitly says the outcome could not be confirmed and directs the tourist to reconnect and inspect Trips before retrying.
- pgTAP proves owner recovery, code rotation, and cross-owner denial.

## 4. Cross-system scenario inventory

| Scenario | Authoritative state and operation boundary | Failure/concurrency points | Local evidence | Batch 7 result / remaining evidence |
|---|---|---|---|---|
| Booking submit and concurrent acceptance | Locked PostgreSQL booking/offer RPCs, live-booking and live-driver constraints | repeated tap, response loss, two drivers, cancel-vs-accept | Flutter race tests; pgTAP; new owner-only timeout recovery | **Implemented** locally; network-shaped UI and physical process death remain |
| Checkout and reconciliation | PayMongo provider identity plus atomic SQL transition/ledger functions | duplicate create, provider success then DB outage, delayed/duplicate/out-of-order webhook, amount mismatch | Deno signature/state tests; pgTAP atomic commit and monotonic events | **Implemented** locally; real PayMongo test mode **Unverified** |
| Cancellation/completion/charge/refund | Booking row locks, snapshotted policy/fare, finance reservation, provider reconciliation, append-only ledger | cancel-vs-complete, repeated reservation, timeout, late provider event | Flutter TripRules/concurrency; financial pgTAP and refund reconciliation | **Implemented** for defined policy; arbitrary partial-refund reasons remain **Policy** |
| Notification creation and worker recovery | Database notification/delivery dedupe key and current lease token | duplicate trigger, provider failure, crash, stale worker, retry ceiling | fake-provider Deno tests and lease pgTAP | **Implemented** locally; Brevo/FCM receipt **Unverified** |
| Auth refresh, revocation, logout, account switch | Supabase Auth plus active profile/capability; session generation and teardown stores | stale token/UI, in-flight old response, remote sign-out outage | pure policy tests and isolated local Auth integration | **Implemented** locally; hosted callback/token revocation **Unverified** |
| Offline snapshot and acknowledgement queue | PostgreSQL remains authority; bounded user-scoped local snapshot/allowlist | stale response, corrupt/full queue, logout during acknowledgement | offline store and session-generation tests | **Implemented**; critical writes deliberately never replayed |
| Driver availability and tracking teardown | server-approved availability/trip plus validated location RPC | stale/out-of-order point, permission loss, terminal trip, logout late sample | deterministic location/controller/service tests | **Implemented** locally; Android/OEM background behavior **Unverified** |
| Avatar mutation and cleanup | Storage ownership/RLS plus profile reference | upload failure, profile failure, referenced object, cleanup failure | avatar service tests and Storage/RLS tests | **Implemented** safely; automatic orphan purge remains **Policy** |
| Admin stale capability/concurrent revision | active capability RPC/RLS and optimistic revision value | revocation with stale screen, two fare/policy editors | capability/revocation pgTAP and revision tests | **Implemented**; admin list cursor pagination remains **Partial** |

No row is considered externally tested merely because a unit test exists. The evidence column distinguishes deterministic local behavior from the later provider/device/hosted phase.

## 5. Files and behavior changed in Batch 7

- `lib/core/services/backend_repository.dart`
  - removes user-driven communications dispatch;
  - recovers ambiguous booking creation through authoritative read and secure pickup-code rotation.
- `supabase/functions/_shared/edge_authorization.ts`
  - pure operations-dispatch and payment-reconciliation authorization rules.
- `supabase/functions/tests/edge_authorization_test.ts`
  - operations/tourist/finance/driver authorization regressions.
- `supabase/functions/dispatch-communications/index.ts`
  - scheduler or active operations-admin boundary; generic correlated worker errors.
- `supabase/functions/reconcile-paymongo-payment/index.ts`
  - tourist-owner or finance-only reconciliation.
- `supabase/functions/create-paymongo-checkout/index.ts`
  - atomic local commit RPC and bounded correlated errors.
- `supabase/migrations/202610240004_cross_system_consistency.sql`
  - atomic checkout commit, ambiguous-booking credential recovery, and final execution-grant hardening.
- `supabase/tests/006_cross_system_consistency.sql`
  - 22 new ACL, checkout, and booking-recovery assertions.
- `docs/application-scenario-matrix.md`
  - Batch 7 evidence and status updates.

## 6. Validation results

| Gate | Actual result |
|---|---|
| Dart formatting | PASS — 115 files inspected; one Batch 7 file formatted |
| Flutter static analysis | PASS — no issues; 124.3 seconds |
| Flutter tests | PASS — 88/88 |
| Deno formatting | PASS — 20 files checked |
| Deno lint | PASS — 19 files checked |
| Deno deterministic tests | PASS — 16/16; local Auth test correctly ignored without credentials |
| Isolated local Supabase Auth test | PASS — 1/1 against loopback local Auth/Postgres |
| Frozen Deno type checks | PASS — all five Edge Function entry points |
| Fresh local migration chain | PASS — all 35 migrations applied from zero |
| pgTAP | PASS — 113/113 across six files |
| Database lint | COMPLETED — no new migration failure; PostGIS-owned function diagnostics and the existing unused `p_resource_id` parameter remain reported |
| Android debug APK | PASS |
| Git whitespace check | PASS — no whitespace error; Windows LF-to-CRLF notices only |

APK evidence:

- Path: `build/app/outputs/flutter-apk/app-debug.apk`
- Size: 288,367,917 bytes
- SHA-256: `BC4A98EE002604FCD514BFFDEE0CB4A1259C657F3A876B437CFDD13273E86936`

## 7. Existing issues intentionally left unchanged

| Status | Issue | Reason |
|---|---|---|
| **Partial** | Several administrator directory/catalog loads use finite limits instead of cursor-driven UI | A dataset/UX threshold was not supplied; inventing pagination behavior could change expected administration workflows |
| **Partial** | App-wide async/error/empty-state consistency beyond the audited routes | A full screen-by-screen physical pass and telemetry evidence are still required; Batch 7 did not perform an unbounded UI rewrite |
| **Unverified** | Native map outage, route suitability, GPS permission cycling, background tracking, process death, notification taps | Requires physical devices, provider traffic, or network shaping excluded by this batch |
| **Unverified** | PayMongo checkout/webhook/refund, Brevo delivery, FCM receipt, hosted Auth callbacks | Requires external test providers/hosted configuration excluded by this batch |
| **Policy** | Mid-trip account suspension handoff, municipal tricycle road rules, location-history retention, arbitrary partial refunds, automatic orphan-image purge | These require product/municipal decisions and were not invented |
| **Operational** | Production signing, hosted backup/restore rehearsal, secret rotation, alert routing, deployment approvals | Must be performed in the later hosted/release phase |
| **Tooling** | Database lint warnings in PostGIS-provided routines and existing unused webhook parameter | They were not caused by Batch 7; changing extension-owned code would be unsafe, and removing the event interface parameter could break provider compatibility |

## 8. Final status

Updated scenario statuses are recorded in `docs/application-scenario-matrix.md` using **Implemented**, **Partial**, **Missing**, **Unverified**, and **Policy** distinctions. Batch 7's confirmed local gaps are corrected and regression-protected. No confirmed Batch 7 P0/P1 local defect is knowingly being labeled as passed without evidence.

No hosted resource, external provider, commit, push, merge, or deployment was touched. The next phase is still the explicit physical-device, real test-provider, hosted-environment, operational rehearsal, and product-policy validation phase—not a production release declaration.

# Tric-Gabay Engineering Audit

**Audit date:** 2026-10-23  
**Repository commit:** `be032162bdbbd740292bca29444fe4e52978ec08`  
**Scope:** Flutter application, Supabase migrations and deployed Edge Functions, PayMongo test-mode flows, Mapbox/location tracking, communications, operational controls, CI/release configuration, and automated tests.

## Executive summary

Tric-Gabay has a substantial, internally consistent foundation. Static analysis passes, all 42 Flutter tests pass, a current Android debug APK builds, the local and linked Supabase migration histories match through `202610230007`, and the five expected Edge Functions are deployed. Important safeguards already exist for booking concurrency, server-authoritative transitions, pickup-code hashing and lockout, fixed-fare snapshots, test-only PayMongo credentials, webhook signatures, bounded offline replay, and foreground trip tracking.

The application is **not ready for external testing yet**. Two confirmed release blockers remain:

1. Any active administrator can reach the real PayMongo test-refund operation even without the `finance` capability.
2. A delayed `payment.failed` webhook can overwrite an already-paid payment and booking because payment transitions are not monotonic or atomic.

The capability model also remains incomplete at the read and storage layers, and several reliability controls are implemented in source but not yet demonstrated in the deployed environment or on physical devices. The appropriate next milestone is a focused P0/P1 remediation batch with database and Edge Function regression tests, followed by controlled two-device validation.

## Verified working functionality

- `dart analyze` completes with **no issues**.
- `flutter test` completes with **42 passing tests**.
- A current Android debug APK exists at `build/app/outputs/flutter-apk/app-debug.apk` (288,343,528 bytes, built 2026-10-23 09:59 local time).
- The working tree was clean at the start of the audit.
- Local and linked Supabase migrations match through `202610230007`.
- Deployed Edge Functions and gateway configuration were verified:
  - `create-paymongo-checkout` v8, JWT verification enabled.
  - `paymongo-webhook` v8, JWT verification disabled as required for a provider webhook; application-level HMAC and timestamp verification are present.
  - `process-paymongo-refund` v9, JWT verification enabled.
  - `reconcile-paymongo-payment` v6, JWT verification enabled.
  - `dispatch-communications` v9, JWT verification enabled.
- Required Supabase secret names exist for PayMongo test mode, Brevo, Firebase service-account authentication, application return URL, and Supabase service access. Secret values were not exposed during this audit.
- PayMongo functions reject credentials that are not `sk_test_` credentials, and the webhook rejects live-mode events.
- Critical booking and trip writes are implemented as validated database functions rather than client-only state changes.
- Partial unique indexes prevent more than one live booking per tourist or driver.
- Driver acceptance uses a server-side atomic transition and has coverage for competing acceptance.
- Pickup codes are hashed, excluded from the offline snapshot, and protected by attempt limits.
- The booking stores fare, itinerary, and policy snapshots rather than relying on mutable catalog values.
- Payment records have provider-identifier and active-operation uniqueness controls; ledger entries have idempotency keys.
- Location publication checks approved-driver state, active trip eligibility, coordinate bounds, accuracy, timestamp freshness, and monotonic updates.
- Tourist tracking and driver navigation use real Mapbox routes. The route request uses `driving-traffic` with motorway and toll exclusions and does not fabricate a straight-line route when routing fails.
- Offline persistence is user-keyed and bounded: up to 100 bookings, 100 attractions, and 50 commands; only notification acknowledgements are replayable, with a seven-day/five-attempt limit.
- Communication delivery is durable and independently scheduled, with exponential retry backoff and a five-attempt ceiling.
- Destructive retention is disabled by default, as required.
- Release configuration refuses to silently produce a production release with debug signing unless an explicit override is supplied.

## Findings

### P0 — Any active administrator can initiate a PayMongo refund

**Status:** Confirmed defect; deployed path affected.

**Evidence:**

- `supabase/functions/process-paymongo-refund/index.ts:31-38` authorizes only by `profiles.role = admin` and active status, then calls `reserve_paymongo_refund`.
- `supabase/migrations/202610220001_payment_reconciliation_and_ledger.sql:119-171` implements `reserve_paymongo_refund` with only `public.is_admin()` and grants it to `authenticated`.
- `supabase/migrations/202610230005_operations_roles_retention.sql:72-117` adds finance wrappers to fare publication, cancellation policy, charge resolution, and test-refund completion, but does not wrap or replace `reserve_paymongo_refund`.

**Impact:** A support, content, compliance, or operations administrator can initiate an external test-mode refund despite lacking finance permission. The UI capability check is not a security boundary.

**Reproduction:** Sign in as an active administrator without `finance`, invoke `process-paymongo-refund` with a refundable booking and valid amount/reason, and observe that both the Edge Function role check and reservation RPC admit the request.

**Expected:** Both the Edge Function and database function require `finance` (or `super_admin`) and record the acting administrator.

**Remediation:** Add capability enforcement at both layers, preserve idempotency, record an immutable audit event, and add direct API tests for finance/non-finance administrators.

### P0 — Reordered webhook events can downgrade a successful payment

**Status:** Confirmed data-integrity defect; deployed path affected.

**Evidence:**

- `supabase/functions/paymongo-webhook/index.ts:65-89` writes payment and booking status `paid`.
- `supabase/functions/paymongo-webhook/index.ts:99-118` later writes `failed` unconditionally for a matching payment.
- The payment and booking updates are separate service-role REST writes, not one locked database transition.
- Event IDs are deduplicated, but no provider ordering, current-state guard, or monotonic transition rule prevents a distinct delayed failure event from replacing `paid`.

**Impact:** A paid booking can appear failed, contradict the ledger, prompt another checkout, and create refund or settlement disputes. A partial failure can also temporarily leave payment and booking rows inconsistent.

**Reproduction:** Process a valid paid event, then process a distinct signed failure event for the same provider payment/checkout. The second handler writes `failed` to both rows.

**Expected:** Terminal success cannot be downgraded by an older or lower-authority event. Payment, booking, and ledger effects must transition atomically in the database.

**Remediation:** Move provider-event application into a transaction-safe RPC that locks the payment, validates amount/currency/current state/event time, applies monotonic transitions, and records the provider event and ledger effect atomically. Add duplicate, reversed-order, partial-failure, and concurrent webhook tests.

### P1 — Administrator capability separation is incomplete for sensitive reads and storage

**Status:** Confirmed authorization weakness.

**Evidence:**

- `supabase/migrations/202610200001_initial_backend.sql:338-395` grants broad `public.is_admin()` reads over profiles, driver records, bookings, trip events, live and historical location, payments, refunds, disputes, and feedback.
- `supabase/migrations/202610200001_initial_backend.sql:503-509` allows every administrator to read driver documents and write tourist-spot storage.
- `supabase/migrations/202610220003_public_brand_assets.sql:9-16` allows every administrator to write application assets.
- `supabase/migrations/202610230005_operations_roles_retention.sql:181-195` narrows several table writes, but does not replace all sensitive read/storage policies.

**Impact:** An administrator assigned only content or support duties can access financial, compliance, and precise-location data; non-content administrators can modify public assets. This violates least privilege and the advertised capability model.

**Expected:** Finance, compliance, content, support, operations, and super-administrator access must be enforced by RLS/storage policies according to data purpose.

**Remediation:** Build a policy matrix, replace broad admin clauses with capability predicates, preserve participant access, and add direct cross-capability RLS/storage tests.

### P1 — Profile avatar replacement fails after the first upload

**Status:** Confirmed defect from policy/client mismatch.

**Evidence:**

- `lib/core/services/backend_repository.dart:703-716` uploads the deterministic avatar path with `upsert: true`.
- `supabase/migrations/202610200003_participant_profiles.sql:128-131` defines only an INSERT policy for the user's profile-image folder; no UPDATE policy exists in later migrations.

**Impact:** The first avatar upload can succeed, while replacement of the existing object is rejected by storage RLS.

**Expected:** A user can update or delete only their own deterministic avatar object, with MIME and size validation retained.

**Remediation:** Add narrowly scoped UPDATE/DELETE policies or replace through a server-controlled operation, then test initial upload, replacement, and cross-user denial.

### P2 — Communications dispatcher can be triggered by any active user

**Status:** Confirmed authorization weakness.

**Evidence:** `supabase/functions/dispatch-communications/index.ts:103-113` correctly authenticates scheduler requests, but the manual path accepts any authenticated active tourist, driver, or administrator. It then claims and processes the global service-role queue.

**Impact:** Any active account can consume provider capacity, force retries, and observe per-delivery result metadata. The user cannot create arbitrary queued messages through this path, which limits—but does not remove—the risk.

**Remediation:** Allow only the scheduler or an administrator with `operations`; return aggregate results without provider/internal error detail.

### P2 — Notification rows allow recipients to update all mutable columns

**Status:** Confirmed integrity weakness.

**Evidence:** `supabase/migrations/202610200001_initial_backend.sql:394-395` permits UPDATE of a recipient's notification row without restricting the changed columns.

**Impact:** A direct client can rewrite its own notification title, body, category, or route. It cannot affect another user, but it can destroy audit-like evidence or create misleading local deep links.

**Remediation:** Revoke direct UPDATE and expose a narrow `mark_notification_read` RPC, or add a trigger that permits only `read_at` changes.

### P2 — Offline booking snapshots retain personal trip data in plaintext and survive logout

**Status:** Confirmed privacy/recovery weakness.

**Evidence:**

- `lib/core/state/offline_state_store.dart:85-119` serializes up to 100 complete booking models into `SharedPreferences`, removing only the pickup code.
- `lib/core/prototype/prototype_session.dart:1252-1294` clears in-memory state on logout but does not call `OfflineStateStore.clearUser`.

**Impact:** Names, pickup details, route/stops, and trip history may remain recoverable on a shared or compromised device after logout. User-keyed storage prevents ordinary cross-account display but is not encryption or deletion.

**Remediation dependency:** The owner must decide whether logout should remove offline history or retain it for the same account. In either case, minimize cached fields, add a retention limit, and use platform-protected encrypted storage for sensitive data.

### P2 — Feature-state decomposition remains transitional

**Status:** Confirmed maintainability gap, not a current functional failure.

**Evidence:** `lib/core/prototype/prototype_session.dart` remains approximately 1,351 lines and is referenced by 47 library files. `lib/core/state/feature_controllers.dart` separates notifiers, but controllers are global containers rather than feature-owned command/state boundaries.

**Impact:** Cross-feature coupling, stale-response races, and regression scope remain high. A sweeping rewrite would be riskier than incremental migration.

**Remediation:** Move one bounded workflow at a time—authentication/session, booking, driver trip, then admin—behind testable controllers while retaining `PrototypeSession` as a compatibility facade until consumers are migrated.

### P2 — Scheduled processing and provider delivery are not operationally proven

**Status:** Unverified external behavior, not a confirmed source-code failure.

**Evidence:** Migrations, function deployments, scheduler authentication, secret names, retry backoff, and attempt bounds are present. This audit did not obtain execution history proving that cron invokes the worker, nor provider-side evidence that Brevo accepts mail and FCM accepts/delivers pushes.

**Impact:** Lifecycle notifications may remain queued or fail silently in the actual project even though the implementation is present.

**Remediation:** Run a controlled queued-message canary, inspect cron/function/provider logs, verify terminal failure alerts after five attempts, and test revoked FCM-token cleanup.

### P2 — Current driver location has no explicit retention cleanup

**Status:** Confirmed policy gap; product decision required.

**Evidence:** `supabase/migrations/202610230005_operations_roles_retention.sql:285-320` covers old location-history candidates, but the current `driver_locations` record is not deleted when a driver goes offline or after a completed/cancelled trip.

**Impact:** A driver's last precise coordinate can remain stored indefinitely. Client timestamp checks can prevent presenting it as live, but they do not solve retention.

**Remediation dependency:** Define an approved current-location retention rule, then clear or coarsen stale/offline locations without enabling broad destructive retention.

### P2 — Scheduled booking activation is globally triggerable by any authenticated user

**Status:** Confirmed authorization/design weakness with limited direct impact.

**Evidence:** `supabase/migrations/202610210006_scheduling_and_reassignment.sql:112-148` and the later hardened replacement still grant `activate_due_scheduled_bookings()` to `authenticated`; `PrototypeSession` invokes it during sync.

**Impact:** Any authenticated user can trigger a global due-booking scan. The operation is time-gated and idempotent, so direct corruption is unlikely, but it creates avoidable load and couples correctness to client activity.

**Remediation:** Make activation scheduler/service-role only and have clients only fetch their resulting state.

### P2 — Edge Function dependencies are not pinned to immutable versions

**Status:** Confirmed reproducibility/supply-chain weakness.

**Evidence:** All five functions import `https://esm.sh/@supabase/supabase-js@2` rather than an exact version or committed lock/import map.

**Impact:** A future deploy can resolve different dependency code without a repository change.

**Remediation:** Pin exact versions and validate with Deno checks/tests in CI.

### P2 — Internal/provider error details can reach clients

**Status:** Confirmed information-exposure weakness.

**Evidence:** Edge Functions commonly return caught exception messages or provider response detail in JSON, including `paymongo-webhook/index.ts:147-148` and refund reservation/provider failures.

**Impact:** Database or provider details may be disclosed to authenticated callers or webhook responses and complicate stable client handling.

**Remediation:** Return stable public error codes and correlation IDs; keep sanitized details in server logs/operational records.

### P2 — Localization and accessibility coverage is incomplete

**Status:** Confirmed coverage gap.

**Evidence:** The application declares English and Filipino locales, persists the choice, and translates several major screens through a custom two-string helper. There is no complete message catalog/generated localization layer, and many user-visible strings remain English-only. Automated UI coverage includes limited font scaling and small-screen checks, but not 150%/200% scaling across critical flows, TalkBack traversal, focus order, contrast, or keyboard overlap.

**Impact:** Filipino flows can become mixed-language and critical screens may clip or become difficult to operate with accessibility settings.

**Remediation:** Inventory strings, migrate incrementally to ARB/generated localization, add semantics labels and golden/widget coverage at required scales, then perform TalkBack testing on physical Android devices.

### P2 — Release and CI evidence is incomplete

**Status:** Unverified release readiness.

**Evidence:** `android/key.properties` is absent as expected for a protected local checkout. No Git remote is configured and GitHub CLI is unavailable, so workflow execution could not be inspected. Docker/Podman and Deno are unavailable locally, so Supabase integration tests and Edge checks were not executed here. Only a debug APK was verified.

**Impact:** A passing Flutter suite does not prove database policy behavior, Edge compatibility, signed release installation, Crashlytics symbol upload, or protected-release correctness.

**Remediation:** Run the existing workflows on a connected remote, configure protected signing secrets, create a signed release candidate without committing keys, upload symbols, install it on supported devices, and verify startup/telemetry.

### P2 — Active-trip recovery and background tracking still require physical proof

**Status:** Implemented in source; not fully verified.

**Evidence:** Restored Supabase sessions resynchronize bookings, accepted/ongoing driver trips restart foreground tracking, and Android service declarations/permissions exist. There is no automated process-death test and no two-device evidence for OEM battery restrictions, permission denial/revocation, stale GPS, or app relaunch during a trip.

**Impact:** Tracking may degrade on specific Android versions/manufacturers despite correct nominal code.

**Remediation:** Execute the physical-device matrix below. Do not claim tracking after Android Force Stop, which the platform intentionally prevents.

### P3 — Documentation and catalog data need reconciliation

**Status:** Confirmed documentation/data-quality issues.

- Earlier audit/roadmap documents still describe several now-implemented items as pending.
- `supabase/migrations/202610200004_seed_catalog.sql` maps Cafe Portillo to `assets/images/galilee_wonderland_resort.jpg`, which appears inconsistent. The correct image must be supplied or approved by the owner; it should not be invented.
- Seven ignored `lib*.zip` source archives remain in the repository root. A targeted in-archive scan found no known project secret patterns, but they are stale local artifacts and can confuse audits/backups.

## Missing automated coverage

The current 42-test Flutter suite is useful but primarily exercises in-memory business rules and selected widgets. `supabase/tests/001_schema_contracts.sql` checks schema presence, not behavioral authorization or concurrency. Edge coverage is limited to scheduler-authentication logic.

Required additions, in priority order:

1. Finance versus non-finance refund authorization through Edge and RPC paths.
2. Paid-then-failed, failed-then-paid, duplicate, concurrent, amount-mismatch, and partial-write webhook scenarios.
3. Cross-role RLS tests for financial, location, compliance, support, content, and storage records.
4. Concurrent driver acceptance versus tourist cancellation.
5. Duplicate refund and settlement requests, including provider timeouts and reconciliation.
6. Notification queue claim concurrency, duplicate worker invocation, retry exhaustion, and alert creation.
7. Notification deep link to another user's resource.
8. Logout/account-switch while a delayed request completes and while offline cache exists.
9. Process restoration with accepted and ongoing trips.
10. Pagination boundaries, cache expiry, large catalog/booking lists, and migration tests against populated fixtures.

## Validation evidence and environment limitations

| Check | Result |
|---|---|
| `dart analyze` | Passed: no issues found |
| `flutter test` | Passed: 42 tests |
| Android debug build | Current APK verified in the build output |
| Git working tree before audit | Clean at commit `be03216` |
| Linked Supabase migration list | Local and remote match through `202610230007` |
| Deployed Edge Function inventory | Five expected functions active; JWT settings verified |
| Supabase secret inventory | Required secret names present; values not read or printed |
| Linked database lint | Application review was obscured by PostGIS extension findings; those extension-owned functions must not be altered as an app fix |
| Linked schema dump/local database tests | Could not run because Docker/Podman is unavailable in this environment |
| Edge Function type-check/tests | Could not run because Deno is unavailable locally |
| GitHub Actions inspection | Could not run because this checkout has no Git remote and GitHub CLI is unavailable |
| Dependency freshness query | Did not complete in the available network environment; no dependency-upgrade claim is made |
| Physical Android tests | Not performed in this audit |

No application implementation, database data, deployed function, provider configuration, or secret was changed during this audit. The only repository change is this report.

## Required physical-device validation

Use at least two Android devices, one tourist and one driver, with a third administrator/browser session when possible:

- Fresh install, login, logout, token refresh, account switch, and process kill/relaunch.
- Location permission denied, approximate-only, while-in-use, background permission, and permission revoked mid-trip.
- Driver online/offline, accepted trip, navigation away from screen, locked screen, background tracking notification, and relaunch.
- Tourist sees driver motion, timestamp/accuracy/stale state, together/arrival states, route refresh, and recenter behavior.
- Network loss during booking, acceptance, pickup-code entry, stop completion, cancellation, payment return, and trip completion.
- Two-driver acceptance race and tourist cancellation race.
- Map/routing failure and route deviation/breakdown/replacement flows.
- English and Filipino at 100%, 150%, and 200% font scale; TalkBack order; keyboard overlap; landscape where supported.
- Signed release candidate install/start, Crashlytics test event, performance trace, push receipt/deep link, and lifecycle email receipt.

## External configuration not verified locally

- PayMongo webhook endpoint registration and exact event subscription list.
- Provider-side PayMongo event delivery/retry history and test refund behavior.
- Brevo sender verification, API acceptance, bounce/delivery status, and branding in received clients.
- Firebase service-account validity, FCM project/package alignment, token acceptance, delivery, and revoked-token behavior.
- Supabase cron execution history, function logs, database backups, point-in-time recovery, and restore rehearsal.
- Mapbox public-token URL/application restrictions, quota, and real-world route suitability for Bustos tricycles.
- GitHub Actions executions, protected environment approvals, release signing secrets, and artifact retention.
- Crashlytics/Performance event arrival and symbol mapping.

## Recommended remediation sequence

1. **P0 financial integrity:** finance-gate refund reservation/Edge execution; implement atomic monotonic webhook transitions; add adversarial regression tests; deploy and verify in PayMongo test mode.
2. **P1 authorization:** complete capability-aware table/storage policies and fix avatar replacement; test every role directly against Supabase.
3. **P2 operational security:** restrict communications dispatch and scheduled activation; narrow notification updates; sanitize Edge errors; pin dependencies.
4. **P2 privacy/reliability:** decide logout-cache and current-location retention policy; implement only after owner approval; verify retry exhaustion and provider delivery.
5. **P2 maintainability/UX:** incrementally move feature commands out of `PrototypeSession`; complete localization/accessibility; retain the existing visual identity.
6. **Release validation:** run database/Edge CI in an isolated environment, connect and inspect CI, create a properly signed release candidate, rehearse backup/restore, and complete the two-device matrix.

## Core workflow readiness matrix

| Workflow | Current assessment | Release-blocking work |
|---|---|---|
| Authentication/session | Implemented; local checks pass | Device token refresh, revocation, account-switch race tests |
| Explore/catalog/packages | Implemented; catalog independent from packages | Confirm suspect catalog image and all owner-supplied facts |
| Booking/fare snapshots | Strong server-side foundation | Direct integration/concurrency tests |
| Driver matching/acceptance | Atomic acceptance implemented | Acceptance/cancellation race and large-pool tests |
| Pickup/trip/stops/completion | Server transitions and pickup-code protection present | Two-device/process-death/offline adversarial validation |
| Live tracking/navigation | Real Mapbox/location implementation present | Physical Android/OEM validation and retention decision |
| PayMongo checkout | Test-mode server flow present | Provider configuration and end-to-end reconciliation validation |
| Webhook/payment state | Signature/idempotency foundation present | **P0 monotonic atomic transition fix** |
| Refunds/settlement | Durable records and reconciliation present | **P0 finance authorization fix**, duplicate/retry tests |
| Notifications/email/push | Durable queue, worker, retry present | Restrict invocation; prove scheduler/provider delivery and exhaustion alerts |
| Administrator controls | Capability model and UI present | Complete RLS/storage capability enforcement |
| Offline/recovery | Bounded safe replay and cache present | Privacy decision, logout cleanup/encryption, process tests |
| Release/operations | Guardrails and workflow files present | Signed RC, actual CI evidence, telemetry and restore rehearsal |

## Release recommendation

**Not ready for external testing.**

The codebase is ready for the focused remediation phase. After the two P0 defects and P1 authorization/storage issues are fixed and backed by direct integration tests, it can be reassessed for **controlled test-environment validation**. Production readiness must remain a separate decision after signed-release, provider, backup/restore, accessibility, and physical-device evidence exists.


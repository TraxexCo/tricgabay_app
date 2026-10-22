# Tric-Gabay advanced engineering audit

Updated: 23 October 2026.

## Decision

Tric-Gabay is **not yet production-passable** and the work is **not limited to
final testing**. It is suitable for continued controlled development and, after
the manual gates below, a supervised closed field test. It must not be described
as production-ready until every release blocker is closed with evidence.

This audit uses `Advanced Engineering Requirements for This Mobile Application`
as the definition of done. A checked feature in an older roadmap is not treated
as evidence by itself.

## Evidence collected

- The linked Supabase project is `xcsrjuqzwequmeqzedzd` (`tric-gabay`).
- Local and remote migrations matched through `202610220005`; migrations
  `202610230001` through `202610230003` were then deployed successfully.
- Remote Supabase database lint originally found four application failures:
  booking creation and pickup-code verification could not resolve pgcrypto
  functions, and scheduled activation/refund finalization attempted an invalid
  `system` account role. The new migration fixed all four. The remaining lint
  messages belong to installed PostGIS extension routines, not Tric-Gabay
  routines.
- `flutter analyze`: no issues after the hardening changes (fresh verification).
- `flutter test`: 39 tests passed (fresh verification). These are local
  unit/widget tests; they do not
  prove RLS, external providers, real GPS, process death, or two-device behavior.
- `flutter build apk --release`: succeeded; the resulting 142.6 MB APK is still
  debug-signed by the current Gradle configuration and is suitable only for
  controlled testing.
- PayMongo, Brevo, Firebase service credentials, and the sender identity are
  stored as server secrets. No privileged secret is embedded in Flutter.

## Requirements assessment

| Requirement | Status | Evidence / gap |
| --- | --- | --- |
| Architectural boundaries | **Fail** | Most screens depend directly on the 1,248-line global `PrototypeSession`; several screens call `BackendRepository` directly. Riverpod is present but is not the application architecture. |
| Single source of truth | **Partial** | Supabase is authoritative for authenticated booking/payment state. Tour packages, itinerary, favorites, names, online state, and cached directory data still have duplicated or hard-coded client representations. |
| Race and stale-response control | **Partial** | Database transitions use row locks/constraints. Client synchronization is now coalesced and bound to the authenticated session generation, but many fire-and-forget admin/notification writes lack surfaced retry state. |
| Explicit state machines | **Partial** | Booking/payment/refund states are explicit in SQL and models. Driver onboarding, uploads, communication delivery, and authentication recovery are not yet represented by domain state machines. |
| Boundary contracts | **Partial** | Models and SQL functions provide contracts, but database responses are parsed from dynamic maps without schema generation/version negotiation. Edge Function request schemas are handwritten. |
| Idempotency | **Mostly pass** | Booking uniqueness, offer acceptance, webhooks, ledgers, deliveries, refunds, cash confirmation, and checkout requests have server safeguards. Provider behavior still needs concurrent live test evidence. |
| Concurrent edits | **Partial** | Fare/cancellation revisions and booking transitions are protected. Attraction/profile edits are last-write-wins with no version conflict surfaced to admins. |
| Authorization / RLS | **Partial** | RLS and server-side role checks exist. There is no automated role-matrix/RLS regression suite, and offered drivers can currently query more participant profile columns than they need. |
| Backward-compatible migrations | **Partial** | Migrations are additive and deployed in order. There is no supported-old-client matrix, expand/migrate/contract policy, restore rehearsal, or rollback runbook. |
| Offline behavior | **Fail** | Read errors are shown, but there is no persistent offline command queue, conflict-safe replay, cache freshness model, or connectivity-aware state. Critical actions intentionally require the server. |
| Session/account switching | **Mostly pass** | User-scoped state now clears on session changes; stale sync responses are discarded; signed-out events redirect; push-token ownership can be reclaimed. Suspension during an already active tourist session needs a defined policy. |
| Local sensitive data | **Partial** | Pickup codes use secure storage and are now user-scoped/removed after terminal trips; Android backup and cleartext traffic are disabled. Screenshot protection, retention policy, and rooted-device assumptions remain undocumented. |
| Untrusted links/payloads | **Mostly pass** | Push routes are allowlisted and UUID-validated; router role guards remain. The mobile recovery redirect is configured remotely; password recovery and PayMongo return links still require end-to-end validation. |
| Observability | **Fail** | There is no crash reporting, structured production logging, performance monitoring, correlation ID surfaced in the app, webhook alerting, or admin health dashboard. |
| Resource control | **Partial** | Uploads are now bounded to 5 MB and booking/notification reads have some limits. Bookings, directories, map annotations, location history, and admin reports are not comprehensively paginated or retained. |
| Failure/combinational testing | **Fail** | Local rules have useful negative/concurrency tests, but there are no automated Supabase/RLS, Edge Function, offline, process-death, provider, or two-device end-to-end tests. |
| Regression prevention | **Partial** | Analyzer and 39 tests pass. No CI pipeline, coverage threshold, golden UI suite, contract tests, or release gates are configured. |
| Background recovery | **Fail** | Android foreground location is used while the stream is alive. App force-stop/process death does not persist and restart active tracking automatically; communication retries also lack an independent scheduler. |
| Dependency/API evolution | **Partial** | Lockfile and an exact Mapbox version exist. There is no upgrade cadence, compatibility matrix, automated dependency scanning, or API contract versioning. |
| Complete-system verification | **Fail** | Migrations and server configuration are verified, but real auth recovery, RLS isolation, GPS, Mapbox routes, PayMongo checkout/webhook/refund, FCM, Brevo, weak network, and two-phone journeys remain unverified. |

## Scenario coverage matrix

### Identity and accounts

| Scenario | Required outcome | Current state |
| --- | --- | --- |
| Tourist registers twice / taps twice | One account; useful recovery message | Supabase owns uniqueness; needs device test. |
| Driver upload interrupted after one document | Retry resumes without a second account | Hardened with deterministic uploads and `submit_driver_application`; needs device test. |
| App closes during driver registration | Correct password resumes pending application | Implemented; navigation/recovery UX still needs device test. |
| Wrong-role login | Sign out and route to correct portal message | Implemented in `AuthService`; needs integration test. |
| Token expires during request | No old data remains; re-auth is required | Signed-out cleanup is implemented; forced-expiry test missing. |
| Account A logs out, Account B logs in on same phone | No A data/push/code appears for B | State generation, scoped pickup codes, and push-token reclaim implemented; test missing. |
| Password-reset link expired/reused | Reject safely and request a new link | Screen/callback handling and the remote redirect allowlist are configured; email-link expiry/reuse tests remain. |
| Admin suspends user during trip | Preserve safety and a fair settlement path | Driver path hardened; tourist suspension policy remains to be specified. |

### Booking and matching

| Scenario | Required outcome | Current state |
| --- | --- | --- |
| Repeated booking submission | One active booking only | Server unique index/function and local serialization. |
| Fare changes while checkout is open | Existing quote remains immutable | Fare revision is snapshotted. |
| Attraction closes before booking | Reject unavailable stop | Trigger/function validation exists. |
| Attraction closes after booking | Preserve snapshot; offer an audited route decision | Implemented; needs two-device test. |
| No eligible driver | Search expires and offers a retry/cancel path | Implemented; needs timed integration test. |
| Two drivers accept together | Exactly one wins | Conditional update/unique active-driver rule; database concurrency test missing. |
| Driver goes offline/stale | Exclude after two-minute GPS freshness window | Implemented server-side. |
| Passenger/capacity/accessibility mismatch | Do not offer driver | Implemented server-side. |
| Scheduled pickup across timezone/restart | UTC server activation and reminders | Implemented with pg_cron; cron execution and timezone test missing. |
| Assigned driver becomes unavailable | Tourist chooses replacement or free cancellation | Participant and new admin-suspension paths implemented. |

### Live trip, navigation, and safety

| Scenario | Required outcome | Current state |
| --- | --- | --- |
| GPS denied/off/stale/inaccurate | Block proof actions; explain recovery | Mostly implemented; Android-version matrix missing. |
| Driver backgrounds app | Visible foreground notification and continued samples | Implemented while process lives; physical-device evidence missing. |
| OS kills/force-stops app | Resume/alert without silently claiming live tracking | **Not implemented.** |
| Driver publishes while offline and unassigned | Server rejects | Fixed in migration `202610230001`. |
| Older GPS response arrives after newer one | Older point cannot overwrite current point | Server timestamp condition implemented. |
| Driver deviates from route | Sustained deviation, warning, audit, recompute | Implemented client/server; false-positive and weak-GPS tests missing. |
| Mapbox route unavailable | No fake straight route; actionable fallback | Implemented. |
| Restricted/highway route | Prefer local roads; driver follows legal signage | Guidance only; no tricycle-specific routing profile exists. |
| Pickup-code guessing | Rate-limit and alert repeated failures | Five failures trigger a server-enforced 15-minute lock, audit events, and a tourist alert; device/RLS test remains. |
| Breakdown/unsafe route/medical event | Stop safely, notify, hold settlement | Core workflow exists; emergency escalation and incident evidence are incomplete. |
| Driver/admin suspended during service | End safely and hold payment review | Driver admin-suspension path implemented in `202610230003`. |

### Payment, cancellation, disputes, and refunds

| Scenario | Required outcome | Current state |
| --- | --- | --- |
| Checkout button tapped concurrently | Reuse one PayMongo checkout | Idempotency key and race recovery deployed; provider test missing. |
| Redirect says success but webhook absent | Stay processing; never trust redirect | Implemented. Manual refresh exists; automatic return reconciliation is missing. |
| Duplicate/out-of-order webhook | Idempotent processing | Provider event uniqueness and retry release exist. |
| Wrong amount/currency | Hold for admin review | Implemented. |
| Cash handover disputed | Dual confirmation; admin cannot impersonate | Implemented and locally tested. |
| Tourist/driver cancels before pickup | Versioned fee rules | Implemented. |
| Either party ends after pickup | Immediate safe end and settlement hold | Implemented. |
| Partial/full refund | Never exceed paid minus final charge | Server reservation/ledger constraints exist; provider test-mode journey missing. |
| Refund provider timeout | Recoverable status and retry without duplication | Timeout/idempotency implemented; operational retry UI/runbook needs testing. |
| Admin collusion or accidental override | Separate roles/approval for financial actions | **Not implemented; one admin role has all privileges.** |

### Communications and operations

| Scenario | Required outcome | Current state |
| --- | --- | --- |
| Duplicate notification event | One delivery per channel/event | Dedupe key implemented. |
| Brevo/FCM timeout | Bounded call, persisted retry/backoff | Timeouts and queue backoff exist. |
| No subsequent app activity after failure | Retry still runs independently | **Not guaranteed; an independent communication scheduler is missing.** |
| Invalid/foreign push deep link | Reject before navigation | Allowlist and UUID validation implemented/tested. |
| Device token reused after account switch | Reassign to current account | Atomic server RPC implemented. |
| Admin needs failed-delivery visibility | Queue/search/retry health view | Table exists; polished admin operations UI is missing. |
| Data grows for months | Retain/purge by policy | **No retention jobs for GPS, webhook payloads, messages, or audit data.** |

## Release blockers

1. Replace `PrototypeSession` with authenticated, feature-scoped controllers and
   repositories; remove direct backend calls from screens.
2. Add persistent offline/read-cache semantics and decide which commands may be
   queued. Payment, acceptance, pickup, cancellation, and settlement must remain
   server-confirmed.
3. Add automated Supabase/RLS role tests and Edge Function contract tests using
   isolated tourist, driver, admin, suspended, and anonymous identities.
4. Add process-death recovery for active trips and an explicit stale-tracking
   warning visible to both participants.
5. Add crash/error/performance monitoring with PII redaction and correlation IDs.
6. Add an independent scheduled communication dispatcher and delivery-health
   alerts.
7. Verify the configured `tricgabay://auth-callback` flow on Android with a real reset email, including expired/reused links.
8. Add pagination, bounded caches, image lifecycle cleanup, and retention jobs.
9. Add administrator role separation for finance, driver compliance, content,
    and support; require stronger review for settlement/refund overrides.
10. Replace debug signing with a protected release keystore and establish CI
    release gates, dependency scanning, backups, and restore rehearsal.
11. Complete accessibility, localization, low-end Android, weak-network,
    permission, GPS, Mapbox, PayMongo, FCM, Brevo, and two-device field tests.

## Controlled field-test gates

Before giving the current APK to testers:

- build a new APK after this audit batch;
- verify the password-reset redirect and one real reset email;
- run one tourist/driver/admin journey on two physical Android phones;
- verify RLS manually with three isolated accounts;
- verify background tracking with screen off, app backgrounded, lost network,
  restored network, and process termination;
- complete PayMongo test checkout, signed webhook, reconciliation, cancellation,
  dispute, and test refund;
- receive one branded email and one FCM push for each high-risk lifecycle event;
- record actual evidence in `final-field-testing-checklist.md`.

Until those gates pass, statements such as “everything works,” “production
ready,” or “only testing remains” are not supported by evidence.

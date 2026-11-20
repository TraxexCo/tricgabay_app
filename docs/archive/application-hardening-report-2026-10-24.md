# Tric-Gabay application hardening report

Date: 2026-10-24  
Batch: Comprehensive application hardening, edge-case handling, and workflow completeness  
Baseline: `master` at `be032162bdbbd740292bca29444fe4e52978ec08` with the existing dirty working tree preserved

## Outcome

This batch converted the implemented product into a 72-scenario traceability matrix, corrected four confirmed application defects and one backend authorization-boundary defect, added regression coverage, rebuilt the database from the complete forward migration chain, and passed every local validation gate.

The result is ready for the next validation phase. It is **not** declared production-ready: physical Android behavior, hosted configuration, live PayMongo test mode, email, push delivery, and map-provider failure behavior were deliberately not exercised in this local-only batch.

## Scenario inventory

The full inventory is in `docs/application-scenario-matrix.md` and covers authentication/session state, booking and trip transitions, driver availability, mapping/location, payments/refunds, communications, administration, offline recovery, uploads/forms, UI/navigation, and cross-entity invariants.

The 72 recorded scenarios currently classify as:

- 50 implemented before this batch.
- 6 confirmed defects implemented in this batch.
- 1 notification-read case implemented after the Batch 4 session-generation guard.
- 9 partially implemented scenarios with bounded remaining work.
- 3 unverified scenarios requiring a device or external dependency.
- 2 unresolved product policies and 1 policy/provider-dependent case.

The matrix explicitly records dependencies and does not count unavailable physical/provider evidence as a pass.

## Confirmed defects corrected

### 1. Revoked account state was stale across session restoration and long-lived sessions

Previously, session restoration read the profile status but did not fail closed, and it did not verify a driver's current approval status. A user with a still-valid token could therefore enter the app shell using stale account eligibility.

Correction:

- `AuthService.restoreSession` now accepts only an active profile.
- Driver restoration additionally requires an existing, currently approved driver profile.
- Every authoritative application refresh revalidates the user id, role, active status, and driver approval before loading protected state.
- A failed eligibility check signs out and clears the application session instead of continuing from cached role data.
- Network errors remain distinguishable from a confirmed revocation: they use the existing read-only offline fallback rather than silently inventing an account decision.

### 2. User-scoped cache and retry data survived logout

Memory and active tracking were cleared, but the departing user's offline snapshot and safe notification queue remained on the device.

Correction:

- Real session teardown now captures the departing user id and removes both persisted user-scoped stores.
- This applies to explicit logout, provider-driven session termination, and the unconfigured local adapter.
- A new unit regression saves both kinds of state, clears the user, and proves neither can be restored/replayed.

### 3. An in-flight notification acknowledgement could recreate old-account data after logout

The optimistic mark-read failure handler captured the old user id. If logout cleared the store before the request failed, the later callback could recreate that old user's queue.

Correction:

- Both single and mark-all completion/failure callbacks now require the same authenticated user and the same session generation before refreshing or enqueuing.
- Stale callbacks become no-ops and cannot write into a later account's state.

### 4. Driver availability could become online before location permission succeeded

The previous switch updated the authoritative availability state first and only then requested GPS/location permission. A denied permission could leave a driver matchable but unable to publish a usable location.

Correction:

- Going online first proves that location services, permission, and a current position are available.
- The server availability transition occurs only after that prerequisite succeeds.
- Publishing and the location stream begin only after the server accepts the online transition.
- The switch is disabled while the transition is running, preventing repeated toggles.
- A server failure cancels the screen-owned stream and leaves the driver offline.
- Going offline still refuses while an accepted/ongoing trip exists.

### 5. Mobile clients could execute a global scheduled-booking maintenance job

`activate_due_scheduled_bookings()` was granted to every authenticated user, and the Flutter synchronization path invoked it on every refresh. The transition was deterministic, but a global maintenance operation did not belong at the mobile-client trust boundary.

Correction:

- Forward migration `202610240001_scheduled_activation_execution_boundary.sql` revokes execution from public, anonymous, and authenticated roles.
- Only `service_role` retains the explicit recovery execution grant; the existing database scheduler continues to run as the database owner.
- The mobile refresh call was removed.
- A pgTAP schema-contract assertion proves the authenticated role cannot execute the function.

## Invariants reconfirmed

- A tourist cannot create a conflicting active booking.
- Concurrent driver acceptance cannot assign two drivers to one booking.
- Cancellation/acceptance races do not resurrect terminal state.
- Driver trip mutations require assignment and valid state.
- Pickup start remains protected by the server-side pickup-code transition.
- Completed/cancelled trips cannot be converted back to an active state by client actions.
- Offline replay remains restricted to idempotent notification-read acknowledgements; booking, payment, refund, cancellation, and trip transitions are never automatically queued.
- Payment/refund provider events remain signature checked, identity/amount checked, monotonic, atomic, and ledger backed.
- Admin capability checks remain enforced by database/RPC/storage boundaries, not merely hidden UI.
- Cached pickup codes remain stripped, caches remain user-scoped and bounded, and cached active state alone never restarts driver tracking.
- Notification routes remain allowlisted and are re-authorized by the router and backend.

## Validation evidence

All validation used local containers, local fixtures, or deterministic test code. No hosted project mutation, PayMongo request, real refund, email, push notification, deployment, commit, push, or merge occurred.

| Gate | Result |
|---|---|
| Fresh local migration chain | **PASS** — all 32 migrations applied in order |
| pgTAP database suite | **PASS** — 80/80 assertions across 4 files |
| Deno Edge Function suite | **PASS** — 10/10 tests |
| Flutter suite | **PASS** — 50/50 tests |
| Dart formatting | **PASS** — 101 files checked, 0 changes required |
| Flutter static analysis | **PASS** — no issues |
| Git whitespace check | **PASS** — no whitespace errors; only existing Windows line-ending notices |
| Android debug compilation | **PASS** — `build/app/outputs/flutter-apk/app-debug.apk` |

Debug APK evidence:

- Size: 288,347,669 bytes.
- SHA-256: `54AD75902EB474C5413F31BB2BDD7E4C22F6AFAAC5604E620FFFF05B39217DE1`.
- The build reports a forward-looking Flutter warning that `mapbox_maps_flutter` and `share_plus` still apply the Kotlin Gradle Plugin rather than Built-in Kotlin. It does not fail this build, but dependency upgrades must be reviewed before a future Flutter upgrade turns the warning into an error.

The Flutter test log's Firebase platform-channel messages are expected on the Windows test runner. The service fails safely there and the suite passes; this is not evidence that physical push behavior works.

## Remaining risks and required next phase

### P1 / must validate before release

1. Physical Android permission combinations, approximate/precise behavior, GPS disabled/re-enabled, backgrounding, process death, foreground-service persistence, terminal-trip tracking shutdown, notification taps, and system Back behavior.
2. Live PayMongo **test-mode only** checkout/webhook/refund/reconciliation behavior, including ambiguous timeouts and duplicate delivery.
3. Real email and FCM push delivery/retry/deduplication with non-production recipients/devices.
4. Hosted Supabase configuration review, secret/environment separation, migration review, backup/restore rehearsal, and an explicit go/no-go. This report does not authorize deployment.
5. Tricycle route suitability must be approved against local road/legal knowledge; “avoid highways/tolls” is a provider preference, not a legal guarantee.

### P2 / meaningful follow-up

1. Add an injectable geolocation boundary so permission ordering, stream shutdown, stale timestamps, and process recovery can be tested without a phone.
2. Complete screen-reader semantics, text scaling, focus order, contrast, and keyboard/form behavior on physical devices.
3. Add cursor-based pagination at product-defined dataset thresholds for large administrator lists.
4. Replace deterministic avatar overwrite with versioned upload → profile update → old-object cleanup after a retention policy is approved.
5. Pin the Supabase JavaScript dependency to a reviewed exact release and commit a Deno dependency lock strategy; the current `@2` import is not reproducible enough for a production release.
6. Review whether the driver home availability stream and active-trip service can ever overlap during nested route transitions; static inspection suggests ownership is separated by screen/trip lifecycle, but a device trace is required before claiming it.

### Product-owner decisions still required

1. Mid-trip suspension/deactivation and the municipal support/handoff procedure.
2. Historical driver-location retention and who may retrieve it after a trip.
3. Allowed partial-refund reasons, amount limits, approval levels, and dispute evidence.
4. Exact road classes prohibited for tricycles and the fallback when no compliant provider route exists.
5. Orphaned upload retention and cleanup timing.

## Repository handling

- Existing dirty work and all earlier remediation files were preserved.
- Only a forward migration was added; no applied migration was rewritten.
- The Supabase CLI's generated `.branches/_current_branch` marker was removed after validation.
- No reset, clean, stash, discard, commit, push, merge, remote migration, or deployment was performed against the repository or hosted backend.

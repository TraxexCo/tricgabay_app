# Tric-Gabay Batch 6 hardening report

Date: 2026-10-24  
Scope: residual recovery gaps, isolated integration testing, and accessibility foundations  
Repository state: existing dirty worktree preserved; no commit, push, deployment, hosted-project mutation, external-provider delivery, or physical-device claim

## Executive result

Batch 6 closes confirmed local gaps in communication-worker ownership, abandoned delivery recovery, provider-error privacy, authentication policy consistency, logout failure isolation, location freshness boundaries, tracking teardown, and avatar cleanup safety. It also establishes automated semantics coverage for shared critical controls.

All claims in this report are limited to repository code and isolated local infrastructure. PayMongo, Brevo, FCM, hosted Supabase, Mapbox network behavior, email callbacks, Android OEM lifecycle behavior, and TalkBack remain external or physical validation work.

## Implemented corrections

### Authentication and session isolation

- Added a pure, shared authorization policy used by session restoration and interactive sign-in. Unknown roles, portal mismatch, inactive profiles, and unapproved drivers fail closed.
- Added explicit password-recovery-session policy coverage for missing/expired recovery state.
- Added a session-termination coordinator that clears protected local state before attempting remote sign-out. A provider outage cannot repopulate or expose the departing account.
- Added isolated local Supabase Auth coverage for user creation, invalid credentials, session restoration, duplicate creation, suspension state, logout, and account switching.
- Preserved server authority: the local integration test does not bypass Auth, RLS, or profile status.

Remaining auth limits are explicit: interrupted driver registration with document storage still needs a dedicated local Storage/Auth fixture, and real reset-email callback behavior requires the configured external email path.

### Independent communications recovery

- Added a unique lease token and claim timestamp to each delivery attempt.
- Finalization now requires the current claim token and a `sending` row. A delayed worker cannot overwrite a newer attempt.
- A `sending` row abandoned for five minutes can be reclaimed with a new token; attempts remain capped at five.
- Provider diagnostics are normalized, bounded to 500 characters in the worker, and redact bearer values, common secret fields, tokens, and email addresses before database persistence or API response.
- Added fake-provider tests for success, transient failure followed by success, malformed/bounded errors, and diagnostic redaction.
- Added pgTAP coverage for a single claim, attempt increments, stale-token rejection, current-token finalization, retry ceiling, and abandoned-lease recovery.

Message delivery remains downstream from booking/payment truth. The new migration changes only `message_deliveries`; no communication result can alter booking, payment, refund, or ledger state.

### Location freshness and lifecycle

- Locked the accepted timestamp window to inclusive `now - 2 minutes` and `now + 30 seconds` boundaries.
- Added deterministic rejection coverage for one millisecond beyond either boundary, duplicate timestamps, out-of-order samples, and accuracy worse than 200 meters.
- Added a logout/account-switch-style teardown regression: the stream is cancelled, the recovery marker is cleared, a late fake sample is not published, and the service does not restart itself.
- Retained the safety rule that a cached booking identifier alone never starts location transmission; only an authoritative active assignment may start tracking.

Physical Android permission changes, foreground-service survival, process death, Force Stop, OEM battery controls, and two-device movement still require the device matrix.

### Avatar replacement and cleanup

- Retained upload-first/profile-second ordering, preserving the old avatar when upload or profile mutation fails.
- Added an owner-prefix guard so a cross-owner previous path is never submitted for deletion.
- Added a reference check before deleting the previous object. A referenced object is retained.
- Reference-check failures fail closed and create a bounded diagnostic instead of guessing.
- Added coverage for upload failure, profile failure, new-orphan cleanup failure, old-object cleanup failure, both profile and cleanup failure, referenced-object retention, cross-owner denial, invalid image, and invalid owner path.

No automatic destructive orphan purge was scheduled because no product retention policy was supplied. Cleanup failures are observable and safe for deliberate later review.

### Accessibility foundations

- Shared app buttons now expose one explicit button label, enabled state, and a live `Loading` value while work is in progress.
- Status badges expose a single read-only status announcement without duplicate visual text.
- Password visibility controls now expose meaningful `Show Password` / `Hide Password` tooltips.
- Blocking loading overlays expose a live operation label.
- Added widget regressions for all four shared behaviors.

This is a foundation, not a full accessibility certification. TalkBack traversal, large-text layouts across every route, switch/control semantics on physical Android, contrast measurements, keyboard focus order, and reduced-motion behavior remain in the physical accessibility pass.

## New automated evidence

| Gate | Result |
|---|---|
| Flutter formatting | PASS — all `lib` and `test` sources formatted |
| Flutter tests | PASS — 88/88 |
| Flutter static analysis | PASS — no issues |
| Deno formatting | PASS — 18 files |
| Deno lint | PASS — 17 files |
| Deno deterministic tests | PASS — 14/14; local-Auth test intentionally ignored without local credentials |
| Isolated local Supabase Auth integration | PASS — 1/1 against loopback-only local Auth/Postgres |
| Fresh local migration chain | PASS — all 34 forward migrations applied |
| pgTAP | PASS — 91/91 across five files |
| Frozen Edge Function type checks | PASS — all five entry points |
| Android debug APK | PASS — `build/app/outputs/flutter-apk/app-debug.apk` |
| Git whitespace check | PASS — no whitespace errors; Windows line-ending notices only |

APK evidence:

- Size: 288,367,420 bytes.
- SHA-256: `40F7B088A51719C9684C2DE0C0768CB55F4DBFFA5A1F9EF775ECA50A8F39B1EA`.

## Important files

- `lib/core/services/auth_session_policy.dart`
- `lib/core/services/session_termination_coordinator.dart`
- `lib/core/services/auth_service.dart`
- `lib/core/services/avatar_replacement_service.dart`
- `lib/core/services/location_gateway.dart`
- `lib/core/services/active_trip_tracking_service.dart`
- `lib/core/widgets/app_button.dart`
- `lib/core/widgets/app_text_field.dart`
- `lib/core/widgets/shared_widgets.dart`
- `supabase/migrations/202610240003_message_delivery_leases.sql`
- `supabase/functions/_shared/delivery_attempt.ts`
- `supabase/functions/dispatch-communications/index.ts`
- `supabase/tests/005_message_delivery_leases.sql`
- `supabase/functions/tests/auth_local_integration_test.ts`
- `supabase/functions/tests/delivery_attempt_test.ts`
- `test/auth_session_policy_test.dart`
- `test/session_termination_coordinator_test.dart`
- `test/accessibility_foundations_test.dart`
- `test/avatar_replacement_service_test.dart`
- `test/location_services_test.dart`

## Deferred or blocked evidence

1. Physical Android: permissions, GPS cycling, process death, Force Stop, foreground notification, OEM battery policy, system Back, TalkBack, large text, rotation, two-device tracking, and notification taps.
2. External providers: PayMongo test checkout/webhook/refund, Brevo delivery, FCM device receipt, Mapbox outage/routing samples, and actual reset/lifecycle emails.
3. Hosted operations: migration review/deployment, alert routing, backup/restore rehearsal, secret rotation, CI execution, and production signing.
4. Product/municipal decisions: exact tricycle road restrictions, mid-trip suspension/handoff, location retention, arbitrary partial-refund policy, and orphan-image retention period.
5. Broader UI: Batch 6 covers shared accessibility primitives and targeted regressions, not every screen or every asynchronous route.

No deferred item is reported as passed.

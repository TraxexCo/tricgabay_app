# Tric Gabay audit follow-up — Batch 2

Date: 2026-11-03 (Asia/Manila)
Scope: current local checkout, preserving Batch 1 and the existing local hardening.
App build: 1.0.0+2. No commit, push, hosted deployment, migration application,
real payment, refund, email, notification, account deletion, or provider-state
mutation was performed. Public Poppins font assets were downloaded from Google Fonts.

This report distinguishes tested client behavior from server implementations
that have not been exercised against a real database. This batch is not a
production-readiness certification.

## Implemented

### Implemented and tested locally

| Work item | Evidence and limits |
| --- | --- |
| Booking request identity | Account-scoped UUID/payload material persists before the RPC; retries reuse it, changed ambiguous requests are rejected, and recovery checks both owner and UUID. An authoritative matching booking clears pending request material. Unit tests exercise persistence, interruption, and rejecting another active booking. Database deduplication is separately untested. |
| Payment initiation | Online requests navigate to trip/payment details rather than the success screen. Resume payment uses a checked PayMongo HTTPS origin. Tests cover checkout creation failure, browser-launch failure, retrying the same booking, and rejecting untrusted origins. Actual browser/provider callbacks remain untested. |
| Pickup-code material | Reissue shares the existing durable recovery-material lifecycle. Tests simulate response loss, reuse the same code/request, keep the old displayed code until confirmation, and verify confirmed persistence and cleanup. Existing recovery tests remain passing. Server rotation and rate limiting are untested. |
| Pickup-area calculation | Client distance checks use the configured centre/radius. Tests cover centre, outside points, invalid coordinates, and changing radius. Actual map confirmation and server geospatial enforcement are untested. |
| Validators | Unicode letters/combining marks, Filipino names, hyphens/apostrophes/periods; plus-tag and long-TLD emails; PH and international phone formats; E.164-shaped normalization before signup/profile writes. Tests include Niño, Muñoz, name+tag@gmail.com and +14155550123. Phone validation checks structure, not number assignment or ownership. |
| Admin feedback | Tourist changes require a reason and confirmation. Previously unused unawaited status/announcement wrappers now return awaited futures. Announcement preview can be cancelled, an audience selector is present, and failures stay visible without claiming success. Existing tourist-action test was updated for the required reason. Actual server targeting and compliance-restoration checks are untested. |
| Error messages | A central mapper replaces raw error interpolation/toString in user-facing error paths, including route errors. Tests confirm backend URLs, contact data and arbitrary detail are not echoed. Reports retain exception type/stack rather than free-form messages. Native reporting and collection controls require device validation. |
| Routing calculations and cache | Point-to-segment distance handles long straight and degenerate segments. Route reuse considers destination changes and distance from geometry. An injected Directions adapter tests a 13-coordinate request, the 25-coordinate guard, and plan caching. No live Directions request was made. |
| Sync section and row isolation | A failed section keeps its previous value without discarding successful sections. A malformed booking row does not prevent later rows being parsed. These boundaries have local tests. Profile/session validation remains a required common boundary. |
| Pagination | History starts with a 50-row window; people load in 100-profile pages. Load-more controls extend the window, and refreshes retain the requested window size. Active trips are fetched separately so older active assignments remain reachable. Tests verify bounded page fetching and loading/end states. Real database ordering/RLS behavior remains untested. |
| Unknown data | Booking, payment, payment-method and event-actor parsing use unknown values. Unknown booking/payment data blocks transactional detail controls rather than becoming an actionable default. Tests cover parsing and active-booking protection. |
| Version/time helpers | package_info_plus, a blocking minimum-version widget, cached version policy, server-clock synchronization and explicit Manila schedule conversion are implemented. Tests cover blocking, URL validation, clock offset and Manila display. Native package info, configuration RPC and real clock skew remain untested. |
| Fonts/localization | Five used Poppins weights (400–800) and their OFL license are bundled. Runtime font fetching is disabled in main. Tests load all five without network fetching. gen_l10n, English/Filipino ARB files and 134 translated labels are wired into auth, booking/payment and emergency screens. A widget test verifies Filipino payment text. Dead app_strings.dart was removed after verifying no imports. |
| Registration consent | A notice and mandatory acceptance precede registration; optional diagnostics default off. A widget test verifies registration cannot proceed without acceptance and that cancelling does not save consent. A database consent record is implemented but untested. |
| Account-deletion orchestration | An authenticated Edge Function, profile buttons and durable service-only recovery requests are implemented. Six Deno tests verify operation order and stopping at failures. These tests simulate boundaries; no real identity, document or financial record was deleted. |

### Implemented, untested — needs database, provider or device validation

- Booking UUID uniqueness, per-account locking, repeated-request return behavior,
  rejection of UUID/payload conflicts and the changed RPC signature.
- payment_pending holds, paid-only release, scheduled paid dispatch, unpaid
  expiry, withdrawal of legacy unpaid offers, and late-payment refund handling.
  The migration refuses to proceed with legacy unpaid assigned tours; those
  must be resolved safely by operations first.
- General owner-only pickup-code rotation, invalidation of old codes, five-minute
  throttling, hourly limits and preservation of verification lockout counters.
- Configurable PostGIS pickup enforcement, server configuration access controls,
  minimum-build policy and time RPC.
- Announcement audience enforcement and preserving the existing support
  capability; reason enforcement preserves driver_compliance authorization.
- Realtime reconnection invalidates subscribed sections, but no reconnect was
  exercised against a real Realtime service in this batch.
- Native map redraw behavior, Android background GPS, browser launch/resume,
  store links and package-info integration were not exercised on a physical device.
- Native diagnostics start disabled. Crash diagnostics require consent. Automatic
  Firebase Performance collection remains disabled because route URL paths can
  contain coordinates; enabling it safely is additional work.
- Account deletion prepares disconnected participant identities, erases personal
  text/location and driver records, removes document/avatar folders, revokes
  sessions and deletes the Auth identity. Monetary amounts/provider references
  are retained. These are pseudonymized financial records, not a claim that all
  provider-held data becomes anonymous. A private interrupted-operation mapping
  is removed on final completion. The operation is service-only and is not tested
  against actual Auth, Storage, foreign keys, triggers or RLS.
- The financial ledger remains immutable for amounts, references and timestamps;
  the proposed service-only privacy path permits erasure of descriptive text and
  metadata. That exception and the nullable Auth link for retained participants
  need specific database/security review before use.

## Verification

Final local command results:

| Command | Exact final result |
| --- | --- |
| flutter pub get | Exit 0; Got dependencies!; 74 packages have newer versions incompatible with dependency constraints. No Firebase major upgrade was performed. |
| flutter analyze --no-pub | Exit 0; No issues found! (27.8s) |
| flutter test --no-pub | Exit 0; 129 passed; All tests passed! The previous 101-test suite remains passing; 28 tests were added. |
| flutter build apk --debug --no-pub | Exit 0; assembleDebug completed in 35.6s; built build/app/outputs/flutter-apk/app-debug.apk. |
| deno test --allow-env --allow-read --allow-net tests/ | Exit 0; 32 passed, 0 failed, 1 ignored. The real local Auth/Storage integration test was not enabled. |
| deno check delete-account/index.ts create-paymongo-checkout/index.ts | Exit 0; both entry points checked. |
| flutter gen-l10n | Exit 0; generated localization sources from l10n.yaml. |
| git diff --check | Exit 0; no whitespace errors. |
| Supabase/pgTAP | NOT RUN. No migrations were applied to a local or hosted database. The new 15-assertion pgTAP file is intended coverage only. |

The APK still emits the existing Mapbox/share_plus legacy Kotlin plugin warning.
A successful debug build does not establish future Flutter compatibility or store approval.
Command logs are included alongside the complete replacement-file bundle.

### New migrations

| Filename | Status |
| --- | --- |
| 202611030002_payment_pending_enum.sql | NOT applied/tested |
| 202611030003_booking_payment_idempotency_geofence.sql | NOT applied/tested |
| 202611030004_pickup_code_reissue.sql | NOT applied/tested |
| 202611030005_targeted_announcements.sql | NOT applied/tested |
| 202611030006_client_version_and_clock.sql | NOT applied/tested |
| 202611030007_privacy_and_account_deletion.sql | NOT applied/tested |

The enum migration must commit before the following migration uses its new value.
The new client depends on the new RPC/configuration contracts; do not release it
against an unchanged backend. The seed minimum Android build is 2 and the store
URL is deliberately empty until a real listing is available. The service circle
seed copies the existing driver defaults; operations must approve its coverage.

## Audit corrections

- The checkout already had ordinary pickup recovery, payment reconciliation,
  financial hardening and a substantial test suite. This batch adds reissue and
  booking-request idempotency rather than replacing those protections.
- Driver compliance actions and the actual announcement screen already awaited
  repository calls and displayed failures. The unused session wrappers still
  had unawaited paths; those were corrected. Preview/targeting/reasons were
  remaining gaps.
- The current [Mapbox Directions API reference](https://docs.mapbox.com/api/navigation/directions/)
  explicitly allows up to 25 coordinates for driving-traffic. The app's maximum
  12 stops plus origin fits this limit, so per-leg requests were unnecessary.
  The separate [HTTP POST documentation](https://docs.mapbox.com/api/navigation/http-post/)
  still mentions three for that profile. This discrepancy is recorded rather
  than assuming the earlier audit's three-point claim is current. Provider
  acceptance was not tested; request construction was tested with an adapter.
- Scheduled trips already count toward the one-active-booking limit. This batch
  retains that rule and extends it to payment_pending.
- Driver matching already excludes stale location samples. That does not prove
  a scheduled job clears every stale online indicator or blocks all mid-service
  compliance expirations.
- Generated iOS/macOS plugin registration files changed through dependency
  resolution. No iOS support implementation or validation was started.

## Outstanding work

### Not done / release prerequisites

1. Apply and exercise the migrations in an isolated database only after review;
   run and adapt existing SQL contracts to the intentional new RPC/state rules.
   The new pgTAP scenarios have not run. No database/RLS correctness is claimed.
2. Exercise real PayMongo sandbox timeouts, webhook/reconciliation ordering,
   expiry/late-payment refunds, scheduling, duplicate requests and concurrent
   requests. Local tests do not prove provider idempotency or delivery timing.
3. Exercise reinstall/new-phone reissue and interrupted deletion against actual
   Auth/Storage. A service-role worker can resume prepared deletion requests;
   automatic worker scheduling was not added. Administrators require assisted
   deletion. Interrupted deletion may require support after sessions are revoked.
4. Approve a financial retention period and implement scheduled retention/purge
   rules and backup/provider handling. The code describes retained fields but
   does not invent a statutory retention duration. A public web deletion-request
   page and final store/privacy disclosures are not included.
5. Complete remaining localization: dynamic transaction descriptions, several
   labels/help strings, validator/error messages, privacy text and generated
   prose still fall back to English. The 134-label migration is a foundation,
   not complete Filipino coverage or a professional translation review.
6. Pickup address/pin consistency is explicitly confirmed by the tourist after
   the circle check; automatic geocoding or barangay-boundary verification was
   not implemented. Verify the actual map flow and chosen service circle.
7. Validate native routing transitions, stale-plan presentation, traffic ETA
   freshness, accessibility and device clock changes. Cached plans intentionally
   avoid repeated redraws; their original traffic duration can become stale.
8. Real Realtime reconnect and multi-account pagination tests remain necessary.
   Loaded windows are refreshed; active trips are fetched separately. Search
   still operates on loaded people rather than a server-side search endpoint.
9. Fill the approved store URL and verify the minimum-version rollout. Cached
   offline policy cannot learn a newly raised server minimum while disconnected.
10. Driver registration's earlier authenticated document-upload/email-confirmation
    lifecycle was not redesigned. Local font and localization tests do not
    establish offline behavior for every screen on a real device.

### Explicitly not started in this batch

- iOS support.
- Admin MFA or a separate web admin.
- Masked calling or chat.
- SOS/share-trip.
- Offline-cache encryption.
- Firebase major upgrades.
- Favorites sync.

## Complete replacement files

The accompanying ZIP contains complete files at their checkout-relative paths,
including heavily changed session/repository/screen files, new tests, migrations,
assets and generated localization sources. It contains no partial code snippets.
Existing local hardening is preserved in those full-file copies.

DELETE lib/core/constants/app_strings.dart when applying the bundle elsewhere;
the deletion is recorded in the manifest. Generated plugin registrations and
Android local build metadata are listed for transparency. Review machine-specific
android/local.properties rather than copying SDK paths to a different machine.
Build outputs and tool caches are excluded. The APK is available separately in
the checkout. Every packaged replacement is SHA-256 checked against the final
source file; the JSON manifest records those digests.

### Every source/asset/config/report file touched

- android/app/src/main/AndroidManifest.xml (modified)
- android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java (modified)
- android/local.properties (modified)
- assets/google_fonts/OFL.txt (new)
- assets/google_fonts/Poppins-Bold.ttf (new)
- assets/google_fonts/Poppins-ExtraBold.ttf (new)
- assets/google_fonts/Poppins-Medium.ttf (new)
- assets/google_fonts/Poppins-Regular.ttf (new)
- assets/google_fonts/Poppins-SemiBold.ttf (new)
- docs/audit-follow-up-batch2-2026-11-03.md (new)
- ios/Runner/GeneratedPluginRegistrant.m (modified)
- l10n.yaml (new)
- lib/core/prototype/prototype_session.dart (modified)
- lib/core/services/auth_service.dart (modified)
- lib/core/services/backend_repository.dart (modified)
- lib/core/services/booking_payment_flow.dart (new)
- lib/core/services/booking_request_material.dart (new)
- lib/core/services/error_messages.dart (new)
- lib/core/services/map_route_service.dart (modified)
- lib/core/services/pickup_recovery_material.dart (modified)
- lib/core/services/pickup_service_area.dart (new)
- lib/core/services/push_notification_service.dart (modified)
- lib/core/services/remote_pagination.dart (new)
- lib/core/services/route_geometry.dart (new)
- lib/core/services/section_refresh.dart (new)
- lib/core/services/server_clock.dart (new)
- lib/core/services/telemetry_service.dart (modified)
- lib/core/services/trip_rules.dart (modified)
- lib/core/utils/validators.dart (modified)
- lib/core/widgets/delete_account_button.dart (new)
- lib/core/widgets/l10n_text.dart (new)
- lib/core/widgets/minimum_version_gate.dart (new)
- lib/core/widgets/registration_privacy.dart (new)
- lib/core/widgets/remote_page_controls.dart (new)
- lib/features/admin/screens/admin_live_map_screen.dart (modified)
- lib/features/admin/screens/admin_login_screen.dart (modified)
- lib/features/admin/screens/driver_detail_admin_screen.dart (modified)
- lib/features/admin/screens/fare_settings_screen.dart (modified)
- lib/features/admin/screens/manage_drivers_screen.dart (modified)
- lib/features/admin/screens/manage_spots_screen.dart (modified)
- lib/features/admin/screens/manage_tourists_screen.dart (modified)
- lib/features/admin/screens/monitor_bookings_screen.dart (modified)
- lib/features/admin/screens/send_announcement_screen.dart (modified)
- lib/features/admin/screens/spot_form_screen.dart (modified)
- lib/features/auth/screens/forgot_password_screen.dart (modified)
- lib/features/auth/screens/login_screen.dart (modified)
- lib/features/auth/screens/onboarding_screen.dart (modified)
- lib/features/auth/screens/register_driver_screen.dart (modified)
- lib/features/auth/screens/register_role_screen.dart (modified)
- lib/features/auth/screens/register_tourist_screen.dart (modified)
- lib/features/auth/screens/reset_password_screen.dart (modified)
- lib/features/auth/screens/splash_screen.dart (modified)
- lib/features/driver/screens/active_trip_screen.dart (modified)
- lib/features/driver/screens/driver_bookings_screen.dart (modified)
- lib/features/driver/screens/driver_edit_profile_screen.dart (modified)
- lib/features/driver/screens/driver_emergency_screen.dart (modified)
- lib/features/driver/screens/driver_home_screen.dart (modified)
- lib/features/driver/screens/driver_profile_screen.dart (modified)
- lib/features/driver/screens/incoming_booking_screen.dart (modified)
- lib/features/tourist/screens/booking_confirmation_screen.dart (modified)
- lib/features/tourist/screens/booking_detail_screen.dart (modified)
- lib/features/tourist/screens/driver_tracking_screen.dart (modified)
- lib/features/tourist/screens/emergency_screen.dart (modified)
- lib/features/tourist/screens/fare_summary_screen.dart (modified)
- lib/features/tourist/screens/feedback_screen.dart (modified)
- lib/features/tourist/screens/find_driver_screen.dart (modified)
- lib/features/tourist/screens/location_picker_screen.dart (modified)
- lib/features/tourist/screens/rate_review_screen.dart (modified)
- lib/features/tourist/screens/tour_package_detail_screen.dart (modified)
- lib/features/tourist/screens/tourist_bookings_screen.dart (modified)
- lib/features/tourist/screens/tourist_edit_profile_screen.dart (modified)
- lib/features/tourist/screens/tourist_home_screen.dart (modified)
- lib/features/tourist/screens/tourist_profile_screen.dart (modified)
- lib/l10n/app_en.arb (new)
- lib/l10n/app_fil.arb (new)
- lib/l10n/app_localizations.dart (new)
- lib/l10n/app_localizations_en.dart (new)
- lib/l10n/app_localizations_fil.dart (new)
- lib/main.dart (modified)
- lib/models/booking_model.dart (modified)
- lib/models/trip_record.dart (modified)
- macos/Flutter/GeneratedPluginRegistrant.swift (modified)
- pubspec.lock (modified)
- pubspec.yaml (modified)
- supabase/config.toml (modified)
- supabase/functions/_shared/account_deletion.ts (new)
- supabase/functions/create-paymongo-checkout/index.ts (modified)
- supabase/functions/delete-account/index.ts (new)
- supabase/functions/tests/account_deletion_test.ts (new)
- supabase/migrations/202611030002_payment_pending_enum.sql (new)
- supabase/migrations/202611030003_booking_payment_idempotency_geofence.sql (new)
- supabase/migrations/202611030004_pickup_code_reissue.sql (new)
- supabase/migrations/202611030005_targeted_announcements.sql (new)
- supabase/migrations/202611030006_client_version_and_clock.sql (new)
- supabase/migrations/202611030007_privacy_and_account_deletion.sql (new)
- supabase/tests/008_batch2_booking_contracts.sql (new)
- test/admin_action_feedback_test.dart (modified)
- test/batch2_behaviors_test.dart (new)
- test/batch2_route_and_announcement_test.dart (new)
- test/remote_pagination_test.dart (new)
- lib/core/constants/app_strings.dart (deleted)

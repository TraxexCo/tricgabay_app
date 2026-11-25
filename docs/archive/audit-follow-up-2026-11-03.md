# Audit follow-up: sync and dependency cleanup

Date: 2026-11-03 (Asia/Manila)

This is a first implementation batch against the supplied audit. Existing local
hardening changes were preserved. It does not close the entire audit.

## Implemented

- Realtime GPS payloads patch only drivers already in local state, by driver ID.
  They do not trigger remote state downloads. Older samples are ignored.
- Other realtime events invalidate their own data sections. Booking-related
  events reload bookings and the visible directory; notification events reload
  notifications. Unchanged fares, policies and catalog data are reused.
- Invalidations accumulate during an in-flight refresh. A fixed 300 ms window
  batches events without continually postponing refresh under sustained traffic.
- Heartbeat-only driver profile changes do not reload the directory. Changes to
  selected availability/compliance/profile fields still invalidate it.
- A shared upload gate covers both foreground and active-trip GPS publishers:
  at least five seconds between successful writes, plus at least 15 metres of
  movement, with a 30-second stationary-sample exception. Concurrent writes are
  suppressed; failed writes can retry; logout/account changes reset the gate.
- Android location streams request five-second updates without a native distance
  filter, allowing stationary samples to reach the upload gate. Actual delivery
  still depends on Android/GPS/background execution and needs device validation.
- Configured booking creation no longer depends on finding the tourist in a
  truncated directory. Server authorization remains authoritative.
- Notification-read actions request only notification refreshes. Sync failures
  now display a generic connection message rather than the raw backend error.
- Removed unused shimmer, gap, timeago, permission_handler and cupertino_icons;
  dependency resolution removed ten direct/transitive entries in total.
- Documented share_plus and Mapbox pins in README.
- Added a migration publishing the additional observed tables. Existing RLS and
  grants remain unchanged. This migration has NOT been applied or database-tested.

## Verification

- flutter pub get: passed.
- flutter analyze --no-pub: no issues.
- flutter test --no-pub: 101 passed, including ten added upload/patch tests.
- flutter pub outdated --no-dev-dependencies and dart pub deps --style=compact:
  completed. Installed Firebase versions are core 3.15.2, messaging 15.2.10,
  Crashlytics 4.3.10 and performance 0.10.1+10. Major upgrades remain separate work.
- git diff --check: passed.

## Audit corrections and outstanding work

- Current checkout already contains pickup recovery, payment hardening and tests;
  earlier statements that no tests/recovery exist describe an older snapshot.
- Scheduled bookings count toward the server's single-active-booking constraint
  (202610210006_scheduling_and_reassignment.sql).
- Ranked matching excludes locations older than two minutes
  (202610210004_ranked_driver_offers.sql). This is a matching freshness condition,
  not proof that every stale online indicator is cleared by a scheduled job.
- The current create_booking function checks coordinate ranges, but has no Bustos
  pickup geofence (202610240005_payment_pickup_authorization.sql). Driver matching
  radius checks do not replace validating a requested pickup's service boundary.
- Scoped refreshes still revalidate the authenticated profile. Full/manual/resume
  refreshes still fetch all sections. The requested sections still share a
  Future.wait failure boundary. Directory pagination, booking pagination,
  independent section errors, per-assignment subscriptions, and reconnect catch-up
  need further work. This is not a completed sync architecture overhaul.
- Bundled Poppins, generated localization, validators, minimum-version handling,
  privacy/account deletion, additional scenarios and major dependency upgrades
  remain open. No extra package was added without implementing its feature.
- No hosted deployment, production modification, commit or push was performed.

Android debug APK build passed. The toolchain still warns that the pinned
Mapbox/share_plus plugins use the legacy Kotlin Gradle plugin setup; the current
build succeeds, but this remains relevant before a future Flutter upgrade.

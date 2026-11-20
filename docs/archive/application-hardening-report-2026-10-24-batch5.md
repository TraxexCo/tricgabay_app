# Tric-Gabay Batch 5 hardening report

Date: 2026-10-24  
Scope: local testability, dependency reproducibility, upload consistency, administrator feedback, bounded inputs, and map-data reliability  
Baseline: `master` at `be032162bdbbd740292bca29444fe4e52978ec08`; the pre-existing dirty working tree was preserved

## Outcome

Batch 5 is locally complete. It corrected the confirmed defects described below and passed Flutter, Dart, Deno, fresh local Supabase, pgTAP, Android debug compilation, and Git whitespace validation. No hosted Supabase project, PayMongo endpoint, email provider, push provider, or physical device was contacted. Nothing was committed, pushed, merged, or deployed.

This is not a production-release declaration. Physical Android behavior, external-provider delivery, hosted configuration, production signing, policy decisions, and release operations remain separate evidence gates.

## Confirmed defects and corrections

### Driver availability and active-trip tracking

- Added `LocationGateway`, a narrow injectable boundary around service state, permission, current-position acquisition, and position streams.
- Added `DriverAvailabilityController` to serialize repeated requests, require a fresh usable point before the online write, wait for server confirmation, cancel failed startup resources, and keep location sharing active until an offline write is confirmed.
- Invalid, stale, future-skewed, and out-of-order samples are ignored. A failed post-approval startup attempts to return the server state to offline.
- `ActiveTripTrackingService` now uses the same injectable boundary. A cached booking id is recovery information only; it cannot start transmission. Tracking begins only after authoritative assignment reconciliation and stops when that assignment becomes terminal or disappears.
- Production foreground/background behavior was not expanded beyond the existing Android-supported tracking behavior.

### Reproducible Edge Function dependencies

- Replaced broad Supabase JavaScript imports with the reviewed exact release `@supabase/supabase-js@2.118.0` through a Deno import map.
- Added `supabase/functions/deno.json` and `supabase/functions/deno.lock`; frozen dependency validation is now possible.
- The complete Deno formatter, linter, 10-test suite, and every Edge Function entry-point type check pass with the frozen graph.
- Deno's stricter Web Crypto types exposed an `ArrayBufferLike` mismatch in Firebase service-account key parsing. The helper now copies decoded bytes into a concrete `Uint8Array<ArrayBuffer>` without changing authentication behavior.

### Safe avatar replacement

- Avatar bytes are validated for size, supported MIME type, and JPEG/PNG signature before storage access.
- New avatars use unique owner-scoped paths: `<user-id>/avatars/<uuid>.<extension>`.
- The profile is changed only after a successful upload. The previous avatar is removed only after the profile update succeeds.
- If the profile update fails, the previous reference is preserved and only the new orphan is removed where possible.
- Cleanup failures do not roll back a successful profile change; a sanitized diagnostic records the owner-scoped storage path (never image bytes, credentials, or profile contents) for later repair.
- Forward migration `202610240002_versioned_profile_avatars.sql` adds owner-path read/write/delete policies for versioned avatars while retaining safe access to existing legacy avatar objects.

### Administrator mutation reliability

- Tourist suspension/restoration now awaits the mutation, shows success only after completion, disables that row while pending, and offers an authoritative refresh after failure.
- Attraction visibility, temporary closure/reopening, and deletion now use the same per-record pending/error pattern. Duplicate taps are blocked.
- Fixed a real persistence defect where visibility changed only local memory. Visibility now writes through `BackendRepository.setSpotActive` before success is shown.
- Fixed a recovery defect where hidden attractions disappeared from the administrator catalog. Authorized admin synchronization includes inactive rows; tourists still request active rows only, and RLS remains the security boundary.
- Added meaningful semantics to touched tourist-status and content visibility controls.

### Bounded forms, stale async responses, and map data

- Shared validators now bound email, password, full name, plate number, and franchise/OR-CR values. Touched tourist/driver profile and attraction forms expose matching input limits.
- Profile-save completions verify that the authenticated user is still the account that started the request before mutating app state or navigating.
- Added a central finite/range coordinate validator. Malformed catalog rows are filtered before model/render creation, and malformed live-driver rows are skipped instead of being silently placed at a plausible Bustos fallback coordinate.
- Valid global coordinate boundaries remain accepted. Non-map catalog controls continue working when an individual point is excluded.

## Files and rationale

Major Batch 5 implementation files:

- `lib/core/services/location_gateway.dart` — injectable platform boundary and usable-sample predicate.
- `lib/core/services/driver_availability_controller.dart` — serialized, server-confirmed availability lifecycle.
- `lib/core/services/active_trip_tracking_service.dart` and `lib/features/driver/screens/driver_home_screen.dart` — authoritative tracking recovery and production integration.
- `lib/core/services/avatar_replacement_service.dart`, `lib/core/services/backend_repository.dart`, and `supabase/migrations/202610240002_versioned_profile_avatars.sql` — versioned avatar transaction sequence and storage ownership.
- `lib/features/admin/screens/manage_tourists_screen.dart` and `manage_spots_screen.dart` — per-row feedback, duplicate prevention, persistence, and retry/refresh behavior.
- `lib/core/utils/map_coordinate_validator.dart` and `admin_live_map_screen.dart` — defensive map-data filtering without invented coordinates.
- `lib/core/utils/validators.dart`, touched profile screens, and `spot_form_screen.dart` — bounded inputs and account-safe async completion.
- `supabase/functions/deno.json`, `deno.lock`, and five Edge Function imports — exact dependency resolution and frozen checks.
- `supabase/tests/003_capability_rls.sql` — versioned avatar ownership regression.
- `test/location_services_test.dart`, `avatar_replacement_service_test.dart`, `map_coordinate_validator_test.dart`, `validators_test.dart`, and `admin_action_feedback_test.dart` — deterministic regression coverage.

Some Edge Function source files were also formatted by the new canonical Deno formatter. Those changes are mechanical except for the import-map conversion, the concrete Firebase key byte buffer, and removal of one unused push-response body variable.

## Validation evidence

| Gate | Result |
|---|---|
| Dart formatting | **PASS** — 110 files checked, zero remaining changes |
| Flutter static analysis | **PASS** — no issues |
| Flutter tests | **PASS** — 72/72 |
| Deno formatting | **PASS** — 15 files |
| Deno lint | **PASS** — 14 files |
| Deno tests | **PASS** — 10/10 |
| Deno frozen type checking | **PASS** — all five Edge Function entry points |
| Fresh local migration chain | **PASS** — all 33 forward migrations applied in order |
| pgTAP | **PASS** — 81/81 assertions across four files |
| Android debug APK | **PASS** — `build/app/outputs/flutter-apk/app-debug.apk` |

APK evidence:

- Size: 288,363,965 bytes.
- SHA-256: `4DFB748859AB7F1A63BA0A84B13204EC6D2C145CB7731F321FED27FCC962AA3B`.

The Windows Flutter runner continues to print expected Firebase platform-channel unavailability messages during tests; notification initialization fails safely and all tests pass. This does not validate physical-device push delivery.

## Dependency review

- Selected Edge dependency: `@supabase/supabase-js@2.118.0`, verified against package metadata and current imports, then locked with all transitive integrity data.
- Installed Mapbox remains `mapbox_maps_flutter 2.30.1`. Package metadata reports `3.33.0`, which is a major migration and requires focused Mapbox API/web/mobile compatibility testing; it was not changed in this hardening batch.
- Installed sharing plugin remains `share_plus 13.1.0`. Metadata reports `13.3.1`, but the repository documents an Android AGP/Kotlin regression beginning with the attempted 13.2 line. It was not upgraded without a dedicated compatibility branch/test.
- The debug build still emits Flutter's forward-looking Built-in Kotlin warning for Mapbox and share_plus, plus an Android SDK XML tool-version warning. Neither fails the current build; both remain release-toolchain follow-ups.

## Remaining partial, blocked, policy-dependent, or unverified work

1. Physical Android validation: precise/approximate and revoked permissions, GPS cycling, foreground-service behavior, OEM battery restrictions, process death, two-device tracking, large text, TalkBack, notification taps, and system Back.
2. External test integrations: PayMongo test-mode checkout/webhooks/refunds, Brevo test recipients, FCM device delivery, Mapbox outages, and route sampling. These were explicitly excluded from local Batch 5.
3. Hosted operations: configuration review, migration review, backup/restore rehearsal, alert routing, production signing, and CI release execution.
4. Product/municipal decisions: exact tricycle road restrictions, mid-trip suspension/handoff, historical location retention, arbitrary partial-refund policy, and orphan-upload retention/repair scheduling.
5. Administrator pagination remains bounded by finite repository limits rather than product-defined cursor UX. Dataset thresholds are still required.
6. Accessibility was improved only on touched controls. No claim of complete WCAG/TalkBack compliance is made.
7. Avatar ownership is protected by validated path segments, RLS, and pgTAP. Deliberate background cleanup/retry for the rare case where both profile rollback cleanup and old-object cleanup fail remains a separate retention/operations decision.

## Exact local validation commands

```text
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
deno fmt --config deno.json --check
deno lint --config deno.json
deno test --config deno.json --frozen tests
deno check --config deno.json --frozen <each Edge Function index.ts>
npx --yes supabase@2.122.0 db reset --local --no-seed
npx --yes supabase@2.122.0 test db
git diff --check
```

The local Supabase stack used Docker Desktop and only loopback endpoints. No remote migration or deployment command was run.

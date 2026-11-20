# Tric Gabay audit follow-up — Batch 3

Date: 2026-11-03 (Asia/Manila). Base: the current local Batch 2 checkout,
including its pre-existing uncommitted hardening. App version remains 1.0.0+2.
No commit, push, hosted deployment, hosted database operation, real provider
payment/refund, external email or external notification was performed.

Database work used the separate temporary project `tricgabay_batch3_isolated`,
Supabase CLI 2.121.0, Docker 29.9.2, PostgreSQL 17.11, real Auth/Storage/PostgREST,
PostGIS 3.3.7, pgcrypto 1.3, pg_cron 1.6.4, pg_net 0.20.4 and Vault 0.3.1.
pgTAP 1.3.3 was available and installed within the transactional test suites.
There were no Auth/Storage schema stubs. Realtime and Edge Runtime were excluded.

## Implemented

### Implemented and tested locally

| Work item | Evidence and practical limits |
| --- | --- |
| Migration syntax and full chain | Fixed the invalid dollar quotes in `attach_profile_auth_identity()` in 007. The parser checks all 47 migrations and 13 pgTAP files. A clean local reset applied every migration in filename order, then all 230 assertions passed. No older pgTAP file was changed in this batch. |
| Late payment race | Tests pay at 29 minutes, at 31 minutes before expiry runs, and at 31 minutes after expiry runs. The first releases the booking; the two late cases require a refund. The cron-cancelled case can no longer remain cancelled+paid without a refund obligation. |
| Deletion and financial integrity | Real fixtures include bookings, payments, refunds, ledger entries, trip events and disputes. Preparation and retry preserve monetary facts, provider references and timestamps, including payment/refund `updated_at`. Dispute statements are redacted. An explicit foreign-key allow-list replaces arbitrary reassignment; an unknown future protected audit FK makes preparation roll back. The privacy flag still cannot change ledger money. A separate harness commits preparation, disconnects, and retries in another session; the anonymous ID and ledger fact hash remain unchanged. |
| Provider mode | The database reads `service_configuration.paymongo_mode`, defaulting to `test`. This deployment's remaining provider paths are test-only, so `live` explicitly refuses checkout instead of silently recording a live checkout as test. Edge key/mode mismatch also fails closed. SQL and Deno tests cover this. Live payments are not enabled. |
| Announcements | Each draft retains a request UUID across retries. The same UUID and content returns the original recipient count; different content conflicts. The transaction records sending admin, audience and count in an append-only audit row. New sends are limited to three per admin per ten minutes. Preview, audience targeting and the existing support capability remain. SQL tests cover duplicate submit, conflicting reuse, recipients, audit and rate limit; widget tests retain preview/cancel behavior. |
| Existing-user consent | The database supplies the current version and EN/Fil notice. Missing/old consent blocks signed-in app content, including after resume/account change. Acceptance records the exact version shown; load/record failure keeps the gate closed. Signup uses that server version too. SQL and widget tests cover old/current consent, blocking and acceptance. The Dart version literal was removed. |
| Real concurrency | Three races use separate live PostgreSQL connections and a barrier that proves both sessions overlap on a lock: different UUIDs for one tourist, the same UUID twice, and two drivers with offers accepting one booking. Counts prove one booking/acceptance/event rather than merely checking returned errors. |
| Pending-driver lifecycle | Pending drivers can restore/sign in to an application-only route, upload documents, submit and check approval. Operational routes remain blocked. Real local Auth, with email confirmation enabled, rejects unconfirmed login; token verification permits sign-in, real Storage uploads succeed and submission leaves the account pending/offline. Going online is rejected by the server. No production confirmation setting was disabled. Widget/policy tests cover the restricted state. |
| Connectivity | `connectivity_plus` drives an offline banner with retry above the main app content. Returning from offline triggers one refresh. Tests exercise offline/retry and repeated online events. An available network interface does not prove internet/server reachability; server errors remain visible. No offline booking queue was added. |
| Mock-location review | Driver availability and active-trip publishers forward `Position.isMocked`. The server stores the flag and alerts admin at most once per driver per five minutes, without blocking matching. A client test preserves the flag through tracking; SQL verifies persistence, alert throttling and continued eligibility. This signal does not prevent a modified client from lying. |
| Stale drivers | A real one-minute pg_cron job marks missing/stale heartbeats offline. Threshold defaults to 120 seconds and is configurable from 30 to 3600. SQL tests cover missing/fresh/stale heartbeat, a changed threshold, privilege restriction and the scheduled job. Detection may take another scheduler interval. Assigned trips are not cancelled. |
| Localization | Generated English/Filipino resources now contain 768 message entries, including driver/admin controls, statuses, dynamic labels, validators, safe errors and consent UI. Shared buttons, fields, navigation, empty states and map fallbacks use them. Tests verify Filipino validation/error text and dynamic messages. User content, place/person names, historical server text and technical CSV field identifiers remain data. Native copy review is still useful; every possible screen/data combination was not manually inspected. |
| Accessibility | Main tourist/driver layouts, including scrolled content and navigation, pass at 390×844 and 1.5× text in English and Filipino. Headers wrap, tourist card dimensions grow with text and buttons can wrap. Main notification, location/reset-map and emergency controls expose labeled actions. Tests inspect actual semantics. The tourist map is replaced by a placeholder in widget tests; native map controls and TalkBack still need device testing. |

### Implemented, untested at the external boundary

- Provider expiry: migration 010 adds a durable queue, leases, bounded retries,
  service-only completion and a one-minute invoker. Database tests exercise queue
  creation, claiming, stale claims, retries, acknowledgement and access controls.
  Seven Deno tests exercise provider outcomes with injected responses: expired,
  already expired, paid/reconciliation, processing, failures and mode mismatch.
  The worker is implemented and type-checked, but no real PayMongo call or hosted
  Edge invocation was made. No Vault worker URL was configured locally; the
  invoker stays inactive without it. Expiry is asynchronous, so the late-payment
  guard remains essential. PayMongo documents the
  [explicit expiry operation](https://docs.paymongo.com/reference/expire-a-checkout-session)
  and [checkout lifecycle](https://docs.paymongo.com/docs/payment-channels-key-concepts).
- Android reset links: HTTPS redirect generation, one shared build-time host,
  `autoVerify` manifest filter and the `assetlinks.json` template are implemented.
  The URI tests and debug build passed. The packaged manifest contains
  `auth.example.test`, HTTPS and `/auth/reset-password`, preserves payment-return
  and disables Flutter's duplicate link handler. **This is not domain verified.**
  The owner must supply a real domain, package/signing fingerprint and Auth
  allow-list entry, publish the association and test recovery on Android.
  See [setup instructions](app-links/README.md) and
  [Android verification](https://developer.android.com/training/app-links/verify-applinks).
- Account-deletion recovery: the loopback runner's real REST dry run found one
  committed pending request. SQL retry and Deno orchestration tests passed.
  Actual HTTP cleanup through a running Edge Function was not exercised, and no
  hosted schedule was installed. Exact local and future scheduler instructions,
  including age filtering and retry behavior, are in
  [the operations guide](batch3-local-operations.md).

## Verification

Final command results and reproduction details are included with the replacement
files. Commands ran from `C:/Users/Prince/tricgabay_app` unless stated otherwise.

| Command | Exact result |
| --- | --- |
| `pwsh -NoProfile -File scripts/check_sql.ps1 -SkipBuild` | Exit 0; `SQL_PARSE_PASS files=60 pglast=v7.22`. The pinned parser image was built first. |
| `pwsh -NoProfile -File scripts/validate_database.ps1` | Exit 0; `FULL_CHAIN_PASS migrations=47 clean_database=true storage_auth=real_services`; `PGTAP_RESULT suites=13 assertions=230 failed_suites=0`; `CONCURRENCY_PASS races=3 observed_lock_overlap=3`; `DELETION_RESUME_PASS independent_committed_sessions=2 ledger_facts_unchanged=true`. |
| `flutter pub get` | Exit 0; `Got dependencies!`; 76 packages have newer versions incompatible with constraints. Added connectivity_plus 7.3.1; no Firebase major upgrade. |
| `flutter gen-l10n` | Exit 0; generated sources using `l10n.yaml`. |
| `flutter analyze --no-pub` | Exit 0; `No issues found! (ran in 22.6s)`. |
| `flutter test --no-pub` | Exit 0; `00:15 +140: All tests passed!` (129 existing + 11 additional tests). |
| `flutter build apk --debug --no-pub --dart-define=AUTH_APP_LINK_HOST=auth.example.test` | Exit 0; `assembleDebug` 38.7s; `Built build/app/outputs/flutter-apk/app-debug.apk`. |
| `deno test --config supabase/functions/deno.json --allow-env --allow-net --allow-read supabase/functions/tests` | Local Auth/Storage environment enabled; exit 0; `ok` / `41 passed` / `0 failed (3s)`; neither integration test ignored. |
| `deno check --config supabase/functions/deno.json supabase/functions/create-paymongo-checkout/index.ts supabase/functions/expire-paymongo-checkouts/index.ts supabase/functions/delete-account/index.ts` | Exit 0; all three entry points checked. |
| `pwsh -NoProfile -File scripts/resume_account_deletions.ps1 -BaseUrl $env:LOCAL_SUPABASE_URL -DryRun` | Exit 0; `RECOVERY_REQUESTS count=1 dry_run=True`. Read-only discovery, not completed identity deletion. |
| `git -c core.safecrlf=false diff --check` | Exit 0; no whitespace errors. |
| `npx --yes supabase@2.121.0 stop --project-id tricgabay_batch3_isolated --no-backup` | Exit 0; isolated setup stopped with backup=false; no matching running containers remained. |

The debug APK still emits the existing Mapbox/share_plus Kotlin plugin warning.
The first build also emitted an Android SDK XML tool-version warning; the final
incremental build succeeded. No release/store submission was tested.
The packaged APK's reset host is a test placeholder and must be changed for a
usable recovery build. These client/RPC changes require coordinated backend and
client release; review the minimum supported build policy at that time.

### Database suites

| Suite | Passing assertions |
| --- | ---: |
| 001 schema contracts | 20 |
| 002 financial security | 31 |
| 003 capability/RLS | 14 |
| 004 refund reconciliation | 16 |
| 005 message delivery leases | 10 |
| 006 cross-system consistency | 22 |
| 007 payment/pickup authorization | 32 |
| 008 Batch 2 booking contracts | 15 |
| 009 payment timing | 9 |
| 010 privacy/financial integrity | 17 |
| 011 modes/consent/announcements | 22 |
| 012 checkout expiry queue | 12 |
| 013 location review/heartbeat | 10 |
| **Total** | **230** |

The race harness additionally reports first/second connection exit codes:
different UUID `0/3`, same UUID `0/0`, acceptance `0/3`. Exit 3 is the expected
SQL refusal for the losing conflicting request, not a failed harness check.

### Migration status

Every row below was applied during the clean reset and is included in the green
database suite. This means the migration chain and its current tested contracts
passed locally; it does not imply exhaustive feature coverage or a hosted run.
Each migration committed separately. The payment_pending enum in 002 therefore
committed before 003 used it. No additional ordering, enum-commit, extension or
schema-search-path failure occurred in the full chain after correcting 007.

| Migration | Status | Evidence |
| --- | --- | --- |
| 202610200001_initial_backend.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610200002_trip_workflows.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610200003_participant_profiles.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610200004_seed_catalog.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610200005_atomic_test_refunds.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610210001_pickup_arrival_no_show.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610210002_dispatch_expiration.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610210003_admin_cancellation_policy.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610210004_ranked_driver_offers.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610210005_scheduled_replacement_statuses.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610210006_scheduling_and_reassignment.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610210007_route_disruptions.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610220001_payment_reconciliation_and_ledger.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610220002_refund_simulation_and_communications.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610220003_public_brand_assets.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610220004_test_mode_refund_completion.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610220005_driver_compliance_and_matching.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610230001_core_integrity_hardening.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610230002_upload_and_registration_hardening.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610230003_active_driver_admin_safety.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610230004_pickup_security_and_offer_privacy.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610230005_operations_roles_retention.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610230006_pause_communications_scheduler.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610230007_secure_communications_scheduler.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610230008_refund_finance_authorization.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610230009_atomic_paymongo_webhooks.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610230010_capability_rls_and_avatar_storage.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610230011_refund_timeout_reconciliation.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610230012_financial_ledger_trigger_enum_safety.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610230013_admin_rpc_execute_privileges.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610230014_environment_scoped_communications_dispatcher.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610240001_scheduled_activation_execution_boundary.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610240002_versioned_profile_avatars.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610240003_message_delivery_leases.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610240004_cross_system_consistency.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202610240005_payment_pickup_authorization.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202611030001_scoped_realtime_refresh.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202611030002_payment_pending_enum.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202611030003_booking_payment_idempotency_geofence.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202611030004_pickup_code_reissue.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202611030005_targeted_announcements.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202611030006_client_version_and_clock.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202611030007_privacy_and_account_deletion.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202611030008_tested_payment_privacy_integrity.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202611030009_consent_and_announcement_guards.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202611030010_provider_checkout_expiry_queue.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |
| 202611030011_location_review_and_heartbeat_expiry.sql | APPLIED+TESTED LOCALLY | Clean reset; aggregate 001–013 suites green |

## Audit corrections

- The 007 syntax defect was real. It was fixed before the first full-chain run.
  The initial unchanged 001–008 suites then passed 160 assertions; none needed
  weakening or updating for this batch.
- New tests reproduced the cron-first late-payment defect before its fix: a
  cancelled booking could become paid without refund-required. Both 31-minute
  orderings now pass. Expiring the browser checkout is a separate asynchronous
  provider operation, not something the database alone can guarantee.
- Deletion's arbitrary FK loop did **not** reassign ledger participants: the
  ledger has no direct profile FK. The concrete failures were payment/refund
  updated_at changes and missing dispute-statement erasure. Those were corrected,
  and the loop was still replaced with a reviewed allow-list to protect future
  immutable tables. Money/provider/timestamp invariants and rollback were tested.
- Live mode cannot safely be enabled by relabeling checkout rows alone: webhook,
  refund and ledger behavior in this checkout remain test-scoped. An explicit
  refusal is the tested safe behavior until that whole flow is supported.
- The current registration RPC already supports repeated pending submissions.
  The client sign-in policy and navigation excluded those users. Restricted
  access now uses that existing server boundary without disabling confirmation.
- App Links support already arrives through Supabase's app_links dependency.
  No second link listener or additional app_links dependency was needed.
- A pglast pass alone does not execute PL/pgSQL bodies. The full migration run
  compiled them and the database suites exercised their relevant paths. The
  provider-response tests still use injected responses and are labeled accordingly.

## Outstanding

- Real PayMongo expiry/late-payment reconciliation and refund execution, deployed
  worker authentication/delivery, configured Vault URL/secrets and queue monitoring.
- Publish/verify the real Android association and test actual password recovery
  email, cold/warm starts, native background location and TalkBack on devices.
- Run account-deletion HTTP cleanup through the deployed worker and install the
  documented recovery schedule when deployment is authorized. The database
  interrupted/retry path is already tested; HTTP cleanup remains untested.
- Native Realtime/network reconnection and provider/quota behavior were not
  exercised. There is no new offline booking queue or spoofing prevention claim.
- Do not start: **iOS support**, **admin MFA or separate web admin**, **masked
  calling/chat**, **SOS/share-trip**, **offline-cache encryption**, **Firebase
  major upgrades**, **favorites sync**, **financial retention schedule** (owner
  decision required). No financial retention schedule was introduced.

Flutter regenerated existing platform plugin-registration files when adding
connectivity_plus, including the existing iOS registration file. This is generated
dependency bookkeeping; iOS support/configuration/testing was not undertaken.

## Complete replacement files

The bundle contains full file contents, not patches, relative to this Batch 2
checkout. Pre-existing local changes remain intact. No source file was deleted
by Batch 3. Build caches and `.flutter-plugins-dependencies` are generated local
artifacts and are not replacement files. Secrets, linked-project metadata and
the private startup/status output are excluded. A SHA-256 manifest and selected
verification logs accompany the files.

- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java`
- `docs/app-links/README.md`
- `docs/app-links/assetlinks.json`
- `docs/audit-follow-up-batch3-2026-11-03.md`
- `docs/batch3-local-operations.md`
- `ios/Runner/GeneratedPluginRegistrant.m`
- `lib/app.dart`
- `lib/core/config/auth_link_config.dart`
- `lib/core/prototype/prototype_session.dart`
- `lib/core/services/active_trip_tracking_service.dart`
- `lib/core/services/auth_service.dart`
- `lib/core/services/auth_session_policy.dart`
- `lib/core/services/backend_repository.dart`
- `lib/core/services/connectivity_monitor.dart`
- `lib/core/services/error_messages.dart`
- `lib/core/services/privacy_service.dart`
- `lib/core/utils/validators.dart`
- `lib/core/widgets/app_button.dart`
- `lib/core/widgets/app_text_field.dart`
- `lib/core/widgets/l10n_text.dart`
- `lib/core/widgets/offline_banner.dart`
- `lib/core/widgets/privacy_consent_gate.dart`
- `lib/core/widgets/registration_privacy.dart`
- `lib/core/widgets/role_navigation_bar.dart`
- `lib/core/widgets/shared_widgets.dart`
- `lib/core/widgets/web_map_fallback.dart`
- `lib/features/admin/screens/admin_dashboard_screen.dart`
- `lib/features/admin/screens/admin_live_map_screen.dart`
- `lib/features/admin/screens/admin_login_screen.dart`
- `lib/features/admin/screens/admin_reports_screen.dart`
- `lib/features/admin/screens/admin_shell_screen.dart`
- `lib/features/admin/screens/driver_detail_admin_screen.dart`
- `lib/features/admin/screens/fare_settings_screen.dart`
- `lib/features/admin/screens/manage_drivers_screen.dart`
- `lib/features/admin/screens/manage_spots_screen.dart`
- `lib/features/admin/screens/manage_tourists_screen.dart`
- `lib/features/admin/screens/monitor_bookings_screen.dart`
- `lib/features/admin/screens/ratings_feedback_screen.dart`
- `lib/features/admin/screens/send_announcement_screen.dart`
- `lib/features/admin/screens/spot_form_screen.dart`
- `lib/features/auth/screens/login_screen.dart`
- `lib/features/auth/screens/register_driver_screen.dart`
- `lib/features/auth/screens/register_tourist_screen.dart`
- `lib/features/auth/screens/splash_screen.dart`
- `lib/features/driver/screens/active_trip_screen.dart`
- `lib/features/driver/screens/driver_application_pending_screen.dart`
- `lib/features/driver/screens/driver_bookings_screen.dart`
- `lib/features/driver/screens/driver_earnings_screen.dart`
- `lib/features/driver/screens/driver_edit_profile_screen.dart`
- `lib/features/driver/screens/driver_home_screen.dart`
- `lib/features/driver/screens/driver_notifications_screen.dart`
- `lib/features/driver/screens/driver_profile_screen.dart`
- `lib/features/driver/screens/incoming_booking_screen.dart`
- `lib/features/tourist/screens/tourist_home_screen.dart`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_fil.arb`
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_en.dart`
- `lib/l10n/app_localizations_fil.dart`
- `lib/main.dart`
- `macos/Flutter/GeneratedPluginRegistrant.swift`
- `pubspec.lock`
- `pubspec.yaml`
- `scripts/check_sql.ps1`
- `scripts/fixtures/concurrency.sql`
- `scripts/resume_account_deletions.ps1`
- `scripts/sqlcheck/Dockerfile`
- `scripts/sqlcheck/check_sql.py`
- `scripts/test_database_concurrency.ps1`
- `scripts/test_local_database.ps1`
- `scripts/validate_database.ps1`
- `supabase/config.toml`
- `supabase/functions/_shared/paymongo_expiry.ts`
- `supabase/functions/create-paymongo-checkout/index.ts`
- `supabase/functions/expire-paymongo-checkouts/index.ts`
- `supabase/functions/tests/paymongo_expiry_test.ts`
- `supabase/functions/tests/pending_driver_local_integration_test.ts`
- `supabase/migrations/202611030007_privacy_and_account_deletion.sql`
- `supabase/migrations/202611030008_tested_payment_privacy_integrity.sql`
- `supabase/migrations/202611030009_consent_and_announcement_guards.sql`
- `supabase/migrations/202611030010_provider_checkout_expiry_queue.sql`
- `supabase/migrations/202611030011_location_review_and_heartbeat_expiry.sql`
- `supabase/tests/009_payment_timing.sql`
- `supabase/tests/010_privacy_financial_integrity.sql`
- `supabase/tests/011_modes_consent_announcements.sql`
- `supabase/tests/012_checkout_expiry_queue.sql`
- `supabase/tests/013_location_review_and_heartbeat.sql`
- `test/auth_session_policy_test.dart`
- `test/batch2_behaviors_test.dart`
- `test/batch2_route_and_announcement_test.dart`
- `test/batch3_client_ops_test.dart`
- `test/location_services_test.dart`
- `test/privacy_consent_gate_test.dart`
- `windows/flutter/generated_plugin_registrant.cc`
- `windows/flutter/generated_plugins.cmake`

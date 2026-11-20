# Batch 4 implementation and verification report

3 November 2026. Working directory: `C:\Users\Prince\tricgabay_app`. Accepted Batch 3 working files were preserved. Git HEAD remains `be032162bdbbd740292bca29444fe4e52978ec08`; no commit, push, hosted schema/configuration change or functional payment/maps/Firebase/communications-provider call was issued. Package/tool downloads and the requested OSV advisory queries used the network.

Database work used only the unlinked temporary workspace `tricgabay-batch4-isolated`, project `tricgabay_batch4_isolated`, and its task-owned Docker services. Auth, Storage and Realtime were real local services. Live payments remain OFF. No physical device was used.

## Implemented

| Request | Result |
|---|---|
| 1a. Stale availability | Verified existing go-online timestamp; stale idle drivers go offline; assigned trips retain assignment and raise a critical alert. Fresh GPS publishes serve as heartbeats. |
| 1b. Paid replay | Fee-retaining cancellations preserve their settled fee; excess funds retain refund-required state; refunded/expiry paths and duplicate ledger prevention tested. |
| 1c. Consent history | Immutable append-only version/time/language/digest alongside current consent; English/Filipino shown language travels through signup and acceptance; legacy unknown language is `und`. |
| 1d. Other-party dispute text | Preserve the other author's statements. Redact only deleting-author statements/authored dispute text; preserve other-party reason and administrator resolution. |
| 1e. Expiry alerts | Immediate blocked-row alert; minute monitoring of blocked/stuck/exhausted processing; deduplication and last-attempt crash tests. |
| 2. Authorization/security evidence | Catalog contract, 13-identity relation/RPC matrix, all-role definer snapshot, unknown-object/unsafe-definer negative tests, real Storage bucket matrix, upload guards, versioned image URLs, OSV/Gitleaks scans. |
| 3. Environments/operations | Android dev/staging/production flavors and required release defines; manual CI drafts; authenticated health handler, service-only health view and eight monitoring queries; critical persisted alerts. |
| 4. Product/compliance | Editable bilingual emergency table/placeholders and dialer; own export requests/support fulfilment/private JSON/audits; mode-scoped live-ready payment plumbing behind OFF flag; real local Realtime catch-up/load; 100k EXPLAIN/index/filter work. |
| 5. Documentation | ARCHITECTURE, SECURITY, TESTING, DEPLOYMENT, OPERATIONS, KNOWN_ISSUES and RELEASE_CHECKLIST written from the implementation and measured limits. |

### Heartbeat details

The online/idle Android screen requests GPS every five seconds with zero distance filter. A shared gate allows at most one successful publish per five seconds and waits 30 seconds for movement under 15 metres. Payload: latitude, longitude, accuracy, heading, speed, sample timestamp and mock-location flag. The server sets `last_seen_at` after validating the publish. There is no independent timer heartbeat without fresh usable GPS. Idle screen disposal or OS/GPS interruption can stop publishes; the minute expiry job uses a default 120-second threshold. Assigned tracking uses the foreground trip service; stale assignments are retained and alerted rather than silently reassigned.

## Verification — tested

Exact final result lines:

```text
No issues found! (ran in 65.7s)
00:13 +144: All tests passed!
SQL_PARSE_PASS files=78 pglast=v7.22
FULL_CHAIN_PASS migrations=52 clean_database=true storage_auth=real_services realtime=true managed_owner_bootstrap=true
PGTAP_RESULT suites=20 assertions=336 failed_suites=0
CONCURRENCY_PASS races=3 observed_lock_overlap=3
DELETION_RESUME_PASS independent_committed_sessions=2 ledger_facts_unchanged=true
AUTHORIZATION_MATRIX actors=13 relations=56 functions=871 buckets=4 cases=24453 rpc_invocations=9490 catalog_only_functions=141 failures=0
SECURITY_DEFINER_SNAPSHOT functions=123 missing_search_path=0 unexpected_anon=0
CATALOG_NEGATIVE_PASS unregistered_table_rejected=true unfixed_definer_rejected=true
CATALOG_REBUILD_MATCH relations=56 functions=871 buckets=4
ok | 46 passed | 0 failed (3s)
STORAGE_MATRIX actors=13 buckets=4 cases=270 failures=0
REALTIME_LOAD connections=60 published=600 expected=1200 received=1200 dropped=0 duplicates=0 stale_final_rows=0 publish_ms=31726.1
REALTIME_RECONNECT missed=3 authoritative_heading=103 passed=true
LOCAL_INTEGRATIONS_PASS deno=true storage=true
ANDROID_CONFIGURATION_PASS checks=11 flavors=3 required_service_values_fail_closed=true synthetic_values_only=true
OSV_RESULT packages=188 affected_packages=0 vulnerabilities=0
MONITORING_SQL_PASS queries=8
```

Analysis wall time is environment-specific. Raw logs are authoritative for progress prefixes/durations. Edge entry points and new diagnostic scripts type-check. A final pending-driver API test also reproduces Flutter storage_client 2.8.1 multipart encoding with an empty filename; both multipart and binary document uploads pass. The Deno/Storage portion was repeated with --SkipLoad after adding that test. `actionlint 1.7.7` and `git diff --check` exited 0. No hosted CI run was performed.

### Commands, results and evidence

Logs/JSON are in `C:\Users\Prince\.codex\artifacts\tricgabay-batch4`; the evidence archive contains the selected non-secret outputs. Startup logs/local credentials are excluded.

| Command or command family | Exit/result | Evidence |
|---|---|---|
| `flutter gen-l10n` | 0 | gen-l10n.txt; generated English/Filipino files |
| `flutter analyze --no-pub` | 0 | flutter-analyze-final.txt |
| `flutter test --no-pub` | 0, 144 tests | flutter-tests-final.txt |
| `pwsh -NoProfile -File scripts/check_sql.ps1 -SkipBuild` | 0, 78 SQL files | sql-parser-final.txt |
| `pwsh -NoProfile -File scripts/validate_database.ps1 -LogDirectory <artifact-dir>` | 0; clean 52-file chain, owner bootstrap, 336 assertions, 3 races | database-validation-final.txt, full-chain-reset.txt, managed-extension-bootstrap.txt, pgtap/, concurrency/ |
| `deno run --allow-run=docker --allow-read --allow-write --allow-env scripts/test_catalog_access.ts` | 0; strict saved-contract comparison and all cases | authorization-matrix-final.txt, authorization-matrix.json, security-definer-snapshot.json |
| Same catalog command with `--catalog-only` after final rebuild | 0 | catalog-final-rebuild.txt |
| `deno run --allow-run --allow-env scripts/test_catalog_registration.ts` | 0; both intentional negative probes rejected | catalog-negative.txt |
| `deno check --config supabase/functions/deno.json <all Edge index.ts files>` | 0 | edge-check-final.txt |
| `pwsh -NoProfile -File scripts/run_local_integrations.ps1 -LogDirectory <artifact-dir>` | 0 | local-integrations.txt, deno-tests.txt, storage-authorization.*, realtime-load.* |
| `flutter build apk --debug --flavor <dev/staging/production> --dart-define=APP_ENV=<matching-flavor>` | 0 for each flavor | android-*-debug-final.txt; APK identity logs |
| `flutter build apk --release --flavor production --dart-define=APP_ENV=production` without service values | 1, expected rejection | android-production-release-missing.txt |
| `pwsh -NoProfile -File scripts/test_android_configuration.ps1 -LogDirectory <artifact-dir>/android-config` | 0; 3 synthetic complete configs and 8 individual missing-value rejections | android-config-summary.txt, android-config/ |
| `deno run --allow-read=pubspec.lock,supabase/functions/deno.lock --allow-write=<artifact-dir> --allow-net=api.osv.dev scripts/scan_dependencies.ts <artifact-dir>/dependency-scan.json` | 0 | dependency-scan.* |
| Gitleaks 8.24.3 `dir /repo --config /repo/.gitleaks.toml --redact --max-target-megabytes 2` in a read-only, network-disabled container | 0, no current-source findings | secret-scan-working-tree-final.* |
| Same Gitleaks image `git /repo ... --log-opts=--all` | 1, three redacted historical matches across four commits | secret-scan-history.* |
| `rhysd/actionlint:1.7.7` over local workflows in a read-only, network-disabled container | 0, no diagnostics | actionlint.txt |
| Monitoring query set executed with a synthetic operations actor/database-owner connection inside a rolled-back transaction | 0, eight queries | monitoring-query-summary.txt, monitoring-query-validation.txt |

The expected missing-configuration build failure names SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, MAPBOX_PUBLIC_TOKEN, all four FIREBASE fields and AUTH_APP_LINK_HOST. The diagnostic configuration tests use fake public values and produce no signed release artifact. APK package IDs/labels were inspected: `com.tricgabay.app.dev` / Tric-Gabay Dev; `.staging` / Tric-Gabay Staging; `com.tricgabay.app` / Tric-Gabay; version 1.0.0, build 3.

### Security matrix boundaries

The 13 identities include anon, A/B tourists, A/B drivers, suspended user, pending driver and six separate admin capabilities. There are 56 relations, 871 functions and four registered buckets. Reads include A/B records; writes/executes test owner/participant and cross-user cases. Mutations are rolled back. Unknown objects or catalog privilege/policy/function drift fail the suite.

Of the functions, 141 are trigger/internal/polymorphic support routines, so they receive catalog execution checks rather than ordinary RPC invocation. Upstream computations use typed NULLs; revoked strict helpers use non-NULL inputs to avoid planner folding. Allowed application calls may refuse invalid workflow state; dedicated pgTAP tests cover successful transition paths. This is not proof that every arbitrary argument combination is safe. The real HTTP Storage matrix separately verifies bucket read/list/upload/overwrite/delete/public-URL behavior, MIME/extension/size restrictions and versioned cache headers. Magic-byte checking is app-side prefix validation, not server image decoding/antivirus.

All 123 SECURITY DEFINER entries have fixed paths. The snapshot lists PUBLIC and all effective executor roles, not only API roles. Six anonymous role/configuration predicates are explicitly allowed. The separate extension-owner bootstrap is part of the verified local state, not something ordinary migrations can guarantee on a hosted platform.

### Realtime measurements and load

Local tenant limits: 100 messages/second, 200 concurrent users, 100 channels/client. Final canary warm-up delivered 60/60 events in one attempt. Then 30 simulated tourists plus 30 drivers published 600 workload updates in 31.726 seconds: 1,200/1,200 expected deliveries, zero duplicates, zero unauthorized payloads, zero stale final rows. While a tourist was disconnected, three writes were missed; reconnect plus authoritative SELECT recovered heading 103.

During the measured workload, sampled PostgreSQL connections peaked at 33. Database-counter deltas: 944 commits, 33 rollbacks, 706,678 buffer hits, zero block reads, 274,383 tuples fetched, 1,318 updated, 744 inserted and 13,325,481 returned. These include local background activity and statistics timing; they are not per-request CPU or hosted-capacity measurements. Full snapshots are retained in JSON.

The earlier 100-ms-round burst produced 1,043/1,200 workload deliveries (157 missed), no duplicates and no stale authoritative final rows. Server logs reported `MessagePerSecondRateLimitReached`. An earlier cold under-limit run missed `0:driver:1` despite channel acknowledgment; a measured delivery-readiness barrier was added to the harness, with warm-up counts kept separate. Neither failure is hidden by the final successful profile. Realtime does not replay missed events; state recovery relies on authoritative reads.

### Performance — controlled before/after

Exactly 100,000 synthetic terminal bookings were seeded. Both final comparison runs used the same database containing 100,064 total bookings. The before run temporarily removed only the five new indexes and used the original query shape, then restored the indexes in `finally`. The after run used the current filters (including pending unassigned offers for drivers). One cold and three warm EXPLAIN ANALYZE/BUFFERS runs per query; warm median below.

| Base list under actual RLS | Before ms | After ms |
|---|---:|---:|
| Tourist history | 4403.331 | 0.367 |
| Driver history | 4393.089 | 0.368 |
| Tourist active | 4.856 | 0.096 |
| Driver active, preserving offers | 5.315 | 4.877 |
| Admin history | 2045.586 | 2.249 |
| Admin active | 2.782 | 1.994 |

Commands: `scripts/run_performance.ts after --seed`, then `before --baseline-indexes`, then `after`, with Deno read/write/docker permissions and VALIDATION_LOG_DIR. Exact command examples are in TESTING.md. All five migration 016 indexes were verified restored. JSON includes query text, plans and buffers. The terminal-heavy bulk seed bypasses workflow/FK triggers during INSERT; it does not simulate 100k real booking requests. Network, nested PostgREST hydration and device rendering are excluded. Filters and indexes change together, so individual contributions are not isolated.

### Scans and findings

OSV queried 179 locked hosted Pub packages and nine locked Deno npm packages: zero reported affected packages at scan time. No major upgrades were made. Flutter SDK/native Android transitive artifacts are outside that scan's coverage.

The source scan was clean. The history scan's three matches are: a synthetic scheduler test token; an old Supabase anonymous client JWT; an old Firebase client API key. Reports redact values. No private backend/payment secret was identified by these scans. Firebase API restrictions were not inspected; owner review is required before deciding restriction/rotation or a narrow documented baseline. The history CI gate therefore remains nonzero. No Git history or hosted credential was changed.

### Migration table

Status means applied in the clean local CLI chain; tests run against the resulting final schema, not individually against every intermediate state. The owner bootstrap is an additional verified step. None is applied to a hosted environment by this work.

| Migration file | Local status |
|---|---|
| `202610200001_initial_backend.sql` | APPLIED |
| `202610200002_trip_workflows.sql` | APPLIED |
| `202610200003_participant_profiles.sql` | APPLIED |
| `202610200004_seed_catalog.sql` | APPLIED |
| `202610200005_atomic_test_refunds.sql` | APPLIED |
| `202610210001_pickup_arrival_no_show.sql` | APPLIED |
| `202610210002_dispatch_expiration.sql` | APPLIED |
| `202610210003_admin_cancellation_policy.sql` | APPLIED |
| `202610210004_ranked_driver_offers.sql` | APPLIED |
| `202610210005_scheduled_replacement_statuses.sql` | APPLIED |
| `202610210006_scheduling_and_reassignment.sql` | APPLIED |
| `202610210007_route_disruptions.sql` | APPLIED |
| `202610220001_payment_reconciliation_and_ledger.sql` | APPLIED |
| `202610220002_refund_simulation_and_communications.sql` | APPLIED |
| `202610220003_public_brand_assets.sql` | APPLIED |
| `202610220004_test_mode_refund_completion.sql` | APPLIED |
| `202610220005_driver_compliance_and_matching.sql` | APPLIED |
| `202610230001_core_integrity_hardening.sql` | APPLIED |
| `202610230002_upload_and_registration_hardening.sql` | APPLIED |
| `202610230003_active_driver_admin_safety.sql` | APPLIED |
| `202610230004_pickup_security_and_offer_privacy.sql` | APPLIED |
| `202610230005_operations_roles_retention.sql` | APPLIED |
| `202610230006_pause_communications_scheduler.sql` | APPLIED |
| `202610230007_secure_communications_scheduler.sql` | APPLIED |
| `202610230008_refund_finance_authorization.sql` | APPLIED |
| `202610230009_atomic_paymongo_webhooks.sql` | APPLIED |
| `202610230010_capability_rls_and_avatar_storage.sql` | APPLIED |
| `202610230011_refund_timeout_reconciliation.sql` | APPLIED |
| `202610230012_financial_ledger_trigger_enum_safety.sql` | APPLIED |
| `202610230013_admin_rpc_execute_privileges.sql` | APPLIED |
| `202610230014_environment_scoped_communications_dispatcher.sql` | APPLIED |
| `202610240001_scheduled_activation_execution_boundary.sql` | APPLIED |
| `202610240002_versioned_profile_avatars.sql` | APPLIED |
| `202610240003_message_delivery_leases.sql` | APPLIED |
| `202610240004_cross_system_consistency.sql` | APPLIED |
| `202610240005_payment_pickup_authorization.sql` | APPLIED |
| `202611030001_scoped_realtime_refresh.sql` | APPLIED |
| `202611030002_payment_pending_enum.sql` | APPLIED |
| `202611030003_booking_payment_idempotency_geofence.sql` | APPLIED |
| `202611030004_pickup_code_reissue.sql` | APPLIED |
| `202611030005_targeted_announcements.sql` | APPLIED |
| `202611030006_client_version_and_clock.sql` | APPLIED |
| `202611030007_privacy_and_account_deletion.sql` | APPLIED |
| `202611030008_tested_payment_privacy_integrity.sql` | APPLIED |
| `202611030009_consent_and_announcement_guards.sql` | APPLIED |
| `202611030010_provider_checkout_expiry_queue.sql` | APPLIED |
| `202611030011_location_review_and_heartbeat_expiry.sql` | APPLIED |
| `202611030012_batch4_lifecycle_and_consent.sql` | APPLIED |
| `202611030013_batch4_access_and_uploads.sql` | APPLIED |
| `202611030014_batch4_operations_and_data_rights.sql` | APPLIED |
| `202611030015_batch4_mode_scoped_payments.sql` | APPLIED |
| `202611030016_batch4_booking_list_performance.sql` | APPLIED |

Owner step: `supabase/bootstrap/managed_extensions.sql` — APPLIED AND VERIFIED as local supabase_admin. Hosted status for every row/owner step: NOT APPLIED BY THIS WORK.

## Audit corrections and validation discoveries

- Go-online already set `last_seen_at`; the missing-null-stamp concern was not reproduced. Assigned-stale alerting was added and tested.
- The event processor already ignored a paid replay for an already-paid payment. The cancellation release trigger still needed protection if re-fired; retained fee/refund/refunded/expiry cases now cover both boundaries.
- Ledger triggers already copied payment mode. Test-only constraints, event uniqueness and provider transport/configuration were the blockers; they are now mode-scoped behind the OFF gate.
- Driver document buckets were already private. Missing restrictions were app byte/MIME/extension agreement, safe metadata/size validation and Storage preflight compatibility.
- Catalog tests exposed a real driver-location policy shadowing leak, anonymous legacy RPC grants and NULL-role checks. They were fixed rather than relabelled expected access.
- Managed PostGIS definers cannot be altered by the ordinary migration owner on the local Supabase image. A first clean run failed on ownership; the explicit owner bootstrap fixes the final state and remains a hosted prerequisite.
- Storage HTTP testing caught `contentLength` preflight versus `size` persistence. SQL-only fixtures had not exposed that difference; both stages are now tested.
- The initial 100k seed hit the old 32-bit booking-reference unique constraint. Future labels now use 64 random bits; existing labels remain valid.
- One re-run of legacy pgTAP suites after committed load fixtures failed fixture-global assumptions. The final run reset the database first and passed all 336 assertions; the standalone runner now refuses a nonempty booking fixture. This was test ordering, not a green result substituted for a product failure.
- Android/Flutter executes some sibling-variant preparatory tasks. An initial dev build hit a production guard; validation now targets the explicitly requested flavor and rejects aggregate multi-environment builds. All final flavor builds/config checks are recorded.
- New list filters preserve unassigned driver offers; a dedicated RLS regression suite checks offered versus another driver's pending booking.
- Root docs supersede earlier migration comments saying local files were untested. Provider/device behavior is still explicitly unverified.

## Implemented but untested outside the isolated environment

No real-device dialer/share sheet/GPS/foreground/OEM-battery test; no installed App Links/domain association; no real Firebase push/diagnostics, PayMongo browser/webhook/refund/expiry, communications delivery or hosted quota/pause test. No final signed production bundle/store upload, hosted Edge runtime deployment, cloud CI execution or hosted extension-owner operation. The health handler ran through real local HTTP and the actual local database, not a hosted Edge gateway.

The data-export workflow is implemented and authorization-tested. Its JSON currently includes profile, driver application, base bookings, payments, own dispute statements, own feedback and consent history. It is not every child table/binary document/Auth/provider log; owner policy must define supplementary fulfilment. Suspended/inaccessible accounts need an assisted identity-verification process. Five local emergency numbers remain disabled placeholders until the owner supplies verified numbers.

## Not done

iOS; admin MFA/web admin; masked calling/chat; SOS/share-trip; offline cache encryption; Firebase major upgrades; favorites sync; retention scheduling. No live-payment enablement, payout transfer flow, hosted deployment, external paging setup or real provider calls. No Git commit/push or history rewrite. A historical Firebase-key restriction review remains open, so the history scan is completed with findings, not passed.

## Owner decisions

1. Verify the five local agency contacts and assign their maintainer.
2. Supply distinct projects, restricted public keys, Firebase Android registrations, verified domains/return URLs, signing fingerprints and release-keystore custody for all flavors.
3. Review the historical Firebase API key's permitted APIs/quotas and decide restriction/rotation and any narrowly documented historical baseline.
4. Arrange the platform extension-owner bootstrap and staging catalog verification.
5. Choose operators, paging destination/response expectations, queue-repair authority, backup/restore owner and supported concurrency/message budget.
6. Approve bilingual privacy/diagnostics notices, privacy contact, assisted export/identity procedure, response deadlines, additional export categories and retention periods. No retention schedule was inferred.
7. Complete test-provider certification, reconciliation/refund procedures and payout ownership. Keep live mode OFF until a separate approved provider-tested release.
8. Choose device acceptance matrix, minimum build, weather/service-hours policy and replacement/escalation responsibilities.

See RELEASE_CHECKLIST.md for the device/provider acceptance list and KNOWN_ISSUES.md for practical limits.

## Delivery and cleanup

The replacement archive contains full files changed/added relative to the accepted Batch 3 starting snapshot, not patch fragments. Apply only over that accepted working tree. A SHA-256 manifest identifies every replacement/new file; no source deletion is required. Local machine configuration, generated build caches, credentials and startup logs are excluded. The separate evidence archive contains selected safe logs, plans, matrices and redacted scan results.

Task-owned stack cleanup verified: `CLEANUP_PASS owned_containers_remaining=0 other_containers_unchanged=true`. The disposable database/Realtime/Auth/Storage stack is stopped; scripts can recreate it for future testing. No other local Supabase project is stopped. No remote action is part of this delivery.

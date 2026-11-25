# Known issues and verification limits

Batch 4 is local coding and validation work, not permission to launch. Read the evidence report for exact results.

## Needs device or provider testing

- Android GPS accuracy, permission denial/settings recovery, foreground notification, kill/restart recovery, background delivery and OEM battery limits. Idle sharing is screen-owned and has no independent timer heartbeat; expired availability is deliberate when samples stop.
- Real dialer, export share sheet, installed flavor coexistence, secure storage/reinstall recovery, accessibility and Filipino wording with local users.
- HTTPS App Links/domain association, password reset and checkout return behavior on installed builds.
- Firebase push, diagnostics consent/collection behavior, real provider webhook/refund/expiry responses, communications sender identity and delivery. No functional calls to those services were made in Batch 4.
- Hosted schema privileges/owner bootstrap, Realtime quotas, database pause/quota recovery, backups/restore and signed store distribution. No hosted rollout or cloud CI run was performed.

## Remaining implementation boundaries

- The Realtime burst stress profile exceeded the local tenant's 100-message/second limit and lost intermediate updates. A cold-start run also missed one first event after acknowledgment. The lower-rate profile delivered all 1,200 workload events after measured canary readiness, and authoritative reconnect/final-state reads passed. Hosted capacity still needs a realistic usage budget; no production throughput claim is made.
- Historical Gitleaks reports three matches across four commits. One is a synthetic token, one a Supabase anonymous client JWT, and one a Firebase client API key whose restrictions are unverified. Current source scans are clean. The history CI gate remains nonzero; no history rewrite or remote key change was authorized.
- Magic-byte checks validate prefixes in the app, not full decoding or server antivirus. A direct malicious uploader can forge metadata/signatures. Documents remain private; public attraction photos are intentionally public. JPEG-only driver documents are explained in the form.
- Data export covers account profile, driver application, base bookings, payments, own dispute statements, own feedback and consent history, excluding pickup hashes, provider metadata and other parties' statement bodies. It does not include every application child table, binary document, Auth or provider log. The owner must decide which additional categories their fulfilment procedure requires. Suspended or inaccessible accounts need an assisted owner procedure. Export payload sharing may expose personal information to the destination chosen by the user.
- The old eight-character booking reference space collided during a 100k seed. Future references use sixteen hex characters; old labels are unchanged. Reference labels never authorize access. Device layouts should include long-reference cases.
- PostGIS platform-owner grants cannot be revoked by hosted postgres. Migration `202611080001` isolates the extension in the non-exposed `extensions` schema; keep that schema outside the Data API. This replaces the earlier hosted extension-owner runbook requirement. Direct SQL database accounts remain privileged and need operator access controls.
- Gradle reports Mapbox/share_plus Kotlin plugin migration warnings and Android SDK XML version skew. All three debug flavors built locally; no major dependency upgrades were made. OSV covers locked hosted Pub/Deno npm packages, not native transitive artifacts or Flutter SDK code.
- Base-list EXPLAIN improvements do not include PostgREST nested hydration, network, image loads or device frames. The synthetic seed bypasses workflow side effects and contains terminal-heavy data; it is not a behavioral load test of 100,000 real bookings.
- Emergency local numbers remain placeholders until owner verification. The national 911 fallback is not a municipality-sourced local directory.
- State still uses ValueNotifiers/feature controllers alongside Riverpod. Offline booking submission, multi-vehicle groups, synced favorites, GPS attestation and a driver payout transfer workflow remain outside this batch.

## Explicitly not started

iOS support; admin MFA/web admin; masked calling/chat; SOS/share-trip; offline cache encryption; Firebase major upgrades; favorites sync; a retention schedule. Existing generated cross-platform registration files may change during dependency tooling; that is not iOS implementation or validation.

Owner decisions are collected in RELEASE_CHECKLIST.md. None of these pending decisions silently enables live payments.

## 2026-11-20 payment redesign follow-ups

- The hosted PayMongo Edge Functions (`create-paymongo-checkout`, `paymongo-webhook`, `process-paymongo-refund`, `reconcile-paymongo-payment`, `expire-paymongo-checkouts`) are still deployed. Their source was removed and new PayMongo bookings are rejected, but the deployments themselves have to be deleted by the owner with `supabase functions delete <name>` or from the dashboard. The two PayMongo cron jobs are paused, not removed. The legacy PayMongo RPCs `reserve_paymongo_refund` and `complete_paymongo_test_refund` no longer have execute grants.
- Migration history is in sync: the GCash migrations were applied to the hosted project in parts (the Supabase connector rejects `DROP`/`DELETE`), and the local files under `supabase/migrations/20261120*` mirror those parts one-to-one with the same version numbers, so `supabase db push` has nothing extra to apply.
- Receipt screenshots have no automatic retention or deletion yet. They are private and visible only to the booking's tourist, its driver and finance/operations admins.
- Leaked-password protection (security advisor) is a Supabase paid-plan feature and is unavailable on this free project. Accepted for the capstone; enable it after upgrading.
- Older pgTAP files that insert `paymongo` bookings directly still work. Only bookings created through the app's RPC are rejected.
- The app no longer simulates booking rules offline: every trip, payment and admin action goes to the server (`AppSession._requireServer`), and the old on-device booking ledger is removed on startup. Server rules are covered by the pgTAP suites in `supabase/tests`. `booking_detail_screen.dart` and `tourist_home_screen.dart` are split into part files of about 400–530 lines each.

# Release checklist and owner decisions

Batch 4 coding is prepared locally. The items below remain launch gates. No store, hosted database or real provider was changed.

## Verified locally

- [x] Full 52-migration chain and explicit extension-owner bootstrap on an isolated database.
- [x] Lifecycle, consent, deletion, expiry-alert, RLS, mode-scoped financial and data-rights database tests; concurrent booking/acceptance and deletion-resumption tests.
- [x] Catalog-wide authorization probes, SECURITY DEFINER snapshot, rejection of unknown objects/unfixed definers and real HTTP Storage bucket matrix.
- [x] Injected test/live provider responses with live disabled outside rolled-back tests; local HTTP health collection and alerts.
- [x] Real local Auth/Storage/Realtime, reconnect catch-up, synthetic 60-connection measurements and 100k base-list EXPLAIN evidence.
- [x] Android dev/staging/production debug builds and missing-release-configuration rejection. Flutter checks and workflow syntax tested locally; see report for exact final commands.
- [x] Dependency/secret scans executed and findings reported. This does not mean the historical secret gate is green.

## Owner must decide/provide

- [ ] Verified MDRRMO, PNP, BFP, hospital and tourism-office phone numbers, names and responsible contact maintainer.
- [ ] Separate development/staging/production projects, Mapbox restrictions, Firebase registrations, Supabase keys, authentication/return domains, verified App Links and release signing fingerprints/keystore custody.
- [ ] Review the historical Firebase client API key's API/quota restrictions; decide whether restriction/rotation and a documented historical-finding baseline are required. Do not suppress it before review.
- [ ] Obtain the platform/extension owner's bootstrap support for managed PostGIS objects and re-run catalog checks in staging.
- [ ] Operator ownership, external monitoring/paging destination, critical-alert response expectations, queue-repair authority, backup/restore responsibility and supported concurrent-user/message budget.
- [ ] Privacy notice wording in English/Filipino, diagnostics disclosures/choice, privacy contact, assisted identity-verification/export procedure, response deadlines and legally appropriate retention periods. No retention schedule was coded.
- [ ] Decide which Auth/provider records must supplement the implemented in-app export, and how inaccessible/suspended/deleted accounts receive a verified response.
- [ ] PayMongo account readiness, approved payment return URL, test webhook/expiry/refund certification, reconciliation procedure and eventual driver payout responsibility. Live mode stays OFF; enabling it requires a separate approved, provider-tested release decision.
- [ ] Device matrix and minimum supported app build; service hours/weather-pause operating policy and incident replacement escalation.

## Device/provider acceptance before release

- [ ] Install all three flavors side by side; confirm package IDs, labels, keys, domains and that no staging build targets production.
- [ ] Test tourist offline pickup/retry, booking lost-response recovery and code reissue after reinstall/new device.
- [ ] Test online idle/assigned driver behavior with denied/disabled GPS, low battery, screen changes, force stop, restart and network reconnect. Confirm stale availability and assigned-trip alerts.
- [ ] Verify real private-document upload/read restrictions and long booking reference layouts; review screenshots and Filipino labels on small screens.
- [ ] Verify dialer and export sharing, privacy acceptance/version changes and deletion with both parties' dispute statements.
- [ ] Exercise real test-mode browser close, webhook delay/replay, checkout expiry, partial/full refund, signed webhook rejection and delivery retries. Verify ledger reconciliation; do not use live money.
- [ ] Exercise real push/communication delivery, App Links, health authentication and paging routes; load-test staging at the chosen quota.
- [ ] Clear/review the historical key finding; verify native dependency advisories and intended Firebase/Mapbox SDK warnings before future upgrades.
- [ ] Generate a properly signed production bundle with real reviewed public configuration, increment store build number, validate store requirements and retain symbols. Do not distribute diagnostic debug-signed release artifacts.

All unchecked items need explicit evidence/owner action. iOS, MFA/web admin, chat, SOS/share-trip, offline encryption, favorites sync and major Firebase upgrades remain separate work.

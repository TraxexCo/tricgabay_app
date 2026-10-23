# Tric-Gabay release, recovery, and validation runbook

## Release gates

No production artifact may be distributed unless all automated checks pass, a
real upload keystore is provided through protected CI environment secrets, and
the physical-device matrix below has current evidence. Debug-signed artifacts
are strictly for local validation.

Required protected GitHub secrets:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_STORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`

The manual `Signed Android release` workflow refuses to build when any are
missing. Store generated symbol files with the release so crash reports can be
decoded. Never commit a keystore, service-account JSON, database password, or
provider secret.

## Database backup and restore rehearsal

1. Run `scripts/backup_supabase.ps1` from the repository root. Encrypt the two
   resulting SQL files at rest and copy them to an access-controlled location.
2. Record the project reference, migration version, UTC time, operator, file
   hashes, and encrypted backup location in the release record.
3. Start a disposable local Supabase stack. Never rehearse against production.
4. Reset the disposable database to the repository migrations, restore the
   schema/data dumps, and verify row counts for profiles, bookings, payment
   ledger, tourist spots, and communication deliveries.
5. Run `supabase test db`, sign in with one account per role, open one completed
   booking, and reconcile its payment ledger total.
6. Destroy the disposable stack and record pass/fail, duration, and findings.

Rehearse quarterly and before any destructive migration. A backup is not
considered valid until a restore rehearsal succeeds.

## Retention and storage

The scheduled retention job starts in dry-run mode (`retention_enabled=false`).
An authorized data owner must approve documented retention periods before the
setting is enabled. Database cleanup covers old completed-trip tracking,
delivered communication records, old notifications, revoked tokens, and
processed webhook receipts. Spot covers and avatars use deterministic object
names, so replacements do not leak old files; deleting a spot removes its
storage folder. Review candidate counts before enabling deletion.

## Physical Android validation matrix

Capture device model, Android version, app version, network type, tester,
timestamp, result, and screenshot/video reference for each row.

| Scenario | Required evidence |
|---|---|
| Fresh tourist/driver/admin sign-in and sign-out | Correct role routing; Android Back never unexpectedly exits a nested flow |
| Permission denied, denied forever, and location services off | Clear recovery instructions; no false “live” state |
| Driver accepts, arrives, starts, navigates, completes | Route visible; foreground tracking indicator; tourist marker updates |
| App backgrounded, process killed, then reopened mid-trip | Active trip is recovered from server; tracking restarts after permission check |
| Force-stop from Android settings | App explains that Android prevents restart until manually opened |
| Offline before and during sync | Cached data is labeled; payments, cancellation, and state transitions remain blocked |
| Weak/alternating mobile data | No duplicated booking, payment, cancellation, or completion |
| Tourist/driver cancellation at every trip stage | Server policy and ledger agree for both participants and admin |
| Payment success, failure, abandonment, duplicate webhook, refund | One ledger outcome; retry remains idempotent |
| Notification permission denied and token refresh | In-app notification still works; delivery retry/alert is visible to operations |
| Emergency flow during active trip | Correct booking/user context without exposing pickup code |
| Font scale 100%, 150%, 200% and TalkBack | Reading order, labels, focus, and actions remain usable without clipping |
| English and Filipino, small and large phones | No untranslated critical action or overflow |
| Low battery/background restriction | Degraded/stale location is clearly shown, never presented as current |

## Incident response

Operational alerts detect exhausted communications, stale active-trip tracking,
and stuck payment/refund processing. The operations administrator acknowledges
the incident, records affected booking references (not private profile data),
retries only idempotent server commands, and escalates payment inconsistencies
to finance. Crash and performance reports must not include names, email,
telephone numbers, coordinates, pickup codes, payment data, or free-form text.

## Known platform boundary

Android can keep location updates alive with a foreground notification while
the process is backgrounded. After the user explicitly force-stops the app,
Android prevents automatic restart; tracking can resume only after the user
opens Tric-Gabay again. The UI and support guidance must describe this honestly.

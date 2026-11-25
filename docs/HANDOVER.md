# Client handover checklist (internal)

For the project owner only. This is not a document for the client. It contains no secrets: only names, and where each thing lives.

Written 2026-11-26 from a read-only audit of the repo, the release APK and the hosted Supabase project. Nothing was changed on the hosted project while writing it.

## The situation

- The client receives **the APK and the Supabase account**. The source repo stays with the owner.
- The hosted project is `xcsrjuqzwequmeqzedzd` (name `tric-gabay`, region ap-northeast-2, **Free plan**). It already sits in its own organization, named `Tric-Gabay`.
- The APK has these values compiled in (checked in the release build): `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` (anon), `MAPBOX_PUBLIC_TOKEN`, the Firebase client options (`FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`) and `AUTH_APP_LINK_HOST`. Changing any of them means **rebuilding and re-delivering the APK**.

### Rebuild or not: it depends on how the project moves

| Route | Project ref / URL / anon key | APK rebuild? |
|---|---|---|
| **A. Move the existing project** (give the client ownership of the `Tric-Gabay` organization, or use Project Transfer to the client's organization) | Unchanged | **No** |
| **B. New project in the client's account** (restore a backup into it) | New URL and new keys | **Yes**, plus the re-setup list in the appendix |

Route A is the recommended one. Supabase describes project transfer as moving a project between organizations without touching the infrastructure, so the URL and keys stay the same. Confirm this on the transfer confirmation screen before you rely on it. Route B is only for the case where the client must have a brand-new project.

## What the app depends on

"Breaks?" means: does the app stop working if ownership of that item changes without a matching update.

| Item | Where it lives | Owner today | Breaks if ownership changes? | Rebuild? | What moving it to the client takes |
|---|---|---|---|---|---|
| **Supabase** (database, auth, storage, 3 Edge Functions, 11 cron jobs) | Project `xcsrjuqzwequmeqzedzd`; URL and anon key compiled into the APK | Organization `Tric-Gabay` (your account) | No on route A. Yes on route B | A: no. B: yes | Route A: see the transfer steps below. Billing moves with the organization |
| **Firebase**: project, FCM push | Firebase project named in `FIREBASE_PROJECT_ID`; client options compiled into the APK. The **server side of push** is the Edge Function secret `FIREBASE_SERVICE_ACCOUNT_JSON` | To confirm in the Firebase console (assumed your Google account) | **Push stops** if that project or its service-account key is deleted or rotated. The rest of the app still works | Only if the client wants their own Firebase project: new app registration, new client options in the APK | Create a Firebase project under the client's Google account, register the Android app `com.tricgabay.app`, put the new client options in `config/production.json`, put the new service-account JSON into the Edge Function secret, rebuild |
| **Mapbox** (maps, search, directions, geocoding) | Public token `pk.…` compiled into the APK (the scan found only a `pk.` token, no `sk.` token). Build-time **downloads token** `MAPBOX_DOWNLOADS_TOKEN` is in `~/.gradle/gradle.properties` on your PC, not in the APK or the repo | To confirm in the Mapbox dashboard (assumed your account). **All Mapbox usage is billed to the account that owns the public token** | Maps and search stop if the token is revoked or the account is closed | Yes, to switch to a client-owned token | Client creates a Mapbox account and a public token. You put it in `config/production.json` and rebuild. The downloads token only matters on the PC that builds |
| **PayMongo** | Retired. App code no longer uses it. Leftovers: Edge Function secrets `PAYMONGO_TEST_SECRET_KEY`, `PAYMONGO_TEST_WEBHOOK_SECRET`, `APP_PAYMENT_RETURN_URL` and two **inactive** cron jobs | You (test keys only; no live keys were found) | No | No | Nothing to move. Delete the three leftover secrets and the two inactive cron jobs (after the transfer or before, your choice) |
| **GCash** | No merchant account. Payment is **direct to the driver's own GCash**: the driver uploads a QR (bucket `driver-gcash-qr`), the tourist sends a receipt (bucket `gcash-receipts`) | Each driver | No | No | Nothing to move. The QR images and receipts move with the database and storage |
| **Brevo** (booking emails sent by the `dispatch-communications` Edge Function) | Edge Function secrets `BREVO_API_KEY`, `EMAIL_FROM`, `EMAIL_FROM_NAME` | Your Brevo account | Booking emails stop if the key is revoked or the account closed | No | Client creates a Brevo account, verifies a sender domain, makes an API key. You (or they) replace the three secrets. See "Later" |
| **Auth emails** (sign-up confirmation, password reset) | Supabase Auth settings. Not Brevo unless custom SMTP is set up. **This setting is not readable without the dashboard** | Supabase organization | See "Risk: auth emails" | AUTH link host needs a rebuild | See "Later" |
| **Google Fonts** | Fetched at runtime by the app | None | No | No | Nothing |
| **GitHub repo** `TraxexCo/tricgabay_app` | Source and CI. CI uses **no secrets** | You | No (the app does not depend on it) | No | Stays with you. The repo is **public** (see below) |

### Risk: auth emails

- The hosted project currently has **Confirm email on**. Checked on the public auth settings endpoint: `mailer_autoconfirm` is false, so sign-up needs a confirmed email.
- Supabase's built-in email sender only delivers to addresses that belong to the organization's team, and it is rate-limited. It is meant for testing. Unless custom SMTP is configured, **a real new tourist or driver will never receive the confirmation email** and cannot sign in.
- Whether custom SMTP is configured could not be read from here. Check it in the dashboard (Authentication, SMTP settings) before telling the client the app is ready for the public.
- The existing test accounts are not affected, because they were created directly.

## Before the transfer

1. **Backup.** Run `scripts/backup_supabase.ps1` (needs Docker Desktop running and the Supabase CLI). Latest backup: `backups/tricgabay-schema-20261126-031239.sql` (411,199 bytes) and `backups/tricgabay-data-20261126-031239.sql` (227,851 bytes). `backups/` is gitignored and contains personal data and password hashes: keep it off the repo and off shared drives.
2. **Free plan.** The project is on the Free plan: no automatic backups, and the project is paused after a week of inactivity. Decide with the client who pays, and move it to a paid plan if they want it kept alive and backed up.
3. **Transfer prerequisites (from Supabase's docs):** you are the owner of the source organization, the target person is at least a member of the target organization, there is no GitHub integration connected to the project, and no log drains. Check the project's Integrations page.
4. **Write down the current settings** you cannot export from here: Authentication (Site URL, Redirect URLs, Confirm email, SMTP, email templates), and any custom domain.
5. **Freeze changes.** No migrations or deploys during the transfer.
6. **Record the Edge Function secret values** you will need to re-enter only on route B. Secrets are not readable back from Supabase. They are: `BREVO_API_KEY`, `EMAIL_FROM`, `EMAIL_FROM_NAME`, `FIREBASE_SERVICE_ACCOUNT_JSON`, `HEALTHCHECK_TOKEN`. Keep them in your password manager.
7. **Privacy.** The database holds tourists' and drivers' personal data (phone numbers, driver documents, GCash QR images, trips). Tell the client they become the data controller after the transfer, and check that the in-app privacy notice names the right party.

## The transfer (route A)

Either of these, in the Supabase dashboard:

- **Give the client the organization:** add the client as **Owner** of the `Tric-Gabay` organization, confirm they can see the project, then remove yourself. The project, its URL and keys, and its billing go with the organization. Make sure the organization holds nothing else of yours.
- **Project Transfer:** Project Settings, General, Transfer project, pick the client's organization. Billing for usage up to the transfer stays with you; usage after it goes to the client's organization.

Do not delete or recreate the project. Do not rotate keys during the transfer.

## After the transfer

1. **Same URL, same anon key:** open the installed APK and sign in as a test tourist, driver and admin. If anything fails, the keys changed and you need a rebuild.
2. **Database:** check that the 11 cron jobs are still scheduled and active (`cron.job`), and that `get_operations_health()` shows no new alerts after 10 minutes.
3. **Edge Functions:** confirm `dispatch-communications`, `health-check` and `delete-account` are still listed and their secrets still exist (`supabase secrets list` shows names only).
4. **Storage:** confirm the 6 buckets and a sample of files.
5. **Auth settings:** re-check Confirm email, Redirect URLs and SMTP (these may not carry over exactly).
6. **Push:** a booking that notifies a driver should still send an FCM push.
7. **Remove your access** from the project once the client confirms.
8. **Keep one backup** from before the transfer for a while, then delete it securely.

## What stays on your accounts, and what to tell the client

Stays with you, unless you move it:

- **Source repo and CI** (public GitHub repo). The client gets only the APK, so they cannot change or rebuild the app. Say so plainly.
- **Firebase project** (push notifications). If it stays yours, **their push notifications depend on your Firebase project staying alive**.
- **Mapbox account** (maps, search, directions). **Usage is billed to you** while the compiled-in token is yours.
- **Brevo account** (booking emails), the same dependency.
- **The upload keystore** (once created). Whoever holds it controls future app updates.
- **The `MAPBOX_DOWNLOADS_TOKEN`** on your PC (build only).

What to tell the client:

- They own the database, accounts, storage and bills of the Supabase project. They have no way to change the app itself.
- Maps, push notifications and booking emails run on **your** third-party accounts for now. Say which of those you will keep paying for, for how long, and what happens if you stop (maps and search go dark, pushes stop, booking emails stop; the rest of the app still works).
- The interim APK is **debug-signed** and its password-reset link is a placeholder. Password reset in the app does not work until the "Later" items are done.
- Moving any of those accounts to them later means a rebuilt APK.

## Later

1. **Real SMTP (Brevo).** Verify a sender domain. In Supabase, Authentication, SMTP settings, point Auth at Brevo so confirmation and reset emails reach any address. Use the same domain for the booking-email secrets.
2. **A real auth domain.** Choose it (for example `auth.<their-domain>`). Host `https://<domain>/.well-known/assetlinks.json` for package `com.tricgabay.app` with the **release key's** SHA-256. Serve a page at `https://<domain>/auth/reset-password`. In Supabase, set the Site URL and add that URL to the Redirect URLs.
3. **Turn Confirm email back on and test it.** It reads as on today (see the risk above). Whatever state it is in, after items 1 and 2, do a full sign-up with a real inbox and check that the link works.
4. **Create the real upload keystore** (run it yourself in a terminal; it asks for the keystore password and the key password, and you type them there):
   `keytool -genkeypair -v -keystore C:\Users\Prince\keys\tricgabay-upload.jks -alias tricgabay -keyalg RSA -keysize 2048 -validity 10000`
   Then put the same two passwords in `android\key.properties` (gitignored). Back up the `.jks` file and both passwords outside the repo. Losing them means no more updates under that key.
5. **Rebuild with `--flavor production`:** put the real `AUTH_APP_LINK_HOST` in `config/production.json`, rename `android\key.properties.unused` back to `key.properties` with the real passwords, then:
   `flutter build apk --release --flavor production --dart-define-from-file=config/production.json`
6. **Tidy-ups:** delete the three PayMongo secrets and the two inactive PayMongo cron jobs; enable leaked-password protection (Supabase Auth setting, currently off).

## Appendix: what in Supabase depends on the owner or the project

If you move the same project (route A) these all stay as they are. On route B each must be recreated.

- **Edge Function secrets** (names): `APP_PAYMENT_RETURN_URL`, `BREVO_API_KEY`, `EMAIL_FROM`, `EMAIL_FROM_NAME`, `FIREBASE_SERVICE_ACCOUNT_JSON`, `HEALTHCHECK_TOKEN`, `PAYMONGO_TEST_SECRET_KEY`, `PAYMONGO_TEST_WEBHOOK_SECRET`, plus the built-in `SUPABASE_*` ones. Values are not readable back.
- **Edge Functions:** `dispatch-communications` (JWT required), `health-check` and `delete-account` (JWT not required). Redeploy from `supabase/functions`.
- **Vault secrets** (names): `tric_gabay_anon_key`, `tric_gabay_communications_url`, `tric_gabay_checkout_expiry_url`. They hold the project's own URL and anon key, so on route B they must be re-created with the new project's values. Two rows in `internal_scheduler_tokens` must be re-provisioned too.
- **Cron jobs** (11 in `cron.job`): active ones are `collect-operations-health`, `expire-stale-online-drivers`, `expire-unpaid-bookings`, `tric-gabay-communications`, `tric-gabay-expire-stale-pending-bookings` (every 5 min), `tric-gabay-gcash-escalation`, `tric-gabay-operational-health`, `tric-gabay-retention`, `tric-gabay-retry-waiting-dispatch`, `tric-gabay-scheduled-bookings`. Inactive: `expire-paymongo-provider-checkouts`, `monitor-checkout-expiries`. They are created by the migrations.
- **Hardcoded project URL** in `supabase/functions/dispatch-communications/index.ts` (the default logo URL, used only when `APP_LOGO_URL` is not set) and in the older migration `202610230005`. Both would need editing on route B.
- **Storage buckets:** `app-assets` (public), `tourist-spots` (public), `driver-documents`, `driver-gcash-qr`, `gcash-receipts`, `profile-images` (all private). Files are not in the SQL backup: route B needs a separate storage copy.
- **Auth:** users and password hashes are in the data backup. Auth settings (Site URL, Redirect URLs, Confirm email, SMTP, email templates) are not, and must be set by hand.
- **Extensions used:** `pg_cron`, `pg_net`, `supabase_vault`, `pgcrypto`, `postgis`, `pg_stat_statements`.
- **Open advisor findings:** leaked-password protection is disabled; the rest are the known `SECURITY DEFINER` function notices, which are covered by the access catalog.

## Privacy note about this file

The repo is public, so this file is public too. It names the project ref (already in older docs) but holds no secrets, passwords, keys or account emails.

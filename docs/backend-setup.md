# Tric-Gabay backend setup (test environment)

## Supabase

Create a Supabase project, link the Supabase CLI, and apply every file in
`supabase/migrations` in filename order. The migrations create the schema,
row-level security, storage policies, trip functions, live-location tables,
audit events, and the Bustos catalog/package seed.

Create the first user through normal sign-up, then promote that known account in
the SQL editor:

```sql
update public.profiles
set role = 'admin', status = 'active'
where id = '<verified-auth-user-uuid>';
```

For closed test builds, disable mandatory email confirmation or add a
complete confirmed-email onboarding flow before testing driver document upload.

## Payments

Payments are cash or GCash sent straight to the driver; the app takes no
online payment, so no payment provider secrets are needed. The PayMongo
checkout used in early testing was retired on 2026-11-20 (its database
functions remain but are closed to the app).

## Branded service email

The `dispatch-communications` function sends lifecycle email through Brevo's
free transactional-email API. The Tric-Gabay test environment uses the verified
sender `tricgabay.bustos@gmail.com`; its API key and sender identity were
installed as encrypted Supabase Edge Function secrets on 23 October 2026.
For a new environment, set the same server-side secret names:

```text
BREVO_API_KEY=xkeysib-...
EMAIL_FROM=your-verified-sender@example.com
EMAIL_FROM_NAME=Tric-Gabay
```

The function displays `tric_gabay_logo.png` from the public, read-only
`app-assets` bucket. Email jobs remain queued when the provider is not configured,
and booking actions do not fail merely because email delivery is unavailable.
Never copy the Brevo API key into Flutter, documentation, screenshots, or source
control.

## Flutter configuration

The checked-in defaults point to the Tric-Gabay Supabase and Firebase Android
clients using public client identifiers, so normal `flutter run` and
`flutter build` commands work without secret configuration. They can still be
overridden per build:

```text
flutter run --dart-define=SUPABASE_URL=https://<project>.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-or-anon-key>
```

Never put the Supabase service-role key or PayMongo secret in Dart, the APK,
source control, or screenshots.

## Firebase push delivery

Supabase remains the only application database. The app initializes Firebase,
requests permission, registers refreshed FCM tokens, revokes the current token
at sign-out, shows foreground notifications, and opens the protected in-app
route when a notification is tapped. The Tric-Gabay Android public values are
checked in. Override them only when building for another Firebase project:

```text
--dart-define=FIREBASE_API_KEY=...
--dart-define=FIREBASE_APP_ID=...
--dart-define=FIREBASE_MESSAGING_SENDER_ID=...
--dart-define=FIREBASE_PROJECT_ID=...
```

`FIREBASE_SERVICE_ACCOUNT_JSON` is installed as a Supabase Edge Function secret
for the HTTP v1 sender. Never place that service-account JSON in the APK or
repository. Notifications remain available through Supabase Realtime if FCM is
temporarily unreachable, and delivery jobs remain queued rather than being
reported as sent.

## Driver compliance and matching

An administrator must review the driver's licence, franchise/permit, vehicle
inspection, capacity, accessibility support, and service area before approving
the driver. Expired or missing documents, an administrative block, stale
location, an incompatible passenger request, an active trip, or a pickup outside
the approved service area prevents dispatch and acceptance on the server. The
app also maintains completed/cancelled/no-show counts and a reliability score;
the score improves ranking but never bypasses mandatory compliance checks.

## Acceptance checks

Use separate tourist and driver phones plus an admin session. Verify competing
acceptance, wrong pickup codes, every stop confirmation, early cancellation,
cash dual confirmation, PayMongo checkout/webhook, refund audit, stale GPS,
revoked location permission, offline/resume, and account suspension.

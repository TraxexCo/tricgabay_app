# Environment and release configuration

No deployment, commit or push occurred in Batch 4. These are operator instructions for a later approved release.

## Android flavors

| Flavor | Application ID | Configuration |
|---|---|---|
| dev | com.tricgabay.app.dev | config/dev.json |
| staging | com.tricgabay.app.staging | config/staging.json |
| production | com.tricgabay.app | config/production.json |

Copy the matching `.example.json`, fill it outside version control, then build:

```powershell
flutter build apk --debug --flavor dev --dart-define-from-file=config/dev.json
flutter build apk --debug --flavor staging --dart-define-from-file=config/staging.json
flutter build appbundle --release --flavor production --dart-define-from-file=config/production.json
```

Every configuration supplies APP_ENV, SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, MAPBOX_PUBLIC_TOKEN, FIREBASE_API_KEY, FIREBASE_APP_ID, FIREBASE_MESSAGING_SENDER_ID, and FIREBASE_PROJECT_ID. Release builds reject missing values, mismatched environment, non-HTTPS Supabase, a non-public Mapbox token and absent release signing. Flutter also validates required runtime configuration. Aggregate multi-flavor builds are rejected; each environment requires its own invocation. Debug defaults to dev only when APP_ENV is omitted. Local cleartext HTTP is limited to dev emulator/loopback hosts.

Use separate Supabase projects, separate Firebase projects/Android app registrations and restricted Mapbox public tokens for each environment. Register each exact package ID and signing fingerprint with its Firebase app. Provide corresponding Firebase values through that flavor's JSON; this app initializes Firebase with explicit options. An APP_ENV label alone does not prevent pointing staging at production: the owner must provision and review the actual project IDs/domains. No service-role, payment secret, webhook secret or service-account JSON may be embedded in an APK.

Sign-up confirmation and password reset use a 6-digit emailed code, so no authentication domain or App Links file is needed (see docs/EMAIL_OTP_SETUP.md). Do not distribute a build containing synthetic values. The Android owner must configure the upload keystore in ignored `android/key.properties` and secure storage. `ALLOW_DEBUG_RELEASE_SIGNING` exists for local diagnostic validation only; never set it for a store build. Build number is 3; increment it for each store upload.

## Database and server

For Edge deployments, supply the repository import map explicitly:

```powershell
npx --yes supabase@2.121.0 functions deploy --project-ref YOUR_PROJECT_REF --use-api --import-map supabase/functions/deno.json
```

Without that map, the remote bundler cannot resolve the shared bare
`@supabase/supabase-js` import.

Review and apply all migrations in order to the intended environment. Migration `202611080001_postgis_api_isolation.sql` rebuilds PostGIS at its existing version in the non-exposed `extensions` schema, preserving spatial references and the two expression indexes. It refuses spatial table columns and unexpected dependencies. Back up schema/data/roles before applying it. Never expose `extensions` in the Data API. Reconnect database clients/restart the project after this relocation to clear cached PostGIS schema lookups, then verify matching and pickup geofences. The isolated runner additionally uses `supabase/bootstrap/managed_extensions.sql` as the extension owner; hosted `postgres` cannot revoke platform-owner grants. See [Supabase's supported procedure](https://supabase.com/kb/troubleshooting/security-advisor-flags-spatial_ref_sys-and-other-postgis-objects-in-the-public-schema-f9d408).

Bucket limits/private settings are recorded in `supabase/config.toml` and migration 013. Enable the Realtime service and the publications configured by the migrations. Review project connection/message quotas separately; the local tenant has 200 concurrent users and 100 events/second. Preserve financial backup/restore procedures before applying schema changes.

Server-only environment variables are listed in `config/server.env.example`. Supabase supplies its server credentials. Provision PayMongo test credentials and test webhook secret only for initial provider testing. Configure APP_PAYMENT_RETURN_URL to the approved return route/domain, health token, communications credentials and sender identity independently per environment. Leave live credentials empty and `live_payments_enabled=false`.

Scheduler dispatcher URLs and credentials belong in the Vault/internal scheduler configuration named by the migrations. Older communications migration 007 now also reads Vault and returns without dispatching if configuration is absent; it no longer embeds a hosted endpoint/key. This source edit does not rewrite applied migration history. Operators upgrading an already migrated environment rely on the later environment-scoped dispatcher migration and must verify the current definition.

The checkout expiry worker authenticates `x-tricgabay-scheduler` against `internal_scheduler_tokens` entry `checkout_expiry`; communications uses its own scheduler entry. Health checks authenticate `x-tricgabay-monitor` against server HEALTHCHECK_TOKEN (at least 32 characters). Do not substitute an anonymous client key for worker authentication. Test authenticated scheduler requests and retry/alert behavior before opening payments.

## CI drafts

`.github/workflows/quality.yml` and `release.yml` use manual `workflow_dispatch` only. They were syntax-checked locally, never pushed or enabled remotely. Quality runs localization drift checks, analysis, Flutter tests/debug build, SQL parser/full local chain/pgTAP/concurrency, authorization/snapshot and negative tests, Edge checks/Deno tests, real local services and OSV/Gitleaks. The historical Firebase key finding intentionally leaves the history secret gate unresolved until owner review.

The release draft expects protected production signing secrets and PRODUCTION_DART_DEFINES_JSON, builds the production bundle and uploads only bundle/symbol artifacts. It does not publish to a store. No signed final bundle, store upload or hosted workflow execution is verified by Batch 4.

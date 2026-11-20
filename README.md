# Tric-Gabay

Tric-Gabay is a Flutter capstone application for discovering Bustos attractions,
booking fixed-price tricycle tours, assigning approved drivers, following live
trip location, confirming tour stops, and resolving payments, cancellations,
disputes, and refunds.

The application uses Supabase as its authoritative backend. Fares are paid in
cash or by direct GCash transfer to the driver (QR or Open GCash, then the driver
slides to confirm); the app records payments but never holds money, so no
payment gateway or business registration is needed. Disputed GCash fares can be
settled by the two parties or ruled on by an admin; see
`docs/gcash-direct-payment.md`. Firebase supports push delivery and optional
diagnostics. See `docs/backend-setup.md` for configuration and
`docs/booking-scenario-review.md` for the implemented rules and scenarios.

Demo data for presentations: `supabase/seed/demo_seed.sql` (idempotent; demo
accounts cannot sign in). Older batch and audit reports live in `docs/archive/`.

## Mobile dependency pins

- `share_plus: 13.1.0` retains the current SharePlus API while avoiding the
  Gradle/Kotlin regression observed with 13.2+ under this app's AGP 9 toolchain.
- `mapbox_maps_flutter: 2.30.1` keeps the tested native mobile SDK reproducible;
  moving to v3 (including web support) requires a separate migration.

When changing either pin, run analysis, Flutter tests, and an Android build,
then exercise sharing and maps on a device.

## Architecture and release preparation

The current architecture, security contract, local test commands and environment
requirements are documented in [ARCHITECTURE.md](ARCHITECTURE.md),
[SECURITY.md](SECURITY.md), [TESTING.md](TESTING.md),
[DEPLOYMENT.md](DEPLOYMENT.md) and [OPERATIONS.md](OPERATIONS.md).
Review [KNOWN_ISSUES.md](KNOWN_ISSUES.md) and
[RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) before device/provider testing.
These documents supersede earlier audit notes where the implementation changed.

Android builds now require an explicit dev/staging/production flavor. Production
releases require reviewed configuration and signing; there are no hardcoded
Supabase, Mapbox or Firebase development fallbacks. Live payments remain disabled.
GitHub workflow drafts are manual only and have not been pushed or run remotely.

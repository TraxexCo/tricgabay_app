# Handoff: Tric-Gabay, 2026-11-21

Branch `feature/gcash-payment-and-cleanup` (local only: no git remote yet; base branch is `master`). Working tree clean. Last commit `f4d25cc`.

## What was done (oldest first)

| Commit | What |
|---|---|
| e889efd, c98db9b | Checkpoint; GCash redesign spec/plan (`docs/superpowers/specs`, `docs/superpowers/plans`) |
| 0142b58 | DB: GCash proof, 24h dispute escalation, admin rulings, outstanding-fare booking block |
| df2ff21 | App: GCash QR, dispute proof, admin rulings; PayMongo removed |
| 4a18bd2 | Docs: old reports moved to `docs/archive/`; GCash-only payments documented |
| 87841d4, de75dda, c7343bc | Fares stored as centavos; `PrototypeSession` renamed `AppSession`; local migration files mirror hosted history |
| c1ca4ab, a7f16d1 | Screen splits; offline booking simulation removed |
| c4d3a3c | Phone Back went to the app's exit; fixed (`lib/core/navigation/back_handling.dart`) |
| 9cf0549, b510878 | UI polish and motion system (`lib/core/motion/`), native splash and logo launch animation |
| 0ab096f | Real-phone fixes: field labels inside boxes (`lib/core/theme/filled_field_border.dart`), cramped buttons, notification prompt moved to after sign-in, status-bar colours, admin tourist trip counts |
| 1856256 | `docs/real-world-scenarios.md`: 12 Bustos use scenarios, pre-launch gaps, two-phone test script |
| f4d25cc | Full three-role phone walkthrough fixes (below) |

### f4d25cc in detail

- **Tourist map:** buttons and legend follow the Explore sheet, so SOS is no longer hidden. The sheet stops above the menu bar. Spot names show only when zoomed in. Files: `tourist_home_screen.dart`, `tourist_home_sections.dart`.
- **Package page:** visible back button; price on its own line (`tour_package_detail_screen.dart`).
- **Booking review:** shows a hint when Book is disabled; the button is full width again (`fare_summary_screen.dart`).
- **Startup:** sign-in restore retries on a weak connection (`splash_screen.dart`).
- **Driver:**
  - New ride offers send a push in about 2 seconds. Migrations: `supabase/migrations/20261121040846_notify_driver_of_ride_offer.sql` and `20261121041257_send_ride_offer_push_immediately.sql`, both applied on the hosted project.
  - Accept now opens the trip (`incoming_booking_screen.dart`).
  - The request card shows the real payment method; its map fills the screen.
  - Going online shows a GPS-wait state and explains failures (`driver_home_screen.dart`, `driver_availability_controller.dart`).
  - Clear errors for an arrival that is too far away or on weak GPS (`error_messages.dart`).
- **Shared:**
  - Package names show instead of "Custom tour" (`backend_repository.dart` joins `tour_packages`; `AppSession.packageNameFor`).
  - Short `#ABCD1234` booking references and an aligned detail table (`booking_detail_screen.dart`).
  - The admin dashboard shows the tour and tourist name (`admin_dashboard_screen.dart`).
  - More space under the GCash slider (`gcash_trip_payment.dart`).
- **New strings** in `lib/l10n/app_en.arb` and `app_fil.arb`: `tickTheAgreementToBook`, `driverDocumentsBlockOnline`, `moveWithin150mOfPickup`, `gpsAccuracyTooLow`. `retryStorage` was reworded to "Try again". Regenerate with `flutter gen-l10n`, `dart run tool/generate_message_codes.dart` and `dart run tool/export_localization.dart`.

## Current state

- `flutter analyze` is clean. `flutter test`: 2,563 pass (63 snapshot tests skipped unless `--dart-define=SNAPSHOTS=true`).
- The phone (Android 17, `AE6RUT4B19001663`) has the latest debug build and is signed in as the admin.
- Build and install, keeping the sign-in (never run `pm clear`):

  ```bash
  flutter build apk --debug --flavor production --dart-define-from-file=config/phone-test.json --no-pub
  ```

  ```bash
  adb install -r build/app/outputs/flutter-apk/app-production-debug.apk
  ```

  adb is at `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`.
- Test accounts are `t1`, `d1` and `a1@tric.test`. The owner holds the passwords; don't store them in the repo.
  - d1 has demo documents attached and is approved.
  - Each account has accepted the privacy notice.
- Hosted Supabase project: `xcsrjuqzwequmeqzedzd`.
- Walkthrough results: the full tour lifecycle passed on the phone (book, push, accept, pickup code, 5 stops, complete, GCash slide-to-confirm, earnings, admin dashboard and disputes). Test bookings were cancelled except one completed ₱700 GCash tour.

## Left to do

1. **Recheck on the phone:** the newest labels, and a booking made through the tourist app's own Book button with GPS on.
2. **Driver "Active" card:** the status word is still lowercase ("accepted"), and the request card still says "N stop custom tour" for packages when names aren't loaded.
3. **Before real riders** (see `docs/real-world-scenarios.md`):
   - The owner enters verified Bustos emergency numbers (only 911 is real today).
   - The custom-tour fare is ₱70, versus ₱700–₱1,000 for packages; fix it in Admin → Fixed fares.
   - Decide how groups over 3 passengers should book.
   - Warn the tourist when no drivers are online.
   - Explain why location is needed before the tourist map asks for it.
4. **Privacy notice text:** still mentions PayMongo; update the notice content and version.
5. **Two-phone test** with real people standing together. Arrival requires being within 150 m of the pickup.
6. **Push the branch** to a private GitHub repo, then merge into `master`.

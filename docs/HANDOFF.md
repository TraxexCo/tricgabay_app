# Handoff: Tric-Gabay, updated 2026-11-22

Branch `feature/gcash-payment-and-cleanup`, last commit `55f6b37` (local only, no remote).
Start with "Session 2026-11-22" and "Left to do" below; the 2026-11-21 sections are history.

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

## Session 2026-11-22: UI fixes and pre-launch code items

- **Tourist home:**
  - The Explore sheet runs behind the menu bar again, and its list is padded so the last section clears the bar.
  - Its resting height shows one full row of spot cards. Fully open, it stops under the greeting.
  - Spot cards are compact: the category is a pill on the photo, plus "0.2 km from town".
  - The "Plan your trip" shortcuts are three even tiles, or stacked rows with large text.
  - The duplicate "List view" pill is gone; the search bar opens the same list.
  - On short screens, the map buttons switch to a row.
- **Location explainer:** before Android's location prompt, a sheet says why the map wants location. "Not now" is remembered; the my-location button can still ask.
- **Driver home:**
  - Online with a GPS fix, the map is 200 to 300 px tall.
  - The label is worked out from GPS: "In the Bustos service area" or "N km from Bustos". The old label always said "Bustos town centre".
  - The activity cards are equal height, and "View booking requests" is full width.
- **Booking titles:** `AppSession.bookingTitle` shows the package name, then "Tour package" while the name loads, then "N stop custom tour". It is used by the driver bookings list, the incoming request card, booking detail and the admin dashboard.
- **Wording:**
  - Status words are capitalised (Accepted, Ongoing and the rest).
  - All-caps labels are now sentence case (Accept, Decline, Sharing location and others).
  - Filipino uses the glossary terms (drayber, traysikel, sunduan, magpareserba).
- **No drivers online:** new RPC `count_online_drivers()` (migration `20261122040000`). It returns a count only and is open to signed-in users. The booking review shows a warning with "Schedule for later" when the count is 0 for a book-now trip. If the RPC fails, nothing is shown.
- **Groups of 4 or more (decided: simplest option):** the booking review explains that a tricycle seats 3, and that someone else in the group books a second tricycle from their own phone. One account can hold only one active booking, so the same person can't book two.
- **Privacy notice:**
  - Migration `20261122040100` replaces only the PayMongo clause, in English and Filipino, with GCash direct payment wording.
  - It moves the version to `2026-11-22`, so each user accepts the notice again once.
  - The test fixture is updated to match.
- **Other polish:**
  - Booking review leads with a fare card.
  - Spot page: the fake "4.8 (128 reviews)" rating is removed. The bottom bar now has map and directions icons and an "Add to trip" / "In your trip" button.
  - Outline buttons are white-filled, so they stay readable on dark backgrounds.
  - The booking confirmation uses a short `#ABCD1234` reference and larger text.
  - The admin spot list's category is no longer yellow on white.
- **Not applied yet:** the two new migrations must be pushed to the hosted project (`supabase db push`).
- **Tests:** `flutter analyze` is clean. In the cloud workspace, 2,561 tests pass. Two fail there: DriverHome and DriverShell accessibility at text 1.0. They also failed on the untouched code there, so they are environment-specific, but rerun `flutter test` locally.

### Follow-up: every-screen review

All 63 screen renders, plus full-height renders of the long screens, were checked by eye. Fixed:

- **Wording:** about 25 English headings and buttons were in Title Case; they are now sentence case. Pipe separators ("Cancel booking | no charge") are now brackets or middle dots.
- **Tourist My bookings:** cards showed the raw database id; they now show the tour name.
- **Booking detail:**
  - The pickup code is a highlighted card at the top.
  - "Price version" shows to admins only.
  - The driver row no longer ends with a stray "·".
- **Saved places:** "Add to trip" silently removed a spot that was already in the trip but still said "Added". It now shows "In your trip" and says when the spot is removed.
- **Booking review:** the payment selector used the platform font instead of Poppins, and the passenger helper text no longer gets cut off.
- **Active trip:** no longer repeats "Bustos, Bulacan" under pickup addresses.
- **Tracking screen:** the status text is larger.
- **Admin screens:**
  - The GCash dispute buttons read "Decide: tourist paid / didn't pay" and "Open booking details".
  - The spot list shows "Category · Visible/Hidden" next to each switch.
  - Emergency contacts are cards, with a warning icon on placeholders.
  - The announcement form has a gap between the audience and title fields.
  - The reports driver card is full width.

### Admin sign-in merged into the main sign-in screen

- The "Manage Tric Gabay? Open the admin portal" link and the separate admin sign-in screen are gone.
- Admins sign in on the normal sign-in screen; either workspace tab works. Their account's role sends them to the admin dashboard.
- `evaluateAuthAccess` lets an active admin through whichever tab is selected. Tourists and drivers still can't enter each other's portal. A new test covers both rules.
- `/admin/login` now redirects to `/login` for old links. Signed-out visits to admin pages also go to `/login`.
- Nothing changed on the server: signing up still can't create an admin account, and every admin action is still checked there.

### Startup freeze and launch animation (`34e3da9`)

- **Freeze:** the app stopped on the logo at every launch. `pubspec.lock` had uncommitted upgrades; `shared_preferences_android` 2.5.5 (with `jni` 1.2.1) threw `channel-error ... SharedPreferencesApi.getAll` on this phone, and that error was fatal in `main()`.
  - Lock file restored to the committed versions. Don't run `flutter pub upgrade` without testing a cold start on the phone.
  - `main.dart` now starts each service through `_startService`, so one failure can't block the first frame. `TelemetryService` reads settings inside its `try`.
- **Launch animation:** the version and privacy checks showed a white spinner (`LaunchBarrier` in `brand_logo_hero.dart` now matches the launch screen). The Android 12+ splash logo was resized to match the app's 128dp logo. The logo is decoded before the first frame (`AppLogo.warmUp`). The window background is brand blue, and `MainActivity.kt` removes the system splash without its fade.
- Verified on the phone with a release-speed (profile) build: the logo holds still, then flies into the sign-in header at about 3 s, with no blink.

### Phone tooling (`34e3da9`, `55f6b37`)

- **Launch recording:** `scripts/phone_check.cmd` (debug), `phone_check_profile.cmd` (release speed), `phone_clean_check.cmd` and `phone_record_launch.cmd`. Each builds, installs (keeping the sign-in), records a cold start and saves logcat to `build/phone_check/`.
- **Screen renders:** `scripts/phone_screens.cmd` runs `integration_test/screens_on_device_test.dart`, which renders all 62 screens on the phone with sample data into `build/phone_screens/`, then reinstalls the normal app. It adds `integration_test` and `flutter_driver` as dev dependencies.
- All 62 phone renders were reviewed. Fixed: the dollar icon on Reports, and a raw `GoException` page (now a friendly `errorBuilder`). The search screen's blank area in the render is the keyboard, not a bug.
- **Tests:** in the cloud workspace, 2,561 pass. The only failures are DriverHome and DriverShell accessibility at text 1.0, which fail on untouched code there too. Not yet run on the PC.

### Packages only, and admin package editor (professor feedback)

- **Build your day is gone.** Tourists can only book the fixed tour packages. The itinerary builder screen was deleted; the old route redirects to the packages list. The home screen shows a "Tour packages" row instead of the builder card, and a spot's sheet and info page show "See tours" plus an "Included in these tours" list. The fare summary shows "Choose a tour package" if no package is selected.
- **Only the 11 places on the three package routes remain** (TRIC LAKBAY ₱700, TRIC SAYA ₱850, TRIC TUKLAS ₱1,000), in the app catalogue and in migration `20261122050000_package_only_catalog.sql`. The migration nulls `booking_stops.spot_id` for removed places (the name and coordinate snapshots stay, so old bookings still read correctly), removes their package stops, deletes them, and renames two places to the professor's spelling ("Nuestra Senora Del Perpetuo", "Zenny's Minasa Pasalubong").
- **Admin package editor:** Admin → Tour packages (also from Manage spots). Admins with the content permission can create, edit (name, price, description, ordered stops, drag to reorder) and delete packages. New RPCs `admin_save_tour_package` and `admin_delete_tour_package` (security definer, content capability). A price change publishes a new fare revision, so existing bookings keep their price. Delete is a soft delete (`is_active = false`). Validation: name 3–60 characters and unique among active packages, price ₱1–₱100,000, 2–12 different active spots.
- The custom-tour fare field was removed from Fixed fares; the stored value is kept unchanged.
- The migration and both RPCs were run against a local Postgres 16 with a small stand-in schema, including permission refusal, every validation, create, edit, reorder, price revision and delete. They were not run against the real schema or the SQL test suite.
- **Not done on purpose:** the server still accepts custom (no-package) bookings, because the SQL tests in `supabase/tests` create them. Blocking them server-side means updating those tests first.

## Left to do

These need the PC, the hosted project or a person, so they were left for Claude Code on the PC:

1. **Run `flutter analyze` and `flutter test` on the PC.** Confirm whether the two DriverHome and DriverShell accessibility failures happen there. If they do, fix the contrast.
2. **Push the three new migrations** with `supabase db push` (project `xcsrjuqzwequmeqzedzd`). Run `supabase db reset` and the SQL tests locally first if Docker is available:
   - `20261122040000_count_online_drivers.sql`, needed for the "no drivers online" warning.
   - `20261122040100_privacy_notice_gcash.sql`, which replaces the PayMongo text in the privacy notice and sets version 2026-11-22.
   - `20261122050000_package_only_catalog.sql`, which deletes every tourist spot not on a package route and adds the package editor RPCs. The app's package editor fails until this is pushed. The two RPCs were added to `scripts/security/access_rules.ts`, but `supabase/security/authorization_catalog.json` was not regenerated: run `scripts/test_catalog_access.ts` (see TESTING.md, needs Docker), review the drift and update the snapshot, or CI's catalog check will refuse the new functions.
   - Optional: block custom bookings in `create_booking` and update the SQL tests that create them.
3. **Walk through the app on the phone over adb:**
   - Sign in on the shared sign-in screen as `t1`, `d1` and `a1@tric.test`. Admins now use the normal screen; there is no separate admin portal any more.
   - Check the tourist home sheet, the location explainer, the driver map label ("In the Bustos service area" or "N km from Bustos"), the no-drivers warning, the group note, the pickup-code card, and booking through the Book button with GPS on.
4. **Owner tasks (only the owner can do these):**
   - Enter verified Bustos emergency numbers in Admin → Emergency contacts.
   - Check the package prices and routes in Admin → Tour packages.
5. **Two-phone test** with real people standing together. Arrival requires being within 150 m of the pickup. Script: `docs/real-world-scenarios.md`.
6. **Smaller items:**
   - "+2 more" and "remaining" are English-only in Filipino mode.
   - The admin spot cards leave empty space under the photo on wide phones.
   - Plugins warn about the Kotlin Gradle plugin; plan the upgrade before Flutter enforces it.
7. **Line endings:** git on Linux shows about 100 files as modified because only CRLF/LF differs. Don't commit those. Consider adding a `.gitattributes` with `* text=auto`.
8. **Push the branch** to a private GitHub repo, then merge into `master`. Both need the owner's OK.

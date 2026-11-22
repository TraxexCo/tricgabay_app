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

## Left to do

1. **Apply the two new migrations** on the hosted project, then rebuild and install on the phone. Check the tourist home sheet, the location explainer (fresh install, or clear the app's storage), the driver map label, and the no-drivers warning.
2. **Before real riders:** owner enters verified Bustos emergency numbers; fix the ₱70 custom-tour fare in Admin → Fixed fares.
3. **Two-phone test** with real people standing together. Arrival requires being within 150 m of the pickup.
4. **Push the branch** to a private GitHub repo, then merge into `master`.
5. **Line endings:** this VM's git shows many files as modified when only CRLF/LF differs. Those aren't real changes, so don't commit them. Consider a `.gitattributes` with `* text=auto`.

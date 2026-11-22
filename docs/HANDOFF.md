# Handoff: Tric-Gabay, updated 2026-11-22

Branch `feature/gcash-payment-and-cleanup` (local only, no remote; base branch `master`).
**Start with "Left to do" at the end.** Then read "Current state (end of 2026-11-22)". Everything above that is history, oldest first.

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

### Packages only, and admin package editor (professor feedback, `79a3be6`)

- **Build your day is gone.** Tourists can only book the fixed tour packages. The itinerary builder screen was deleted; the old route redirects to the packages list. The home screen shows a "Tour packages" row instead of the builder card. A spot's sheet and info page show "See tours" plus an "Included in these tours" list. The booking review shows "Choose a tour package" if none is selected.
- **Only the 11 places on the three package routes remain:** TRIC LAKBAY ₱700, TRIC SAYA ₱850, TRIC TUKLAS ₱1,000.
  - Done in the app catalogue and in migration `20261122050000_package_only_catalog.sql`.
  - The migration nulls `booking_stops.spot_id` for removed places; the name and coordinate snapshots stay, so old bookings still read correctly. It then removes their package stops and deletes them.
  - It renames two places to the professor's spelling: "Nuestra Senora Del Perpetuo" and "Zenny's Minasa Pasalubong".
  - Until the migration is pushed, the app hides non-package places from tourists anyway (`AppSession._applyCatalog`). Admins still see every place.
- **Admin package editor:** Admin → Tour packages (also reachable from Manage spots).
  - Admins with the content permission can create, edit and delete packages: name, price, description, and ordered stops with drag to reorder.
  - New RPCs `admin_save_tour_package` and `admin_delete_tour_package` (security definer, content capability).
  - A price change publishes a new fare revision, so existing bookings keep their price. Delete is a soft delete (`is_active = false`).
  - Validation: name 3–60 characters and unique among active packages, price ₱1–₱100,000, 2–12 different active spots.
- The custom-tour fare field was removed from Fixed fares; the stored value is kept unchanged.
- The migration and both RPCs were run against a local Postgres 16 with a small stand-in schema. That covered permission refusal, every validation, create, edit, reorder, price revision and delete. They were **not** run against the real schema or the SQL test suite.

### Driver screens (`73942b2`)

- **Driver home map:**
  - Shows the driver's real town from Mapbox reverse geocoding (`lib/core/services/place_name_service.dart`) plus the distance to Bustos, e.g. "Baliuag · 6 km from Bustos". It adds "Outside the pickup area" past the service radius and says "Near Bustos town centre" within 1 km.
  - The pickup area is a 15 km circle around Bustos (server default `service_area_radius_km`), which is why Baliwag counts as inside it.
  - The map gets its own drags (`EagerGestureRecognizer`), so the page no longer scrolls while you pan. It stops snapping back to the driver on every GPS update, and a recenter button appears after panning.
- **Bookings and earnings:** a shared, roomier `DriverTripCard` (`lib/features/driver/widgets/driver_trip_card.dart`). Earnings has a gradient summary card for the chosen period, three stat tiles and a "Trips in this period" list.
- **Trip history from Account** opens `/driver/trip-history` above the tabs, so it has a Back button. It starts on the History tab. The Jobs tab itself still has no Back button, on purpose.
- **Help & support** (shared `FeedbackScreen`) was redesigned. Topic tiles show a white check on a solid blue dot (the old blue-on-blue check was invisible). It has an emergency shortcut and a "Send message" button.

### Loading, refreshing and the blue logo (`9dbe657`, `ed28ce4`, `31cc2ce`)

- **"Try again" emptied the app:** it re-ran `AppSession.initialize()`, which cleared places, packages and bookings and never reloaded them. It now only re-downloads (`_RefreshNotice` in `main.dart`). The notice is a slim, closable strip.
- **Slow first load (5–15 s of empty screens):**
  - The app starts from the built-in places and packages, then the saved trips (`_showSavedState`), while the server copy downloads.
  - Places, packages and bookings are applied as soon as each arrives instead of waiting for every request (`_syncRemoteStateOnce`).
  - The second account check right after splash/login is skipped (`_accessVerifiedAt`, 60 s).
  - Each section retries once quietly (600 ms). Notifications got a read timeout.
  - The offline snapshot save, offline replay and pickup-code purge can no longer fail the whole refresh.
- **Blue logo on every return to the app** (even after pulling down the notification shade):
  - `MinimumVersionGate` and `PrivacyConsentGate` re-ran their network checks on every resume and covered the app with `LaunchBarrier` meanwhile. They now re-check quietly, at most every 10 minutes, and never cover the app once loaded. The privacy gate still blocks on an account change.
  - The full data refresh on resume runs only after 30 s or more away (`_leftAt` in `main.dart`).
  - Verified on the phone with `scripts/phone_resume_check.cmd` (shade down/up, Home and back): the app stayed on the same screen.
- **Writes never wait on, or fail because of, the follow-up refresh:** `AppSession._refreshAfterWrite()` waits at most 4 s and swallows refresh errors. This is used by every mutation (cancel, rate, accept, admin actions...).
  - `createBooking` shows the new booking at once and refreshes in the background.
  - It also no longer calls `loadPickupServiceArea` (the meeting point is fixed).
  - "Saving booking" used to take about 10 s.
- **Error details for testing:** builds made with `SHOW_ERROR_DETAILS=true` (set in the git-ignored `config/phone-test.json`) end error messages with "Details: <code message>". Release and test builds keep plain messages; `test/batch2_behaviors_test.dart` guards that.
- **Still unknown:** an intermittent server read failure behind the old "Some information could not refresh" notice. The Honor phone blocks app logs from adb. With details on, the notice now names the failing section and error, so the next screenshot should show the cause.

### Tourist side (`b124b8c`, `dd54df7`, `31cc2ce`, `2a83a02`)

- **Meeting point:** every tour starts and ends at the Bustos Municipal Arts, Culture and Tourism Office.
  - The office is at the Municipal Compound, Poblacion, Bustos, Bulacan 3007 (OSM way 316341741: 14.95369, 120.91894).
  - There is no pickup choice any more. `createBooking` always sends these coordinates. The old location picker route is unused.
  - The booking review shows the office card with a "loop" explainer and Call (+63 917 918 9665), Email (bustostourismofficial@gmail.com) and Get directions (Google Maps) buttons. The phone number came from the owner, not the website.
- **Tour day and time** (`lib/core/config/tour_schedule.dart`, tests in `test/tour_schedule_test.dart`):
  - Office hours: Monday to Friday, 8:00 AM to 5:00 PM (Municipal Hall hours). Closed on weekends and on 2026 and 2027 national holidays (Proclamations 1006 and 1427, listed in `closedDates`).
  - Starts allowed from 8:00 AM to 1:00 PM (a tour takes about 4 h), and at least 1 h ahead. Today drops out once its last start is less than 1 h away.
  - UI: a Calendar button (`showDatePicker` with `selectableDayPredicate`, open days only, up to a year ahead), quick day buttons, hourly start chips, and "Other time" (`showTimePicker`, validated by `isValidStart`).
  - The year-long window needs migration `20261122060000_tour_booking_window.sql`. Until it is pushed, the server refuses bookings more than 30 days ahead.
- **Rating:** the saved rating shows at once (no "failed" after a slow refresh, then "already rated" on the second tap). The tags are sent with the comment. New messages cover "already rated" and "not completed".
- **Redesigns:**
  - Trip & payment (`booking_detail_screen.dart`, `booking_detail_sections.dart`): photo header, section cards, and numbered route and history timelines.
  - Discover (`tourist_search_screen.dart`): blue header, package carousel and big place cards. No keyboard on arrival.
  - Emergency contacts: red "Call 911 now" card, spaced contact cards with green call buttons.
  - My data (`data_rights_screen.dart`): Data Privacy Act header, 3-step explainer, status cards with a Download button. It was kept on purpose and works end to end: request → admin fulfils in Admin → Data requests → download JSON.
- **Home map search** finds places in place (results list under the bar; tap flies the map and opens the card). It no longer jumps to Discover. The my-location button moves at once to the known position, then refines.
- **Booking history from Account** opens `/tourist/booking-history` above the tabs, with Back, on the Past tab.
- **Cancel:** a reason dialog with quick choices (the server needs 5+ characters; a short reason was the cancel error the owner hit). There is an instant "Booking cancelled." confirmation and clearer server-error messages.
- **Driver going online:** `DriverAvailabilityController` tries GPS for 8 s, then a recent last-known fix, then a Wi-Fi/cell (medium accuracy) fix. Before, indoors it failed with "Could not get a current GPS position".
- **Phone notifications late (up to 1 min):** the dispatcher ran once a minute. Migration `20261122070000_send_all_push_immediately.sql` adds a statement-level trigger on `message_deliveries` that calls `invoke_communications_dispatcher()` right away, the same pattern as the ride-offer push. The minute job stays as the retry fallback.

### Current state (end of 2026-11-22)

- Branch `feature/gcash-payment-and-cleanup`, last commit `2a83a02`. Local only; no remote.
- `flutter analyze` is clean. `flutter test` in the cloud workspace: everything passes except DriverHome and DriverShell accessibility at text 1.0, which fail on untouched code there too.
- The phone has the latest **profile** build, made with `scripts/phone_check_profile.cmd` (uses `config/phone-test.json`, which now has `SHOW_ERROR_DETAILS`).
- Phone tooling: `phone_check*.cmd` (build, install, record launch), `phone_screens.cmd` (render all screens), `phone_logs.cmd` (flutter log; empty on this Honor phone), and `phone_resume_check.cmd` (shade and Home return screenshots into `build/phone_resume/`).
- **None of today's 5 migrations are on the hosted project yet.**
- The owner still has to test the admin side; the package editor needs the migrations first.

## Left to do (for Claude Code on the PC)

In this order:

1. **Push the database updates** to project `xcsrjuqzwequmeqzedzd` with `supabase db push`. If Docker is available, run `supabase db reset` and the SQL tests in `supabase/tests` locally first. Pending migrations:
   - `20261122040000_count_online_drivers.sql`: "no drivers online" count.
   - `20261122040100_privacy_notice_gcash.sql`: GCash wording in the privacy notice, version 2026-11-22. Every user accepts once more.
   - `20261122050000_package_only_catalog.sql`: deletes non-package places and adds `admin_save_tour_package` / `admin_delete_tour_package`. It was only tested on a stand-in schema, so check it against the real one first.
   - `20261122060000_tour_booking_window.sql`: bookings up to 365 days ahead (rewrites `create_booking_with_schedule` with `pg_get_functiondef` + `replace`, and raises an error if the 30-day text isn't found).
   - `20261122070000_send_all_push_immediately.sql`: instant push dispatch trigger.
2. **Update the security catalog.** After the push, run `scripts/test_catalog_access.ts` (see TESTING.md; needs Docker) and update `supabase/security/authorization_catalog.json` for the new functions:
   - the two package RPCs, which are already in `scripts/security/access_rules.ts`;
   - `dispatch_queued_messages_now()`, a trigger-only function (execute revoked from everyone).

   Otherwise CI's catalog check fails. Explanation for the owner: the catalog is the list of every server function and who may call it; CI refuses functions that aren't on the list.
3. **Verify on the hosted project after the push:**
   - Only 11 places remain.
   - An admin can create, edit, reorder and delete a package.
   - A booking 2+ months ahead is accepted.
   - A cancellation push arrives within a few seconds.
4. **Run `flutter analyze` and `flutter test` on the PC.** If DriverHome/DriverShell accessibility at text 1.0 fails there too, fix the contrast.
5. **Server-side enforcement (recommended).** The tour-day rules (Mon–Fri, not holidays, 8:00–13:00 Manila start) and the fixed meeting point are enforced only in the app. Options:
   - Add checks to `create_booking_with_schedule`.
   - Add a `tour_closed_dates` table that admins can edit, replacing the hard-coded `TourSchedule.closedDates`. It needs Eid'l Fitr/Eid'l Adha each year and Bustos local holidays.
   - Optionally block custom (no-package) bookings.

   Update the SQL tests in `supabase/tests` that create bookings at arbitrary times or without a package.
6. **Find the intermittent refresh failure.** With the phone-test build, if "Some information could not refresh. Details: …" appears, the details name the section and error. Fix the cause (RLS, timeout or query).
7. **Clean-up:**
   - Remove the unused location picker screen and route (`/tourist/location-picker`) and pickup-picking code (`BookingDraft.pickupLat/Lng`, `pickupAddress`). Delete `driverInServiceArea` if unused.
   - "+2 more" and "remaining" are English-only in Filipino mode.
   - Admin spot cards leave empty space under the photo on wide phones.
   - Plan the Kotlin Gradle plugin upgrade (build warning).
   - Line endings: about 74 files show as modified only because of CRLF/LF. Don't commit them; consider a `.gitattributes` with `* text=auto`.
8. **Owner tasks:**
   - Enter verified Bustos emergency numbers (Admin → Emergency contacts).
   - Confirm package prices and routes (Admin → Tour packages).
   - Confirm office hours and the phone number with the tourism office.
9. **Two-phone test** with real people (arrival needs to be within 150 m of the pickup, which is now the tourism office). Script: `docs/real-world-scenarios.md`.
10. **Push the branch** to a private GitHub repo and merge into `master`. Both need the owner's OK.

## Done on the PC (2026-11-22, evening)

- **Migrations pushed** to `xcsrjuqzwequmeqzedzd` with `supabase db push --remote` (dry run first): `20261122040000` to `20261122070000`. `20261122050000_package_only_catalog.sql` was checked against the live schema first (FKs, nullable `booking_stops.spot_id`, identity `fare_revisions.revision`, all 11 place ids present).
- **Local SQL tests** (Docker, isolated `tricgabay_batch4_isolated` stack, full 70-migration chain): all 24 pgTAP suites pass (464 assertions) after the 2026-11-23 rewrite below.
- **Security catalog regenerated** (`supabase/security/authorization_catalog.json`). `scripts/security/access_rules.ts` now also covers the GCash tables, RPCs and buckets from 2026-11-20, which had never been registered; `scripts/fixtures/authorization.sql` gained driver GCash rows. Full matrix: 7,982 cases, 0 failures.
- **Hosted checks:** 11 places; admin a1 created, renamed, reordered, re-priced and deleted a package (rolled back afterwards; a tourist is refused); a booking 70 days ahead is accepted and 400 days is refused; a cancellation push reached the d1 phone about 1 s after the cancel.
- **Flutter:** analyze clean; 2,566 tests pass. Fixed the Fixed fares intro text contrast (failed since `79a3be6`).
- The phone is signed in as `d1`. A demo-tourist test booking `d9ad40fd` was created, assigned to d1 and cancelled for the push test.
- Note: with `core.autocrlf=true`, `git stash`/checkout rewrites the line break inside `agreedValue` in `docs/localization-review.csv`; rerun `dart run tool/export_localization.dart` if the localization gate fails.

## 2026-11-23: PayMongo test retirement

- `supabase/tests/002_financial_security.sql`, `004_refund_reconciliation.sql` and `008_batch2_booking_contracts.sql` no longer test PayMongo refund reservation, webhook processing, provider reconciliation or the hold-until-paid/late-payment rules.
- Checks that still apply were rewritten against the live functions:
  - **002 (34):** every PayMongo function is closed to anon and authenticated users; only finance (or super admin) can settle a charge (`resolve_booking_charge`) or publish fares; cash needs both participants (`confirm_cash`), and a repeat confirmation is stored once; one ledger credit per cash payment; ledger rows cannot be edited or deleted.
  - **004 (19):** charge decisions are validated (reason, range, no pre-pickup increase); an overpayment becomes `refund_required`; both participants confirm the exact cash refund; nothing to refund means no confirmation.
  - **008 (16):** a PayMongo request is refused and stores nothing; cash and direct-GCash requests go straight to `pending`, unpaid; request IDs are idempotent and conflicts are refused; one active booking per tourist; pickup area; pickup-code reissue and rate limit.
- Fresh local reset: all 24 suites pass, 464 assertions.
- The stray `android/app/src/main/kotlin/com/tricgabay/tricgabay_app/MainActivity.kt` (untracked Flutter template default) was deleted. The build uses `com.tricgabay.app.MainActivity`: the manifest's `.MainActivity` resolves against namespace `com.tricgabay.app`, as the merged manifest shows. A debug APK builds without it.

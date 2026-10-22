# Tric-Gabay final field-testing checklist

Updated: 22 October 2026.

Use two physical Android phones (tourist and driver) and one admin session. Run
the checks below only after the Brevo sender is verified and its server secrets
are installed. Record the test account, booking ID, device models, Android
versions, network type, start/end time, expected result, actual result, and a
screenshot for every failure.

## 1. Installation, accounts, and permissions

- Install the release APK on both phones and confirm login, logout, session
  restore, Android back navigation, notification permission, and precise and
  background location permission flows.
- Register a driver, upload every required document, and confirm that an admin
  cannot approve missing or expired documents.
- Verify that rejected, suspended, expired, and manually blocked drivers cannot
  go online or receive/accept offers.

## 2. Matching and booking lifecycle

- Test immediate and scheduled bookings, passenger capacity, luggage,
  accessibility needs, service-area boundaries, and no-driver availability.
- Send one offer to competing eligible drivers and confirm only one can accept.
- Let an offer and a search expire, then retry without duplicate bookings or
  charges.
- Test driver replacement before pickup and confirm tourist consent, preserved
  fare/payment history, and free cancellation when replacement is refused.

## 3. Maps, routing, and live location

- Confirm tourist and driver markers update while foregrounded, backgrounded,
  screen-locked, temporarily offline, and reconnected.
- Verify stale/inaccurate locations are labelled and never treated as arrival.
- Confirm arrival requires fresh GPS proximity and the pickup code is required
  before trip start.
- Follow the local-road-preferred route, deliberately deviate, and confirm the
  recalculation warning and tourist notification.
- Revoke location permission mid-trip and confirm the app gives a safe recovery
  path without inventing movement or completion.

## 4. Tour progress and safety cases

- Confirm each stop, try skipping/reordering with and without mutual approval,
  and verify completion is blocked until required confirmations exist.
- Test breakdown pause, tourist wait/end choice, and driver safe-resume.
- Test tourist and driver cancellation before pickup, after arrival, and during
  the tour; verify policy version, evidence, fee, settlement hold, and audit
  events are consistent on all three roles.
- Test no-show timing and evidence, early ending, dispute opening, and admin
  resolution.

## 5. Payments, refunds, receipts, and email

- Complete a PayMongo test checkout and confirm signed webhook reconciliation,
  idempotency, immutable ledger entries, and no client-side payment trust.
- Test failed, abandoned, repeated, and delayed payment callbacks.
- Run a test-mode refund from the admin workflow and verify amount limits,
  authorization, settlement state, audit log, and user-facing wording.
- Test cash dual confirmation and a disagreement case.
- Verify branded email and push notifications for booking confirmation,
  reminders, assignment/replacement, cancellation, payment, refund, trip
  completion, dispute updates, and venue closure. Check foreground, background,
  terminated-app, deep-link, duplicate, and retry behavior.

## 6. Resilience and release sign-off

- Repeat critical flows on weak/mobile data and airplane-mode interruption.
- Confirm queued actions recover safely and repeated taps do not duplicate
  bookings, payments, cancellations, or completion.
- Test a low-end phone, small and large text, screen reader labels, narrow
  screens, dark/light system settings, and Filipino/English copy if enabled.
- Review Supabase logs, failed communication jobs, webhook failures, security
  audit events, and database backups after the run.
- Do not approve release while any payment, authorization, location, trip-state,
  or data-loss defect remains open.

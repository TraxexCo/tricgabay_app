# GCash Payment Redesign and Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace PayMongo with direct tourist-to-driver GCash (QR, slide-to-confirm, proof only on dispute, admin rulings, outstanding-fare booking block), bring the hosted Supabase project up to date with demo data, and land the agreed cleanup items.

**Architecture:** Server rules live in one new Postgres migration (RPCs + RLS + triggers + cron), extending the existing `202611150001_gcash_direct_payment` objects. The Flutter app calls them through `BackendRepository`; payment UI lives in focused widgets under `lib/features/payment/`.

**Tech Stack:** Flutter 3.44 / Dart 3.12, Supabase (Postgres 17, Storage, pg_cron), pgTAP, gen_l10n (en + fil ARB) with `tool/generate_message_codes.dart`.

**Spec:** `docs/superpowers/specs/2026-11-20-gcash-payment-and-cleanup-design.md`

## Global Constraints

- Payment methods offered to new bookings: `cash`, `gcash_direct` only; server rejects `paymongo` for new rows.
- Auto-escalation after **24 hours** of an unresolved `disputed` GCash payment; cron every **15 minutes**.
- Ruling values: `paid`, `not_paid`, `waived`. Blocked-booking error message: `OUTSTANDING_FARE`.
- Admin rulers need capability `finance` or `operations` (or `super_admin`).
- Receipt/QR uploads: JPEG or PNG, max **5 MB**, private buckets `gcash-receipts` and `driver-gcash-qr`.
- GCash reference: 8–20 ASCII letters/digits (existing rule), unique across bookings, required only on proof submission.
- Every user-facing string gets an `app_en.arb` and `app_fil.arb` entry; regenerate with `flutter gen-l10n` and `dart run tool/generate_message_codes.dart`.
- Never delete applied migrations or historical financial rows.

## Review Focus

- Tourist switches to cash after a `not_paid` ruling: block must stay until cash is confirmed (pgTAP in Task 1).
- Same reference number submitted on a second booking: rejected with a clear error (pgTAP in Task 1).
- Driver confirms receipt while an escalation is open: confirmation wins, ruling no longer possible (pgTAP in Task 1).
- Non-participant / tourist-role user tries to read another booking's receipt object or rule: denied (pgTAP in Task 1).
- Blocked tourist opens fare summary: sees the outstanding-fare message with a link, not a raw error (widget test in Task 3).

---

### Task 1: Server migration — QR, proof, escalation, rulings, block, PayMongo off

**Files:**
- Create: `supabase/migrations/202611200001_gcash_receipts_disputes_rulings.sql`
- Create: `supabase/tests/024_gcash_disputes_rulings.sql`

**Interfaces — Produces (RPCs, all `security definer`, granted to `authenticated`):**
- `tourist_submit_gcash_proof(p_booking_id uuid, p_reference_no text, p_receipt_path text) returns void` — booking tourist, status `disputed`.
- `request_gcash_admin_review(p_booking_id uuid, p_note text default null) returns void` — tourist or driver, status `disputed`.
- `admin_rule_gcash_dispute(p_booking_id uuid, p_ruling text, p_reason text) returns void` — `p_ruling in ('paid','not_paid')`, reason ≥ 5 chars.
- `admin_waive_unpaid_ruling(p_booking_id uuid, p_reason text) returns void` — sets booking `payment_status='waived'`.
- `list_gcash_disputes() returns table(booking_id uuid, reference_label text, tourist_name text, driver_name text, fare_centavos int, disputed_at timestamptz, escalated_at timestamptz, ruling text)` — admin; escalated first.
- `get_gcash_dispute_detail(p_booking_id uuid) returns jsonb` — keys `reference_no, receipt_path, tourist_marked_sent_at, disputed_at, dispute_note, escalated_at, escalated_by_role, escalation_note, ruling, ruling_reason, ruled_at, fare_centavos`; participants and finance/operations admins.
- `get_my_outstanding_fare() returns uuid` — booking id of the caller's unsettled `not_paid` ruling, or null.
- `get_booking_driver_gcash` additionally returns `qr_object_path text` (drop + recreate).
- `set_driver_gcash_qr(p_object_path text) returns void` — driver, path must start with `auth.uid()::text || '/'`.

- [ ] Step 1: Write pgTAP test `024` covering: proof submit happy path; duplicate reference on another booking throws; proof outside `disputed` throws; escalate by driver and tourist; auto-escalate function escalates a 25h-old dispute and ignores a 23h one; ruling `paid` creates a `payments` row and `gcash_paid`; ruling `not_paid` then `create_booking_with_schedule`/direct insert for that tourist throws `OUTSTANDING_FARE`; switch to cash keeps block; `cash_paid` settles it; waive settles it; non-admin cannot rule; other tourist cannot read detail; new `paymongo` booking insert throws.
- [ ] Step 2: Run it against the hosted DB inside its transaction (it ends with `rollback`). Expected: FAIL (functions missing).
- [ ] Step 3: Write the migration. Buckets with `file_size_limit 5242880` and `allowed_mime_types {image/jpeg,image/png}`; storage policies keyed on `(storage.foldername(name))[1]`; `payment_rulings` table + settle trigger on `bookings.payment_status`; `before insert` triggers `reject_outstanding_fare_booking` and `reject_new_paymongo_booking`; `auto_escalate_gcash_disputes()` + `cron.schedule('tric-gabay-gcash-escalation','*/15 * * * *', ...)`; `cron.unschedule` for `expire-paymongo-provider-checkouts` and `monitor-checkout-expiries` if present; notifications rows on escalate/rule.
- [ ] Step 4: Apply `202611150001` then `202611200001` to hosted; rerun `023` and `024`. Expected: all ok.
- [ ] Step 5: Commit.

### Task 2: Remove PayMongo from app and repo

**Files:**
- Modify: `lib/core/services/backend_repository.dart` (drop `createCheckout`, `processPayMongoRefund`, `reconcilePayMongoPayment`, `completePayMongoTestRefund`), `lib/core/prototype/prototype_session.dart` (matching wrappers), `lib/features/tourist/screens/fare_summary_screen.dart` (no `PaymentMethod.online` option), `lib/features/tourist/screens/booking_detail_screen.dart`, `lib/features/tourist/screens/booking_confirmation_screen.dart`, `lib/core/services/error_messages.dart`.
- Delete: `lib/core/services/booking_payment_flow.dart`, `supabase/functions/{create-paymongo-checkout,paymongo-webhook,process-paymongo-refund,reconcile-paymongo-payment,expire-paymongo-checkouts}`, their tests and `config.toml` entries.
- Keep `PaymentMethod.online` enum value for reading historical rows.

- [ ] Step 1: Remove code; `flutter analyze` → No issues.
- [ ] Step 2: `flutter test` → fix or delete tests that only covered PayMongo.
- [ ] Step 3: Commit.

### Task 3: App — QR, proof, escalation, rulings, outstanding-fare block

**Files:**
- Create: `lib/features/payment/gcash_proof_form.dart`, `lib/features/payment/gcash_dispute_panel.dart`, `lib/features/admin/screens/gcash_disputes_screen.dart`, `lib/core/services/gcash_repository.dart`
- Modify: `lib/features/tourist/screens/gcash_trip_payment.dart` (QR + Share/Save, proof form when disputed, Ask admin), `lib/features/driver/screens/driver_gcash_settings_screen.dart` (QR upload), `lib/features/tourist/screens/fare_summary_screen.dart` (block banner), `lib/app.dart` + `lib/core/constants/app_routes.dart` (`/admin/gcash-disputes`, capability `finance`/`operations`), `lib/features/admin/screens/admin_dashboard_screen.dart` (tile with count), ARB files.
- Test: `test/gcash_disputes_test.dart`

**Interfaces — `GcashRepository` (static, wraps Task 1 RPCs):** `submitProof(String bookingId, String reference, XFile receipt)`, `requestAdminReview(String bookingId, {String? note})`, `rule(String bookingId, String ruling, String reason)`, `waive(String bookingId, String reason)`, `listDisputes() -> Future<List<GcashDispute>>`, `detail(String bookingId) -> Future<GcashDisputeDetail>`, `outstandingFareBookingId() -> Future<String?>`, `uploadDriverQr(XFile image)`, `signedUrl(String bucket, String path) -> Future<String>`.

- [ ] Step 1: Widget tests: proof form requires reference + image; disputed tourist panel shows proof form and Ask admin; admin dispute screen renders receipt slot and both rule buttons; fare summary shows outstanding-fare banner when `outstandingFareBookingId` returns an id.
- [ ] Step 2: Run → FAIL. Step 3: implement. Step 4: run → PASS; `flutter analyze` clean.
- [ ] Step 5: Commit.

### Task 4: Hosted demo data

**Files:** Create `supabase/seed/demo_seed.sql` (idempotent, `demo.tricgabay.test` emails, random unusable passwords).

- [ ] Step 1: Seed 6 approved drivers (with GCash details), 10 tourists, ~30 completed bookings over the last 60 days with stops, reviews, cash/GCash payments, 2 cancelled, 1 escalated GCash dispute with proof.
- [ ] Step 2: Apply via `execute_sql`; verify counts. Step 3: Commit.

### Task 5: Quick cleanup

- [ ] Money: `BookingModel`/`BookingStop` fare fields to `int …Centavos`; formatters take centavos; tests pass.
- [ ] CI: `quality.yml` triggers `push` and `pull_request`.
- [ ] Docs: move batch/audit/hardening reports to `docs/archive/`; update README links.
- [ ] Commit each.

### Task 6: Session refactor

- [ ] Rename `PrototypeSession` → `AppSession` (`lib/core/session/app_session.dart`), extract `BookingDraft` (pickup, passengers, luggage, accessibility, schedule), delete dead code (`addOrUpdateSpot`, no-op `approveDriver`). Tests pass. Commit.
- [ ] Removal of local offline mode: deferred until a fake backend exists for tests (documented in KNOWN_ISSUES).

### Task 7: Verify

- [ ] `flutter analyze`, `flutter test`, pgTAP 023/024 on hosted, Supabase advisors; whole-branch review.

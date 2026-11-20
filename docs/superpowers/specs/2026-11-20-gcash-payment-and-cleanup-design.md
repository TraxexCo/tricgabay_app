# GCash payment redesign and codebase cleanup — design

Date: 2026-11-20. Status: approved in conversation ("go proceed work on it all").

## Intent

Tric-Gabay is a capstone, so the full scope stays: the panel needs to see the
details. The operator has no BIR/DTI registration, so it can't use a payment
gateway (PayMongo) or hold anyone's money. Online payment therefore becomes a
direct tourist-to-driver GCash transfer that the app records but never touches.
Admin stays inside the mobile app (no web admin).

## Goals

- Two payment methods: **cash** and **GCash (send to driver)**. PayMongo goes away
  from the app and from new bookings.
- In the normal case, paying takes seconds: the tourist pays while standing next
  to the driver, and the driver slides to confirm. No upload is needed.
- Disputes can be resolved by the two people involved, or by an admin.
- A tourist who loses an admin ruling can't book again until they settle.

## Non-goals and anti-goals

- No payment gateway, commission, wallet or money custody.
- No automatic GCash verification (GCash has no public API for personal accounts).
- Don't make every trip pay a "receipt tax". A design that forces an upload on
  every trip is a failure even if it works.
- Don't delete historical migrations or financial records.

## Approaches considered

1. **Receipt upload on every GCash payment, driver confirms.** This was the
   user's first idea. It adds friction to every trip even though both people
   are standing together. Rejected.
2. **Slide-to-confirm only, receipt only when disputed (chosen).** Normal trips
   stay fast. The receipt and reference number are collected only when the
   driver says the money didn't arrive, which is the moment proof matters.
3. **Keep PayMongo test mode alongside GCash.** It can't go live without a
   registered business, and it doubles the payment states. Rejected.

## Payment flow (decided)

### Normal case
1. The trip completes. The tourist's payment card shows the fare, the driver's
   GCash name and number, the driver's **QR image** with a **Share/Save QR**
   action (GCash can scan an uploaded QR from the gallery), plus **Open GCash**,
   copy number and copy amount.
2. The tourist pays, then optionally taps **"I've paid"** (with an optional
   reference number).
3. The driver checks their own GCash and **slides to confirm**. Paid. Done.

### Problem case
1. The driver taps **Not received** (optional note). Status becomes `disputed`
   and the tourist is notified.
2. The tourist is asked for **proof**: a receipt screenshot (JPEG/PNG,
   validated) and the **GCash reference number** (required at this step).
   A reference number can only be used on one booking.
3. They sort it out themselves: the driver confirms once the money appears, or
   the tourist switches to cash (existing flow).
4. If they can't agree, either one taps **Ask admin to decide** (optional note).
   Disputes that nobody resolves escalate **automatically after 24 hours**.
5. An admin with the `finance` or `operations` capability sees the fare,
   receipt, reference number, both notes and the trip timeline, then rules:
   - **Paid**: recorded exactly like a driver confirmation (a payment row and
     `gcash_paid`), with the admin noted as the confirmer.
   - **Not paid**: the booking stays due and the tourist is **blocked from new
     bookings until settled**. It's settled when the driver confirms a later
     GCash transfer or confirms cash after a switch. An admin can also
     **waive** it, with a reason.
6. Both parties get a notification for each escalation and ruling.

## Server design

- Migration `202611200001_gcash_receipts_disputes_rulings.sql`:
  - `driver_gcash_details.qr_object_path`, stored in the private bucket
    `driver-gcash-qr` at `{driver_id}/{uuid}.{jpg|png}`. Readable by the owner,
    by admins, and by the tourist of a completed GCash booking with that driver
    while payment is due.
  - Private bucket `gcash-receipts` at `{booking_id}/{uuid}.{jpg|png}`. The
    booking tourist can insert while disputed. The tourist, the assigned driver
    and finance/operations admins can read. 5 MB limit, image MIME types only.
  - `gcash_payment_confirmations` gains `receipt_object_path`,
    `escalated_at`, `escalated_by`, `escalation_note`.
  - A unique partial index on `gcash_reference_no` blocks receipt reuse.
  - Table `payment_rulings(booking_id pk, ruling paid|not_paid|waived,
    reason, ruled_by, ruled_at, settled_at)`.
  - RPCs: `tourist_submit_gcash_proof`, `request_gcash_admin_review`,
    `admin_rule_gcash_dispute`, `admin_waive_unpaid_ruling`,
    `list_gcash_disputes` (admin), `get_gcash_dispute_detail` (participants and
    admin). `get_booking_driver_gcash` also returns the QR path.
  - A trigger settles a `not_paid` ruling when the booking reaches
    `gcash_paid` / `cash_paid` / `waived`.
  - A `BEFORE INSERT` trigger on `bookings` rejects tourists with an unsettled
    `not_paid` ruling (error code `P0001`, message `OUTSTANDING_FARE`).
  - Trigger and switch-to-cash guard: switching to cash after a `not_paid`
    ruling is allowed, but the ruling stays until cash is confirmed.
  - A `BEFORE INSERT` trigger rejects `payment_method = 'paymongo'` for new
    bookings. Old rows and tables stay.
  - A cron job every 15 minutes auto-escalates disputes older than 24 hours.
  - PayMongo cron jobs are unscheduled.
- The missing hosted migration `202611150001_gcash_direct_payment` is applied
  first.
- The local PayMongo edge function folders and their tests are removed. Hosted
  functions are deleted by the owner with the CLI (the MCP tool can't delete
  functions).

## App design

- Fare summary: only Cash and GCash. A blocked tourist sees a clear message
  with a link to the unpaid trip.
- Driver GCash settings: upload or replace the QR image, reusing
  `image_upload_validator`.
- Tourist payment card: QR, Share/Save QR, Open GCash, copy actions, "I've
  paid". When disputed: a proof form (screenshot + reference) and Ask admin.
- Driver payment card: slide to confirm, Not received, view proof when it
  exists, Ask admin.
- Admin: a **GCash disputes** screen (escalated first), reachable from the
  dashboard with a count, showing the dispute detail with the receipt and rule
  buttons. Also accessible from the admin booking detail.
- PayMongo checkout, refund and reconcile UI and repository calls are removed.

## Cleanup items (from the earlier critique)

- Work committed on branch `feature/gcash-payment-and-cleanup` (done).
- Client money as integer centavos in `BookingModel` / `BookingStop`.
- CI runs on push and pull_request (analyze, test, debug build).
- Batch and audit reports moved to `docs/archive/`. The root keeps README,
  ARCHITECTURE, SECURITY, TESTING, DEPLOYMENT, OPERATIONS, KNOWN_ISSUES,
  RELEASE_CHECKLIST.
- `PrototypeSession` renamed to `AppSession`, with the booking draft
  extracted into its own object. Dead code is removed. Removing the local
  offline mode is staged: the test suite exercises it, so it needs a fake
  backend first (builder's call on how far to go in this pass).
- Oversized screens: payment UI extracted from `booking_detail_screen.dart`
  into its own widgets as part of this work.

## Demo data (hosted)

Clearly fake demo accounts (emails on `demo.tricgabay.test`, unusable random
passwords), so nobody can sign in as them. Includes:
- approved drivers with GCash details
- tourists
- completed bookings with reviews and cash/GCash payments
- one open, escalated GCash dispute for the admin demo

The owner's existing accounts are left untouched.

## Left to the builder

Exact widget layout, copy wording (English + Filipino ARB entries), and how
far the local-mode removal goes this pass.

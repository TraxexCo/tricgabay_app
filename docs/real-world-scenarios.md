# Real-world use review: who uses Tric-Gabay in Bustos, and what happens

Written 2026-11-21 against branch `feature/gcash-payment-and-cleanup`.
`application-scenario-matrix.md` lists technical edge cases (races, retries,
stale state). This document is the human companion: real people, real
situations in Bustos, and whether the app copes today.

"Checked" means read in code or the hosted database, or seen on the test
phone (Android 17). The signed-in flows have not yet been run end to end on
two phones; see the test script at the end.

## The setting

- Bustos, Bulacan: day-trippers from Metro Manila and nearby towns, local
  families showing visiting relatives around, church and heritage visitors,
  students on field trips.
- Tricycles carry up to three passengers. Drivers use mid-range or budget
  Android phones, often on prepaid mobile data.
- Payment is cash or GCash handed over face to face. No BIR/DTI permit, so
  no payment gateway.
- Coverage is generally fine in the town centre and can be weaker near
  fields and the river.

## Scenarios

### 1. A day-tripper books a ready-made tour

Ana and her friend arrive by bus at the municipal hall. Ana installs the app,
signs up with her phone number, picks **TRIC LAKBAY** (₱700, five stops),
sets pickup at the hall, and books now.

- **What happens:** the booking is offered to online drivers in ranked order.
  The first driver to accept gets it; a second accept is rejected by the
  server. Ana sees the driver's name, plate and live location. At pickup she
  reads out a four-digit code, so she knows she is boarding the right
  tricycle.
- **Verdict:** works as designed. The pickup code is a real safety plus.
- **Watch:** the hosted database currently has **0 drivers online**. In a
  real launch, a tourist who books when nobody is online waits for the offer
  to expire. The app explains that and lets her retry or cancel, but there is
  no "no drivers right now, try later" warning *before* she books.

### 2. Paying by GCash, the normal case

At the end of the tour Ana pays ₱700 by scanning the driver's GCash QR.

- **What happens:** the driver checks his GCash, slides **Confirm payment**,
  and the trip closes. No receipt upload is needed.
- **Verdict:** matches the flow we agreed. The slide gives a vibration and a
  check mark.

### 3. The driver says the GCash payment never arrived

GCash is slow that day; the driver taps **Not received**.

- **What happens:** Ana is asked for the GCash reference number and a
  screenshot. They can settle it themselves (the driver confirms once the
  money shows up). If neither acts, it escalates to an admin after 24 hours.
  An admin "not paid" ruling blocks Ana's *new* bookings until it is settled
  or waived.
- **Verdict:** complete, and covered by database tests (`024`).
- **Real-world risk:** GCash reference numbers are reused in screenshots that
  circulate online. The server already rejects a reference used on another
  booking (`GCASH_REFERENCE_USED`). Good.

### 4. A family of five

Lola, two parents and two kids want one tour together.

- **What happens:** one booking holds at most **3 passengers**. The family
  must make two separate bookings, which may land on different drivers and
  different start times.
- **Verdict: gap.** This will be common (families, barkadas, field trips).
  Options: allow "2 tricycles" on one booking (bigger change), or at least
  tell the tourist plainly to book a second tricycle and keep the two
  bookings linked in the driver's view.

### 5. A senior or PWD passenger

- **What happens:** the tourist can request extra boarding time; only drivers
  who accept assistance requests are offered the trip.
- **Verdict:** good. Worth showing on the incoming request card *why* the
  trip needs assistance (it currently shows "Allow extra boarding time").

### 6. A spot is closed (Holy Week, repairs, a fiesta)

- **What happens:** admins can mark a spot temporarily closed with a reason.
  The spot page then shows **Closed** and it can't be added to an itinerary.
- **Verdict:** works for single spots. Not yet checked: what a *package*
  containing a closed stop does. Decide whether the driver skips it (and
  whether the fare changes).

### 7. Rain or a breakdown mid-tour

- **What happens:** trips can be interrupted. The tourist and driver both see
  the state, and the cancellation policy snapshot decides any charge.
- **Verdict:** the rules exist. In practice the driver will want a quick
  "end tour early, charge ₱X" path; check that the final-charge dialog is
  easy to reach from the driver's trip screen.

### 8. Something goes wrong: accident, harassment, medical

- **What happens:** both roles have an **SOS / Emergency** screen.
- **Verdict: not ready for real riders.** Only the national **911** number
  is real. Bustos MDRRMO, PNP, BFP, the local hospital and the tourism office
  are placeholders ("owner must supply number"). Fill them in from
  *Admin → Emergency contacts* with numbers you have verified yourself
  before anyone rides.

### 9. Weak signal near the outskirts

- **What happens:** an offline banner appears. Live tracking shows "location
  unavailable" instead of a stale "live" dot. Booking and payment actions
  need the server and say so.
- **Verdict:** behaves honestly. The driver's location resumes when the
  signal returns.

### 10. A foreign visitor without a Philippine SIM

- **What happens:** sign-up accepts international numbers (`+` country
  code), and the app is in English or Filipino.
- **Verdict:** fine. They will usually pay cash; GCash needs a PH account.

### 11. A new driver joins

- **What happens:** the driver registers, uploads a licence and an OR/CR
  photo, and waits. An admin reviews the documents and expiry dates and
  approves. Only approved drivers can go online, and the driver must allow
  location to do so.
- **Verdict:** works. The application screen was cramped; it is now spaced
  out properly.

### 12. Admin's day

- **What happens:** the dashboard shows today's bookings, pending driver
  verifications and open GCash disputes. The admin approves drivers, edits
  spots and fares, rules on disputes and sends announcements.
- **Verdict:** complete for a town-scale pilot.

## Must fix before real (non-test) riders

| # | Issue | Who fixes | Why it matters |
|---|---|---|---|
| 1 | Local emergency numbers are placeholders | Owner: verify the numbers, enter them in the admin screen | SOS shows only 911 today |
| 2 | Custom-tour fare is **₱70 for 1–12 stops**, against ₱700–₱1,000 packages | Owner: set a realistic fare in *Admin → Fixed fares* | A 12-stop custom tour for ₱70 undercuts every package and the drivers |
| 3 | Groups over 3 people need two separate bookings | Product decision, then code | Families and field trips are common |
| 4 | No warning when zero drivers are online | Small code change | Avoids waiting on a request nobody can take |
| 5 | Tourist home asks for location as soon as the map opens, with no explanation first | Small code change | First impressions; Android shows the system prompt cold |

## Phone test script (two phones, about 30 minutes)

Use the test accounts `t1`, `d1` and `a1@tric.test`.

1. **Driver phone (d1):** sign in → allow notifications when asked → go
   online → allow location.
2. **Tourist phone (t1):** sign in → allow notifications → open the map →
   allow location → pick TRIC LAKBAY → book now.
3. **Driver:** accept the request → tap Navigate → "arrive" → enter the
   tourist's pickup code → start the trip → confirm the stops → complete.
4. **Tourist:** watch the live location → pay by GCash (or pretend) → rate
   the driver.
5. **Driver:** slide **Confirm payment** (watch the animation and feel the
   vibration).
6. Repeat with **Not received** → tourist submits a reference and screenshot
   → **admin (a1)** opens *GCash disputes* and rules.
7. On both phones, press **Back** on every screen: it should go back one
   page, never close the app from inside a flow.
8. Turn on *Settings → Accessibility → larger text* and repeat a few screens.

# Tric-Gabay booking, payment, refund, and safety rules

Updated: 20 October 2026.

## Authoritative design

- Supabase is the source of truth for identity, roles, approvals, attractions,
  packages, fixed-fare revisions, bookings, trip events, live locations,
  payments, disputes, refunds, reviews, notifications, and audit records.
- Flutter never receives the Supabase service-role key or PayMongo secret key.
- Row-level security limits records by tourist, assigned driver, or administrator.
- Sensitive state changes use server-side database functions so two devices cannot
  both accept, start, complete, cancel, or settle the same stale state.
- PayMongo runs in **test mode only**. A return URL is only navigation; payment is
  accepted only after a verified, idempotent PayMongo webhook.
- Firebase is optional and limited to push delivery. It is not a second database.

## Pricing and booking

- The administrator publishes one fixed custom-tour price and one fixed price per
  package, with a reason and immutable revision history.
- Every booking snapshots the fare revision, cancellation-policy version, pickup,
  ordered stops, and attraction names/coordinates. Later edits affect future
  bookings only.
- Explore contains the complete active attraction catalog. Packages reference
  ordered subsets of that catalog.
- A tourist may have one active booking. A driver may have one active assignment.
  Only active tourists and online, approved drivers may transact.
- A four-digit pickup code is generated server-side and stored only as a secure
  hash on the server. The driver must first report arrival using a fresh,
  accurate location within 150 meters of pickup, then verify the code before
  starting the trip.

## Cancellation, disputes, and refunds

| Situation | Decision |
| --- | --- |
| Pending request cancelled | No charge. |
| Driver cancels before pickup | No tourist charge; event is audited. |
| Tourist cancels shortly after acceptance | Free during the configured grace period. |
| Tourist cancels after the grace period but before pickup | Published percentage fee applies; the booking retains the exact policy version. |
| Driver waits but tourist does not appear | A no-show is available only after GPS-verified pickup arrival and the complete server-timed wait; the snapshotted percentage applies. |
| Either party ends an ongoing trip | End immediately for safety, release the driver, and hold settlement for admin review. |
| Full route completed | Locked fixed fare becomes the final charge. |
| Cash payment | Tourist and driver independently confirm the physical exchange. Admin cannot impersonate either party. |
| Online payment | Only PayMongo's signed webhook can mark it paid. Redirects and client buttons cannot. |
| Paid amount exceeds final charge | Create a refund-due state. Cash needs dual confirmation; online refunds need admin and provider status. |
| One party disputes service or payment | Freeze settlement, keep both statements/events, and require a reasoned admin decision within the quote. |

PayMongo test mode cannot move money. The admin refund action records and locks an
approved test refund as `refund_processing`, while explicitly saying that no real
money moved. Live refund processing requires separate work and approval before
production.

## Location and navigation

- The driver publishes timestamped GPS coordinates, accuracy, heading, and speed
  only while online or on an assigned trip. On Android, a visible foreground
  notification keeps active sharing running when the app is backgrounded.
- Tourists can read location only for their assigned active booking; admins can
  monitor approved drivers. Stale or inaccurate locations are labelled rather
  than used as proof of service.
- Mapbox Directions provides a local-road-preferred route that excludes motorway
  and toll classes when possible. Mapbox has no tricycle vehicle profile, so the
  route is guidance rather than a guarantee; drivers must follow road signs and
  their approved TODA or LGU route. The app warns about reported restriction
  violations, does not draw a fake straight line when routing fails, and does not
  silently use Bustos center as a pickup.
- The driver reports the next stop and the tourist confirms it. Completion is
  blocked until every stop is confirmed.

## Important real-world cases covered

- Duplicate booking taps and competing driver acceptance.
- Expired driver-search windows and explicit retry without creating a duplicate booking.
- Price changes during checkout and after booking.
- Stale deep links, wrong-role screens, suspended accounts, and vehicle-detail
  edits that reset driver approval.
- Missing or stale GPS, route-service failure, background/resume, and restart with
  backend resynchronization.
- Early ending for breakdown, unsafe conditions, venue closure, or changed plans.
- Repeated cash confirmations, excess settlement, failed online payment, duplicate
  webhooks, and refunds that are due, processing, partial, or complete.
- Emergency actions open the real phone dialer; the app never pretends responders
  were contacted.

## External setup and field validation

Before a two-phone test, configure Supabase, PayMongo test keys/webhook secret,
Mapbox credentials, and optionally an FCM project. Follow `docs/backend-setup.md`.
Then field-test two physical phones under weak signal, denied location, app
termination, low battery, large text, payment retries, and admin dispute review.
Automated tests cannot prove road, GPS, network, or provider behavior.

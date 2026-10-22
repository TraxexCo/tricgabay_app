# Tric-Gabay production-hardening roadmap

Updated: 23 October 2026.

This checklist tracks implementation status. A feature is marked complete only
when its database rule, Flutter flow, and automated validation agree.

## Completed

- [x] Fixed fares with immutable revisions and administrator controls.
- [x] Versioned cancellation, grace-period, pickup-wait, and no-show policies.
- [x] Fee-aware cancellation wording and settlement limits.
- [x] GPS-proximity pickup arrival with freshness and accuracy requirements.
- [x] Server-timed pickup waiting period and evidence-based tourist no-show.
- [x] Ten-minute dispatch expiration, stale-accept rejection, and search retry.
- [x] Atomic booking acceptance and one active booking per participant.
- [x] Pickup-code verification before trip start.
- [x] Stop-by-stop tourist confirmation and completion protection.
- [x] Early-ending settlement hold, disputes, cash dual confirmation, and refund states.
- [x] PayMongo test checkout and signed webhook verification.
- [x] Live driver location, stale-location labels, background Android sharing, and local-road-preferred routing.
- [x] Nearby-driver ranking, two-minute offer leases, real decline handling, and dispatch refresh.
- [x] Passenger count, luggage notes, accessibility needs, and compatible driver capacity matching.
- [x] Scheduled tours with server activation, 24-hour/1-hour reminders, and duplicate-booking protection.
- [x] Consent-based pre-pickup driver replacement with free cancellation and preserved fare/payment history.
- [x] Temporary venue closures with affected-trip notifications and booking prevention.
- [x] Mutually approved stop skipping/reordering with immutable audit events and fair payment review.
- [x] GPS-recorded breakdown pause, tourist wait/end decision, and driver safe-resume confirmation.
- [x] Sustained route-deviation detection, route recalculation warning, and tourist notification.
- [x] PayMongo status reconciliation, provider-submitted refunds, honest test-mode rejection handling, and immutable financial ledger.
- [x] Test-mode refund completion with immutable ledger records and admin-only authorization.
- [x] Branded lifecycle email queue, retry handling, logo-backed templates, verified Brevo sender, and encrypted provider secrets.
- [x] FCM client lifecycle, privacy-safe payloads, foreground display, token rotation/revocation, protected deep links, and encrypted Firebase service credentials.
- [x] Driver document expiry, service areas, capacity, reliability scoring, and compliance-blocked matching.

## Next implementation batches

- [ ] Trusted contacts, trip sharing, incident evidence, and safety case management.
- [ ] Structured attraction schedules, temporary closures, and package validation.
- [ ] Persistent offline action queue and conflict-safe replay.
- [ ] Admin operations queues, role separation, exports, audit views, and health checks.
- [ ] Crash monitoring, webhook alerts, backup verification, retention jobs, and cleanup jobs.
- [ ] Rate limiting, upload validation, RLS regression tests, privacy retention, and GPS anomaly detection.
- [ ] Replace the global PrototypeSession facade with domain controllers and repositories.
- [ ] Full accessibility, localization, low-end-device, weak-network, and two-phone field testing.

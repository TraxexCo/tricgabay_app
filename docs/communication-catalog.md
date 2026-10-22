# Tric-Gabay communication catalog

All messages are transactional service updates. Sensitive details stay inside
the authenticated app; lock-screen push text is intentionally generic.

| Event | Tourist email | Driver email | Push / deep link |
| --- | --- | --- | --- |
| Booking created or scheduled | Confirmation, fixed fare, pickup, schedule | — | Booking record |
| Driver assigned | Driver-found update | — | Tourist tracking map |
| 24-hour and 1-hour reminders | Preparation reminder | — | Booking record |
| Trip completed | Completion and payment-review prompt | Completion and payment status | Role-specific booking record |
| Booking cancelled | Final charge/refund-status prompt | Cancellation status when assigned | Role-specific booking record |
| Refund completed | Provider confirmation or test-mode completion | — | Financial record |
| Refund failed | Action-required notice | — | Booking payment section |
| Payment dispute opened/resolved | Review status | Review status | Role-specific booking record |
| Vehicle/route safety event | Safety update | Existing in-app operational state | Generic private lock-screen text |

Email uses the Tric-Gabay logo, navy/yellow brand palette, a compact booking
summary, and a reminder never to share the pickup code. Delivery is idempotent,
retried with backoff, and visible to administrators through the delivery table.

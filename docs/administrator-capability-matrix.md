# Tric-Gabay administrator capability matrix

This matrix documents the server-enforced access introduced by migration
`202610230010`. `super_admin` is accepted by `has_admin_capability()` as an
explicit bypass for every listed capability. Participant access remains
limited to the tourist/driver ownership rules shown below.

| Resource | Participant access | Administrator capability |
|---|---|---|
| Profiles | Own profile; limited existing trip-participant policy | support, driver_compliance, operations, or finance |
| Driver profiles | Own driver record; assigned-trip minimum | driver_compliance or operations |
| Bookings, stops, trip events | Tourist/assigned driver; pending offers retain their existing minimum | operations, finance, or support |
| Current/historical driver location | Driver; tourist during the authorized trip | operations |
| Payments, refunds, disputes, financial ledger | Booking tourist/driver | finance |
| Cash confirmations | Booking tourist/driver | finance |
| Dispute statements | Booking tourist/driver | finance or support |
| Feedback | Author | support |
| Driver documents | Owning driver | driver_compliance |
| Attraction/package records and attraction images | Public active content is readable | content writes and inactive-content reads |
| Public application assets | Public read | content writes |
| Message deliveries and operational alerts | None | operations |
| Profile avatar object | Owning user only | No general administrator access |

Flutter route visibility is convenience only. PostgreSQL and Storage RLS are
the authorization boundaries.


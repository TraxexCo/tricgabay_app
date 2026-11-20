# Tric Gabay architecture

This describes the implementation at Batch 4, 3 November 2026. See TESTING.md and the Batch 4 evidence report for verification boundaries. No hosted deployment was performed.

## Client and server boundaries

The Android Flutter app uses Supabase Auth, PostgreSQL RPCs and RLS, Storage, Realtime and Deno Edge Functions. Mapbox supplies maps/routes; Firebase supplies messaging and optional diagnostics. Online payment is a direct tourist-to-driver GCash transfer recorded by the app (202611200001); PayMongo was retired and new PayMongo bookings are rejected. Their real services were not called during this batch's functional tests.

`PrototypeSession` remains the session coordinator and publishes state through feature controllers and ValueNotifiers. Riverpod is present but is not the sole state system. `BackendRepository` hydrates booking pages and their child records, maintains scoped Realtime subscriptions, patches location updates and invalidates affected sections. Session generations discard late results belonging to another login. Offline snapshots support reading; there is no durable offline booking queue.

The server owns booking transitions, matching, arrival/code checks, cancellation charges, payment release, refunds and financial ledger writes. The client never establishes payment success by closing a browser or trusting a return URL. Booking requests carry stable request IDs. Pending online payments and provider checkout expiry are separate workflows. Provider event IDs, checkout/payment identities and refund identities are now scoped by test/live mode.

## Location and reconnect

Going online already set `last_seen_at`; Batch 4 verified this instead of replacing it. The foreground online/idle driver screen requests Android GPS samples every five seconds with zero distance filter. The shared upload gate sends at most once per five seconds, and for movement under 15 metres waits 30 seconds between successful writes. The RPC sends latitude, longitude, accuracy, heading, speed, sample timestamp and mock-location flag; the server updates `last_seen_at` after validation. There is no independent timer that manufactures heartbeats without fresh usable GPS. GPS failure, permission loss, screen disposal and OS process management can therefore stop idle heartbeats.

Accepted/ongoing trip tracking belongs to `ActiveTripTrackingService`, with an Android foreground notification and recovery booking ID, independently of screen disposal. A minute job removes stale idle availability after the configured threshold (default 120 seconds). An assigned stale driver is marked offline for new matching, retains the trip, and raises a critical operational alert for intervention.

Realtime is an invalidation/location channel, not a durable event queue. On subscription/reconnection the client refreshes authoritative sections. The local reconnect test deliberately misses three updates, re-subscribes and fetches the current row. Periodic authoritative refresh and manual retry remain important; intermediate events can be lost when a service rate limit is exceeded.

## Data, consent and deletion

Current consent is kept in `privacy_consents`. `consent_history` appends version, server time, shown language and notice digest. Existing records without language evidence use `und`; no language was invented. Append-only evidence has no cascading subject FK. Its pseudonymous UUID remains linkable while other records survive; this is not a retention policy or an assertion of irreversible anonymization.

Deletion uses a resumable server preparation/cleanup workflow. Financial facts and the other party's dispute statements survive. Only the deleting author's statements and their authored dispute text are redacted. Prepared data-export payloads are removed and requests cancelled; audit events remain. Exports are account-owned JSON snapshots prepared by support/super-admin RPC, with private payload reads restricted to the requester. They cover the implemented application data categories, not a provider-wide legal discovery export or every Auth/provider log.

Driver documents and avatars are private buckets. Driver applications accept canonical JPEG paths. Attractions use a new UUID path for each JPEG/PNG replacement and one-year cache-control. Replacing an image changes its URL; old versions are retained pending an owner retention decision.

## Operations and environment isolation

Emergency agencies are editable by operations/super admins. Five local agencies start as disabled, clearly marked placeholders; 911 is the national fallback. Operations health aggregates failed payments, blocked/stuck checkout expiry, failed cron jobs, stale online drivers and failed notifications. The collector persists deduplicated critical alerts. A token-protected health handler returns 200/503 without exposing identities.

Android flavors are `dev`, `staging`, `production`, with distinct application IDs and compile-time public configuration. No Supabase, Mapbox or Firebase development credentials are hardcoded as fallbacks. Release validation requires service values and matching flavor/environment. Server secrets never belong in Dart defines.

The database chain has 52 migrations. Preinstalled PostGIS objects require a separate extension-owner bootstrap; ordinary migration privileges cannot alter them. The local validation runner makes this explicit and audits the resulting catalog.

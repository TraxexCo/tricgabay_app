# Operations

This runbook describes implemented local behavior. The owner must assign operators, contact routes and a monitoring service before public service begins. No real provider dispatch or hosted monitoring was enabled.

## Health and alerts

`operations_health` is service-only. Operations/super admins use `get_operations_health()` and the in-app Service health page. Server-side monitoring calls the health-check function with `x-tricgabay-monitor: <HEALTHCHECK_TOKEN>`; missing/short/wrong tokens return 401 without querying health, healthy metrics return 200, nonzero metrics return 503, and internal errors return generic 503. Responses use no-store caching. The handler was tested with real loopback HTTP and the isolated database; the hosted Edge gateway/runtime was not deployed.

Metrics: failed payments updated in 24 hours; blocked or expired-processing checkout expiry; failed cron jobs started in 15 minutes; online drivers beyond the configured heartbeat threshold; failed message deliveries updated in 24 hours. These are counts, not rate/latency service-level objectives. A nonzero count is intentionally conservative and can include already understood incidents until the window expires.

The minute collector raises deduplicated critical `health:<metric>` alerts. Checkout expiry separately raises a critical alert immediately when blocked, and on a processing lease more than two minutes overdue. Exhausted queued/expired claims become blocked after ten attempts. Repeated detection updates occurrence/time, not duplicate alerts. Assigned stale drivers raise an assignment-specific critical alert and retain the trip.

`supabase/monitoring/operations.sql` provides administrator and server-only diagnostic queries. Observe unacknowledged alerts, inspect the implicated queue/job/provider result and repair the cause before resolving an alert. Alerts persist in the database; this batch does not establish external paging, SMS or email escalation. The owner must decide who receives critical alerts and how quickly they respond.

## Payment/expiry incident

1. Confirm environment and mode. `paymongo_mode='test'` and `live_payments_enabled=false` are the accepted release-preparation defaults.
2. Review payment, mode-scoped event and ledger facts. A browser close/return is not proof of payment. Use reconciliation only with the correct environment's provider configuration.
3. For a blocked checkout-expiry row, inspect attempts, claim lease and sanitized error. Investigate provider connectivity/credentials and scheduler configuration. Do not remove financial records, reuse a live identifier in test mode, or blindly reset attempts indefinitely.
4. A paid replay on a fee-retaining cancellation preserves the retained fee. Excess settled funds still require refund; already refunded states remain unchanged. Use the server refund workflow rather than changing ledger rows.
5. Run the queue monitor/health collector after repair. Verify the provider state before manually requeuing a blocked row through an authorized database operation. No public mobile RPC can reset this queue.

Real PayMongo checkout, signature delivery, expiry and refund lifecycle need controlled provider tests. Injected tests cannot establish bank/GCash payout settlement. Driver payout transfer remains outside this batch.

## Driver/GPS incident

The default stale threshold is 120 seconds, checked each minute. Online/idle heartbeats are fresh GPS publishes throttled to at most one per five seconds, normally about every 30 seconds while stationary. There is no timer-generated heartbeat independent of GPS. Idle availability can expire if the screen is disposed or the device stops location updates; this is preferable to continuing to offer work to an unreachable device. Assigned trips retain their driver and raise an alert. Investigate contact, breakdown/no-show/replacement and the driver's last usable location before intervention.

Mock-location flags are review evidence; they are not spoof-proof attestation. Do not claim a mocked-location flag alone establishes misconduct. Android background/battery behavior still requires device testing.

## Emergency contacts and data rights

Operations/super admins edit emergency names in both languages and a dialable phone number. A number is disabled until entered and verified by the owner/operator; leaving it empty restores the placeholder. Five local agencies are placeholders (MDRRMO, PNP, BFP, hospital, tourism office). Do not publish fabricated numbers. The app displays and confirms a number before opening the dialer; it does not transmit SOS messages or live location.

Tourists/drivers request their own JSON export from My data, including the pending-driver route. Requests are idempotent by UUID and limited to three per day. Support/super admins view the paged request list and prepare the export. Only the requesting account can read the payload. Request, fulfilment and account-deletion actions are audited. Deletion erases prepared payloads/cancels requests while preserving audit evidence. Suspended/sign-in-inaccessible users need an owner-managed assisted request process and identity checks; the owner must publish the contact and response deadline.

## Realtime capacity and recovery

The isolated tenant's limit was 100 events/second and 200 concurrent users. After 60/60 warm-up canary deliveries established readiness, 600 updates/1,200 expected deliveries with 1.5-second rounds all arrived. A prior cold-start run missed one first event despite channel acknowledgment; final-state reads still matched. A faster 100-ms-round profile exceeded the cap; 1,043 of 1,200 deliveries arrived, with zero stale final database reads. Logs explicitly reported MessagePerSecondRateLimitReached. Reconnect catch-up fetched heading 103 after three disconnected writes in all profiles. These are local measurements, not hosted capacity guarantees.

Choose project quota, expected concurrent users and safe location cadence before launch. Monitor message limits, reconnects, database load and failed delivery counts. The client relies on authoritative refresh to recover state; it must not treat receipt of every intermediate Realtime event as a correctness requirement.

## Preservation and deployment boundaries

Backups, restore drills, incident access and retention periods need owner decisions. No retention schedule was introduced. Consent/audit evidence, financial records and superseded spot images remain until a policy is approved. Do not delete another party's dispute statements as part of a user deletion. See DEPLOYMENT.md for extension-owner bootstrap, per-environment keys and scheduler configuration.

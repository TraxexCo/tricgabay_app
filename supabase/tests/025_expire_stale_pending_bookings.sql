-- A pending booking with no driver whose scheduled start is more than 30 minutes
-- behind us is cancelled by the system; nothing a driver already holds is touched.
begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select plan(21);

-- Fixtures: six tourists (one live booking each) and two drivers.
insert into auth.users(id, email, raw_user_meta_data)
select ('e5250000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  'expire-stale-' || i || '@example.test',
  jsonb_build_object('full_name', 'Expiry fixture', 'requested_role', case when i in (7, 8) then 'driver' else 'tourist' end)
from generate_series(1, 8) i;
update public.profiles set status = 'active' where id::text like 'e5250000-%';

insert into public.driver_profiles(profile_id, plate_number, franchise_number, license_document_path,
  vehicle_document_path, approval_status, license_expires_on, franchise_expires_on,
  vehicle_inspection_expires_on, service_area_name, service_area_latitude, service_area_longitude,
  service_area_radius_km, is_online, last_seen_at)
select id, 'EXPIRE-' || right(id::text, 1), 'EXPIRE-FR-' || right(id::text, 1),
  id::text || '/license.jpg', id::text || '/vehicle.jpg', 'approved',
  current_date + 365, current_date + 365, current_date + 365, 'Expiry fixture',
  14.9571, 120.9188, 15, false, null
from public.profiles where id::text like 'e5250000-%' and role = 'driver';

insert into public.fare_revisions(id, custom_fare_centavos, reason)
values ('e5250000-0000-4000-8000-0000000000f1', 10000, 'Expiry fixture');
insert into public.cancellation_policies(id, terms)
values ('e5250000-0000-4000-8000-0000000000f2', 'Expiry fixture');

-- 1 stale pending, 2 pending inside the 30-minute grace, 3 pending with no schedule,
-- 4 accepted long ago, 5 ongoing long ago, 6 stale pending that was already paid.
insert into public.bookings(id, tourist_id, driver_id, fare_revision_id, cancellation_policy_id,
  quoted_amount_centavos, payment_method, status, pickup_address, pickup_latitude,
  pickup_longitude, pickup_code_hash, dispatch_expires_at, scheduled_at, accepted_at)
select ('e5250000-0000-4000-8000-' || lpad((100 + i)::text, 12, '0'))::uuid,
  ('e5250000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  case i when 4 then 'e5250000-0000-4000-8000-000000000007'::uuid
         when 5 then 'e5250000-0000-4000-8000-000000000008'::uuid end,
  'e5250000-0000-4000-8000-0000000000f1', 'e5250000-0000-4000-8000-0000000000f2',
  10000, 'cash',
  case i when 4 then 'accepted'::public.booking_status
         when 5 then 'ongoing'::public.booking_status
         else 'pending'::public.booking_status end,
  'Expiry fixture', 14.9571, 120.9188, crypt('2468', gen_salt('bf')),
  -- Booking 3 is an immediate booking whose search window is still open (see 027
  -- for expired immediate bookings); the others' windows ended a day ago.
  case when i = 3 then now() + interval '10 minutes' else now() - interval '1 day' end,
  case i when 1 then now() - interval '2 hours'
         when 2 then now() - interval '10 minutes'
         when 3 then null
         when 4 then now() - interval '2 hours'
         when 5 then now() - interval '2 hours'
         when 6 then now() - interval '2 days' end,
  case when i in (4, 5) then now() - interval '3 hours' end
from generate_series(1, 6) i;

insert into public.booking_offers(booking_id, driver_id, expires_at)
values ('e5250000-0000-4000-8000-000000000101', 'e5250000-0000-4000-8000-000000000007', now() + interval '1 hour');
insert into public.payments(booking_id, provider, provider_checkout_id, amount_centavos, status, paid_at)
values ('e5250000-0000-4000-8000-000000000106', 'paymongo', 'cs_expire_6', 10000, 'paid', now() - interval '2 days');

-- Access and scheduling.
select is(has_function_privilege('authenticated', 'public.expire_stale_pending_bookings()', 'execute'), false,
  'a signed-in client cannot run the expiry');
select is(has_function_privilege('anon', 'public.expire_stale_pending_bookings()', 'execute'), false,
  'anonymous callers cannot run the expiry');
select is(has_function_privilege('service_role', 'public.expire_stale_pending_bookings()', 'execute'), true,
  'the service role can run the expiry');
select is((select count(*)::integer from cron.job
  where jobname = 'tric-gabay-expire-stale-pending-bookings' and schedule = '*/5 * * * *' and active), 1,
  'the expiry runs every five minutes');

-- The run.
select is(public.expire_stale_pending_bookings(), 2, 'two stale pending bookings are expired');

select is((select status::text from public.bookings where id = 'e5250000-0000-4000-8000-000000000101'),
  'cancelled', 'a pending booking 2 hours past its start is cancelled');
select is((select cancellation_reason from public.bookings where id = 'e5250000-0000-4000-8000-000000000101'),
  'No driver accepted before the scheduled start', 'the reason says why');
select is((select final_charge_centavos from public.bookings where id = 'e5250000-0000-4000-8000-000000000101'),
  0, 'no charge for an unmatched tour');
select is((select payment_status::text from public.bookings where id = 'e5250000-0000-4000-8000-000000000101'),
  'waived', 'an unpaid expired booking is waived');
select is((select cancelled_by from public.bookings where id = 'e5250000-0000-4000-8000-000000000101'),
  null, 'no account is recorded as the canceller');
select isnt((select completed_at from public.bookings where id = 'e5250000-0000-4000-8000-000000000101'),
  null, 'the booking is closed');
select is((select status::text from public.booking_offers where booking_id = 'e5250000-0000-4000-8000-000000000101'),
  'expired', 'its open driver offer is expired');
select is((select payment_status::text from public.bookings where id = 'e5250000-0000-4000-8000-000000000106'),
  'refund_required', 'an expired booking that was already paid is flagged for refund');

-- The trip event has a system actor, not a person.
select is((select count(*)::integer from public.trip_events
  where booking_id = 'e5250000-0000-4000-8000-000000000101' and event_type = 'booking_cancelled'
    and actor_id is null and actor_role is null and metadata ->> 'actor' = 'system'
    and metadata ->> 'reason' = 'scheduled_start_passed'), 1,
  'one system-actor booking_cancelled event is logged');
select is((select count(*)::integer from public.notifications
  where booking_id = 'e5250000-0000-4000-8000-000000000101' and title = 'Booking cancelled'
    and recipient_id = 'e5250000-0000-4000-8000-000000000001'), 1,
  'the tourist is told through the existing event trigger');

-- Nothing else moves.
select is((select status::text from public.bookings where id = 'e5250000-0000-4000-8000-000000000102'),
  'pending', 'a booking inside the 30-minute grace stays pending');
select is((select status::text from public.bookings where id = 'e5250000-0000-4000-8000-000000000103'),
  'pending', 'a pending booking with no scheduled start and an open search window is not touched');
select is((select status::text from public.bookings where id = 'e5250000-0000-4000-8000-000000000104'),
  'accepted', 'an accepted booking is not touched');
select is((select status::text from public.bookings where id = 'e5250000-0000-4000-8000-000000000105'),
  'ongoing', 'a started booking is not touched');
select is((select count(*)::integer from public.trip_events
  where booking_id in ('e5250000-0000-4000-8000-000000000102', 'e5250000-0000-4000-8000-000000000103',
    'e5250000-0000-4000-8000-000000000104', 'e5250000-0000-4000-8000-000000000105')
    and event_type = 'booking_cancelled'), 0, 'no cancel event for the bookings that were skipped');

-- Idempotent.
select is(public.expire_stale_pending_bookings(), 0, 'a second run finds nothing to expire');

select * from finish();
rollback;

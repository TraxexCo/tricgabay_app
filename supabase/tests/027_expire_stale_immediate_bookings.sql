-- An immediate booking (no scheduled_at) with no driver is cancelled by the system
-- once its driver search window ended more than 30 minutes ago. Open windows,
-- recent windows and anything a driver holds are left alone; the scheduled rule
-- from 20261125010000 still applies.
begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select plan(21);

-- Fixtures: eight tourists (one live booking each) and two drivers.
insert into auth.users(id, email, raw_user_meta_data)
select ('e5270000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  'expire-immediate-' || i || '@example.test',
  jsonb_build_object('full_name', 'Immediate expiry fixture', 'requested_role', case when i in (9, 10) then 'driver' else 'tourist' end)
from generate_series(1, 10) i;
update public.profiles set status = 'active' where id::text like 'e5270000-%';

insert into public.driver_profiles(profile_id, plate_number, franchise_number, license_document_path,
  vehicle_document_path, approval_status, license_expires_on, franchise_expires_on,
  vehicle_inspection_expires_on, service_area_name, service_area_latitude, service_area_longitude,
  service_area_radius_km, is_online, last_seen_at)
select id, 'IMMED-' || right(id::text, 2), 'IMMED-FR-' || right(id::text, 2),
  id::text || '/license.jpg', id::text || '/vehicle.jpg', 'approved',
  current_date + 365, current_date + 365, current_date + 365, 'Immediate expiry fixture',
  14.9571, 120.9188, 15, false, null
from public.profiles where id::text like 'e5270000-%' and role = 'driver';

insert into public.fare_revisions(id, custom_fare_centavos, reason)
values ('e5270000-0000-4000-8000-0000000000f1', 10000, 'Immediate expiry fixture');
insert into public.cancellation_policies(id, terms)
values ('e5270000-0000-4000-8000-0000000000f2', 'Immediate expiry fixture');

-- 1 immediate, search ended 2 hours ago        -> expired
-- 2 immediate, search ended 10 minutes ago      -> inside the grace, stays
-- 3 immediate, search still open                -> stays
-- 4 accepted, search ended 2 days ago           -> stays
-- 5 ongoing,  search ended 2 days ago           -> stays
-- 6 immediate, search ended 2 days ago, paid    -> expired, refund_required
-- 7 scheduled for tomorrow, search ended 2 days ago -> stays (start not past)
-- 8 scheduled 2 hours ago (scheduled rule)      -> expired
insert into public.bookings(id, tourist_id, driver_id, fare_revision_id, cancellation_policy_id,
  quoted_amount_centavos, payment_method, status, pickup_address, pickup_latitude,
  pickup_longitude, pickup_code_hash, dispatch_expires_at, scheduled_at, accepted_at)
select ('e5270000-0000-4000-8000-' || lpad((100 + i)::text, 12, '0'))::uuid,
  ('e5270000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  case i when 4 then 'e5270000-0000-4000-8000-000000000009'::uuid
         when 5 then 'e5270000-0000-4000-8000-000000000010'::uuid end,
  'e5270000-0000-4000-8000-0000000000f1', 'e5270000-0000-4000-8000-0000000000f2',
  10000, 'cash',
  case i when 4 then 'accepted'::public.booking_status
         when 5 then 'ongoing'::public.booking_status
         else 'pending'::public.booking_status end,
  'Immediate expiry fixture', 14.9571, 120.9188, crypt('2468', gen_salt('bf')),
  case i when 1 then now() - interval '2 hours'
         when 2 then now() - interval '10 minutes'
         when 3 then now() + interval '10 minutes'
         when 8 then now() - interval '3 hours'
         else now() - interval '2 days' end,
  case i when 7 then now() + interval '1 day'
         when 8 then now() - interval '2 hours' end,
  case when i in (4, 5) then now() - interval '3 hours' end
from generate_series(1, 8) i;

insert into public.booking_offers(booking_id, driver_id, expires_at)
values ('e5270000-0000-4000-8000-000000000101', 'e5270000-0000-4000-8000-000000000009', now() + interval '1 hour');
insert into public.payments(booking_id, provider, provider_checkout_id, amount_centavos, status, paid_at)
values ('e5270000-0000-4000-8000-000000000106', 'paymongo', 'cs_expire_imm_6', 10000, 'paid', now() - interval '2 days');

-- The run: bookings 1, 6 (immediate) and 8 (scheduled).
select is(public.expire_stale_pending_bookings(), 3, 'two immediate and one scheduled booking are expired');

-- Immediate booking, search ended 2 hours ago.
select is((select status::text from public.bookings where id = 'e5270000-0000-4000-8000-000000000101'),
  'cancelled', 'an immediate booking whose search ended 2 hours ago is cancelled');
select is((select cancellation_reason from public.bookings where id = 'e5270000-0000-4000-8000-000000000101'),
  'No driver accepted during the driver search', 'the reason names the driver search');
select is((select final_charge_centavos from public.bookings where id = 'e5270000-0000-4000-8000-000000000101'),
  0, 'no charge for an unmatched booking');
select is((select payment_status::text from public.bookings where id = 'e5270000-0000-4000-8000-000000000101'),
  'waived', 'an unpaid expired booking is waived');
select is((select cancelled_by from public.bookings where id = 'e5270000-0000-4000-8000-000000000101'),
  null, 'no account is recorded as the canceller');
select isnt((select completed_at from public.bookings where id = 'e5270000-0000-4000-8000-000000000101'),
  null, 'the booking is closed');
select is((select status::text from public.booking_offers where booking_id = 'e5270000-0000-4000-8000-000000000101'),
  'expired', 'its open driver offer is expired');
select is((select payment_status::text from public.bookings where id = 'e5270000-0000-4000-8000-000000000106'),
  'refund_required', 'an expired immediate booking that was already paid is flagged for refund');
select is((select count(*)::integer from public.trip_events
  where booking_id = 'e5270000-0000-4000-8000-000000000101' and event_type = 'booking_cancelled'
    and actor_id is null and actor_role is null and metadata ->> 'actor' = 'system'
    and metadata ->> 'reason' = 'dispatch_window_expired'), 1,
  'one system-actor booking_cancelled event is logged');
select is((select count(*)::integer from public.notifications
  where booking_id = 'e5270000-0000-4000-8000-000000000101' and title = 'Booking cancelled'
    and recipient_id = 'e5270000-0000-4000-8000-000000000001'), 1,
  'the tourist is told through the existing event trigger');

-- The scheduled rule still works next to it.
select is((select cancellation_reason from public.bookings where id = 'e5270000-0000-4000-8000-000000000108'),
  'No driver accepted before the scheduled start', 'a scheduled booking past its start is still expired');
select is((select count(*)::integer from public.trip_events
  where booking_id = 'e5270000-0000-4000-8000-000000000108' and event_type = 'booking_cancelled'
    and actor_id is null and metadata ->> 'reason' = 'scheduled_start_passed'), 1,
  'with the scheduled reason on its event');

-- Nothing else moves.
select is((select status::text from public.bookings where id = 'e5270000-0000-4000-8000-000000000102'),
  'pending', 'an immediate booking whose search ended 10 minutes ago stays pending');
select is((select status::text from public.bookings where id = 'e5270000-0000-4000-8000-000000000103'),
  'pending', 'an immediate booking whose search window is still open stays pending');
select is((select status::text from public.bookings where id = 'e5270000-0000-4000-8000-000000000104'),
  'accepted', 'an accepted booking is not touched');
select is((select status::text from public.bookings where id = 'e5270000-0000-4000-8000-000000000105'),
  'ongoing', 'a started booking is not touched');
select is((select status::text from public.bookings where id = 'e5270000-0000-4000-8000-000000000107'),
  'pending', 'a scheduled booking whose start is still ahead is not touched');
select is((select count(*)::integer from public.trip_events
  where booking_id in ('e5270000-0000-4000-8000-000000000102', 'e5270000-0000-4000-8000-000000000103',
    'e5270000-0000-4000-8000-000000000104', 'e5270000-0000-4000-8000-000000000105',
    'e5270000-0000-4000-8000-000000000107') and event_type = 'booking_cancelled'), 0,
  'no cancel event for the bookings that were skipped');

-- Idempotent, and still not callable by clients.
select is(public.expire_stale_pending_bookings(), 0, 'a second run finds nothing to expire');
select is(has_function_privilege('authenticated', 'public.expire_stale_pending_bookings()', 'execute')
  or has_function_privilege('anon', 'public.expire_stale_pending_bookings()', 'execute'), false,
  'clients still cannot run the expiry');

select * from finish();
rollback;

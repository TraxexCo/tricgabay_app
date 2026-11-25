begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select plan(16);

insert into auth.users(id, email, raw_user_meta_data)
select ('b5110000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  'dispatch-retry-' || i || '@example.test',
  jsonb_build_object('full_name', 'Dispatch fixture', 'requested_role', case when i in (4, 5) then 'driver' else 'tourist' end)
from generate_series(1, 7) i;
update public.profiles set status = 'active' where id::text like 'b5110000-%';

insert into public.driver_profiles(profile_id, plate_number, franchise_number, license_document_path,
  vehicle_document_path, approval_status, license_expires_on, franchise_expires_on,
  vehicle_inspection_expires_on, service_area_name, service_area_latitude, service_area_longitude,
  service_area_radius_km, is_online, last_seen_at)
select id, 'DISPATCH-' || right(id::text, 1), 'DISPATCH-FR-' || right(id::text, 1),
  id::text || '/license.jpg', id::text || '/vehicle.jpg', 'approved',
  current_date + 365, current_date + 365, current_date + 365, 'Dispatch fixture',
  14.9571, 120.9188, 15, false, null
from public.profiles where id::text like 'b5110000-%' and role = 'driver';

insert into public.fare_revisions(id, custom_fare_centavos, reason)
values ('b5120000-0000-4000-8000-000000000001', 10000, 'Dispatch fixture');
insert into public.cancellation_policies(id, terms)
values ('b5120000-0000-4000-8000-000000000002', 'Dispatch fixture');

insert into public.bookings(id, tourist_id, fare_revision_id, cancellation_policy_id,
  quoted_amount_centavos, payment_method, status, pickup_address, pickup_latitude,
  pickup_longitude, pickup_code_hash, dispatch_expires_at)
select ('b5130000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  ('b5110000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  'b5120000-0000-4000-8000-000000000001', 'b5120000-0000-4000-8000-000000000002',
  10000, case when i = 3 then 'paymongo'::public.payment_method else 'cash'::public.payment_method end,
  case when i = 3 then 'payment_pending'::public.booking_status else 'pending'::public.booking_status end,
  'Dispatch fixture', 14.9571, 120.9188, crypt('2468', gen_salt('bf')),
  case when i = 2 then now() - interval '1 minute' else now() + interval '10 minutes' end
from generate_series(1, 3) i;

select is(public.create_ranked_driver_offers('b5130000-0000-4000-8000-000000000001'), 0,
  'booking created before the driver goes online has no initial offer');

select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config('request.jwt.claim.sub', 'b5110000-0000-4000-8000-000000000004', true);
set local role authenticated;
select public.set_driver_online(true);
reset role;
select dispatch_internal.retry_waiting_bookings();
select is((select count(*)::integer from public.booking_offers where booking_id::text like 'b5130000-%'), 0,
  'online alone does not dispatch without fresh GPS');

update public.driver_profiles set is_online = true, last_seen_at = now() - interval '3 minutes'
where profile_id = 'b5110000-0000-4000-8000-000000000005';
insert into public.driver_locations(driver_id, latitude, longitude, recorded_at)
values ('b5110000-0000-4000-8000-000000000005', 14.9571, 120.9188, now() - interval '3 minutes');
set local role authenticated;
select public.publish_driver_location_with_flags(14.9571, 120.9188, 5, 0, 0, now(), false);
reset role;
select is((select count(*)::integer from public.booking_offers where booking_id = 'b5130000-0000-4000-8000-000000000001'
  and driver_id = 'b5110000-0000-4000-8000-000000000004' and status = 'offered'), 1,
  'the first fresh location sends the offer without a tourist refresh or cron tick');
select is((select count(*)::integer from public.booking_offers where booking_id::text like 'b5130000-%'
  and driver_id = 'b5110000-0000-4000-8000-000000000005'), 0, 'stale GPS stays ineligible');
select is((select count(*)::integer from public.booking_offers where booking_id = 'b5130000-0000-4000-8000-000000000002'), 0,
  'expired search is skipped');
select is((select count(*)::integer from public.booking_offers where booking_id = 'b5130000-0000-4000-8000-000000000003'), 0,
  'payment-pending booking is skipped');
select dispatch_internal.retry_waiting_bookings();
select is((select count(*)::integer from public.booking_offers where booking_id = 'b5130000-0000-4000-8000-000000000001'), 1,
  'repeated background retries do not duplicate offers');

set local role authenticated;
select is((select count(*)::integer from public.bookings where id = 'b5130000-0000-4000-8000-000000000001'), 1,
  'matched driver can read the request under app RLS');
select set_config('request.jwt.claim.sub', 'b5110000-0000-4000-8000-000000000005', true);
select is((select count(*)::integer from public.bookings where id = 'b5130000-0000-4000-8000-000000000001'), 0,
  'unmatched driver cannot read the request under app RLS');
select set_config('request.jwt.claim.sub', 'b5110000-0000-4000-8000-000000000004', true);
select public.decline_booking_offer('b5130000-0000-4000-8000-000000000001');
reset role;
select dispatch_internal.retry_waiting_bookings();
select is((select status from public.booking_offers where booking_id = 'b5130000-0000-4000-8000-000000000001'), 'declined',
  'background retries respect an explicit decline');

insert into public.bookings(id, tourist_id, fare_revision_id, cancellation_policy_id,
  quoted_amount_centavos, payment_method, status, pickup_address, pickup_latitude,
  pickup_longitude, pickup_code_hash)
select ('b5130000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  ('b5110000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  'b5120000-0000-4000-8000-000000000001', 'b5120000-0000-4000-8000-000000000002',
  10000, 'cash', 'pending', 'Dispatch fixture', 14.9571, 120.9188, crypt('2468', gen_salt('bf'))
from generate_series(6, 7) i;

select public.publish_driver_location_with_flags(14.9571, 120.9188, 5, 0, 0, now(), false);
select is((select count(*)::integer from public.booking_offers where booking_id in
  ('b5130000-0000-4000-8000-000000000006', 'b5130000-0000-4000-8000-000000000007')), 0,
  'ordinary GPS samples do not rerun immediate dispatch');
select dispatch_internal.retry_waiting_bookings();
select is((select count(*)::integer from public.booking_offers where booking_id = 'b5130000-0000-4000-8000-000000000006'
  and driver_id = 'b5110000-0000-4000-8000-000000000004' and status = 'offered'), 1,
  'periodic matching still picks up a request skipped by the immediate path');
delete from public.booking_offers where booking_id = 'b5130000-0000-4000-8000-000000000007';

select public.set_driver_online(false);
update public.driver_locations set updated_at = now() - interval '1 minute'
where driver_id = 'b5110000-0000-4000-8000-000000000004';
select public.set_driver_online(true);
select is((select count(*)::integer from public.booking_offers where booking_id = 'b5130000-0000-4000-8000-000000000007'), 0,
  'going online does not offer the booking before the new location is uploaded');
select public.publish_driver_location_with_flags(14.9571, 120.9188, 5, 0, 0, now(), false);
select is((select count(*)::integer from public.booking_offers where booking_id = 'b5130000-0000-4000-8000-000000000007'
  and driver_id = 'b5110000-0000-4000-8000-000000000004' and status = 'offered'), 1,
  'a driver returning online also matches on the next accepted location');

select ok(not has_schema_privilege('authenticated', 'dispatch_internal', 'USAGE')
  and not has_schema_privilege('anon', 'dispatch_internal', 'USAGE'), 'dispatch worker is private');
select ok(exists(select 1 from cron.job where jobname = 'tric-gabay-retry-waiting-dispatch'
  and active and schedule = '30 seconds'), 'background retry is scheduled every 30 seconds');

select * from finish();
rollback;

begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select plan(61);

insert into auth.users(id, email, raw_user_meta_data)
select ('b6150000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  'gcash-fixture-' || i || '@example.test',
  jsonb_build_object('full_name', 'GCash fixture', 'requested_role', case when i in (3,4) then 'driver' else 'tourist' end)
from generate_series(1,7) i;
update public.profiles set status = 'active' where id::text like 'b6150000-%';
update public.profiles set role = 'admin' where id = 'b6150000-0000-4000-8000-000000000005';
insert into public.driver_profiles(profile_id, plate_number, franchise_number, approval_status)
select id, 'GCASH-' || right(id::text,1), 'GCASH-FR-' || right(id::text,1), 'approved'
from public.profiles where id::text like 'b6150000-%' and role = 'driver';

insert into public.fare_revisions(id, custom_fare_centavos, reason)
values ('b6160000-0000-4000-8000-000000000001', 15000, 'GCash fixture');
insert into public.cancellation_policies(id, terms)
values ('b6160000-0000-4000-8000-000000000002', 'GCash fixture');
insert into public.bookings(id, tourist_id, driver_id, fare_revision_id, cancellation_policy_id,
  quoted_amount_centavos, final_charge_centavos, payment_method, status, pickup_address,
  pickup_latitude, pickup_longitude, pickup_code_hash)
select ('b6170000-0000-4000-8000-' || lpad(i::text,12,'0'))::uuid,
  'b6150000-0000-4000-8000-000000000001',
  case when i=4 then 'b6150000-0000-4000-8000-000000000004'::uuid
       else 'b6150000-0000-4000-8000-000000000003'::uuid end,
  'b6160000-0000-4000-8000-000000000001', 'b6160000-0000-4000-8000-000000000002',
  15000, 13750, 'gcash_direct',
  case i when 5 then 'cancelled'::public.booking_status
         when 6 then 'ongoing'::public.booking_status
         else 'completed'::public.booking_status end,
  'GCash fixture', 14.9571, 120.9188, 'fixture'
from generate_series(1,6) i;

select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','b6150000-0000-4000-8000-000000000003',true);
set local role authenticated;
select lives_ok($$ insert into public.driver_gcash_details(driver_id,gcash_number,gcash_account_name,is_active)
 values ('b6150000-0000-4000-8000-000000000003','09171234567','Fixture Driver',true)
 on conflict (driver_id) do update set driver_id=excluded.driver_id,
   gcash_number=excluded.gcash_number,gcash_account_name=excluded.gcash_account_name,is_active=excluded.is_active $$,
 'driver can upsert their own details using the mobile API column set');
select lives_ok($$ insert into public.driver_gcash_details(driver_id,gcash_number,gcash_account_name,is_active)
 values ('b6150000-0000-4000-8000-000000000003','09171234567','Fixture Driver',true)
 on conflict (driver_id) do update set driver_id=excluded.driver_id,
   gcash_number=excluded.gcash_number,gcash_account_name=excluded.gcash_account_name,is_active=excluded.is_active $$,
 'driver can update an existing row');
select throws_ok($$ insert into public.driver_gcash_details(driver_id,gcash_number,gcash_account_name)
 values ('b6150000-0000-4000-8000-000000000004','09171234567','Fixture Driver') $$,
 '42501', null, 'driver cannot insert details for another driver');
select throws_ok($$ select public.get_booking_driver_gcash('b6170000-0000-4000-8000-000000000001') $$,
 '42501',null,'driver cannot use the tourist payee lookup');

select set_config('request.jwt.claim.sub','b6150000-0000-4000-8000-000000000004',true);
select is((select count(*)::int from public.driver_gcash_details),0,'another driver cannot read details');
select throws_ok($$ select public.driver_confirm_gcash_received('b6170000-0000-4000-8000-000000000001') $$,
 '42501',null,'unassigned driver cannot confirm');
select throws_ok($$ select public.driver_flag_gcash_not_received('b6170000-0000-4000-8000-000000000001') $$,
 '42501',null,'unassigned driver cannot dispute');

select set_config('request.jwt.claim.sub','b6150000-0000-4000-8000-000000000005',true);
select is((select count(*)::int from public.driver_gcash_details),1,'admin can read driver GCash details');
with changed as (update public.driver_gcash_details set is_active=false returning 1)
select is((select count(*)::int from changed),0,'admin does not edit driver-supplied information');

select set_config('request.jwt.claim.sub','b6150000-0000-4000-8000-000000000002',true);
select is((select count(*)::int from public.get_booking_driver_gcash('b6170000-0000-4000-8000-000000000001')),0,
 'tourist cannot fetch another booking payee');

select set_config('request.jwt.claim.sub','b6150000-0000-4000-8000-000000000001',true);
select is((select count(*)::int from public.driver_gcash_details),0,'tourist has no direct detail rows');
select throws_ok($$ select * from public.gcash_payment_confirmations $$,'42501',null,
 'private confirmations have no direct client access');
select is((select fare_centavos from public.get_booking_driver_gcash('b6170000-0000-4000-8000-000000000001')),13750,
 'payee RPC returns the saved final charge, not the quote');
select is((select count(*)::int from public.get_booking_driver_gcash('b6170000-0000-4000-8000-000000000004')),0,
 'missing or inactive driver details yield no payee');
select is((select count(*)::int from public.get_booking_driver_gcash('b6170000-0000-4000-8000-000000000006')),0,
 'ongoing trips do not reveal a payee');
select throws_ok($$ select public.tourist_mark_gcash_sent('b6170000-0000-4000-8000-000000000005') $$,
 'P0001','GCash payment is unavailable for this trip','cancelled trip cannot enter the payment flow');
select throws_ok($$ select public.tourist_mark_gcash_sent('b6170000-0000-4000-8000-000000000006') $$,
 'P0001','GCash payment is unavailable for this trip','ongoing trip cannot enter the payment flow');
select throws_ok($$ select public.tourist_mark_gcash_sent('b6170000-0000-4000-8000-000000000001','invalid ref') $$,
 'P0001','Invalid GCash reference format','invalid reference is rejected on the server');
select throws_ok($$ select public.driver_confirm_gcash_received('b6170000-0000-4000-8000-000000000001') $$,
 '42501',null,'tourist cannot confirm as the driver');
select throws_ok($$ select public.driver_flag_gcash_not_received('b6170000-0000-4000-8000-000000000001') $$,
 '42501',null,'tourist cannot dispute as the driver');
select lives_ok($$ select public.tourist_mark_gcash_sent('b6170000-0000-4000-8000-000000000001') $$,'reporting requires no reference');
select lives_ok($$ select public.tourist_mark_gcash_sent('b6170000-0000-4000-8000-000000000001',' REFC1234 ') $$,'retry can add a reference');

reset role;
select is((select count(*)::int from public.notifications
 where booking_id='b6170000-0000-4000-8000-000000000001' and title='GCash payment update'),1,
 'report retries do not duplicate notifications');
select is((select count(*)::int from public.message_deliveries
 where booking_id='b6170000-0000-4000-8000-000000000001' and channel='push' and title='GCash payment update'),1,
 'notification uses the existing push queue');
select is((select count(*)::int from public.message_deliveries
 where booking_id='b6170000-0000-4000-8000-000000000001' and row_to_json(message_deliveries)::text ~ 'REFC1234|09171234567'),0,
 'push delivery rows contain no payee number or reference');

select set_config('request.jwt.claim.sub','b6150000-0000-4000-8000-000000000003',true);
set local role authenticated;
select is(public.get_booking_gcash_reference('b6170000-0000-4000-8000-000000000001'),'REFC1234',
 'assigned driver sees the trimmed reference');
select lives_ok($$ select public.driver_flag_gcash_not_received('b6170000-0000-4000-8000-000000000001','Check receipt') $$,'assigned driver can flag nonreceipt');
select is((select payment_status::text from public.bookings where id='b6170000-0000-4000-8000-000000000001'),'disputed',
 'nonreceipt sets disputed status');
select lives_ok($$ select public.driver_confirm_gcash_received('b6170000-0000-4000-8000-000000000002') $$,
 'driver can confirm without a prior tourist signal');
select lives_ok($$ select public.driver_confirm_gcash_received('b6170000-0000-4000-8000-000000000002') $$,
 'confirm retry succeeds');
select throws_ok($$ select public.driver_flag_gcash_not_received('b6170000-0000-4000-8000-000000000002') $$,
 'P0001','GCash payment is no longer due','driver cannot dispute a paid fare');

select set_config('request.jwt.claim.sub','b6150000-0000-4000-8000-000000000001',true);
select throws_ok($$ select public.tourist_switch_gcash_to_cash('b6170000-0000-4000-8000-000000000002') $$,
 'P0001','GCash payment is no longer due','paid fare cannot be switched to cash');
select throws_ok($$ select public.tourist_mark_gcash_sent('b6170000-0000-4000-8000-000000000002') $$,
 'P0001','GCash payment is no longer due','paid fare cannot be reported again');
select throws_ok($$ select public.open_dispute('b6170000-0000-4000-8000-000000000002','Legacy review request') $$,
 'P0001','Confirmed GCash payment cannot be changed','legacy review cannot reopen a confirmed GCash fare');
select lives_ok($$ select public.tourist_mark_gcash_sent('b6170000-0000-4000-8000-000000000001','NEXT1234') $$,
 'tourist may report again from disputed');
select is((select payment_status::text from public.bookings where id='b6170000-0000-4000-8000-000000000001'),
 'gcash_awaiting_confirmation','report after dispute returns to awaiting driver');

select set_config('request.jwt.claim.sub','b6150000-0000-4000-8000-000000000003',true);
select lives_ok($$ select public.driver_flag_gcash_not_received('b6170000-0000-4000-8000-000000000001') $$,'driver may dispute again');
select set_config('request.jwt.claim.sub','b6150000-0000-4000-8000-000000000001',true);
select lives_ok($$ select public.tourist_switch_gcash_to_cash('b6170000-0000-4000-8000-000000000001') $$,'tourist can switch a disputed fare to cash');
select lives_ok($$ select public.tourist_switch_gcash_to_cash('b6170000-0000-4000-8000-000000000001') $$,'cash switch can be retried');
select lives_ok($$ select public.confirm_cash('b6170000-0000-4000-8000-000000000001','payment') $$,'tourist uses existing cash confirmation');
select set_config('request.jwt.claim.sub','b6150000-0000-4000-8000-000000000003',true);
select throws_ok($$ select public.driver_confirm_gcash_received('b6170000-0000-4000-8000-000000000001') $$,
 'P0001','GCash payment is no longer due','GCash cannot be confirmed after cash fallback');
select lives_ok($$ select public.confirm_cash('b6170000-0000-4000-8000-000000000001','payment') $$,'driver uses existing cash confirmation');
reset role;
select is((select payment_status::text from public.bookings where id='b6170000-0000-4000-8000-000000000002'),'gcash_paid',
 'rejected review leaves the booking paid');
select is((select count(*)::int from public.disputes where booking_id='b6170000-0000-4000-8000-000000000002'),0,
 'rejected review rolls back the inserted dispute');
select is((select payment_status::text from public.bookings where id='b6170000-0000-4000-8000-000000000001'),'cash_paid',
 'two cash confirmations still complete the payment');
select is((select count(*)::int from public.gcash_payment_confirmations where booking_id='b6170000-0000-4000-8000-000000000001'),0,
 'cash fallback clears direct GCash confirmation and dispute data');
select is((select count(*)::int from public.payments where booking_id='b6170000-0000-4000-8000-000000000002'),1,
 'confirmation retry creates exactly one payment row');
select is((select amount_centavos from public.payments where booking_id='b6170000-0000-4000-8000-000000000002'
 and provider='gcash_direct'),13750,'payment amount matches the final fare');
select is((select count(*)::int from public.financial_ledger_entries
 where booking_id='b6170000-0000-4000-8000-000000000002'),0,'no ledger entry is created for direct GCash');

-- Exercise the real initial dispatch path with the same eligible driver for
-- both methods. Separate tourists avoid the single-active-booking guard.
update public.fare_revisions set is_current=false where is_current;
update public.fare_revisions set is_current=true where id='b6160000-0000-4000-8000-000000000001';
update public.cancellation_policies set is_current=false where is_current;
update public.cancellation_policies set is_current=true where id='b6160000-0000-4000-8000-000000000002';
insert into public.tourist_spots(id,name,category,address,latitude,longitude)
values ('gcash-fixture-stop','GCash fixture stop','other','GCash fixture',14.9571,120.9188);
update public.driver_profiles set
  license_document_path=profile_id::text || '/license.jpg',
  vehicle_document_path=profile_id::text || '/vehicle.jpg',
  license_expires_on=current_date+365, franchise_expires_on=current_date+365,
  vehicle_inspection_expires_on=current_date+365,
  service_area_name='GCash fixture', service_area_latitude=14.9571,
  service_area_longitude=120.9188, service_area_radius_km=15,
  is_online=true, last_seen_at=now()
where profile_id='b6150000-0000-4000-8000-000000000004';
insert into public.driver_locations(driver_id,latitude,longitude,recorded_at)
values ('b6150000-0000-4000-8000-000000000004',14.9571,120.9188,now());

select set_config('request.jwt.claim.sub','b6150000-0000-4000-8000-000000000002',true);
set local role authenticated;
select lives_ok($$ select public.create_booking_with_schedule(
 null,'cash','GCash fixture pickup',14.9571,120.9188,
 '[{"spot_id":"gcash-fixture-stop","stop_order":1}]',1,'','',null,
 'b6180000-0000-4000-8000-000000000001') $$,'cash creates a booking through the public RPC');
select set_config('request.jwt.claim.sub','b6150000-0000-4000-8000-000000000006',true);
select lives_ok($$ select public.create_booking_with_schedule(
 null,'gcash_direct','GCash fixture pickup',14.9571,120.9188,
 '[{"spot_id":"gcash-fixture-stop","stop_order":1}]',1,'','',null,
 'b6180000-0000-4000-8000-000000000002') $$,'tourist creates direct GCash through the public RPC');
reset role;
select is((select payment_method::text from public.bookings where client_request_id='b6180000-0000-4000-8000-000000000002'),
 'gcash_direct','the RPC saves direct GCash as the method');
select is((select payment_status::text from public.bookings where client_request_id='b6180000-0000-4000-8000-000000000002'),
 'unpaid','direct GCash starts unpaid');
select is((select status::text from public.bookings where client_request_id='b6180000-0000-4000-8000-000000000002'),
 'pending','direct GCash enters dispatch instead of waiting for payment');
select is((select count(*)::int from public.booking_offers o join public.bookings b on b.id=o.booking_id
 where b.client_request_id='b6180000-0000-4000-8000-000000000001'
 and o.driver_id='b6150000-0000-4000-8000-000000000004' and o.status='offered'),1,'cash immediately offers to the eligible driver');
select is((select count(*)::int from public.booking_offers o join public.bookings b on b.id=o.booking_id
 where b.client_request_id='b6180000-0000-4000-8000-000000000002'
 and o.driver_id='b6150000-0000-4000-8000-000000000004' and o.status='offered'),1,'direct GCash immediately offers to the same driver');

update public.profiles set status='suspended' where id='b6150000-0000-4000-8000-000000000007';
select set_config('request.jwt.claim.sub','b6150000-0000-4000-8000-000000000007',true);
set local role authenticated;
select throws_ok($$ select public.create_booking_with_schedule(
 null,'cash','GCash fixture pickup',14.9571,120.9188,
 '[{"spot_id":"gcash-fixture-stop","stop_order":1}]',1,'','',null,gen_random_uuid()) $$,
 '42501','Active trip participant account required','inactive tourist cannot book with cash');
select throws_ok($$ select public.create_booking_with_schedule(
 null,'gcash_direct','GCash fixture pickup',14.9571,120.9188,
 '[{"spot_id":"gcash-fixture-stop","stop_order":1}]',1,'','',null,gen_random_uuid()) $$,
 '42501','Active trip participant account required','inactive tourist cannot book with direct GCash');
reset role;
update public.profiles set status='active' where id='b6150000-0000-4000-8000-000000000007';
update public.fare_revisions set is_current=false where is_current;
set local role authenticated;
select throws_ok($$ select public.create_booking_with_schedule(
 null,'cash','GCash fixture pickup',14.9571,120.9188,
 '[{"spot_id":"gcash-fixture-stop","stop_order":1}]',1,'','',null,gen_random_uuid()) $$,
 'P0001','Published fare or cancellation policy is unavailable','cash rejects a missing published fare');
select throws_ok($$ select public.create_booking_with_schedule(
 null,'gcash_direct','GCash fixture pickup',14.9571,120.9188,
 '[{"spot_id":"gcash-fixture-stop","stop_order":1}]',1,'','',null,gen_random_uuid()) $$,
 'P0001','Published fare or cancellation policy is unavailable','direct GCash rejects a missing published fare');
reset role;

select is((select count(*)::int from pg_publication_tables
 where schemaname='public' and tablename in ('driver_gcash_details','gcash_payment_confirmations')),
 0,'neither private GCash table is published');

select * from finish();
rollback;

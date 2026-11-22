-- Booking request contracts: client request IDs, the live payment methods,
-- the pickup area and pickup-code reissue. The PayMongo hold-until-paid and
-- late-payment checks were retired with PayMongo on 2026-11-20; a PayMongo
-- request is now refused outright.
begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;
select plan(16);
select is(has_function_privilege('authenticated','public.create_booking(text,public.payment_method,text,double precision,double precision,jsonb)','execute'),false,'base creator cannot bypass request IDs');
select is(has_function_privilege('anon','public.reissue_booking_pickup_code(uuid,uuid,text)','execute'),false,'anonymous code rotation denied');
select is(has_function_privilege('authenticated','public.prepare_account_deletion(uuid,uuid)','execute'),false,'clients cannot use service deletion RPC');
select is(has_function_privilege('anon','public.get_client_configuration()','execute'),true,'signed-out clients can check minimum version');
insert into auth.users(id,email,raw_user_meta_data) values
  ('b2000000-0000-4000-8000-000000000001','batch2@example.test','{"full_name":"Batch Two"}'),
  ('b2000000-0000-4000-8000-000000000021','batch2-gcash@example.test','{"full_name":"Batch Two GCash"}');
update public.fare_revisions set is_current=false where is_current;
insert into public.fare_revisions(custom_fare_centavos,package_fares,is_current,reason) values(10000,'{}',true,'Batch two test fare');
update public.cancellation_policies set is_current=false where is_current;
insert into public.cancellation_policies(is_current,terms) values(true,'Batch two test policy');
insert into public.tourist_spots(id,name,category,address,latitude,longitude) values('batch-two-stop','Test stop','other','Test address',14.9571,120.9188);
select set_config('request.jwt.claim.sub','b2000000-0000-4000-8000-000000000001',true);
select set_config('request.jwt.claim.role','authenticated',true);

-- PayMongo is gone: the request is refused before anything is stored.
select throws_ok($$select public.create_booking_with_schedule(null,'paymongo','Test pickup',14.9571,120.9188,
  '[{"spot_id":"batch-two-stop","stop_order":1}]',1,'','',null,'b2000000-0000-4000-8000-000000000009')$$,
  'P0001','ONLINE_PAYMENT_UNAVAILABLE','an online (PayMongo) request is refused');
select is((select count(*)::integer from public.bookings where client_request_id='b2000000-0000-4000-8000-000000000009'),0,'a refused online request stores nothing');

-- Cash and GCash bookings go straight to driver matching, unpaid.
create temp table batch_two_result as select public.create_booking_with_schedule(null,'cash','Test pickup',centre_latitude,centre_longitude,
  '[{"spot_id":"batch-two-stop","stop_order":1}]',1,'','',null,'b2000000-0000-4000-8000-000000000002') as result from public.service_configuration;
select is((select status::text from public.bookings where client_request_id='b2000000-0000-4000-8000-000000000002'),'pending','a cash request goes straight to driver matching');
select is((select payment_status::text from public.bookings where client_request_id='b2000000-0000-4000-8000-000000000002'),'unpaid','a cash request starts unpaid');

-- The same request ID is idempotent; a changed payload under it is refused.
select is((select public.create_booking_with_schedule(null,'cash','Test pickup',centre_latitude,centre_longitude,
  '[{"spot_id":"batch-two-stop","stop_order":1}]',1,'','',null,'b2000000-0000-4000-8000-000000000002')->>'booking_id' from public.service_configuration),
  (select result->>'booking_id' from batch_two_result),'repeated request returns the original booking');
select throws_ok($$select public.create_booking_with_schedule(null,'cash','Changed pickup',14.9571,120.9188,'[{"spot_id":"batch-two-stop","stop_order":1}]',1,'','',null,'b2000000-0000-4000-8000-000000000002')$$,'P0001','Booking request conflict','same UUID with changed payload fails');
select throws_ok($$select public.create_booking_with_schedule(null,'cash','Test pickup',14.9571,120.9188,'[{"spot_id":"batch-two-stop","stop_order":1}]',1,'','',null,'b2000000-0000-4000-8000-000000000005')$$,'P0001','Finish or cancel the active booking first','a new request ID cannot start a second active booking');
select throws_ok($$select public.require_pickup_in_service_area(0,0)$$,'P0001','Pickup is outside the service area','outside pickup rejected');

-- Pickup-code reissue.
select lives_ok($$select public.reissue_booking_pickup_code((select (result->>'booking_id')::uuid from batch_two_result),
  'b2000000-0000-4000-8000-000000000003',case when (select result->>'pickup_code' from batch_two_result)='1111' then '2222' else '1111' end)$$,'owner can reissue code');
select is((select crypt((select result->>'pickup_code' from batch_two_result),pickup_code_hash)=pickup_code_hash from public.bookings where client_request_id='b2000000-0000-4000-8000-000000000002'),false,'old pickup code is invalidated');
select throws_ok($$select public.reissue_booking_pickup_code((select (result->>'booking_id')::uuid from batch_two_result),
  'b2000000-0000-4000-8000-000000000004','3333')$$,'P0001','Wait before requesting another pickup code','reissue is rate-limited');

-- A direct-GCash request is dispatched the same way (paid to the driver later).
select set_config('request.jwt.claim.sub','b2000000-0000-4000-8000-000000000021',true);
create temp table batch_two_gcash as select public.create_booking_with_schedule(null,'gcash_direct','Test pickup',centre_latitude,centre_longitude,
  '[{"spot_id":"batch-two-stop","stop_order":1}]',1,'','',null,'b2000000-0000-4000-8000-000000000022') as result from public.service_configuration;
select is((select status::text from public.bookings where id=(select (result->>'booking_id')::uuid from batch_two_gcash)),
  'pending','a direct-GCash request goes straight to driver matching');
select * from finish();
rollback;

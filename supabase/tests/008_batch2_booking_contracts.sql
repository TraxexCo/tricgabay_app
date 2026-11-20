-- Intended pgTAP coverage. NOT RUN: new migrations are file-only in this batch.
begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;
select plan(15);
select is(has_function_privilege('authenticated','public.create_booking(text,public.payment_method,text,double precision,double precision,jsonb)','execute'),false,'base creator cannot bypass request IDs');
select is(has_function_privilege('anon','public.reissue_booking_pickup_code(uuid,uuid,text)','execute'),false,'anonymous code rotation denied');
select is(has_function_privilege('authenticated','public.prepare_account_deletion(uuid,uuid)','execute'),false,'clients cannot use service deletion RPC');
select is(has_function_privilege('anon','public.get_client_configuration()','execute'),true,'signed-out clients can check minimum version');
insert into auth.users(id,email,raw_user_meta_data) values('b2000000-0000-4000-8000-000000000001','batch2@example.test','{"full_name":"Batch Two"}');
update public.fare_revisions set is_current=false where is_current;
insert into public.fare_revisions(custom_fare_centavos,package_fares,is_current,reason) values(10000,'{}',true,'Batch two test fare');
update public.cancellation_policies set is_current=false where is_current;
insert into public.cancellation_policies(is_current,terms) values(true,'Batch two test policy');
insert into public.tourist_spots(id,name,category,address,latitude,longitude) values('batch-two-stop','Test stop','other','Test address',14.9571,120.9188);
select set_config('request.jwt.claim.sub','b2000000-0000-4000-8000-000000000001',true);
select set_config('request.jwt.claim.role','authenticated',true);
create temp table batch_two_result as select public.create_booking_with_schedule(null,'paymongo','Test pickup',centre_latitude,centre_longitude,
  '[{"spot_id":"batch-two-stop","stop_order":1}]',1,'','',null,'b2000000-0000-4000-8000-000000000002') as result from public.service_configuration;
select is((select status::text from public.bookings where client_request_id='b2000000-0000-4000-8000-000000000002'),'payment_pending','online booking held before payment');
select is((select count(*)::integer from public.booking_offers where booking_id=(select (result->>'booking_id')::uuid from batch_two_result)),0,'unpaid booking has no driver offers');
select is((select public.create_booking_with_schedule(null,'paymongo','Test pickup',centre_latitude,centre_longitude,
  '[{"spot_id":"batch-two-stop","stop_order":1}]',1,'','',null,'b2000000-0000-4000-8000-000000000002')->>'booking_id' from public.service_configuration),
  (select result->>'booking_id' from batch_two_result),'repeated request returns the original booking');
select throws_ok($$select public.create_booking_with_schedule(null,'cash','Changed pickup',14.9571,120.9188,'[{"spot_id":"batch-two-stop","stop_order":1}]',1,'','',null,'b2000000-0000-4000-8000-000000000002')$$,'P0001','Booking request conflict','same UUID with changed payload fails');
select throws_ok($$select public.require_pickup_in_service_area(0,0)$$,'P0001','Pickup is outside the service area','outside pickup rejected');
update public.bookings set payment_status='paid' where client_request_id='b2000000-0000-4000-8000-000000000002';
select is((select status::text from public.bookings where client_request_id='b2000000-0000-4000-8000-000000000002'),'pending','confirmed payment releases dispatch');
select lives_ok($$select public.reissue_booking_pickup_code((select (result->>'booking_id')::uuid from batch_two_result),
  'b2000000-0000-4000-8000-000000000003',case when (select result->>'pickup_code' from batch_two_result)='1111' then '2222' else '1111' end)$$,'owner can reissue code');
select is((select crypt((select result->>'pickup_code' from batch_two_result),pickup_code_hash)=pickup_code_hash from public.bookings where client_request_id='b2000000-0000-4000-8000-000000000002'),false,'old pickup code is invalidated');
select throws_ok($$select public.reissue_booking_pickup_code((select (result->>'booking_id')::uuid from batch_two_result),
  'b2000000-0000-4000-8000-000000000004','3333')$$,'P0001','Wait before requesting another pickup code','reissue is rate-limited');
insert into auth.users(id,email,raw_user_meta_data) values('b2000000-0000-4000-8000-000000000011','batch2-expiry@example.test','{"full_name":"Expiry Test"}');
insert into public.bookings(tourist_id,fare_revision_id,cancellation_policy_id,quoted_amount_centavos,payment_method,payment_status,pickup_address,pickup_latitude,pickup_longitude,pickup_code_hash)
  select 'b2000000-0000-4000-8000-000000000011',f.id,c.id,10000,'paymongo','unpaid','Test expiry',14.9571,120.9188,crypt('1234',gen_salt('bf')) from public.fare_revisions f cross join public.cancellation_policies c where f.is_current and c.is_current;
update public.bookings set payment_expires_at=now()-interval '1 minute' where tourist_id='b2000000-0000-4000-8000-000000000011';
update public.bookings set payment_status='paid' where tourist_id='b2000000-0000-4000-8000-000000000011';
select is((select status::text from public.bookings where tourist_id='b2000000-0000-4000-8000-000000000011'),'cancelled','late payment cannot dispatch an expired request');
select is((select payment_status::text from public.bookings where tourist_id='b2000000-0000-4000-8000-000000000011'),'refund_required','late payment is held for refund');
select * from finish();
rollback;

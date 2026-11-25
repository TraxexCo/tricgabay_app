begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;
select plan(32);

select is(has_function_privilege('authenticated','public.generate_secure_pickup_code()','execute'),false,
  'pickup-code generator is not a client RPC');
select is(has_function_privilege('anon','public.recover_booking_pickup_code(uuid,uuid,text)','execute'),false,
  'anonymous callers cannot recover pickup codes');
select is(has_function_privilege('authenticated','public.recover_booking_pickup_code(uuid,uuid,text)','execute'),true,
  'authenticated callers reach the self-authorizing recovery RPC');
select is(has_function_privilege('service_role','public.record_paymongo_checkout(uuid,text,text,integer)','execute'),true,
  'service role can commit a provider checkout');
select is(has_function_privilege('authenticated','public.record_paymongo_checkout(uuid,text,text,integer)','execute'),false,
  'application users cannot commit provider checkout data');

select set_config('request.jwt.claim.role','',true);
select throws_ok($$
  select public.record_paymongo_checkout(
    '72000000-0000-4000-8000-000000000001','cs_null_role',
    'https://checkout.paymongo.com/cs_null_role',12500
  )
$$,'42501','Service role required','a null JWT role fails closed even for a direct owner-context call');

insert into auth.users(id,email,raw_user_meta_data)
values
  ('70000000-0000-4000-8000-000000000101','batch8-owner@test.local','{"full_name":"Batch 8 Owner"}'),
  ('70000000-0000-4000-8000-000000000102','batch8-other@test.local','{"full_name":"Batch 8 Other"}'),
  ('70000000-0000-4000-8000-000000000103','batch8-driver@test.local','{"full_name":"Batch 8 Driver","requested_role":"driver"}'),
  ('70000000-0000-4000-8000-000000000104','batch8-locked@test.local','{"full_name":"Batch 8 Locked Owner"}');
update public.profiles set status='active' where id='70000000-0000-4000-8000-000000000103';
insert into public.fare_revisions(id,custom_fare_centavos,package_fares,is_current,reason)
values ('71000000-0000-4000-8000-000000000001',12500,'{}',false,'Batch 8');
insert into public.cancellation_policies(id,is_current,terms)
values ('71000000-0000-4000-8000-000000000002',false,'Batch 8');
insert into public.bookings(
  id,tourist_id,fare_revision_id,cancellation_policy_id,quoted_amount_centavos,
  payment_method,payment_status,status,pickup_address,pickup_latitude,
  pickup_longitude,pickup_code_hash,pickup_code_failed_attempts,pickup_code_locked_until
) values
  ('72000000-0000-4000-8000-000000000001','70000000-0000-4000-8000-000000000101','71000000-0000-4000-8000-000000000001','71000000-0000-4000-8000-000000000002',12500,'paymongo','unpaid','pending','Batch 8',14.95,120.91,crypt('1111',gen_salt('bf')),3,null),
  ('72000000-0000-4000-8000-000000000002','70000000-0000-4000-8000-000000000101','71000000-0000-4000-8000-000000000001','71000000-0000-4000-8000-000000000002',12500,'cash','unpaid','completed','Batch 8',14.95,120.91,crypt('1111',gen_salt('bf')),0,null),
  ('72000000-0000-4000-8000-000000000003','70000000-0000-4000-8000-000000000104','71000000-0000-4000-8000-000000000001','71000000-0000-4000-8000-000000000002',12500,'cash','unpaid','accepted','Batch 8',14.95,120.91,crypt('1111',gen_salt('bf')),5,now()+interval '10 minutes'),
  ('72000000-0000-4000-8000-000000000004','70000000-0000-4000-8000-000000000102','71000000-0000-4000-8000-000000000001','71000000-0000-4000-8000-000000000002',12500,'paymongo','unpaid','pending','Batch 8',14.95,120.91,crypt('1111',gen_salt('bf')),0,null);

set local role service_role;
select set_config('request.jwt.claim.role','service_role',true);
select lives_ok($$
  select public.record_paymongo_checkout(
    '72000000-0000-4000-8000-000000000001','cs_batch8',
    'https://checkout.paymongo.com/cs_batch8#client-key',12500
  )
$$,'valid documented checkout identity commits');
reset role;
select is((select payment_status::text from public.bookings where id='72000000-0000-4000-8000-000000000001'),
  'checkout_created','checkout and booking state commit together');
select is((select count(*)::integer from public.payments where booking_id='72000000-0000-4000-8000-000000000001'),
  1,'checkout commit creates one payment');

set local role service_role;
select set_config('request.jwt.claim.role','service_role',true);
select is((public.record_paymongo_checkout(
  '72000000-0000-4000-8000-000000000001','cs_batch8',
  'https://checkout.paymongo.com/cs_batch8#client-key',12500)->>'reused')::boolean,
  true,'identical provider retry reuses local state');
select throws_ok($$
  select public.record_paymongo_checkout(
    '72000000-0000-4000-8000-000000000001','cs_inconsistent',
    'https://checkout.paymongo.com/cs_inconsistent',12500
  )
$$,'P0001','Stored checkout does not match the provider result','inconsistent provider identity is rejected');
select throws_ok($$
  select public.record_paymongo_checkout(
    '72000000-0000-4000-8000-000000000001','cs_batch8','https://evil.test/cs_batch8',12500
  )
$$,'P0001','Invalid checkout result','untrusted checkout host is rejected');
select throws_ok($$
  select public.record_paymongo_checkout(
    '72000000-0000-4000-8000-000000000001','invalid','https://checkout.paymongo.com/invalid',12500
  )
$$,'P0001','Invalid checkout result','malformed provider checkout ID is rejected');
select throws_ok($$
  select public.record_paymongo_checkout(
    '72000000-0000-4000-8000-000000000001','cs_batch8','https://checkout.paymongo.com/cs_batch8#client-key',12499
  )
$$,'P0001','Checkout amount does not match the booking quote','quote mismatch is rejected');
select throws_ok($$
  select public.record_paymongo_checkout(
    '72000000-0000-4000-8000-000000000004','cs_batch8',
    'https://checkout.paymongo.com/cs_batch8',12500
  )
$$,'23505','duplicate key value violates unique constraint "payments_provider_mode_provider_checkout_id_key"',
  'one provider checkout identifier cannot be attached to another booking');
reset role;
select is((select count(*)::integer from public.payments where booking_id='72000000-0000-4000-8000-000000000001'),
  1,'rejected retries create no duplicate payment');
select is((select count(*)::integer from public.payments where booking_id='72000000-0000-4000-8000-000000000004'),
  0,'duplicate provider identity leaves the second booking unchanged');

set local role authenticated;
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','70000000-0000-4000-8000-000000000101',true);
select is(public.recover_booking_pickup_code(
  '72000000-0000-4000-8000-000000000001','73000000-0000-4000-8000-000000000001','4827'),
  '4827','rightful tourist completes one recovery');
reset role;
select ok((select pickup_code_hash=crypt('4827',pickup_code_hash) from public.bookings
  where id='72000000-0000-4000-8000-000000000001'),'recovered code is hashed at rest');
select is((select pickup_code_failed_attempts from public.bookings where id='72000000-0000-4000-8000-000000000001'),
  3,'recovery does not reset failed-attempt state');

set local role authenticated;
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','70000000-0000-4000-8000-000000000101',true);
select is(public.recover_booking_pickup_code(
  '72000000-0000-4000-8000-000000000001','73000000-0000-4000-8000-000000000001','4827'),
  '4827','lost-response retry with the same request is idempotent');
reset role;
select is((select count(*)::integer from public.trip_events where booking_id='72000000-0000-4000-8000-000000000001'
  and event_type='pickup_code_recovered'),1,'idempotent retry emits one audit event');

set local role authenticated;
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','70000000-0000-4000-8000-000000000101',true);
select throws_ok($$select public.recover_booking_pickup_code(
  '72000000-0000-4000-8000-000000000001','73000000-0000-4000-8000-000000000002','1954')$$,
  'P0001','Pickup code recovery already completed','a second recovery request cannot rotate the code');
select throws_ok($$select public.recover_booking_pickup_code(
  '72000000-0000-4000-8000-000000000001','73000000-0000-4000-8000-000000000001','1954')$$,
  'P0001','Pickup code recovery already completed','same request ID cannot be replayed with a different code');
reset role;

set local role authenticated;
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','70000000-0000-4000-8000-000000000102',true);
select throws_ok($$select public.recover_booking_pickup_code(
  '72000000-0000-4000-8000-000000000001','73000000-0000-4000-8000-000000000003','2356')$$,
  'P0001','Recoverable booking not found','another tourist cannot recover the code');
reset role;

set local role authenticated;
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','70000000-0000-4000-8000-000000000103',true);
select throws_ok($$select public.recover_booking_pickup_code(
  '72000000-0000-4000-8000-000000000001','73000000-0000-4000-8000-000000000004','2356')$$,
  '42501','Active trip participant account required','driver cannot recover a tourist pickup code');
reset role;

set local role authenticated;
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','70000000-0000-4000-8000-000000000101',true);
select throws_ok($$select public.recover_booking_pickup_code(
  '72000000-0000-4000-8000-000000000002','73000000-0000-4000-8000-000000000005','2356')$$,
  'P0001','Recoverable booking not found','terminal booking cannot rotate a code');
select set_config('request.jwt.claim.sub','70000000-0000-4000-8000-000000000104',true);
select throws_ok($$select public.recover_booking_pickup_code(
  '72000000-0000-4000-8000-000000000003','73000000-0000-4000-8000-000000000006','2356')$$,
  'P0001','Pickup code is temporarily locked','recovery cannot bypass an active verification lockout');
select throws_ok($$select public.recover_booking_pickup_code(
  '72000000-0000-4000-8000-000000000003','73000000-0000-4000-8000-000000000006','12')$$,
  'P0001','Invalid pickup-code recovery request','recovery rejects codes outside the four-digit contract');
reset role;

select ok(not exists(select 1 from public.trip_events
  where booking_id='72000000-0000-4000-8000-000000000001'
    and (description like '%4827%' or metadata::text like '%4827%')),
  'audit event contains no plaintext pickup code');
select is((select pickup_code_recovery_id from public.bookings where id='72000000-0000-4000-8000-000000000001'),
  '73000000-0000-4000-8000-000000000001'::uuid,'booking binds recovery to one stable request');
select ok(not exists(
  select 1 from generate_series(1,1000)
  where public.generate_secure_pickup_code()!~'^[1-9][0-9]{3}$'
),'CSPRNG helper always returns a four-digit code in the documented 1000-9999 range');

select * from finish();
rollback;

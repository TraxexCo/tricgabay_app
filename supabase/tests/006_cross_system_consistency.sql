begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;
select plan(22);

select is(
  has_function_privilege('anon','public.record_paymongo_checkout(uuid,text,text,integer)','execute'),
  false,'anonymous callers cannot record provider checkouts'
);
select is(
  has_function_privilege('authenticated','public.record_paymongo_checkout(uuid,text,text,integer)','execute'),
  false,'authenticated clients cannot record provider checkouts'
);
select is(
  has_function_privilege('service_role','public.record_paymongo_checkout(uuid,text,text,integer)','execute'),
  true,'only the service role has the checkout commit capability'
);
select is(
  has_function_privilege('anon','public.claim_message_deliveries(integer,text[])','execute'),
  false,'anonymous callers cannot claim global communications work'
);
select is(
  has_function_privilege('authenticated','public.claim_message_deliveries(integer,text[])','execute'),
  false,'application users cannot claim global communications work'
);
select is(
  has_function_privilege('authenticated','public.send_scheduled_booking_reminders()','execute'),
  false,'application users cannot run the global reminder scheduler'
);
select is(
  has_function_privilege('anon','public.set_admin_capabilities(uuid,text[])','execute'),
  false,'anonymous callers cannot invoke administrator capability management'
);
select is(
  has_function_privilege('authenticated','public.record_financial_ledger_entry()','execute'),
  false,'trigger-only ledger code is not an application RPC'
);
select is(
  has_function_privilege('anon','public.create_ranked_driver_offers(uuid)','execute'),
  false,'anonymous callers cannot mutate the global driver-offer queue'
);
select is(
  has_function_privilege('authenticated','public.create_ranked_driver_offers(uuid)','execute'),
  false,'application users cannot bypass booking-owned dispatch workflows'
);
select is(
  has_function_privilege('authenticated','public.refresh_driver_reliability_metrics(uuid)','execute'),
  false,'computed driver metrics can only be refreshed by trusted database workflows'
);

insert into auth.users(id,email,raw_user_meta_data)
values
  ('60000000-0000-4000-8000-000000000101','checkout-tourist-a@test.local','{"full_name":"Checkout Tourist A"}'),
  ('60000000-0000-4000-8000-000000000102','checkout-tourist-b@test.local','{"full_name":"Checkout Tourist B"}'),
  ('60000000-0000-4000-8000-000000000103','checkout-tourist-c@test.local','{"full_name":"Checkout Tourist C"}');
insert into public.fare_revisions(id,custom_fare_centavos,package_fares,is_current,reason)
values ('61000000-0000-4000-8000-000000000001',12500,'{}',false,'Checkout consistency test');
insert into public.cancellation_policies(id,is_current,terms)
values ('61000000-0000-4000-8000-000000000002',false,'Checkout consistency test');
insert into public.bookings(
  id,tourist_id,fare_revision_id,cancellation_policy_id,quoted_amount_centavos,
  payment_method,payment_status,status,pickup_address,pickup_latitude,
  pickup_longitude,pickup_code_hash
) values
  ('62000000-0000-4000-8000-000000000001','60000000-0000-4000-8000-000000000101','61000000-0000-4000-8000-000000000001','61000000-0000-4000-8000-000000000002',12500,'paymongo','unpaid','pending','Test',14.95,120.91,'hash'),
  ('62000000-0000-4000-8000-000000000002','60000000-0000-4000-8000-000000000102','61000000-0000-4000-8000-000000000001','61000000-0000-4000-8000-000000000002',12500,'paymongo','unpaid','pending','Test',14.95,120.91,'hash'),
  ('62000000-0000-4000-8000-000000000003','60000000-0000-4000-8000-000000000103','61000000-0000-4000-8000-000000000001','61000000-0000-4000-8000-000000000002',12500,'paymongo','unpaid','ongoing','Test',14.95,120.91,'hash');

set local role service_role;
select set_config('request.jwt.claim.role','service_role',true);
select lives_ok($$
  select public.record_paymongo_checkout(
    '62000000-0000-4000-8000-000000000001','cs_atomic','https://checkout.paymongo.com/cs_atomic',12500
  )
$$,'valid checkout result commits atomically');
reset role;
select is(
  (select payment_status::text from public.bookings where id='62000000-0000-4000-8000-000000000001'),
  'checkout_created','checkout commit updates the booking state'
);
select is(
  (select count(*)::integer from public.payments where booking_id='62000000-0000-4000-8000-000000000001'),
  1,'checkout commit creates exactly one payment row'
);

set local role service_role;
select set_config('request.jwt.claim.role','service_role',true);
select is(
  (public.record_paymongo_checkout(
    '62000000-0000-4000-8000-000000000001','cs_atomic','https://checkout.paymongo.com/cs_atomic',12500
  )->>'reused')::boolean,
  true,'a repeated checkout commit reuses authoritative local state'
);
reset role;
select is(
  (select count(*)::integer from public.payments where booking_id='62000000-0000-4000-8000-000000000001'),
  1,'retry remains idempotent'
);

set local role authenticated;
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','60000000-0000-4000-8000-000000000101',true);
select is(
  public.recover_booking_pickup_code(
    '62000000-0000-4000-8000-000000000001',
    '63000000-0000-4000-8000-000000000001','4827'
  ),
  '4827','tourist can recover an interrupted active booking with a stable code'
);
reset role;
select isnt(
  (select pickup_code_hash from public.bookings where id='62000000-0000-4000-8000-000000000001'),
  'hash','recovery replaces rather than reveals the stored pickup credential'
);
set local role authenticated;
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','60000000-0000-4000-8000-000000000102',true);
select throws_ok($$
  select public.recover_booking_pickup_code(
    '62000000-0000-4000-8000-000000000001',
    '63000000-0000-4000-8000-000000000002','1954'
  )
$$,'P0001','Recoverable booking not found','another tourist cannot recover the booking credential');
reset role;

set local role service_role;
select set_config('request.jwt.claim.role','service_role',true);
select throws_ok($$
  select public.record_paymongo_checkout(
    '62000000-0000-4000-8000-000000000002','cs_wrong_amount','https://checkout.paymongo.com/cs_wrong_amount',12499
  )
$$,'P0001','Checkout amount does not match the booking quote','amount mismatch is rejected');
select throws_ok($$
  select public.record_paymongo_checkout(
    '62000000-0000-4000-8000-000000000003','cs_wrong_state','https://checkout.paymongo.com/cs_wrong_state',12500
  )
$$,'P0001','Booking is not eligible for online checkout','ongoing booking cannot open a checkout');
reset role;
select is(
  (select count(*)::integer from public.payments where booking_id in (
    '62000000-0000-4000-8000-000000000002','62000000-0000-4000-8000-000000000003'
  )),0,'rejected commits leave no partial payment rows'
);

select * from finish();
rollback;

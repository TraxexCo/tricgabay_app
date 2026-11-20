begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;

select plan(31);

-- Isolated identities. The auth trigger creates tourist profiles first; role
-- and status are then assigned explicitly for each authorization fixture.
insert into auth.users(id,email,raw_user_meta_data)
values
  ('00000000-0000-4000-8000-000000000101','tourist@test.local','{"full_name":"Tourist"}'),
  ('00000000-0000-4000-8000-000000000103','tourist-webhook-a@test.local','{"full_name":"Webhook Tourist A"}'),
  ('00000000-0000-4000-8000-000000000104','tourist-webhook-b@test.local','{"full_name":"Webhook Tourist B"}'),
  ('00000000-0000-4000-8000-000000000105','tourist-webhook-c@test.local','{"full_name":"Webhook Tourist C"}'),
  ('00000000-0000-4000-8000-000000000102','driver@test.local','{"full_name":"Driver","requested_role":"driver"}'),
  ('00000000-0000-4000-8000-000000000201','finance@test.local','{"full_name":"Finance"}'),
  ('00000000-0000-4000-8000-000000000202','support@test.local','{"full_name":"Support"}'),
  ('00000000-0000-4000-8000-000000000203','super@test.local','{"full_name":"Super"}'),
  ('00000000-0000-4000-8000-000000000204','inactive@test.local','{"full_name":"Inactive"}'),
  ('00000000-0000-4000-8000-000000000205','operations@test.local','{"full_name":"Operations"}'),
  ('00000000-0000-4000-8000-000000000206','content@test.local','{"full_name":"Content"}'),
  ('00000000-0000-4000-8000-000000000207','compliance@test.local','{"full_name":"Compliance"}');

update public.profiles set role='admin',status='active'
where id in (
  '00000000-0000-4000-8000-000000000201',
  '00000000-0000-4000-8000-000000000202',
  '00000000-0000-4000-8000-000000000203',
  '00000000-0000-4000-8000-000000000205',
  '00000000-0000-4000-8000-000000000206',
  '00000000-0000-4000-8000-000000000207'
);
update public.profiles set role='admin',status='suspended'
where id='00000000-0000-4000-8000-000000000204';
update public.profiles set role='driver',status='active'
where id='00000000-0000-4000-8000-000000000102';

insert into public.admin_capabilities(profile_id,capability,granted_by)
values
  ('00000000-0000-4000-8000-000000000201','finance','00000000-0000-4000-8000-000000000203'),
  ('00000000-0000-4000-8000-000000000202','support','00000000-0000-4000-8000-000000000203'),
  ('00000000-0000-4000-8000-000000000203','super_admin','00000000-0000-4000-8000-000000000203'),
  ('00000000-0000-4000-8000-000000000204','finance','00000000-0000-4000-8000-000000000203'),
  ('00000000-0000-4000-8000-000000000205','operations','00000000-0000-4000-8000-000000000203'),
  ('00000000-0000-4000-8000-000000000206','content','00000000-0000-4000-8000-000000000203'),
  ('00000000-0000-4000-8000-000000000207','driver_compliance','00000000-0000-4000-8000-000000000203');

insert into public.driver_profiles(
  profile_id,plate_number,franchise_number,approval_status,is_online
) values (
  '00000000-0000-4000-8000-000000000102','TEST-01','TEST-FRANCHISE','approved',true
);

insert into public.fare_revisions(
  id,custom_fare_centavos,package_fares,is_current,reason,created_by
) values (
  '10000000-0000-4000-8000-000000000001',10000,'{}',false,
  'Security test fare','00000000-0000-4000-8000-000000000201'
);
insert into public.cancellation_policies(
  id,is_current,terms,created_by
) values (
  '10000000-0000-4000-8000-000000000002',false,'Security test policy',
  '00000000-0000-4000-8000-000000000201'
);

insert into public.bookings(
  id,tourist_id,driver_id,fare_revision_id,cancellation_policy_id,
  quoted_amount_centavos,final_charge_centavos,payment_method,payment_status,status,
  pickup_address,pickup_latitude,pickup_longitude,pickup_code_hash
) values
  ('20000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000101','00000000-0000-4000-8000-000000000102','10000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000002',10000,5000,'paymongo','refund_required','completed','Test',14.95,120.91,'hash'),
  ('20000000-0000-4000-8000-000000000002','00000000-0000-4000-8000-000000000101',null,'10000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000002',10000,5000,'paymongo','refund_required','completed','Test',14.95,120.91,'hash'),
  ('20000000-0000-4000-8000-000000000003','00000000-0000-4000-8000-000000000103',null,'10000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000002',10000,null,'paymongo','checkout_created','pending','Test',14.95,120.91,'hash'),
  ('20000000-0000-4000-8000-000000000004','00000000-0000-4000-8000-000000000104',null,'10000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000002',10000,null,'paymongo','checkout_created','pending','Test',14.95,120.91,'hash'),
  ('20000000-0000-4000-8000-000000000005','00000000-0000-4000-8000-000000000105',null,'10000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000002',10000,null,'paymongo','checkout_created','pending','Test',14.95,120.91,'hash');

insert into public.payments(
  id,booking_id,provider,provider_mode,provider_checkout_id,provider_payment_id,
  amount_centavos,status,paid_at
) values
  ('30000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','paymongo','test','cs_refund_finance','pay_refund_finance',10000,'paid',now()),
  ('30000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000002','paymongo','test','cs_refund_super','pay_refund_super',10000,'paid',now()),
  ('30000000-0000-4000-8000-000000000003','20000000-0000-4000-8000-000000000003','paymongo','test','cs_paid_then_failed',null,10000,'checkout_created',null),
  ('30000000-0000-4000-8000-000000000004','20000000-0000-4000-8000-000000000004','paymongo','test','cs_failed_then_paid',null,10000,'checkout_created',null),
  ('30000000-0000-4000-8000-000000000005','20000000-0000-4000-8000-000000000005','paymongo','test','cs_mismatch',null,10000,'checkout_created',null);

set local role authenticated;
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000202',true);
select throws_ok(
  $$select public.reserve_paymongo_refund('20000000-0000-4000-8000-000000000001',5000,'Support must not refund')$$,
  '42501','Finance administrator access required','support administrator cannot reserve a refund'
);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000205',true);
select throws_ok(
  $$select public.reserve_paymongo_refund('20000000-0000-4000-8000-000000000001',5000,'Operations must not refund')$$,
  '42501','Finance administrator access required','operations administrator cannot reserve a refund'
);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000206',true);
select throws_ok(
  $$select public.reserve_paymongo_refund('20000000-0000-4000-8000-000000000001',5000,'Content must not refund')$$,
  '42501','Finance administrator access required','content administrator cannot reserve a refund'
);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000207',true);
select throws_ok(
  $$select public.reserve_paymongo_refund('20000000-0000-4000-8000-000000000001',5000,'Compliance must not refund')$$,
  '42501','Finance administrator access required','compliance administrator cannot reserve a refund'
);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000204',true);
select throws_ok(
  $$select public.reserve_paymongo_refund('20000000-0000-4000-8000-000000000001',5000,'Inactive must not refund')$$,
  '42501','Finance administrator access required','inactive finance administrator cannot reserve a refund'
);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000101',true);
select throws_ok(
  $$select public.reserve_paymongo_refund('20000000-0000-4000-8000-000000000001',5000,'Tourist must not refund')$$,
  '42501','Finance administrator access required','tourist cannot reserve a refund'
);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000102',true);
select throws_ok(
  $$select public.reserve_paymongo_refund('20000000-0000-4000-8000-000000000001',5000,'Driver must not refund')$$,
  '42501','Finance administrator access required','driver cannot reserve a refund'
);
reset role;
set local role anon;
select set_config('request.jwt.claim.role','anon',true);
select throws_ok(
  $$select public.reserve_paymongo_refund('20000000-0000-4000-8000-000000000001',5000,'Missing auth must not refund')$$,
  '42501','permission denied for function reserve_paymongo_refund','anonymous caller cannot invoke the refund reservation RPC'
);
reset role;
set local role authenticated;
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000201',true);
select lives_ok(
  $$select public.reserve_paymongo_refund('20000000-0000-4000-8000-000000000001',5000,'Authorized finance refund')$$,
  'finance administrator can reserve a valid refund'
);
select throws_ok(
  $$select public.reserve_paymongo_refund('20000000-0000-4000-8000-000000000001',5000,'Duplicate finance refund')$$,
  'P0001','This booking does not currently require an online refund',
  'processing refund reservation blocks a duplicate provider request'
);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000203',true);
select lives_ok(
  $$select public.reserve_paymongo_refund('20000000-0000-4000-8000-000000000002',5000,'Authorized super refund')$$,
  'super administrator retains finance bypass'
);
reset role;
select is((select count(*)::integer from public.refunds),2,'only authorized refunds were reserved');
select is((select count(*)::integer from public.trip_events where event_type='refund_requested'),2,'authorized refunds have audit events');

set local role service_role;
select set_config('request.jwt.claim.role','service_role',true);
select lives_ok($$
  select public.process_paymongo_payment_event(
    'evt_paid_after_refund','checkout_session.payment.paid','cs_refund_finance','cs_refund_finance','pay_refund_finance',
    10000,'PHP','paid',null,null,now(),'{}',gen_random_uuid()
  )
$$,'payment success cannot revert an active refund lifecycle');
select lives_ok($$
  select public.process_paymongo_payment_event(
    'evt_paid_1','checkout_session.payment.paid','cs_paid_then_failed','cs_paid_then_failed','pay_paid_1',
    10000,'PHP','paid',null,null,now(),'{}',gen_random_uuid()
  )
$$,'valid paid event is applied');
select lives_ok($$
  select public.process_paymongo_payment_event(
    'evt_failed_late','payment.failed','pay_paid_1','cs_paid_then_failed','pay_paid_1',
    null,null,'failed','card_declined','late failure',null,'{}',gen_random_uuid()
  )
$$,'delayed failure is safely processed');
reset role;
select is((select payment_status::text from public.bookings where id='20000000-0000-4000-8000-000000000001'),'refund_processing','late payment event preserves refund processing');
select is((select status::text from public.payments where id='30000000-0000-4000-8000-000000000003'),'paid','delayed failure cannot downgrade payment');
select is((select payment_status::text from public.bookings where id='20000000-0000-4000-8000-000000000003'),'paid','delayed failure cannot downgrade booking');
select is((select count(*)::integer from public.financial_ledger_entries where payment_id='30000000-0000-4000-8000-000000000003' and entry_type='payment_received'),1,'paid event creates one ledger credit');

set local role service_role;
select set_config('request.jwt.claim.role','service_role',true);
select lives_ok($$
  select public.process_paymongo_payment_event(
    'evt_failed_first','payment.failed','pay_failed_1','cs_failed_then_paid','pay_failed_1',
    null,null,'failed','declined','declined',null,'{}',gen_random_uuid()
  )
$$,'failure may precede a later authoritative success');
select lives_ok($$
  select public.process_paymongo_payment_event(
    'evt_failed_first','payment.failed','pay_failed_1','cs_failed_then_paid','pay_failed_1',
    null,null,'failed','declined','declined',null,'{}',gen_random_uuid()
  )
$$,'duplicate failure event is idempotent');
select lives_ok($$
  select public.process_paymongo_payment_event(
    'evt_paid_later','checkout_session.payment.paid','cs_failed_then_paid','cs_failed_then_paid','pay_paid_2',
    10000,'PHP','paid',null,null,now(),'{}',gen_random_uuid()
  )
$$,'valid success upgrades a failed checkout');
select lives_ok($$
  select public.process_paymongo_payment_event(
    'evt_paid_later','checkout_session.payment.paid','cs_failed_then_paid','cs_failed_then_paid','pay_paid_2',
    10000,'PHP','paid',null,null,now(),'{}',gen_random_uuid()
  )
$$,'duplicate event is idempotent');
select lives_ok($$
  select public.process_paymongo_payment_event(
    'evt_mismatch','checkout_session.payment.paid','cs_mismatch','cs_mismatch','pay_mismatch',
    9999,'USD','paid',null,null,now(),'{}',gen_random_uuid()
  )
$$,'amount and currency mismatch is recorded without success');
select throws_ok($$
  select public.process_paymongo_payment_event(
    'evt_unknown','payment.failed','pay_unknown',null,'pay_unknown',
    null,null,'failed','declined','unknown payment',null,'{}',gen_random_uuid()
  )
$$,'40001','Payment is not ready for provider event','unknown provider identifier is retryable and not consumed');
reset role;
select is((select status::text from public.payments where id='30000000-0000-4000-8000-000000000004'),'paid','later success becomes authoritative');
select is((select count(*)::integer from public.financial_ledger_entries where payment_id='30000000-0000-4000-8000-000000000004' and entry_type='payment_received'),1,'duplicate success creates one ledger credit');
select is((select status::text from public.payments where id='30000000-0000-4000-8000-000000000005'),'checkout_created','mismatch does not mark payment paid');
select is((select payment_status::text from public.bookings where id='20000000-0000-4000-8000-000000000005'),'under_review','mismatch places booking under review');
select is((select count(*)::integer from public.payment_webhook_events where provider_event_id='evt_failed_first'),1,'duplicate failure stores one provider event');

select * from finish();
rollback;


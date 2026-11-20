begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;

select plan(16);

insert into auth.users(id,email,raw_user_meta_data)
values
  ('50000000-0000-4000-8000-000000000101','refund-tourist@test.local','{"full_name":"Tourist"}'),
  ('50000000-0000-4000-8000-000000000201','refund-finance@test.local','{"full_name":"Finance"}');

update public.profiles set role='admin',status='active'
where id='50000000-0000-4000-8000-000000000201';
insert into public.admin_capabilities(profile_id,capability)
values ('50000000-0000-4000-8000-000000000201','finance');

insert into public.fare_revisions(id,custom_fare_centavos,package_fares,is_current,reason)
values ('51000000-0000-4000-8000-000000000001',10000,'{}',false,'Refund recovery test');
insert into public.cancellation_policies(id,is_current,terms)
values ('51000000-0000-4000-8000-000000000002',false,'Refund recovery test');

insert into public.bookings(
  id,tourist_id,fare_revision_id,cancellation_policy_id,
  quoted_amount_centavos,final_charge_centavos,payment_method,payment_status,status,
  pickup_address,pickup_latitude,pickup_longitude,pickup_code_hash
) values
  ('52000000-0000-4000-8000-000000000001','50000000-0000-4000-8000-000000000101','51000000-0000-4000-8000-000000000001','51000000-0000-4000-8000-000000000002',10000,5000,'paymongo','refund_required','completed','Test',14.95,120.91,'hash'),
  ('52000000-0000-4000-8000-000000000002','50000000-0000-4000-8000-000000000101','51000000-0000-4000-8000-000000000001','51000000-0000-4000-8000-000000000002',10000,5000,'paymongo','refund_required','completed','Test',14.95,120.91,'hash');

insert into public.payments(
  id,booking_id,provider,provider_mode,provider_checkout_id,provider_payment_id,
  amount_centavos,status,paid_at
) values
  ('53000000-0000-4000-8000-000000000001','52000000-0000-4000-8000-000000000001','paymongo','test','cs_timeout_success','pay_timeout_success',10000,'paid',now()),
  ('53000000-0000-4000-8000-000000000002','52000000-0000-4000-8000-000000000002','paymongo','test','cs_timeout_failure','pay_timeout_failure',10000,'paid',now());

set local role authenticated;
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','50000000-0000-4000-8000-000000000201',true);
select lives_ok(
  $$select public.reserve_paymongo_refund('52000000-0000-4000-8000-000000000001',5000,'Timeout success recovery')$$,
  'finance can reserve the refund that later times out'
);
select lives_ok(
  $$select public.reserve_paymongo_refund('52000000-0000-4000-8000-000000000002',5000,'Timeout failure recovery')$$,
  'finance can reserve a second independent refund'
);
select is((select count(*)::integer from public.refunds where status='processing'),2,'both ambiguous requests remain processing');
select throws_ok(
  $$select public.reserve_paymongo_refund('52000000-0000-4000-8000-000000000001',5000,'Duplicate timeout request')$$,
  'P0001','This booking does not currently require an online refund',
  'a processing timeout reservation blocks a duplicate provider request'
);
reset role;

set local role service_role;
select set_config('request.jwt.claim.role','service_role',true);
select lives_ok($$
  select public.process_paymongo_refund_event(
    'evt_refund_timeout_success','payment.refund.updated',
    '[{"id":"ref_timeout_success","attributes":{"amount":5000,"status":"succeeded","updated_at":100}}]'::jsonb,
    '{"source":"reconciliation","provider_payment_id":"pay_timeout_success"}'::jsonb,
    gen_random_uuid()
  )
$$,'reconciliation binds a provider refund after the create request timed out');
reset role;

select is((select provider_refund_id from public.refunds where booking_id='52000000-0000-4000-8000-000000000001'),'ref_timeout_success','authoritative reconciliation binds the provider refund identifier');
select is((select status::text from public.refunds where booking_id='52000000-0000-4000-8000-000000000001'),'succeeded','later reconciliation confirms refund success');
select is((select payment_status::text from public.bookings where id='52000000-0000-4000-8000-000000000001'),'refunded','successful reconciliation updates the booking');
select is((select count(*)::integer from public.financial_ledger_entries where refund_id=(select id from public.refunds where booking_id='52000000-0000-4000-8000-000000000001')),1,'successful reconciliation records one refund ledger entry');

set local role service_role;
select set_config('request.jwt.claim.role','service_role',true);
select lives_ok($$
  select public.process_paymongo_refund_event(
    'evt_refund_timeout_success','payment.refund.updated',
    '[{"id":"ref_timeout_success","attributes":{"amount":5000,"status":"succeeded","updated_at":100}}]'::jsonb,
    '{"source":"reconciliation","provider_payment_id":"pay_timeout_success"}'::jsonb,
    gen_random_uuid()
  )
$$,'duplicate authoritative refund event is idempotent');
reset role;
select is((select count(*)::integer from public.payment_webhook_events where provider_event_id='evt_refund_timeout_success'),1,'duplicate reconciliation stores one provider event');

set local role service_role;
select set_config('request.jwt.claim.role','service_role',true);
select lives_ok($$
  select public.process_paymongo_refund_event(
    'evt_refund_timeout_failure','payment.refund.updated',
    '[{"id":"ref_timeout_failure","attributes":{"amount":5000,"status":"failed","failure_reason":"provider_declined","updated_at":100}}]'::jsonb,
    '{"source":"reconciliation","provider_payment_id":"pay_timeout_failure"}'::jsonb,
    gen_random_uuid()
  )
$$,'reconciliation can establish a definitive refund failure');
reset role;
select is((select status::text from public.refunds where booking_id='52000000-0000-4000-8000-000000000002'),'failed','definitive provider failure is distinct from an ambiguous timeout');
select is((select payment_status::text from public.bookings where id='52000000-0000-4000-8000-000000000002'),'refund_required','definitive failure reopens the refund-required state');

set local role service_role;
select set_config('request.jwt.claim.role','service_role',true);
select throws_ok($$
  select public.process_paymongo_refund_event(
    'evt_refund_unknown','payment.refund.updated',
    '[{"id":"ref_unknown","attributes":{"amount":5000,"status":"succeeded"}}]'::jsonb,
    '{"source":"webhook","provider_payment_id":"pay_unknown"}'::jsonb,
    gen_random_uuid()
  )
$$,'40001','Refund is not ready for provider event','unknown early refund events remain retryable');
reset role;
select is((select count(*)::integer from public.payment_webhook_events where provider_event_id='evt_refund_unknown'),0,'unknown retryable event is not consumed');

select * from finish();
rollback;

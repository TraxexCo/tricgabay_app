begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;
select no_plan();
select set_config('request.jwt.claim.role','service_role',true);
select is((select live_payments_enabled from public.service_configuration),false,'live flag defaults OFF');
select throws_ok($$select public.require_provider_mode('live')$$,'42501',null,'live operation fails closed while flag is off');
insert into auth.users(id,email,raw_user_meta_data) values
('b4800000-0000-4000-8000-000000000001','mode-test@example.test','{"full_name":"Mode Test"}'),
('b4800000-0000-4000-8000-000000000002','mode-live@example.test','{"full_name":"Mode Live"}');
insert into public.fare_revisions(id,custom_fare_centavos,reason) values('b4810000-0000-4000-8000-000000000001',10000,'Mode fixture');
insert into public.cancellation_policies(id,terms) values('b4810000-0000-4000-8000-000000000002','Mode fixture');
insert into public.bookings(id,tourist_id,fare_revision_id,cancellation_policy_id,quoted_amount_centavos,payment_method,pickup_address,pickup_latitude,pickup_longitude,pickup_code_hash)
select ('b4820000-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,('b4800000-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,'b4810000-0000-4000-8000-000000000001','b4810000-0000-4000-8000-000000000002',10000,'paymongo','Mode fixture',14.9571,120.9188,crypt('1234',gen_salt('bf')) from generate_series(1,2)i;
select throws_ok($$insert into public.payments(booking_id,provider,provider_mode,provider_checkout_id,amount_centavos,status) values('b4820000-0000-4000-8000-000000000002','paymongo','live','cs_collision',10000,'checkout_created')$$,'42501',null,'even privileged inserts cannot silently create live payments while disabled');
-- Test-only transaction enablement: no provider transport is invoked, and the
-- entire transaction is rolled back. Deployment configuration stays OFF.
update public.service_configuration set live_payments_enabled=true;
insert into public.payments(id,booking_id,provider,provider_mode,provider_checkout_id,amount_centavos,status)
values('b4830000-0000-4000-8000-000000000001','b4820000-0000-4000-8000-000000000001','paymongo','test','cs_collision',10000,'checkout_created'),
('b4830000-0000-4000-8000-000000000002','b4820000-0000-4000-8000-000000000002','paymongo','live','cs_collision',10000,'checkout_created');
select public.process_paymongo_payment_event_in_mode('evt_same','checkout_session.payment.paid',null,'cs_collision','pay_same',10000,'PHP','paid',null,null,now(),'{}',gen_random_uuid(),'test');
select is((select status::text from public.payments where provider_mode='live' and id='b4830000-0000-4000-8000-000000000002'),'checkout_created','test event cannot mutate matching live provider identifiers');
select public.process_paymongo_payment_event_in_mode('evt_same','checkout_session.payment.paid',null,'cs_collision','pay_same',10000,'PHP','paid',null,null,now(),'{}',gen_random_uuid(),'live');
select is((select count(*)::integer from public.payment_webhook_events where provider_event_id='evt_same'),2,'same event identifier is independently deduplicated per mode');
select is((select count(*)::integer from public.financial_ledger_entries where booking_id::text like 'b4820000%' and provider_mode='test'),1,'test credit has test ledger mode');
select is((select count(*)::integer from public.financial_ledger_entries where booking_id::text like 'b4820000%' and provider_mode='live'),1,'live credit has live ledger mode');
select is(public.process_paymongo_payment_event_in_mode('evt_same','checkout_session.payment.paid',null,'cs_collision','pay_same',10000,'PHP','paid',null,null,now(),'{}',gen_random_uuid(),'live')->>'result','duplicate','live replay is idempotent within mode');
update public.bookings set status='cancelled',final_charge_centavos=0,payment_status='refund_required' where id::text like 'b4820000%';
insert into public.refunds(id,booking_id,payment_id,provider_refund_id,amount_centavos,reason,status,requested_by)
values('b4840000-0000-4000-8000-000000000001','b4820000-0000-4000-8000-000000000001','b4830000-0000-4000-8000-000000000001','re_same',10000,'Mode refund fixture','processing','b4800000-0000-4000-8000-000000000001'),
('b4840000-0000-4000-8000-000000000002','b4820000-0000-4000-8000-000000000002','b4830000-0000-4000-8000-000000000002','re_same',10000,'Mode refund fixture','processing','b4800000-0000-4000-8000-000000000002');
select public.process_paymongo_refund_event_in_mode('evt_refund_same','payment.refund.updated','[{"id":"re_same","attributes":{"status":"succeeded","amount":10000,"payment_id":"pay_same"}}]','{}',gen_random_uuid(),'test');
select is((select status::text from public.refunds where id='b4840000-0000-4000-8000-000000000002'),'processing','test refund event cannot finalize live refund with the same provider ID');
select public.process_paymongo_refund_event_in_mode('evt_refund_same','payment.refund.updated','[{"id":"re_same","attributes":{"status":"succeeded","amount":10000,"payment_id":"pay_same"}}]','{}',gen_random_uuid(),'live');
select is((select provider_mode from public.financial_ledger_entries where refund_id='b4840000-0000-4000-8000-000000000001'),'test','test refund debit keeps payment mode');
select is((select provider_mode from public.financial_ledger_entries where refund_id='b4840000-0000-4000-8000-000000000002'),'live','live refund debit keeps payment mode');
select throws_ok($$update public.payments set provider_mode='test' where id='b4830000-0000-4000-8000-000000000002'$$,'P0001','Payment mode is immutable','a recorded payment cannot be relabelled');
update public.service_configuration set live_payments_enabled=false;
select throws_ok($$select public.process_paymongo_payment_event_in_mode('evt_disabled','payment.processing',null,'cs_collision','pay_same',null,null,'processing',null,null,now(),'{}',gen_random_uuid(),'live')$$,'42501',null,'disabled live event is rejected before persistence');
select is((select count(*)::integer from public.payment_webhook_events where provider_event_id='evt_disabled'),0,'disabled live webhook is not consumed');
select is((select live_payments_enabled from public.service_configuration),false,'test leaves the live flag OFF');
select * from finish();rollback;

-- Refunds for the live payment methods. With PayMongo retired (2026-11-20)
-- there is no provider refund to reconcile: an overpayment found during a
-- review is returned in person, and both participants confirm it, like the
-- original cash payment. The provider timeout/reconciliation checks that used
-- to live here were retired with PayMongo.
begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;

select plan(19);

insert into auth.users(id,email,raw_user_meta_data)
values
  ('50000000-0000-4000-8000-000000000101','refund-tourist@test.local','{"full_name":"Tourist"}'),
  ('50000000-0000-4000-8000-000000000102','refund-driver@test.local','{"full_name":"Driver","requested_role":"driver"}'),
  ('50000000-0000-4000-8000-000000000201','refund-finance@test.local','{"full_name":"Finance"}');

update public.profiles set role='admin',status='active'
where id='50000000-0000-4000-8000-000000000201';
update public.profiles set role='driver',status='active'
where id='50000000-0000-4000-8000-000000000102';
insert into public.admin_capabilities(profile_id,capability)
values ('50000000-0000-4000-8000-000000000201','finance');
insert into public.driver_profiles(profile_id,plate_number,franchise_number,approval_status,is_online)
values ('50000000-0000-4000-8000-000000000102','REFUND-01','REFUND-FR','approved',false);

insert into public.fare_revisions(id,custom_fare_centavos,package_fares,is_current,reason)
values ('51000000-0000-4000-8000-000000000001',10000,'{}',false,'Refund test fare');
insert into public.cancellation_policies(id,is_current,terms)
values ('51000000-0000-4000-8000-000000000002',false,'Refund test policy');

-- 1: paid 10000 in cash, under review after the tour ended early
-- 2: under review before pickup, cancellation charge snapshotted at 2000
insert into public.bookings(
  id,tourist_id,driver_id,fare_revision_id,cancellation_policy_id,
  quoted_amount_centavos,final_charge_centavos,payment_method,payment_status,status,
  pickup_address,pickup_latitude,pickup_longitude,pickup_code_hash,started_at
) values
  ('52000000-0000-4000-8000-000000000001','50000000-0000-4000-8000-000000000101','50000000-0000-4000-8000-000000000102','51000000-0000-4000-8000-000000000001','51000000-0000-4000-8000-000000000002',10000,10000,'cash','under_review','completed','Test',14.95,120.91,'hash',now()-interval '2 hours'),
  ('52000000-0000-4000-8000-000000000002','50000000-0000-4000-8000-000000000101','50000000-0000-4000-8000-000000000102','51000000-0000-4000-8000-000000000001','51000000-0000-4000-8000-000000000002',10000,2000,'cash','under_review','cancelled','Test',14.95,120.91,'hash',null);

insert into public.payments(id,booking_id,provider,amount_centavos,status,paid_at)
values ('53000000-0000-4000-8000-000000000001','52000000-0000-4000-8000-000000000001','cash',10000,'cash_paid',now());

set local role authenticated;
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','50000000-0000-4000-8000-000000000201',true);

-- ── Charge decisions are validated ────────────────────────────────────────
select throws_ok(
  $$select public.resolve_booking_charge('52000000-0000-4000-8000-000000000001',6000,'too short')$$,
  'P0001','A detailed decision reason is required','a charge decision needs a real reason'
);
select throws_ok(
  $$select public.resolve_booking_charge('52000000-0000-4000-8000-000000000001',12000,'Charge above the quoted fare')$$,
  'P0001','Booking or final charge is invalid','a charge above the agreed fare is refused'
);
select throws_ok(
  $$select public.resolve_booking_charge('52000000-0000-4000-8000-000000000001',-1,'Negative charge attempt')$$,
  'P0001','Booking or final charge is invalid','a negative charge is refused'
);
select throws_ok(
  $$select public.resolve_booking_charge('52000000-0000-4000-8000-000000000002',5000,'Raise a pre-pickup charge')$$,
  'P0001','A pre-pickup review cannot increase the snapshotted cancellation charge',
  'a review before pickup cannot raise the cancellation charge'
);
select lives_ok(
  $$select public.resolve_booking_charge('52000000-0000-4000-8000-000000000002',1000,'Lower the pre-pickup charge')$$,
  'a review before pickup may lower the cancellation charge'
);

-- ── An overpayment becomes a cash refund ──────────────────────────────────
select lives_ok(
  $$select public.resolve_booking_charge('52000000-0000-4000-8000-000000000001',6000,'Tour ended early after three stops')$$,
  'finance lowers the charge after an early end'
);
reset role;
select is((select payment_status::text from public.bookings where id='52000000-0000-4000-8000-000000000001'),'refund_required','paying more than the new charge requires a refund');
select is((select payment_status::text from public.bookings where id='52000000-0000-4000-8000-000000000002'),'unpaid','an unpaid lower charge stays unpaid');

set local role authenticated;
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','50000000-0000-4000-8000-000000000102',true);
select lives_ok(
  $$select public.confirm_cash('52000000-0000-4000-8000-000000000001','refund')$$,
  'the driver confirms handing back the difference'
);
select lives_ok(
  $$select public.confirm_cash('52000000-0000-4000-8000-000000000001','refund')$$,
  'a repeated driver refund confirmation is harmless'
);
reset role;
select is((select payment_status::text from public.bookings where id='52000000-0000-4000-8000-000000000001'),'refund_required','one side alone does not complete the refund');
select is((select count(*)::integer from public.cash_confirmations where booking_id='52000000-0000-4000-8000-000000000001' and direction='refund'),1,'a repeated refund confirmation is stored once');
select is((select amount_centavos from public.cash_confirmations where booking_id='52000000-0000-4000-8000-000000000001' and direction='refund'),4000,'the refund is exactly the overpayment');

set local role authenticated;
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','50000000-0000-4000-8000-000000000101',true);
select lives_ok(
  $$select public.confirm_cash('52000000-0000-4000-8000-000000000001','refund')$$,
  'the tourist confirms receiving the refund'
);
reset role;
select is((select payment_status::text from public.bookings where id='52000000-0000-4000-8000-000000000001'),'refunded','both confirmations complete the refund');
select is((select count(*)::integer from public.cash_confirmations where booking_id='52000000-0000-4000-8000-000000000001' and direction='refund'),2,'one refund confirmation per participant');
select is((select count(*)::integer from public.financial_ledger_entries where booking_id='52000000-0000-4000-8000-000000000001' and entry_type='payment_received'),1,'the original cash payment keeps one ledger credit');

-- ── Nothing to refund when nothing was overpaid ───────────────────────────
set local role authenticated;
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','50000000-0000-4000-8000-000000000101',true);
select throws_ok(
  $$select public.confirm_cash('52000000-0000-4000-8000-000000000002','refund')$$,
  'P0001','No cash amount is outstanding','no refund can be confirmed without an overpayment'
);
reset role;
select is((select count(*)::integer from public.cash_confirmations where booking_id='52000000-0000-4000-8000-000000000002'),0,'a refused refund leaves no confirmation');

select * from finish();
rollback;

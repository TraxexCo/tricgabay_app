-- Money authorization and ledger integrity for the live payment methods
-- (cash and direct GCash). The PayMongo refund-reservation and webhook checks
-- that used to live here were retired with PayMongo on 2026-11-20; what is
-- left of them is only asserted to be closed to clients (first block).
begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;

select plan(34);

-- Isolated identities. The auth trigger creates tourist profiles first; role
-- and status are then assigned explicitly for each authorization fixture.
insert into auth.users(id,email,raw_user_meta_data)
values
  ('00000000-0000-4000-8000-000000000101','tourist@test.local','{"full_name":"Tourist"}'),
  ('00000000-0000-4000-8000-000000000103','other-tourist@test.local','{"full_name":"Other Tourist"}'),
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
  '00000000-0000-4000-8000-000000000102','TEST-01','TEST-FRANCHISE','approved',false
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

-- 1: completed cash trip, not yet paid (cash confirmation and ledger)
-- 2: cash trip paid in full, under review (finance lowers the charge)
-- 3: cash trip under review with nothing paid (super admin waives it)
insert into public.bookings(
  id,tourist_id,driver_id,fare_revision_id,cancellation_policy_id,
  quoted_amount_centavos,final_charge_centavos,payment_method,payment_status,status,
  pickup_address,pickup_latitude,pickup_longitude,pickup_code_hash,started_at
) values
  ('20000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000101','00000000-0000-4000-8000-000000000102','10000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000002',10000,10000,'cash','unpaid','completed','Test',14.95,120.91,'hash',now()-interval '3 hours'),
  ('20000000-0000-4000-8000-000000000002','00000000-0000-4000-8000-000000000101','00000000-0000-4000-8000-000000000102','10000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000002',10000,10000,'cash','under_review','completed','Test',14.95,120.91,'hash',now()-interval '3 hours'),
  ('20000000-0000-4000-8000-000000000003','00000000-0000-4000-8000-000000000103','00000000-0000-4000-8000-000000000102','10000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000002',10000,10000,'cash','under_review','completed','Test',14.95,120.91,'hash',now()-interval '3 hours');

insert into public.payments(id,booking_id,provider,amount_centavos,status,paid_at)
values ('30000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000002','cash',10000,'cash_paid',now());

-- ── Retired PayMongo functions stay closed to every client ────────────────
select is(has_function_privilege('authenticated','public.reserve_paymongo_refund(uuid,integer,text)','execute'),false,'signed-in users cannot reserve a PayMongo refund');
select is(has_function_privilege('authenticated','public.complete_paymongo_test_refund(uuid,integer,text)','execute'),false,'signed-in users cannot complete a PayMongo test refund');
select is(has_function_privilege('authenticated','public.approve_test_refund(uuid,integer,text)','execute'),false,'signed-in users cannot approve a test refund');
select is(has_function_privilege('authenticated','public.record_paymongo_checkout(uuid,text,text,integer)','execute'),false,'signed-in users cannot record a checkout');
select is(
  (select bool_or(has_function_privilege('authenticated',p.oid,'execute') or has_function_privilege('anon',p.oid,'execute'))
   from pg_proc p where p.pronamespace='public'::regnamespace and p.proname like '%paymongo%'),
  false,'no PayMongo function is executable by anon or authenticated');

-- ── Settling a disputed charge needs the finance capability ───────────────
set local role authenticated;
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000202',true);
select throws_ok(
  $$select public.resolve_booking_charge('20000000-0000-4000-8000-000000000002',6000,'Support must not settle charges')$$,
  'P0001','Finance administrator access required','support administrator cannot settle a charge'
);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000205',true);
select throws_ok(
  $$select public.resolve_booking_charge('20000000-0000-4000-8000-000000000002',6000,'Operations must not settle charges')$$,
  'P0001','Finance administrator access required','operations administrator cannot settle a charge'
);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000206',true);
select throws_ok(
  $$select public.resolve_booking_charge('20000000-0000-4000-8000-000000000002',6000,'Content must not settle charges')$$,
  'P0001','Finance administrator access required','content administrator cannot settle a charge'
);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000207',true);
select throws_ok(
  $$select public.resolve_booking_charge('20000000-0000-4000-8000-000000000002',6000,'Compliance must not settle charges')$$,
  'P0001','Finance administrator access required','compliance administrator cannot settle a charge'
);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000204',true);
select throws_ok(
  $$select public.resolve_booking_charge('20000000-0000-4000-8000-000000000002',6000,'Inactive must not settle charges')$$,
  'P0001','Finance administrator access required','inactive finance administrator cannot settle a charge'
);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000101',true);
select throws_ok(
  $$select public.resolve_booking_charge('20000000-0000-4000-8000-000000000002',6000,'Tourist must not settle charges')$$,
  'P0001','Finance administrator access required','tourist cannot settle a charge'
);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000102',true);
select throws_ok(
  $$select public.resolve_booking_charge('20000000-0000-4000-8000-000000000002',6000,'Driver must not settle charges')$$,
  'P0001','Finance administrator access required','driver cannot settle a charge'
);
reset role;
set local role anon;
select set_config('request.jwt.claim.role','anon',true);
select throws_ok(
  $$select public.resolve_booking_charge('20000000-0000-4000-8000-000000000002',6000,'Missing auth must not settle')$$,
  '42501','permission denied for function resolve_booking_charge','anonymous caller cannot invoke charge settlement'
);
reset role;
set local role authenticated;
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000201',true);
select lives_ok(
  $$select public.resolve_booking_charge('20000000-0000-4000-8000-000000000002',6000,'Authorized finance settlement')$$,
  'finance administrator can lower a disputed charge'
);
select throws_ok(
  $$select public.resolve_booking_charge('20000000-0000-4000-8000-000000000002',5000,'Second settlement attempt')$$,
  'P0001','Booking or final charge is invalid','a settled booking cannot be settled again'
);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000203',true);
select lives_ok(
  $$select public.resolve_booking_charge('20000000-0000-4000-8000-000000000003',0,'Authorized super waiver')$$,
  'super administrator retains the finance bypass'
);
reset role;
select is((select payment_status::text from public.bookings where id='20000000-0000-4000-8000-000000000002'),'refund_required','overpaid cash after a lower charge requires a refund');
select is((select final_charge_centavos from public.bookings where id='20000000-0000-4000-8000-000000000002'),6000,'the settled charge is stored');
select is((select payment_status::text from public.bookings where id='20000000-0000-4000-8000-000000000003'),'waived','a zero charge with nothing paid is waived');
select is((select count(*)::integer from public.trip_events where event_type='settlement_resolved' and booking_id::text like '20000000-%'),2,'each settlement is audited');

-- ── Publishing fares needs the finance capability ─────────────────────────
set local role authenticated;
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000202',true);
select throws_ok(
  $$select public.publish_fares(10000,'{}'::jsonb,'Support must not publish fares')$$,
  'P0001','Finance administrator access required','support administrator cannot publish fares'
);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000201',true);
select lives_ok(
  $$select public.publish_fares(10000,'{}'::jsonb,'Finance publishes test fares')$$,
  'finance administrator can publish fares'
);

-- ── Cash payment needs both participants and posts one ledger credit ──────
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000103',true);
select throws_ok(
  $$select public.confirm_cash('20000000-0000-4000-8000-000000000001','payment')$$,
  'P0001','Only a participant can confirm cash','a stranger cannot confirm cash on another trip'
);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000101',true);
select throws_ok(
  $$select public.confirm_cash('20000000-0000-4000-8000-000000000001','tip')$$,
  'P0001','Invalid cash direction','an unknown cash direction is refused'
);
select lives_ok(
  $$select public.confirm_cash('20000000-0000-4000-8000-000000000001','payment')$$,
  'the tourist confirms handing over the cash'
);
select lives_ok(
  $$select public.confirm_cash('20000000-0000-4000-8000-000000000001','payment')$$,
  'a repeated tourist confirmation is harmless'
);
reset role;
select is((select payment_status::text from public.bookings where id='20000000-0000-4000-8000-000000000001'),'cash_awaiting_confirmation','one side alone does not mark cash as paid');
select is((select count(*)::integer from public.cash_confirmations where booking_id='20000000-0000-4000-8000-000000000001'),1,'a repeated confirmation is stored once');
set local role authenticated;
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000102',true);
select lives_ok(
  $$select public.confirm_cash('20000000-0000-4000-8000-000000000001','payment')$$,
  'the driver confirms receiving the cash'
);
reset role;
select is((select payment_status::text from public.bookings where id='20000000-0000-4000-8000-000000000001'),'cash_paid','both confirmations mark cash as paid');
select is((select count(*)::integer from public.payments where booking_id='20000000-0000-4000-8000-000000000001' and status='cash_paid' and amount_centavos=10000),1,'one cash payment for the final charge');
select is((select count(*)::integer from public.financial_ledger_entries where booking_id='20000000-0000-4000-8000-000000000001' and entry_type='payment_received' and amount_centavos=10000),1,'cash payment creates one ledger credit');

-- ── Ledger entries cannot be edited or removed ────────────────────────────
select throws_ok(
  $$update public.financial_ledger_entries set amount_centavos=1 where booking_id='20000000-0000-4000-8000-000000000001'$$,
  'P0001','Financial ledger entries are immutable','ledger entries cannot be edited'
);
select throws_ok(
  $$delete from public.financial_ledger_entries where booking_id='20000000-0000-4000-8000-000000000001'$$,
  'P0001','Financial ledger entries are immutable','ledger entries cannot be deleted'
);

select * from finish();
rollback;

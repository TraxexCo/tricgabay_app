begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select no_plan();

-- 1,2 tourists · 3 driver · 5 finance admin
insert into auth.users(id, email, raw_user_meta_data)
select ('c6150000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  'gcash-dispute-fixture-' || i || '@example.test',
  jsonb_build_object('full_name', 'Dispute fixture ' || i,
    'requested_role', case when i = 3 then 'driver' else 'tourist' end)
from generate_series(1,5) i;
update public.profiles set status = 'active' where id::text like 'c6150000-%';
update public.profiles set role = 'admin' where id = 'c6150000-0000-4000-8000-000000000005';
insert into public.admin_capabilities(profile_id, capability)
values ('c6150000-0000-4000-8000-000000000005', 'finance');
insert into public.driver_profiles(profile_id, plate_number, franchise_number, approval_status)
values ('c6150000-0000-4000-8000-000000000003', 'DISP-3', 'DISP-FR-3', 'approved');

insert into public.fare_revisions(id, custom_fare_centavos, reason)
values ('c6160000-0000-4000-8000-000000000001', 15000, 'Dispute fixture');
insert into public.cancellation_policies(id, terms)
values ('c6160000-0000-4000-8000-000000000002', 'Dispute fixture');
-- B1,B2,B4: tourist 1 · B3: tourist 2. All completed GCash trips with driver 3.
insert into public.bookings(id, tourist_id, driver_id, fare_revision_id, cancellation_policy_id,
  quoted_amount_centavos, final_charge_centavos, payment_method, status, pickup_address,
  pickup_latitude, pickup_longitude, pickup_code_hash)
select ('c6170000-0000-4000-8000-' || lpad(i::text,12,'0'))::uuid,
  case when i = 3 then 'c6150000-0000-4000-8000-000000000002'::uuid
       else 'c6150000-0000-4000-8000-000000000001'::uuid end,
  'c6150000-0000-4000-8000-000000000003',
  'c6160000-0000-4000-8000-000000000001', 'c6160000-0000-4000-8000-000000000002',
  15000, 15000, 'gcash_direct', 'completed', 'Dispute fixture', 14.9571, 120.9188, 'fixture'
from generate_series(1,4) i;
insert into storage.objects(bucket_id, name) values
  ('gcash-receipts', 'c6170000-0000-4000-8000-000000000001/d6170000-0000-4000-8000-000000000001.jpg'),
  ('gcash-receipts', 'c6170000-0000-4000-8000-000000000002/d6170000-0000-4000-8000-000000000002.jpg');

create function pg_temp.act(p_user text) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  perform set_config('request.jwt.claim.sub', 'c6150000-0000-4000-8000-00000000000' || p_user, true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', 'c6150000-0000-4000-8000-00000000000' || p_user, 'role', 'authenticated')::text, true);
end $$;

-- Driver reports non-receipt on B1, B2, B3, B4.
select pg_temp.act('3');
set local role authenticated;
select lives_ok($$ select public.driver_flag_gcash_not_received(id, 'Not in my history')
  from public.bookings where id::text like 'c6170000-%' $$, 'driver can report non-receipt');

-- Tourist must answer with proof, not another "I've paid".
select pg_temp.act('1');
select throws_like($$ select public.tourist_mark_gcash_sent('c6170000-0000-4000-8000-000000000001', 'ABCD1234') $$,
  '%GCASH_PROOF_REQUIRED%', 'disputed payment requires proof');
select throws_like($$ select public.tourist_submit_gcash_proof('c6170000-0000-4000-8000-000000000001',
  'ABCD12345678', 'c6170000-0000-4000-8000-000000000001/e6170000-0000-4000-8000-000000000009.jpg') $$,
  '%Upload the receipt screenshot first%', 'proof needs an uploaded receipt');
select lives_ok($$ select public.tourist_submit_gcash_proof('c6170000-0000-4000-8000-000000000001',
  'ABCD12345678', 'c6170000-0000-4000-8000-000000000001/d6170000-0000-4000-8000-000000000001.jpg') $$,
  'tourist submits proof');
select throws_like($$ select public.tourist_submit_gcash_proof('c6170000-0000-4000-8000-000000000002',
  'abcd12345678', 'c6170000-0000-4000-8000-000000000002/d6170000-0000-4000-8000-000000000002.jpg') $$,
  '%GCASH_REFERENCE_USED%', 'one reference cannot settle two bookings');

-- Receipt access: participants yes, other tourists no.
select is((select count(*)::int from storage.objects
  where name like 'c6170000-0000-4000-8000-000000000001/%'), 1, 'tourist can read own receipt');
select pg_temp.act('2');
select is((select count(*)::int from storage.objects
  where name like 'c6170000-0000-4000-8000-000000000001/%'), 0, 'other tourist cannot read receipt');
select throws_like($$ select public.get_gcash_dispute_detail('c6170000-0000-4000-8000-000000000001') $$,
  '%access denied%', 'other tourist cannot read dispute detail');
select pg_temp.act('3');
select is((select count(*)::int from storage.objects
  where name like 'c6170000-0000-4000-8000-000000000001/%'), 1, 'driver can read receipt');
select is((public.get_gcash_dispute_detail('c6170000-0000-4000-8000-000000000001')->>'reference_no'),
  'ABCD12345678', 'driver sees the reference in the detail');

-- Escalation by a participant.
select pg_temp.act('1');
select lives_ok($$ select public.request_gcash_admin_review('c6170000-0000-4000-8000-000000000001', 'Please check') $$,
  'tourist asks admin to decide');
reset role;
select isnt((select escalated_at from public.gcash_payment_confirmations
  where booking_id = 'c6170000-0000-4000-8000-000000000001'), null, 'escalation is recorded');

-- Auto-escalation after 24 hours only.
update public.gcash_payment_confirmations set disputed_at = now() - interval '25 hours'
  where booking_id = 'c6170000-0000-4000-8000-000000000002';
update public.gcash_payment_confirmations set disputed_at = now() - interval '23 hours'
  where booking_id = 'c6170000-0000-4000-8000-000000000003';
select ok(public.auto_escalate_gcash_disputes() >= 1, 'auto-escalation runs');
select isnt((select escalated_at from public.gcash_payment_confirmations
  where booking_id = 'c6170000-0000-4000-8000-000000000002'), null, '25-hour dispute escalated');
select is((select escalated_at from public.gcash_payment_confirmations
  where booking_id = 'c6170000-0000-4000-8000-000000000003'), null, '23-hour dispute not escalated');

-- Only finance/operations admins rule.
select pg_temp.act('1');
set local role authenticated;
select throws_like($$ select public.admin_rule_gcash_dispute('c6170000-0000-4000-8000-000000000001', 'paid', 'Self ruling') $$,
  '%access required%', 'tourist cannot rule');
select pg_temp.act('3');
select throws_like($$ select public.admin_rule_gcash_dispute('c6170000-0000-4000-8000-000000000001', 'paid', 'Self ruling') $$,
  '%access required%', 'driver cannot rule');

-- "Not paid" blocks new bookings until settled.
select pg_temp.act('5');
select ok((select count(*) from public.list_gcash_disputes()) >= 3, 'admin lists disputes');
select lives_ok($$ select public.admin_rule_gcash_dispute('c6170000-0000-4000-8000-000000000001', 'not_paid',
  'Driver history shows nothing') $$, 'admin rules not paid');
select pg_temp.act('1');
select is(public.get_my_outstanding_fare(), 'c6170000-0000-4000-8000-000000000001'::uuid, 'tourist sees outstanding fare');
select throws_like($$ select public.create_booking_with_schedule(null, 'cash', 'x', 14.9, 120.9, '[]'::jsonb,
  1, '', '', null, gen_random_uuid()) $$, '%OUTSTANDING_FARE%', 'blocked tourist cannot book');
select lives_ok($$ select public.tourist_switch_gcash_to_cash('c6170000-0000-4000-8000-000000000001') $$,
  'tourist can switch the unpaid fare to cash');
select is(public.get_my_outstanding_fare(), 'c6170000-0000-4000-8000-000000000001'::uuid,
  'switching to cash alone does not lift the block');
reset role;
update public.bookings set payment_status = 'cash_paid' where id = 'c6170000-0000-4000-8000-000000000001';
select isnt((select settled_at from public.payment_rulings
  where booking_id = 'c6170000-0000-4000-8000-000000000001'), null, 'confirmed cash settles the ruling');
select ok(not public.tourist_has_outstanding_fare('c6170000-0000-4000-8000-000000000001'), 'block lifted');

-- PayMongo is no longer offered.
select pg_temp.act('2');
set local role authenticated;
select throws_like($$ select public.create_booking_with_schedule(null, 'paymongo', 'x', 14.9, 120.9, '[]'::jsonb,
  1, '', '', null, gen_random_uuid()) $$, '%ONLINE_PAYMENT_UNAVAILABLE%', 'PayMongo bookings rejected');

-- "Paid" ruling records the payment.
select pg_temp.act('5');
select lives_ok($$ select public.admin_rule_gcash_dispute('c6170000-0000-4000-8000-000000000002', 'paid',
  'Receipt matches driver history') $$, 'admin rules paid');
reset role;
select is((select payment_status::text from public.bookings where id = 'c6170000-0000-4000-8000-000000000002'),
  'gcash_paid', 'paid ruling marks the fare paid');
select is((select count(*)::int from public.payments where booking_id = 'c6170000-0000-4000-8000-000000000002'),
  1, 'paid ruling records one payment');

-- Waiver lifts a block.
select pg_temp.act('5');
set local role authenticated;
select lives_ok($$ select public.admin_rule_gcash_dispute('c6170000-0000-4000-8000-000000000003', 'not_paid',
  'No receipt provided') $$, 'admin rules not paid for tourist 2');
select lives_ok($$ select public.admin_waive_unpaid_ruling('c6170000-0000-4000-8000-000000000003',
  'Goodwill waiver approved') $$, 'admin waives');
reset role;
select ok(not public.tourist_has_outstanding_fare('c6150000-0000-4000-8000-000000000002'), 'waiver lifts block');

-- Participants can still settle during an escalation; the admin then has nothing to rule.
update public.gcash_payment_confirmations set escalated_at = now()
  where booking_id = 'c6170000-0000-4000-8000-000000000004';
select pg_temp.act('3');
set local role authenticated;
select lives_ok($$ select public.driver_confirm_gcash_received('c6170000-0000-4000-8000-000000000004') $$,
  'driver confirms during escalation');
select pg_temp.act('5');
select throws_like($$ select public.admin_rule_gcash_dispute('c6170000-0000-4000-8000-000000000004', 'not_paid',
  'Too late ruling') $$, '%no longer disputed%', 'settled dispute cannot be ruled');
reset role;
select isnt((select disputed_at from public.gcash_payment_confirmations
  where booking_id = 'c6170000-0000-4000-8000-000000000004'), null, 'dispute history is kept after confirmation');

select * from finish();
rollback;

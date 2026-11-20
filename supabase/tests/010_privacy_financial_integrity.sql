begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;
select no_plan();
select set_config('request.jwt.claim.role','service_role',true);
insert into auth.users(id,email,raw_user_meta_data) values('b3300000-0000-4000-8000-000000000001','erase@example.test','{"full_name":"Erasure Fixture"}');
insert into public.fare_revisions(id,custom_fare_centavos,reason) values('b3310000-0000-4000-8000-000000000001',12500,'Erasure fixture');
insert into public.cancellation_policies(id,terms) values('b3310000-0000-4000-8000-000000000002','Erasure fixture');
insert into public.bookings(id,tourist_id,fare_revision_id,cancellation_policy_id,quoted_amount_centavos,final_charge_centavos,payment_method,payment_status,status,pickup_address,pickup_latitude,pickup_longitude,pickup_code_hash,created_at,completed_at)
values('b3320000-0000-4000-8000-000000000001','b3300000-0000-4000-8000-000000000001','b3310000-0000-4000-8000-000000000001','b3310000-0000-4000-8000-000000000002',12500,10000,'paymongo','partially_refunded','completed','Personal address',14.9571,120.9188,crypt('1234',gen_salt('bf')),now()-interval '2 days',now()-interval '1 day');
insert into public.payments(id,booking_id,provider,provider_mode,provider_checkout_id,provider_payment_id,amount_centavos,status,paid_at,created_at,updated_at) values('b3330000-0000-4000-8000-000000000001','b3320000-0000-4000-8000-000000000001','paymongo','test','cs_erasure','pay_erasure',12500,'paid',now()-interval '1 day',now()-interval '2 days',now()-interval '1 day');
insert into public.refunds(id,booking_id,payment_id,provider_refund_id,amount_centavos,reason,status,requested_by,created_at,updated_at,processed_at) values('b3340000-0000-4000-8000-000000000001','b3320000-0000-4000-8000-000000000001','b3330000-0000-4000-8000-000000000001','re_erasure',2500,'Personal refund statement','succeeded','b3300000-0000-4000-8000-000000000001',now()-interval '1 day',now()-interval '1 day',now()-interval '1 day');
insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description,created_at) values('b3320000-0000-4000-8000-000000000001','b3300000-0000-4000-8000-000000000001','tourist','fixture','Personal event text',now()-interval '1 day');
insert into public.disputes(id,booking_id,opened_by,reason,status,resolution,created_at,resolved_at) values('b3350000-0000-4000-8000-000000000001','b3320000-0000-4000-8000-000000000001','b3300000-0000-4000-8000-000000000001','Personal dispute','resolved','Personal resolution',now()-interval '1 day',now()-interval '1 hour');
insert into public.dispute_statements(dispute_id,author_id,statement) values('b3350000-0000-4000-8000-000000000001','b3300000-0000-4000-8000-000000000001','Personal statement');
create temp table before_financial as select id,to_jsonb(l)-'description'-'metadata' as value from public.financial_ledger_entries l where booking_id='b3320000-0000-4000-8000-000000000001';
create temp table before_timestamps as
select 'booking' as kind,b.id,(select jsonb_object_agg(key,value) from jsonb_each(to_jsonb(b)) where key like '%\_at' escape '\') as value from public.bookings b where id='b3320000-0000-4000-8000-000000000001'
union all select 'payment',p.id,(select jsonb_object_agg(key,value) from jsonb_each(to_jsonb(p)) where key like '%\_at' escape '\') from public.payments p where id='b3330000-0000-4000-8000-000000000001'
union all select 'refund',r.id,(select jsonb_object_agg(key,value) from jsonb_each(to_jsonb(r)) where key like '%\_at' escape '\') from public.refunds r where id='b3340000-0000-4000-8000-000000000001';
select lives_ok($$select public.prepare_account_deletion('b3300000-0000-4000-8000-000000000001','b3360000-0000-4000-8000-000000000001')$$,'prepare deletion succeeds with actual financial/audit rows');
select is((select count(*)::integer from public.profiles where id='b3300000-0000-4000-8000-000000000001'),0,'original profile removed');
select is((select to_jsonb(l)-'description'-'metadata' from public.financial_ledger_entries l where id=(select id from before_financial where value->>'entry_type'='payment_received')),(select value from before_financial where value->>'entry_type'='payment_received'),'payment ledger amount/reference/timestamps unchanged');
select is((select to_jsonb(l)-'description'-'metadata' from public.financial_ledger_entries l where id=(select id from before_financial where value->>'entry_type'='refund_completed')),(select value from before_financial where value->>'entry_type'='refund_completed'),'refund ledger amount/reference/timestamps unchanged');
select is((select jsonb_object_agg(key,value) from public.bookings b,jsonb_each(to_jsonb(b)) where id='b3320000-0000-4000-8000-000000000001' and key like '%\_at' escape '\'),(select value from before_timestamps where kind='booking'),'booking timestamps preserved');
select is((select jsonb_object_agg(key,value) from public.payments p,jsonb_each(to_jsonb(p)) where id='b3330000-0000-4000-8000-000000000001' and key like '%\_at' escape '\'),(select value from before_timestamps where kind='payment'),'payment timestamps preserved');
select is((select jsonb_object_agg(key,value) from public.refunds r,jsonb_each(to_jsonb(r)) where id='b3340000-0000-4000-8000-000000000001' and key like '%\_at' escape '\'),(select value from before_timestamps where kind='refund'),'refund timestamps preserved');
select is((select statement from public.dispute_statements where dispute_id='b3350000-0000-4000-8000-000000000001'),'Personal text removed on account deletion','dispute statement redacted');
select lives_ok($$select public.prepare_account_deletion('b3300000-0000-4000-8000-000000000001','b3360000-0000-4000-8000-000000000001')$$,'interrupted deletion can resume without a second anonymous identity');
select is((select count(*)::integer from public.account_deletion_requests where user_id='b3300000-0000-4000-8000-000000000001'),1,'one durable deletion request remains');
select is((select amount_centavos::text||':'||provider_checkout_id||':'||provider_payment_id from public.payments where id='b3330000-0000-4000-8000-000000000001'),'12500:cs_erasure:pay_erasure','payment amount and both provider identifiers unchanged');
select is((select amount_centavos::text||':'||provider_refund_id from public.refunds where id='b3340000-0000-4000-8000-000000000001'),'2500:re_erasure','refund amount and provider identifier unchanged');
select is((select created_at from public.trip_events where booking_id='b3320000-0000-4000-8000-000000000001' and event_type='fixture'),now()-interval '1 day','trip event timestamp preserved');
select is((select resolved_at from public.disputes where id='b3350000-0000-4000-8000-000000000001'),now()-interval '1 hour','dispute resolution timestamp preserved');
select set_config('app.privacy_erasure','on',true);
select throws_ok($$update public.financial_ledger_entries set amount_centavos=amount_centavos+1 where booking_id='b3320000-0000-4000-8000-000000000001'$$,'P0001','Financial ledger entries are immutable','privacy flag cannot change any ledger amount');
select set_config('app.privacy_erasure','',true);
create table public.batch3_protected_audit(user_id uuid references public.profiles(id),entry text);
insert into auth.users(id,email,raw_user_meta_data) values('b3300000-0000-4000-8000-000000000009','protected@example.test','{"full_name":"Protected Fixture"}');
insert into public.batch3_protected_audit values('b3300000-0000-4000-8000-000000000009','immutable fixture');
select throws_ok($$select public.prepare_account_deletion('b3300000-0000-4000-8000-000000000009','b3360000-0000-4000-8000-000000000009')$$,'23503',null,'unknown participant FK fails closed rather than mutating a future audit table');
select is((select user_id::text from public.batch3_protected_audit),'b3300000-0000-4000-8000-000000000009','unknown audit row unchanged after atomic rollback');
select * from finish();rollback;

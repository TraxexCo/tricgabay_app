begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;
select plan(9);
select set_config('request.jwt.claim.role','service_role',true);
insert into auth.users(id,email,raw_user_meta_data)
select ('b3000000-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,'timing-'||i||'@example.test','{"full_name":"Timing Fixture"}'::jsonb from generate_series(1,3) i;
insert into public.fare_revisions(id,custom_fare_centavos,reason) values('b3100000-0000-4000-8000-000000000001',12500,'Timing fixture');
insert into public.cancellation_policies(id,terms) values('b3100000-0000-4000-8000-000000000002','Timing fixture');
insert into public.bookings(id,tourist_id,fare_revision_id,cancellation_policy_id,quoted_amount_centavos,payment_method,payment_status,pickup_address,pickup_latitude,pickup_longitude,pickup_code_hash,created_at)
select ('b3200000-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,('b3000000-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,
'b3100000-0000-4000-8000-000000000001','b3100000-0000-4000-8000-000000000002',12500,'paymongo','unpaid','Timing fixture',14.9571,120.9188,crypt('1234',gen_salt('bf')),now()-interval '29 minutes' from generate_series(1,2) i;
update public.bookings set payment_expires_at=created_at+interval '30 minutes';
insert into public.payments(booking_id,provider,provider_mode,provider_checkout_id,checkout_url,amount_centavos,status)
select id,'paymongo','test','cs_timing_'||right(id::text,1),'https://checkout.paymongo.com/cs_timing_'||right(id::text,1),12500,'checkout_created' from public.bookings where id::text like 'b3200000%';
select public.process_paymongo_payment_event('evt_29','checkout_session.payment.paid',null,'cs_timing_1','pay_timing_1',12500,'PHP','paid',null,null,now(),'{}',gen_random_uuid());
select is((select status::text from public.bookings where id='b3200000-0000-4000-8000-000000000001'),'pending','payment at 29 minutes releases dispatch');
select is((select payment_status::text from public.bookings where id='b3200000-0000-4000-8000-000000000001'),'paid','timely payment is paid');
update public.bookings set created_at=now()-interval '31 minutes',payment_expires_at=now()-interval '1 minute' where id='b3200000-0000-4000-8000-000000000002';
select public.expire_unpaid_bookings();
select public.process_paymongo_payment_event('evt_31_after_cron','checkout_session.payment.paid',null,'cs_timing_2','pay_timing_2',12500,'PHP','paid',null,null,now(),'{}',gen_random_uuid());
select is((select status::text from public.bookings where id='b3200000-0000-4000-8000-000000000002'),'cancelled','cron-cancelled booking stays cancelled after payment');
select is((select payment_status::text from public.bookings where id='b3200000-0000-4000-8000-000000000002'),'refund_required','31-minute payment after cron requires refund');
insert into public.bookings(id,tourist_id,fare_revision_id,cancellation_policy_id,quoted_amount_centavos,payment_method,payment_status,pickup_address,pickup_latitude,pickup_longitude,pickup_code_hash,created_at)
values('b3200000-0000-4000-8000-000000000003','b3000000-0000-4000-8000-000000000003','b3100000-0000-4000-8000-000000000001','b3100000-0000-4000-8000-000000000002',12500,'paymongo','unpaid','Timing fixture',14.9571,120.9188,crypt('1234',gen_salt('bf')),now()-interval '31 minutes');
update public.bookings set payment_expires_at=created_at+interval '30 minutes' where id='b3200000-0000-4000-8000-000000000003';
insert into public.payments(booking_id,provider,provider_mode,provider_checkout_id,checkout_url,amount_centavos,status) values('b3200000-0000-4000-8000-000000000003','paymongo','test','cs_timing_3','https://checkout.paymongo.com/cs_timing_3',12500,'checkout_created');
select public.process_paymongo_payment_event('evt_31_before_cron','checkout_session.payment.paid',null,'cs_timing_3','pay_timing_3',12500,'PHP','paid',null,null,now(),'{}',gen_random_uuid());
select is((select status::text from public.bookings where id='b3200000-0000-4000-8000-000000000003'),'cancelled','31-minute payment before cron cannot dispatch');
select is((select payment_status::text from public.bookings where id='b3200000-0000-4000-8000-000000000003'),'refund_required','31-minute payment before cron requires refund');
select is((select sum(amount_centavos)::bigint from public.financial_ledger_entries where booking_id::text like 'b3200000%'),37500::bigint,'all received funds are retained in the ledger');
select is((select count(*)::integer from public.booking_offers where booking_id in ('b3200000-0000-4000-8000-000000000002','b3200000-0000-4000-8000-000000000003')),0,'late payments create no offers');
select is((select count(*)::integer from public.bookings where status='cancelled' and payment_status='paid' and id::text like 'b3200000%'),0,'no cancelled+paid financial limbo');
select * from finish();
rollback;

begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;
select plan(3);
insert into auth.users(id,email,raw_user_meta_data)values
('b4900000-0000-4000-8000-000000000001','list-tourist-a@example.test','{"full_name":"List Tourist A"}'),
('b4900000-0000-4000-8000-000000000002','list-tourist-b@example.test','{"full_name":"List Tourist B"}'),
('b4900000-0000-4000-8000-000000000003','list-driver-a@example.test','{"full_name":"List Driver A","requested_role":"driver"}'),
('b4900000-0000-4000-8000-000000000004','list-driver-b@example.test','{"full_name":"List Driver B","requested_role":"driver"}');
update public.profiles set status='active' where id in('b4900000-0000-4000-8000-000000000003','b4900000-0000-4000-8000-000000000004');
insert into public.driver_profiles(profile_id,plate_number,franchise_number,approval_status)values
('b4900000-0000-4000-8000-000000000003','LIST-A','LIST-FR-A','approved'),('b4900000-0000-4000-8000-000000000004','LIST-B','LIST-FR-B','approved');
insert into public.fare_revisions(id,custom_fare_centavos,reason)values('b4910000-0000-4000-8000-000000000001',10000,'List fixture');
insert into public.cancellation_policies(id,terms)values('b4910000-0000-4000-8000-000000000002','List fixture');
insert into public.bookings(id,tourist_id,fare_revision_id,cancellation_policy_id,quoted_amount_centavos,payment_method,status,pickup_address,pickup_latitude,pickup_longitude,pickup_code_hash)
select ('b4920000-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,('b4900000-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,
'b4910000-0000-4000-8000-000000000001','b4910000-0000-4000-8000-000000000002',10000,'cash','pending','List fixture',14.9571,120.9188,crypt('2468',gen_salt('bf')) from generate_series(1,2)i;
insert into public.booking_offers(booking_id,driver_id,status,expires_at)values
('b4920000-0000-4000-8000-000000000001','b4900000-0000-4000-8000-000000000003','offered',now()+interval '10 minutes'),
('b4920000-0000-4000-8000-000000000002','b4900000-0000-4000-8000-000000000004','offered',now()+interval '10 minutes');
set local role authenticated;
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','b4900000-0000-4000-8000-000000000003',true);
select is((select count(*)::integer from public.bookings where id::text like 'b4920000-%' and (driver_id=auth.uid() or status='pending') and status in('payment_pending','scheduled','pending','accepted','replacement_pending','ongoing')),1,'optimized driver active list retains the matched unassigned offer');
select is((select count(*)::integer from public.bookings where id='b4920000-0000-4000-8000-000000000002' and (driver_id=auth.uid() or status='pending')),0,'RLS rejects another drivers pending offer despite the candidate predicate');
select is((select count(*)::integer from public.bookings where id::text like 'b4920000-%' and driver_id=auth.uid()),0,'history participant filter excludes unassigned offers fetched by active list');
select * from finish();rollback;

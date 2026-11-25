-- Isolated synthetic benchmark only. Workflow side effects are bypassed during
-- bulk INSERT to avoid generating 100,000 artificial notifications/payments.
begin;
insert into auth.users(id,email,raw_user_meta_data)
select ('c4100000-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,'benchmark-'||i||'@example.test',
jsonb_build_object('full_name','Synthetic benchmark account','requested_role',case when i>100 then 'driver' else 'tourist' end)
from generate_series(1,200)i;
update public.profiles set status='active' where id::text like 'c4100000-%';
insert into public.driver_profiles(profile_id,plate_number,franchise_number,approval_status,license_expires_on,franchise_expires_on,vehicle_inspection_expires_on)
select ('c4100000-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,'BENCH-'||i,'BENCH-FR-'||i,'approved',current_date+365,current_date+365,current_date+365 from generate_series(101,200)i;
insert into public.fare_revisions(id,custom_fare_centavos,reason,is_current)values('c4200000-0000-4000-8000-000000000001',10000,'Synthetic benchmark fare',false);
insert into public.cancellation_policies(id,terms,is_current)values('c4200000-0000-4000-8000-000000000002','Synthetic benchmark policy',false);
set local session_replication_role=replica;
with code as materialized(select crypt('2468',gen_salt('bf')) hash)
insert into public.bookings(id,tourist_id,driver_id,fare_revision_id,cancellation_policy_id,quoted_amount_centavos,payment_method,payment_status,status,pickup_address,pickup_latitude,pickup_longitude,pickup_code_hash,created_at)
select ('c4300000-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,
('c4100000-0000-4000-8000-'||lpad(((i-1)%100+1)::text,12,'0'))::uuid,
('c4100000-0000-4000-8000-'||lpad(((i-1)%100+101)::text,12,'0'))::uuid,
'c4200000-0000-4000-8000-000000000001','c4200000-0000-4000-8000-000000000002',10000,'cash','paid',
case when i%10=0 then 'cancelled'::public.booking_status else 'completed'::public.booking_status end,
'Synthetic benchmark pickup',14.9571,120.9188,code.hash,now()-make_interval(secs=>i)
from generate_series(1,100000)i cross join code;
set local session_replication_role=origin;
commit;
analyze public.bookings;
select count(*) from public.bookings where id::text like 'c4300000-%';

begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;

select plan(14);

insert into auth.users(id,email,raw_user_meta_data)
values
  ('40000000-0000-4000-8000-000000000101','owner@test.local','{"full_name":"Owner"}'),
  ('40000000-0000-4000-8000-000000000102','other@test.local','{"full_name":"Other"}'),
  ('40000000-0000-4000-8000-000000000103','driver@test.local','{"full_name":"Driver","requested_role":"driver"}'),
  ('40000000-0000-4000-8000-000000000201','finance@test.local','{"full_name":"Finance"}'),
  ('40000000-0000-4000-8000-000000000202','support@test.local','{"full_name":"Support"}'),
  ('40000000-0000-4000-8000-000000000203','operations@test.local','{"full_name":"Operations"}'),
  ('40000000-0000-4000-8000-000000000204','content@test.local','{"full_name":"Content"}'),
  ('40000000-0000-4000-8000-000000000205','compliance@test.local','{"full_name":"Compliance"}');

update public.profiles set role='admin',status='active'
where id in (
  '40000000-0000-4000-8000-000000000201',
  '40000000-0000-4000-8000-000000000202',
  '40000000-0000-4000-8000-000000000203',
  '40000000-0000-4000-8000-000000000204',
  '40000000-0000-4000-8000-000000000205'
);
update public.profiles set role='driver',status='active'
where id='40000000-0000-4000-8000-000000000103';
insert into public.admin_capabilities(profile_id,capability)
values
  ('40000000-0000-4000-8000-000000000201','finance'),
  ('40000000-0000-4000-8000-000000000202','support'),
  ('40000000-0000-4000-8000-000000000203','operations'),
  ('40000000-0000-4000-8000-000000000204','content'),
  ('40000000-0000-4000-8000-000000000205','driver_compliance');
insert into public.driver_profiles(
  profile_id,plate_number,franchise_number,approval_status,is_online
) values (
  '40000000-0000-4000-8000-000000000103','RLS-01','RLS-FRANCHISE','approved',true
);
insert into public.driver_locations(
  driver_id,latitude,longitude,accuracy_meters,recorded_at
) values (
  '40000000-0000-4000-8000-000000000103',14.95,120.91,5,now()
);
insert into public.fare_revisions(
  id,custom_fare_centavos,package_fares,is_current,reason
) values ('41000000-0000-4000-8000-000000000001',10000,'{}',false,'RLS test fare');
insert into public.cancellation_policies(id,is_current,terms)
values ('41000000-0000-4000-8000-000000000002',false,'RLS test policy');
insert into public.bookings(
  id,tourist_id,driver_id,fare_revision_id,cancellation_policy_id,
  quoted_amount_centavos,payment_method,payment_status,status,
  pickup_address,pickup_latitude,pickup_longitude,pickup_code_hash
) values (
  '42000000-0000-4000-8000-000000000001',
  '40000000-0000-4000-8000-000000000101',
  '40000000-0000-4000-8000-000000000103',
  '41000000-0000-4000-8000-000000000001',
  '41000000-0000-4000-8000-000000000002',
  10000,'paymongo','paid','ongoing','RLS test',14.95,120.91,'hash'
);
insert into public.payments(
  id,booking_id,provider,provider_mode,provider_checkout_id,provider_payment_id,
  amount_centavos,status,paid_at
) values (
  '43000000-0000-4000-8000-000000000001',
  '42000000-0000-4000-8000-000000000001',
  'paymongo','test','cs_rls','pay_rls',10000,'paid',now()
);
insert into storage.objects(id,bucket_id,name)
values
  ('44000000-0000-4000-8000-000000000001','driver-documents','40000000-0000-4000-8000-000000000103/license.jpg'),
  ('44000000-0000-4000-8000-000000000002','profile-images','40000000-0000-4000-8000-000000000101/avatar.jpg'),
  ('44000000-0000-4000-8000-000000000003','profile-images','40000000-0000-4000-8000-000000000102/avatar.jpg'),
  ('44000000-0000-4000-8000-000000000004','profile-images','40000000-0000-4000-8000-000000000101/avatars/version-1.jpg'),
  ('44000000-0000-4000-8000-000000000005','profile-images','40000000-0000-4000-8000-000000000102/avatars/version-1.jpg');

set local role authenticated;
select set_config('request.jwt.claim.role','authenticated',true);

select set_config('request.jwt.claim.sub','40000000-0000-4000-8000-000000000201',true);
select is((select count(*)::integer from public.payments),1,'finance can read financial records');
select set_config('request.jwt.claim.sub','40000000-0000-4000-8000-000000000202',true);
select is((select count(*)::integer from public.payments),0,'support cannot read financial records');

select set_config('request.jwt.claim.sub','40000000-0000-4000-8000-000000000203',true);
select is((select count(*)::integer from public.driver_locations),1,'operations can read precise live location');
select set_config('request.jwt.claim.sub','40000000-0000-4000-8000-000000000202',true);
select is((select count(*)::integer from public.driver_locations),0,'support cannot read precise live location');

select set_config('request.jwt.claim.sub','40000000-0000-4000-8000-000000000205',true);
select is((select count(*)::integer from public.driver_profiles),1,'compliance can read driver compliance records');
select is((select count(*)::integer from storage.objects where bucket_id='driver-documents'),1,'compliance can read driver documents');
select set_config('request.jwt.claim.sub','40000000-0000-4000-8000-000000000202',true);
select is((select count(*)::integer from storage.objects where bucket_id='driver-documents'),0,'support cannot read driver documents');

select set_config('request.jwt.claim.sub','40000000-0000-4000-8000-000000000204',true);
select lives_ok($$
  insert into public.tourist_spots(
    id,name,description,category,address,latitude,longitude,is_active
  ) values ('rls-test-spot','RLS test spot','','other','Bustos',14.95,120.91,true)
$$,'content can create catalog records');
select set_config('request.jwt.claim.sub','40000000-0000-4000-8000-000000000202',true);
select throws_ok($$
  insert into public.tourist_spots(
    id,name,description,category,address,latitude,longitude,is_active
  ) values ('rls-denied-spot','Denied spot','','other','Bustos',14.95,120.91,true)
$$,'42501','new row violates row-level security policy for table "tourist_spots"','support cannot create catalog records');

select set_config('request.jwt.claim.sub','40000000-0000-4000-8000-000000000101',true);
select is((select count(*)::integer from storage.objects where bucket_id='profile-images'),2,'user reads only own legacy and versioned avatars');
select lives_ok($$
  update storage.objects set metadata='{"validated":true}'::jsonb
  where bucket_id='profile-images' and name='40000000-0000-4000-8000-000000000101/avatars/version-1.jpg'
$$,'user can update own versioned avatar object');
select is_empty($$
  update storage.objects set metadata='{"attack":true}'::jsonb
  where bucket_id='profile-images' and name='40000000-0000-4000-8000-000000000102/avatar.jpg'
  returning 1
$$,'cross-user avatar overwrite is denied');
select throws_ok($$
  insert into storage.objects(id,bucket_id,name)
  values(
    '44000000-0000-4000-8000-000000000006',
    'profile-images',
    '40000000-0000-4000-8000-000000000102/avatars/attack.jpg'
  )
$$,'42501','new row violates row-level security policy for table "objects"','cross-user versioned avatar creation is denied');
reset role;
select ok(
  exists(
    select 1 from pg_policies
    where schemaname='storage'
      and tablename='objects'
      and policyname='profile_images_own_delete'
      and cmd='DELETE'
      and roles='{authenticated}'::name[]
      and qual like '%auth.uid()%'
      and qual like '%avatars/%'
  ),
  'avatar deletion policy is restricted to the authenticated owner path'
);

select * from finish();
rollback;


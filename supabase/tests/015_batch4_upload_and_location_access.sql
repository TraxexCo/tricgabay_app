begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;
select no_plan();
insert into auth.users(id,email,raw_user_meta_data)
select ('b4600000-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,'access-b4-'||i||'@example.test',jsonb_build_object('full_name','Access Fixture','requested_role',case when i>=3 then 'driver' else 'tourist' end) from generate_series(1,5)i;
update public.profiles set status='active' where id::text like 'b4600000%' and right(id::text,1)<>'5';
insert into public.driver_profiles(profile_id,plate_number,franchise_number,approval_status,is_online)
select id,'ACCESS-'||right(id::text,1),'ACCESS-FR-'||right(id::text,1),'approved',true from public.profiles where id::text like 'b4600000%' and right(id::text,1) in ('3','4');
insert into public.fare_revisions(id,custom_fare_centavos,reason) values('b4610000-0000-4000-8000-000000000001',12500,'Access fixture');
insert into public.cancellation_policies(id,terms) values('b4610000-0000-4000-8000-000000000002','Access fixture');
insert into public.bookings(id,tourist_id,driver_id,fare_revision_id,cancellation_policy_id,quoted_amount_centavos,payment_method,status,pickup_address,pickup_latitude,pickup_longitude,pickup_code_hash)
select ('b4620000-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,('b4600000-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,('b4600000-0000-4000-8000-'||lpad((i+2)::text,12,'0'))::uuid,'b4610000-0000-4000-8000-000000000001','b4610000-0000-4000-8000-000000000002',12500,'cash','accepted','Access fixture',14.9571,120.9188,crypt('1234',gen_salt('bf')) from generate_series(1,2)i;
insert into public.driver_locations(driver_id,latitude,longitude,recorded_at) select profile_id,14.9571,120.9188,now() from public.driver_profiles where profile_id::text like 'b4600000%';
set local role authenticated;
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','b4600000-0000-4000-8000-000000000001',true);
select is((select count(*)::integer from public.driver_locations where driver_id='b4600000-0000-4000-8000-000000000003'),1,'tourist A sees assigned driver A');
select is((select count(*)::integer from public.driver_locations where driver_id='b4600000-0000-4000-8000-000000000004'),0,'tourist A cannot see unrelated driver B even while on a trip');
select set_config('request.jwt.claim.sub','b4600000-0000-4000-8000-000000000002',true);
select is((select count(*)::integer from public.driver_locations where driver_id='b4600000-0000-4000-8000-000000000003'),0,'tourist B cannot see driver A');
select is((select count(*)::integer from public.driver_locations where driver_id='b4600000-0000-4000-8000-000000000004'),1,'tourist B sees assigned driver B');
select set_config('request.jwt.claim.sub','b4600000-0000-4000-8000-000000000005',true);
select lives_ok($$insert into storage.objects(bucket_id,name,metadata) values('driver-documents','b4600000-0000-4000-8000-000000000005/license.jpg','{"mimetype":"image/jpeg","size":4}')$$,'pending driver can upload own JPEG metadata');
select throws_ok($$insert into storage.objects(bucket_id,name,metadata) values('driver-documents','b4600000-0000-4000-8000-000000000005/vehicle-registration.jpg','{"mimetype":"image/png","size":4}')$$,'42501',null,'MIME and destination extension mismatch rejected');
select throws_ok($$insert into storage.objects(bucket_id,name,metadata) values('driver-documents','b4600000-0000-4000-8000-000000000005/other.jpg','{"mimetype":"image/jpeg","size":4}')$$,'42501',null,'unexpected driver document name rejected');
select throws_ok($$insert into storage.objects(bucket_id,name,metadata) values('driver-documents','b4600000-0000-4000-8000-000000000005/vehicle-registration.jpg','{"mimetype":"image/jpeg","size":5242881}')$$,'42501',null,'oversize driver document metadata rejected');
select set_config('request.jwt.claim.sub','b4600000-0000-4000-8000-000000000001',true);
select is((select count(*)::integer from storage.objects where bucket_id='driver-documents' and name like 'b4600000%'),0,'another account cannot read a driver document');
select throws_ok($$insert into storage.objects(bucket_id,name,metadata) values('driver-documents','b4600000-0000-4000-8000-000000000001/license.jpg','{"mimetype":"image/jpeg","size":4}')$$,'42501',null,'tourist cannot submit driver documents under its own prefix');
reset role;
select is((select public from storage.buckets where id='driver-documents'),false,'driver bucket stays private');
select is((select file_size_limit from storage.buckets where id='driver-documents'),5242880::bigint,'driver bucket independently limits bytes');
select is((select allowed_mime_types::text from storage.buckets where id='driver-documents'),'{image/jpeg}','driver bucket independently limits MIME');
select is(public.valid_image_object('bad.jpg','{"mimetype":"image/jpeg","size":"not a number"}',5242880,true),false,'invalid size metadata fails closed without a cast exception');
select is(public.valid_image_object('license.jpg','{"mimetype":"image/jpeg","contentLength":4}',5242880,true),true,'Storage preflight contentLength is accepted before persisted size exists');
select is(public.valid_image_object('license.jpg','{"mimetype":"image/jpeg","contentLength":5242881}',5242880,true),false,'Storage preflight oversize body is rejected');
select is(public.valid_image_object('license.jpg','{"mimetype":"image/jpeg","size":5242881,"contentLength":4}',5242880,true),false,'persisted size takes precedence over preflight size');
select * from finish();rollback;

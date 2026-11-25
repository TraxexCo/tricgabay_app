begin;
insert into auth.users(id,email,raw_user_meta_data)
select ('b3500000-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,'concurrency-'||i||'@example.test',jsonb_build_object('full_name','Concurrency Fixture','requested_role',case when i>100 then 'driver' else 'tourist' end)
from unnest(array[1,2,3,101,102]) i;
update public.profiles set status='active' where id::text like 'b3500000%';
insert into public.driver_profiles(profile_id,plate_number,franchise_number,license_document_path,vehicle_document_path,approval_status,is_online,last_seen_at,license_expires_on,franchise_expires_on,vehicle_inspection_expires_on,service_area_name,service_area_latitude,service_area_longitude,service_area_radius_km)
select id,'TEST-'||right(id::text,3),'TEST-FR-'||right(id::text,3),id::text||'/license.jpg',id::text||'/vehicle.jpg','approved',true,now(),current_date+365,current_date+365,current_date+365,'Fixture service area',14.9571,120.9188,15 from public.profiles where id in ('b3500000-0000-4000-8000-000000000101','b3500000-0000-4000-8000-000000000102');
insert into public.driver_locations(driver_id,latitude,longitude,accuracy_meters,recorded_at) select profile_id,14.9571,120.9188,5,now() from public.driver_profiles where profile_id::text like 'b3500000%';
update public.fare_revisions set is_current=false where is_current;
insert into public.fare_revisions(custom_fare_centavos,package_fares,is_current,reason) values(10000,'{}',true,'Concurrency fixture fare');
update public.cancellation_policies set is_current=false where is_current;
insert into public.cancellation_policies(is_current,terms) values(true,'Concurrency fixture terms');
insert into public.tourist_spots(id,name,category,address,latitude,longitude) values('batch3-concurrency','Fixture stop','other','Fixture address',14.9571,120.9188);
commit;

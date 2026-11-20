-- All identities, documents and money below are synthetic and transaction-local.
create function pg_temp.matrix_id(entity integer,subject integer) returns uuid
language sql immutable as $$select ('a4'||lpad(to_hex(entity),6,'0')||'-0000-4000-8000-'||lpad(subject::text,12,'0'))::uuid$$;
do $$begin perform set_config('request.jwt.claim.role','service_role',true);end $$;
insert into auth.users(id,email,raw_user_meta_data)
select pg_temp.matrix_id(1,i),'matrix-'||i||'@example.test',jsonb_build_object('full_name','Matrix User '||i,'requested_role',case when i in (3,4,6) then 'driver' else 'tourist' end)
from unnest(array[1,2,3,4,5,6,11,12,13,14,15,16])i;
update public.profiles set role='admin' where id in(select pg_temp.matrix_id(1,i) from generate_series(11,16)i);
update public.profiles set status='active' where id in(pg_temp.matrix_id(1,3),pg_temp.matrix_id(1,4));
update public.profiles set status='suspended' where id=pg_temp.matrix_id(1,5);
insert into public.admin_capabilities(profile_id,capability)
select pg_temp.matrix_id(1,i),case i when 11 then 'super_admin' when 12 then 'finance' when 13 then 'driver_compliance' when 14 then 'content' when 15 then 'support' else 'operations' end from generate_series(11,16)i;
insert into public.driver_profiles(profile_id,plate_number,franchise_number,license_document_path,vehicle_document_path,approval_status,is_online,last_seen_at,license_expires_on,franchise_expires_on,vehicle_inspection_expires_on,service_area_name,service_area_latitude,service_area_longitude,service_area_radius_km)
select pg_temp.matrix_id(1,i),'MATRIX-'||i,'MATRIX-FR-'||i,pg_temp.matrix_id(1,i)||'/license.jpg',pg_temp.matrix_id(1,i)||'/vehicle-registration.jpg',case when i=6 then 'pending'::public.driver_approval_status else 'approved'::public.driver_approval_status end,i<>6,now(),current_date+365,current_date+365,current_date+365,'Matrix area',14.9571,120.9188,15 from unnest(array[3,4,6])i;
insert into public.tourist_spots(id,name,category,address,latitude,longitude) values('matrix-a','Matrix attraction A','heritage','Synthetic address A',14.9571,120.9188),('matrix-b','Matrix attraction B','nature','Synthetic address B',14.958,120.919);
insert into public.tour_packages(id,name,is_active) values('matrix-package-a','Matrix package A',true),('matrix-package-b','Matrix package B',false);
insert into public.tour_package_stops(package_id,spot_id,stop_order) values('matrix-package-a','matrix-a',1),('matrix-package-b','matrix-b',1);
update public.fare_revisions set is_current=false where is_current;
update public.cancellation_policies set is_current=false where is_current;
insert into public.fare_revisions(id,custom_fare_centavos,reason,is_current) values(pg_temp.matrix_id(5,1),10000,'Matrix fixture fare',true);
insert into public.cancellation_policies(id,terms,is_current) values(pg_temp.matrix_id(6,1),'Matrix fixture policy',true);
insert into public.bookings(id,tourist_id,driver_id,fare_revision_id,cancellation_policy_id,quoted_amount_centavos,payment_method,payment_status,status,pickup_address,pickup_latitude,pickup_longitude,pickup_code_hash)
select pg_temp.matrix_id(2,i),pg_temp.matrix_id(1,i),pg_temp.matrix_id(1,i+2),pg_temp.matrix_id(5,1),pg_temp.matrix_id(6,1),10000,'cash','unpaid','ongoing','Synthetic matrix pickup',14.9571,120.9188,crypt('2468',gen_salt('bf')) from generate_series(1,2)i;
insert into public.booking_stops(id,booking_id,spot_id,stop_order,spot_name_snapshot,latitude_snapshot,longitude_snapshot)
select pg_temp.matrix_id(7,i),pg_temp.matrix_id(2,i),case when i=1 then 'matrix-a' else 'matrix-b' end,1,'Synthetic stop',14.9571,120.9188 from generate_series(1,2)i;
update public.tourist_spots set is_active=false where id='matrix-b';
insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description)
select pg_temp.matrix_id(2,i),pg_temp.matrix_id(1,i),'tourist','matrix_fixture','Synthetic event' from generate_series(1,2)i;
insert into public.driver_locations(driver_id,latitude,longitude,accuracy_meters,recorded_at)
select pg_temp.matrix_id(1,i),14.9571,120.9188,5,now() from unnest(array[3,4])i;
insert into public.driver_location_history(driver_id,booking_id,latitude,longitude,recorded_at)
select pg_temp.matrix_id(1,i+2),pg_temp.matrix_id(2,i),14.9571,120.9188,now() from generate_series(1,2)i;
insert into public.payments(id,booking_id,provider,provider_mode,provider_checkout_id,provider_payment_id,amount_centavos,status,paid_at)
select pg_temp.matrix_id(8,i),pg_temp.matrix_id(2,i),'paymongo','test','cs_matrix_'||i,'pay_matrix_'||i,10000,'paid',now() from generate_series(1,2)i;
insert into public.refunds(id,booking_id,payment_id,provider_refund_id,amount_centavos,reason,status,requested_by)
select pg_temp.matrix_id(9,i),pg_temp.matrix_id(2,i),pg_temp.matrix_id(8,i),'re_matrix_'||i,1000,'Synthetic fixture refund','succeeded',pg_temp.matrix_id(1,i) from generate_series(1,2)i;
insert into public.disputes(id,booking_id,opened_by,reason)
select pg_temp.matrix_id(10,i),pg_temp.matrix_id(2,i),pg_temp.matrix_id(1,i),'Synthetic fixture dispute' from generate_series(1,2)i;
insert into public.dispute_statements(id,dispute_id,author_id,statement)
select pg_temp.matrix_id(11,i),pg_temp.matrix_id(10,i),pg_temp.matrix_id(1,i),'Synthetic fixture statement' from generate_series(1,2)i;
insert into public.cash_confirmations(id,booking_id,direction,actor_id,actor_role,amount_centavos)
select pg_temp.matrix_id(12,i),pg_temp.matrix_id(2,i),'payment',pg_temp.matrix_id(1,i),'tourist',10000 from generate_series(1,2)i;
insert into public.booking_reviews(booking_id,tourist_id,driver_id,rating,review)
select pg_temp.matrix_id(2,i),pg_temp.matrix_id(1,i),pg_temp.matrix_id(1,i+2),5,'Synthetic review' from generate_series(1,2)i;
insert into public.booking_route_changes(id,booking_id,requested_by,requested_role,change_type,target_stop_id,reason)
select pg_temp.matrix_id(13,i),pg_temp.matrix_id(2,i),pg_temp.matrix_id(1,i),'tourist','skip',pg_temp.matrix_id(7,i),'Synthetic route reason' from generate_series(1,2)i;
insert into public.booking_offers(booking_id,driver_id,status,expires_at)
select pg_temp.matrix_id(2,i),pg_temp.matrix_id(1,i+2),'offered',now()+interval '10 minutes' from generate_series(1,2)i;
insert into public.notifications(id,recipient_id,title,body)
select pg_temp.matrix_id(15,i),pg_temp.matrix_id(1,i),'Matrix notification','Synthetic notification' from generate_series(1,6)i;
insert into public.feedback(id,author_id,category,message)
select pg_temp.matrix_id(16,i),pg_temp.matrix_id(1,i),'matrix','Synthetic feedback' from generate_series(1,6)i;
insert into public.push_tokens(token,profile_id,platform)
select 'matrix-token-'||i,pg_temp.matrix_id(1,i),'android' from generate_series(1,6)i;
insert into public.privacy_consents(profile_id,notice_version)
select pg_temp.matrix_id(1,i),privacy_notice_version from generate_series(1,6)i cross join public.service_configuration;
insert into public.consent_history(id,subject_id,notice_version,notice_language,source,notice_digest)
select pg_temp.matrix_id(17,i),pg_temp.matrix_id(1,i),privacy_notice_version,'en','acceptance','synthetic-digest' from generate_series(1,6)i cross join public.service_configuration;
insert into public.announcement_audit(id,sender_id,request_id,audience,payload_hash,recipient_count)
values(pg_temp.matrix_id(18,1),pg_temp.matrix_id(1,15),pg_temp.matrix_id(18,2),'all','synthetic-digest',1);
insert into public.data_subject_requests(id,subject_id,request_id,notice_language)
select pg_temp.matrix_id(19,i),pg_temp.matrix_id(1,i),pg_temp.matrix_id(19,i),'en' from generate_series(1,6)i;
insert into public.data_subject_exports(request_id,subject_id,payload)
select pg_temp.matrix_id(19,i),pg_temp.matrix_id(1,i),jsonb_build_object('synthetic',true) from generate_series(1,6)i;
insert into public.data_subject_request_audit(id,request_id,subject_id,actor_id,action)
select pg_temp.matrix_id(21,i),pg_temp.matrix_id(19,i),pg_temp.matrix_id(1,i),pg_temp.matrix_id(1,i),'requested' from generate_series(1,6)i;
insert into public.emergency_contact_audit(id,contact_id,actor_id,was_placeholder,is_placeholder)
values(pg_temp.matrix_id(22,1),'mdrrmo',pg_temp.matrix_id(1,16),true,true);
insert into public.operational_alerts(id,severity,category,dedupe_key,title,detail)
values(pg_temp.matrix_id(23,1),'warning','matrix','matrix-fixture','Matrix alert','Synthetic alert');
insert into public.checkout_expiry_requests(payment_id,booking_id) select pg_temp.matrix_id(8,i),pg_temp.matrix_id(2,i) from generate_series(1,2)i;
insert into public.account_deletion_requests(user_id,request_id,anonymous_id) values(pg_temp.matrix_id(1,5),pg_temp.matrix_id(25,1),pg_temp.matrix_id(25,2));
insert into public.payment_webhook_events(provider_event_id,event_type,livemode,payload) values('evt_matrix','fixture',false,'{}');
insert into public.internal_runtime_settings(key,value) values('matrix-fixture','false');
insert into public.internal_scheduler_tokens(name,token) values('matrix-fixture','synthetic-not-a-credential');
insert into public.message_deliveries(id,recipient_id,channel,template_key,title,body,status,dedupe_key)
values(pg_temp.matrix_id(26,1),pg_temp.matrix_id(1,1),'push','matrix','Matrix title','Matrix body','queued','matrix-delivery-fixture');
insert into storage.objects(bucket_id,name,metadata) values
('driver-documents',pg_temp.matrix_id(1,6)||'/license.jpg','{"mimetype":"image/jpeg","size":4}'),
('driver-documents',pg_temp.matrix_id(1,6)||'/vehicle-registration.jpg','{"mimetype":"image/jpeg","size":4}'),
('profile-images',pg_temp.matrix_id(1,1)||'/avatars/matrix.jpg','{"mimetype":"image/jpeg","size":4}'),
('tourist-spots','matrix-a/a4000000-0000-4000-8000-000000000001.jpg','{"mimetype":"image/jpeg","size":4}'),
('app-assets','matrix.png','{"mimetype":"image/png","size":8}');
-- Managed metadata tables are not used by the app, but still get read/write
-- probes and exact catalog entries. This row tests their default-deny RLS.
insert into storage.buckets_analytics(name) values('matrix-analytics');

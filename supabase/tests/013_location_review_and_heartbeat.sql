begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;
select no_plan();
insert into auth.users(id,email,raw_user_meta_data)
select ('b3700000-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,'heartbeat-'||i||'@example.test','{"full_name":"Heartbeat Driver","requested_role":"driver"}'::jsonb from generate_series(1,2)i;
update public.profiles set status='active' where id::text like 'b3700000%';
insert into public.driver_profiles(profile_id,plate_number,franchise_number,license_document_path,vehicle_document_path,approval_status,is_online,last_seen_at,license_expires_on,franchise_expires_on,vehicle_inspection_expires_on,service_area_name,service_area_latitude,service_area_longitude,service_area_radius_km)
select id,'HB-'||right(id::text,1),'HB-FR-'||right(id::text,1),id::text||'/license.jpg',id::text||'/vehicle.jpg','approved',true,case when right(id::text,1)='1' then now()-interval '3 minutes' else now()-interval '1 minute' end,current_date+365,current_date+365,current_date+365,'Heartbeat fixture',14.9571,120.9188,15 from public.profiles where id::text like 'b3700000%';
select public.expire_stale_online_drivers();
select is((select is_online from public.driver_profiles where profile_id='b3700000-0000-4000-8000-000000000001'),false,'three-minute-old heartbeat is set offline');
select is((select is_online from public.driver_profiles where profile_id='b3700000-0000-4000-8000-000000000002'),true,'one-minute heartbeat remains online with default threshold');
update public.service_configuration set stale_heartbeat_seconds=30;
select public.expire_stale_online_drivers();
select is((select is_online from public.driver_profiles where profile_id='b3700000-0000-4000-8000-000000000002'),false,'configured heartbeat threshold is honoured');
update public.driver_profiles set is_online=true,last_seen_at=now() where profile_id='b3700000-0000-4000-8000-000000000002';
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','b3700000-0000-4000-8000-000000000002',true);
select public.publish_driver_location_with_flags(14.9571,120.9188,5,0,0,now(),true);
select is((select is_mocked from public.driver_locations where driver_id=auth.uid()),true,'mock flag stored on the actual location sample');
select is((select is_online from public.driver_profiles where profile_id=auth.uid()),true,'mock report does not block service');
select is(public.driver_is_match_eligible(auth.uid(),14.9571,120.9188,1,false),true,'otherwise eligible mocked sample does not block matching');
select is((select count(*)::integer from public.operational_alerts where dedupe_key='mock-location:'||auth.uid()::text),1,'mock report creates an admin review alert');
select public.publish_driver_location_with_flags(14.9571,120.9188,5,0,0,now(),true);
select is((select occurrences from public.operational_alerts where dedupe_key='mock-location:'||auth.uid()::text),1,'repeated mock samples do not storm the admin alert feed');
select is((select count(*)::integer from cron.job where jobname='expire-stale-online-drivers'),1,'heartbeat expiry job is scheduled');
select is(has_function_privilege('authenticated','public.expire_stale_online_drivers()','execute'),false,'mobile callers cannot run global heartbeat expiry');
select * from finish();rollback;

-- Qualify both sides: the old unqualified driver_id resolved to the inner
-- booking column and accidentally admitted every driver's location.
-- Public catalog RLS may evaluate this predicate for inactive rows. Anonymous
-- callers can ask the boolean question, but never acquire any capability.
grant execute on function public.has_admin_capability(text) to anon;
-- GRANT to authenticated never removed PostgreSQL's default PUBLIC grant.
-- Preserve intended signed-in RPC access while closing the anonymous surface.
do $$
declare item record; signed_in boolean;
begin
  for item in select p.oid,p.oid::regprocedure signature,p.proname,p.prorettype
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.prokind='f' and not exists(
      select 1 from pg_depend d where d.classid='pg_proc'::regclass and d.objid=p.oid and d.deptype='e')
  loop
    signed_in:=has_function_privilege('authenticated',item.oid,'EXECUTE');
    if item.proname in ('is_admin','is_approved_driver','current_profile_role','get_privacy_notice','get_client_configuration','has_admin_capability') then
      execute format('grant execute on function %s to anon,authenticated',item.signature);
    else
      execute format('revoke execute on function %s from public,anon',item.signature);
      if item.prorettype='trigger'::regtype then
        execute format('revoke execute on function %s from authenticated',item.signature);
      elsif signed_in then
        execute format('grant execute on function %s to authenticated',item.signature);
      end if;
    end if;
  end loop;
end $$;
alter default privileges for role postgres in schema public revoke execute on functions from public,anon,authenticated;
revoke insert,update,delete,truncate,references,trigger on public.spatial_ref_sys,public.geography_columns,public.geometry_columns from public,anon,authenticated;
-- Profile/application writes use validated RPCs, never arbitrary row inserts.
revoke insert,update,delete on public.profiles,public.driver_profiles from anon,authenticated;
revoke insert,update,delete on public.fare_revisions,public.cancellation_policies from anon,authenticated;
revoke insert,update,delete on public.notifications from anon,authenticated;
grant update(read_at) on public.notifications to authenticated;
do $$
declare item record;
begin
  for item in select p.oid::regprocedure signature from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname in ('addgeometrycolumn','dropgeometrycolumn','dropgeometrytable','populate_geometry_columns','updategeometrysrid','postgis_extensions_upgrade')
  loop execute format('revoke execute on function %s from public,anon,authenticated',item.signature); end loop;
end $$;
drop policy current_location_participant_operations_read on public.driver_locations;
create policy current_location_participant_operations_read on public.driver_locations
for select to authenticated using (
  driver_locations.driver_id=auth.uid() or public.has_admin_capability('operations') or exists(
    select 1 from public.bookings b where b.driver_id=driver_locations.driver_id
      and b.tourist_id=auth.uid() and b.status in ('accepted','ongoing')
  )
);

-- These upstream SECURITY DEFINER extent helpers are not client RPCs. Keep
-- their lookup path fixed and remove their unnecessary public execution grant.
do $$
begin
  if current_user='supabase_admin' or pg_has_role(current_user,'supabase_admin','MEMBER') then
    alter function public.st_estimatedextent(text,text,text,boolean) set search_path=public,extensions,pg_temp;
alter function public.st_estimatedextent(text,text,text) set search_path=public,extensions,pg_temp;
alter function public.st_estimatedextent(text,text) set search_path=public,extensions,pg_temp;
revoke all on function public.st_estimatedextent(text,text,text,boolean),public.st_estimatedextent(text,text,text),public.st_estimatedextent(text,text) from public,anon,authenticated;
grant execute on function public.st_estimatedextent(text,text,text,boolean),public.st_estimatedextent(text,text,text),public.st_estimatedextent(text,text) to service_role;
  else
    raise notice 'Managed PostGIS hardening requires the extension owner; run supabase/bootstrap/managed_extensions.sql after migrations';
  end if;
end $$;

update storage.buckets set public=false,file_size_limit=5242880,allowed_mime_types=array['image/jpeg'] where id='driver-documents';
update storage.buckets set public=false,file_size_limit=5242880,allowed_mime_types=array['image/jpeg','image/png'] where id='profile-images';
update storage.buckets set public=true,file_size_limit=5242880,allowed_mime_types=array['image/jpeg','image/png'] where id='tourist-spots';
update storage.buckets set public=true,file_size_limit=1048576,allowed_mime_types=array['image/png'] where id='app-assets';

create function public.is_pending_driver_application() returns boolean
language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.profiles where id=auth.uid() and role='driver' and status='pending')
$$;
revoke all on function public.is_pending_driver_application() from public,anon;
grant execute on function public.is_pending_driver_application() to authenticated;
create function public.valid_image_object(p_name text,p_metadata jsonb,p_max_bytes integer,p_jpeg_only boolean default false)
returns boolean language sql immutable set search_path=public as $$
  -- Storage preflight supplies contentLength; final persisted metadata uses size.
  -- Both stages must pass. The bucket service also enforces actual byte limits.
  select case when coalesce(p_metadata->>'size',p_metadata->>'contentLength') ~ '^[0-9]{1,9}$'
    then coalesce(p_metadata->>'size',p_metadata->>'contentLength')::bigint between 1 and p_max_bytes else false end
    and ((lower(storage.extension(p_name))='jpg' and p_metadata->>'mimetype'='image/jpeg')
      or (not p_jpeg_only and lower(storage.extension(p_name))='png' and p_metadata->>'mimetype'='image/png'))
$$;
revoke all on function public.valid_image_object(text,jsonb,integer,boolean) from public;
grant execute on function public.valid_image_object(text,jsonb,integer,boolean) to anon,authenticated;
drop policy driver_documents_insert_own on storage.objects;
drop policy driver_documents_update_own on storage.objects;
drop policy driver_documents_delete_own on storage.objects;
create policy driver_documents_insert_pending on storage.objects for insert to authenticated with check(
  bucket_id='driver-documents' and public.is_pending_driver_application()
  and name in (auth.uid()::text||'/license.jpg',auth.uid()::text||'/vehicle-registration.jpg')
  and public.valid_image_object(name,metadata,5242880,true)
);
create policy driver_documents_update_pending on storage.objects for update to authenticated
using(bucket_id='driver-documents' and public.is_pending_driver_application() and (storage.foldername(name))[1]=auth.uid()::text)
with check(bucket_id='driver-documents' and public.is_pending_driver_application()
  and name in (auth.uid()::text||'/license.jpg',auth.uid()::text||'/vehicle-registration.jpg')
  and public.valid_image_object(name,metadata,5242880,true));
create policy driver_documents_delete_pending on storage.objects for delete to authenticated
using(bucket_id='driver-documents' and public.is_pending_driver_application() and (storage.foldername(name))[1]=auth.uid()::text);

drop policy spot_images_content_insert on storage.objects;
drop policy spot_images_content_update on storage.objects;
create policy spot_images_content_insert on storage.objects for insert to authenticated with check(
  bucket_id='tourist-spots' and public.has_admin_capability('content')
  and name ~ '^[A-Za-z0-9_-]+/[0-9a-f-]{36}[.](jpg|png)$'
  and public.valid_image_object(name,metadata,5242880,false)
);
-- Replacements insert a new immutable URL; old objects are not overwritten.
drop policy profile_images_own_insert on storage.objects;
drop policy profile_images_own_update on storage.objects;
create policy profile_images_own_insert on storage.objects for insert to authenticated with check(
  bucket_id='profile-images' and name ~ ('^'||auth.uid()::text||'/avatars/[A-Za-z0-9_-]+[.](jpg|png)$')
  and public.valid_image_object(name,metadata,5242880,false)
);
drop policy app_assets_content_insert on storage.objects;
drop policy app_assets_content_update on storage.objects;
create policy app_assets_content_insert on storage.objects for insert to authenticated with check(
  bucket_id='app-assets' and public.has_admin_capability('content') and storage.extension(name)='png'
  and public.valid_image_object(name,metadata,1048576,false));
create policy app_assets_content_update on storage.objects for update to authenticated
using(bucket_id='app-assets' and public.has_admin_capability('content'))
with check(bucket_id='app-assets' and public.has_admin_capability('content') and storage.extension(name)='png'
  and public.valid_image_object(name,metadata,1048576,false));

-- A missing pending profile must fail closed (NULL <> 'driver' did not).
do $$
declare definition text;
begin
  definition:=pg_get_functiondef('public.submit_driver_application(text,text,date,date,integer,boolean,text,text)'::regprocedure);
  if position('if profile_role<>''driver''' in definition)=0 then raise exception 'Unexpected application definition'; end if;
  execute replace(definition,'if profile_role<>''driver''','if profile_role is distinct from ''driver''');
end $$;

create function public.require_active_trip_actor(p_roles text[]) returns void
language plpgsql stable security definer set search_path=public as $$
begin
  if auth.uid() is null or not exists(select 1 from public.profiles where id=auth.uid()
    and status='active' and role::text=any(p_roles)) then
    raise exception 'Active trip participant account required' using errcode='42501';
  end if;
end $$;
revoke all on function public.require_active_trip_actor(text[]) from public,anon,authenticated;
grant execute on function public.require_active_trip_actor(text[]) to service_role;
-- SQL NULL is not a successful role check. Apply the same active-account
-- boundary before every client trip mutation, including the older RPCs.
do $$
declare item record; definition text; roles text[];
begin
  for item in select p.oid,p.proname,l.lanname from pg_proc p
    join pg_namespace n on n.oid=p.pronamespace join pg_language l on l.oid=p.prolang
    where n.nspname='public' and p.proname in (
      'create_booking','create_booking_with_requirements','create_booking_with_schedule',
      'recover_booking_pickup_code','reissue_booking_pickup_code','retry_booking_dispatch',
      'confirm_stop_arrival','submit_driver_review','decide_driver_replacement',
      'accept_booking','start_trip','report_pickup_arrival','report_stop_arrival','complete_trip',
      'declare_tourist_no_show','publish_driver_location_with_flags','update_driver_service_profile',
      'decline_booking_offer','request_driver_replacement','report_vehicle_breakdown','resume_after_breakdown','report_route_deviation',
      'cancel_booking','open_dispute','add_dispute_statement','confirm_cash','propose_route_change','decide_route_change','decide_breakdown_wait')
  loop
    if item.lanname<>'plpgsql' then continue; end if;
    roles:=case when item.proname in ('create_booking','create_booking_with_requirements','create_booking_with_schedule','recover_booking_pickup_code','reissue_booking_pickup_code','retry_booking_dispatch','confirm_stop_arrival','submit_driver_review','decide_driver_replacement') then array['tourist']
      when item.proname in ('accept_booking','start_trip','report_pickup_arrival','report_stop_arrival','complete_trip','declare_tourist_no_show','publish_driver_location_with_flags','update_driver_service_profile','decline_booking_offer','request_driver_replacement','report_vehicle_breakdown','resume_after_breakdown','report_route_deviation') then array['driver']
      else array['tourist','driver'] end;
    definition:=pg_get_functiondef(item.oid);
    definition:=regexp_replace(definition,'public.current_profile_role\(\)[[:space:]]*<>[[:space:]]*','public.current_profile_role() is distinct from ','g');
    if position(E'\nbegin\n' in lower(definition))=0 then raise exception 'Review active guard insertion for %',item.proname; end if;
    definition:=regexp_replace(definition,E'\nbegin\n',E'\nbegin\n  perform public.require_active_trip_actor('||quote_literal(roles::text)||E'::text[]);\n','i');
    execute definition;
  end loop;
end $$;
-- These are internal dispatch/compliance calculations, not mobile RPCs.
revoke execute on function public.driver_compliance_issues(uuid),public.driver_is_match_eligible(uuid,double precision,double precision,integer,boolean) from public,anon,authenticated;
create or replace function public.has_active_booking_offer(p_booking_id uuid,p_driver_id uuid) returns boolean
language sql stable security definer set search_path=public as $$
  select (auth.role()='service_role' or p_driver_id=auth.uid()
    or public.owns_booking_as_tourist(p_booking_id) or public.has_admin_capability('operations'))
    and exists(select 1 from public.booking_offers where booking_id=p_booking_id and driver_id=p_driver_id
      and status='offered' and expires_at>now())
$$;

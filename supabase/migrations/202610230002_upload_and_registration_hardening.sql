-- Bound public uploads and make interrupted driver registration resumable.

update storage.buckets set
  file_size_limit=5242880,
  allowed_mime_types=array['image/jpeg']
where id='driver-documents';

update storage.buckets set
  file_size_limit=5242880,
  allowed_mime_types=array['image/jpeg','image/png']
where id in ('profile-images','tourist-spots');

drop policy if exists driver_documents_update_own on storage.objects;
create policy driver_documents_update_own on storage.objects
for update to authenticated
using (
  bucket_id='driver-documents'
  and (storage.foldername(name))[1]=auth.uid()::text
)
with check (
  bucket_id='driver-documents'
  and (storage.foldername(name))[1]=auth.uid()::text
);

drop policy if exists driver_documents_delete_own on storage.objects;
create policy driver_documents_delete_own on storage.objects
for delete to authenticated
using (
  bucket_id='driver-documents'
  and (storage.foldername(name))[1]=auth.uid()::text
);

create or replace function public.submit_driver_application(
  p_plate_number text,
  p_franchise_number text,
  p_license_expires_on date,
  p_franchise_expires_on date,
  p_passenger_capacity integer,
  p_accepts_accessibility_requests boolean,
  p_license_document_path text,
  p_vehicle_document_path text
) returns void
language plpgsql
security definer
set search_path=public
as $$
declare profile_role public.app_role;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select role into profile_role from public.profiles
    where id=auth.uid() and status='pending';
  if profile_role<>'driver' then raise exception 'Pending driver account required'; end if;
  if length(trim(coalesce(p_plate_number,''))) not between 2 and 30
      or length(trim(coalesce(p_franchise_number,''))) not between 2 and 80 then
    raise exception 'Valid vehicle and franchise numbers are required';
  end if;
  if p_license_expires_on<current_date or p_franchise_expires_on<current_date then
    raise exception 'Expired driver documents cannot be submitted';
  end if;
  if p_passenger_capacity not between 1 and 3 then
    raise exception 'Passenger capacity must be between 1 and 3';
  end if;
  if p_license_document_path<>auth.uid()::text||'/license.jpg'
      or p_vehicle_document_path<>auth.uid()::text||'/vehicle-registration.jpg' then
    raise exception 'Driver document paths are invalid';
  end if;
  if not exists(
    select 1 from storage.objects
    where bucket_id='driver-documents'
      and name in (p_license_document_path,p_vehicle_document_path)
    group by bucket_id having count(*)=2
  ) then raise exception 'Both driver documents must finish uploading'; end if;

  insert into public.driver_profiles(
    profile_id,plate_number,franchise_number,
    license_expires_on,franchise_expires_on,passenger_capacity,
    accepts_accessibility_requests,license_document_path,
    vehicle_document_path,approval_status,is_online
  ) values (
    auth.uid(),upper(trim(p_plate_number)),trim(p_franchise_number),
    p_license_expires_on,p_franchise_expires_on,p_passenger_capacity,
    p_accepts_accessibility_requests,p_license_document_path,
    p_vehicle_document_path,'pending',false
  ) on conflict(profile_id) do update set
    plate_number=excluded.plate_number,
    franchise_number=excluded.franchise_number,
    license_expires_on=excluded.license_expires_on,
    franchise_expires_on=excluded.franchise_expires_on,
    passenger_capacity=excluded.passenger_capacity,
    accepts_accessibility_requests=excluded.accepts_accessibility_requests,
    license_document_path=excluded.license_document_path,
    vehicle_document_path=excluded.vehicle_document_path,
    approval_status='pending',approved_by=null,approved_at=null,is_online=false;
end;
$$;
revoke all on function public.submit_driver_application(
  text,text,date,date,integer,boolean,text,text
) from public;
grant execute on function public.submit_driver_application(
  text,text,date,date,integer,boolean,text,text
) to authenticated;

-- LOCAL FILE ONLY: NOT applied/tested against a real database.
drop function public.send_announcement(text,text);
create function public.send_announcement(p_title text,p_body text,p_audience text)
returns integer language plpgsql security definer set search_path=public as $$
declare inserted integer;
begin
  if not public.has_admin_capability('support') then raise exception 'Support capability required' using errcode='42501'; end if;
  if p_audience is null or p_audience not in ('tourists','drivers','all') then raise exception 'Choose an audience'; end if;
  if length(trim(p_title)) not between 3 and 150 or length(trim(p_body)) not between 5 and 2000 then raise exception 'Invalid announcement length'; end if;
  insert into public.notifications(recipient_id,title,body)
    select id,trim(p_title),trim(p_body) from public.profiles where status='active'
      and ((p_audience='all' and role in ('tourist','driver')) or
        (p_audience='tourists' and role='tourist') or (p_audience='drivers' and role='driver'));
  get diagnostics inserted=row_count;
  return inserted;
end $$;
revoke all on function public.send_announcement(text,text,text) from public,anon;
grant execute on function public.send_announcement(text,text,text) to authenticated;
-- Require an entered reason for compliance approval/restoration as well as
-- suspension. LOCAL FILE ONLY: NOT applied/tested against a real database.
alter function public.admin_review_driver_compliance(uuid,date,date,date,text,double precision,double precision,numeric,boolean,text)
  rename to _admin_review_driver_compliance_before_reason;
revoke all on function public._admin_review_driver_compliance_before_reason(uuid,date,date,date,text,double precision,double precision,numeric,boolean,text)
  from public,anon,authenticated;
create function public.admin_review_driver_compliance(
  p_driver_id uuid,p_license_expires_on date,p_franchise_expires_on date,p_vehicle_inspection_expires_on date,
  p_service_area_name text,p_service_area_latitude double precision,p_service_area_longitude double precision,
  p_service_area_radius_km numeric,p_approve boolean,p_review_note text default null
) returns public.driver_profiles language plpgsql security definer set search_path=public as $$
begin
  if not public.has_admin_capability('driver_compliance') then raise exception 'Driver compliance capability required' using errcode='42501'; end if;
  if length(trim(coalesce(p_review_note,'')))<5 then raise exception 'An entered review reason is required'; end if;
  return public._admin_review_driver_compliance_before_reason(p_driver_id,p_license_expires_on,p_franchise_expires_on,p_vehicle_inspection_expires_on,p_service_area_name,p_service_area_latitude,p_service_area_longitude,p_service_area_radius_km,p_approve,p_review_note);
end $$;
revoke all on function public.admin_review_driver_compliance(uuid,date,date,date,text,double precision,double precision,numeric,boolean,text) from public,anon;
grant execute on function public.admin_review_driver_compliance(uuid,date,date,date,text,double precision,double precision,numeric,boolean,text) to authenticated;

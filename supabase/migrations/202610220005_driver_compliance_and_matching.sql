-- Driver compliance is enforced server-side for every online and matching
-- decision. Dates are supplied by the driver and verified by an administrator.

alter table public.driver_profiles
  add column if not exists license_expires_on date,
  add column if not exists franchise_expires_on date,
  add column if not exists vehicle_inspection_expires_on date,
  add column if not exists service_area_name text not null default 'Bustos, Bulacan',
  add column if not exists service_area_latitude double precision not null default 14.9571
    check (service_area_latitude between -90 and 90),
  add column if not exists service_area_longitude double precision not null default 120.9188
    check (service_area_longitude between -180 and 180),
  add column if not exists service_area_radius_km numeric(4,1) not null default 15.0
    check (service_area_radius_km between 1 and 30),
  add column if not exists matching_blocked_until timestamptz,
  add column if not exists matching_blocked_reason text,
  add column if not exists compliance_reviewed_at timestamptz,
  add column if not exists compliance_reviewed_by uuid references public.profiles(id),
  add column if not exists completed_trip_count integer not null default 0
    check (completed_trip_count >= 0),
  add column if not exists driver_cancelled_trip_count integer not null default 0
    check (driver_cancelled_trip_count >= 0),
  add column if not exists reliability_score numeric(5,2) not null default 100
    check (reliability_score between 0 and 100);

create index if not exists driver_profiles_matching_eligibility_idx
  on public.driver_profiles(approval_status,is_online,matching_blocked_until);

create or replace function public.refresh_driver_reliability_metrics(p_driver_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare
  completed_count integer;
  cancelled_count integer;
begin
  if p_driver_id is null then return; end if;
  select
    count(*) filter (where status='completed'),
    count(*) filter (where status='cancelled' and cancelled_by=p_driver_id)
  into completed_count,cancelled_count
  from public.bookings
  where driver_id=p_driver_id;

  update public.driver_profiles set
    completed_trip_count=completed_count,
    driver_cancelled_trip_count=cancelled_count,
    reliability_score=case
      when completed_count+cancelled_count=0 then 100
      else round(100.0*completed_count/(completed_count+cancelled_count),2)
    end
  where profile_id=p_driver_id;
end;
$$;
revoke all on function public.refresh_driver_reliability_metrics(uuid) from public;

create or replace function public.refresh_driver_reliability_trigger()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
  if tg_op<>'INSERT' then
    perform public.refresh_driver_reliability_metrics(old.driver_id);
  end if;
  if tg_op<>'DELETE' and (tg_op='INSERT' or new.driver_id is distinct from old.driver_id
      or new.status is distinct from old.status
      or new.cancelled_by is distinct from old.cancelled_by) then
    perform public.refresh_driver_reliability_metrics(new.driver_id);
  end if;
  if tg_op='DELETE' then return old; end if;
  return new;
end;
$$;

drop trigger if exists bookings_refresh_driver_reliability on public.bookings;
create trigger bookings_refresh_driver_reliability
after insert or update or delete on public.bookings
for each row execute function public.refresh_driver_reliability_trigger();

do $$
declare driver_row record;
begin
  for driver_row in select profile_id from public.driver_profiles loop
    perform public.refresh_driver_reliability_metrics(driver_row.profile_id);
  end loop;
end;
$$;

create or replace function public.driver_compliance_issues(p_driver_id uuid)
returns text[]
language plpgsql
stable
security definer
set search_path=public
as $$
declare
  d public.driver_profiles;
  p public.profiles;
  issues text[] := array[]::text[];
  total_outcomes integer;
begin
  select * into d from public.driver_profiles where profile_id=p_driver_id;
  select * into p from public.profiles where id=p_driver_id;
  if d.profile_id is null or p.id is null then return array['Driver profile is missing']; end if;
  if p.status<>'active' then issues:=array_append(issues,'Driver account is not active'); end if;
  if d.approval_status<>'approved' then issues:=array_append(issues,'Administrator approval is required'); end if;
  if coalesce(trim(d.license_document_path),'')='' then issues:=array_append(issues,'Driver license document is missing'); end if;
  if coalesce(trim(d.vehicle_document_path),'')='' then issues:=array_append(issues,'Vehicle or franchise document is missing'); end if;
  if d.license_expires_on is null then
    issues:=array_append(issues,'Driver license expiry is not verified');
  elsif d.license_expires_on<current_date then
    issues:=array_append(issues,'Driver license is expired');
  end if;
  if d.franchise_expires_on is null then
    issues:=array_append(issues,'Franchise expiry is not verified');
  elsif d.franchise_expires_on<current_date then
    issues:=array_append(issues,'Franchise document is expired');
  end if;
  if d.vehicle_inspection_expires_on is null then
    issues:=array_append(issues,'Vehicle inspection expiry is not verified');
  elsif d.vehicle_inspection_expires_on<current_date then
    issues:=array_append(issues,'Vehicle inspection is expired');
  end if;
  if d.matching_blocked_until is not null and d.matching_blocked_until>now() then
    issues:=array_append(issues,coalesce(nullif(trim(d.matching_blocked_reason),''),'Driver matching is temporarily blocked'));
  end if;
  total_outcomes:=d.completed_trip_count+d.driver_cancelled_trip_count;
  if total_outcomes>=5 and d.driver_cancelled_trip_count*100.0/total_outcomes>30 then
    issues:=array_append(issues,'Driver cancellation rate is above the 30% matching limit');
  end if;
  return issues;
end;
$$;
revoke all on function public.driver_compliance_issues(uuid) from public;
grant execute on function public.driver_compliance_issues(uuid) to authenticated;

create or replace function public.driver_is_match_eligible(
  p_driver_id uuid,
  p_pickup_latitude double precision,
  p_pickup_longitude double precision,
  p_passenger_count integer,
  p_needs_accessibility boolean
) returns boolean
language sql
stable
security definer
set search_path=public
as $$
  select exists(
    select 1 from public.driver_profiles d
    where d.profile_id=p_driver_id
      and d.is_online
      and cardinality(public.driver_compliance_issues(d.profile_id))=0
      and d.passenger_capacity>=p_passenger_count
      and (not p_needs_accessibility or d.accepts_accessibility_requests)
      and st_dwithin(
        st_setsrid(st_makepoint(d.service_area_longitude,d.service_area_latitude),4326)::geography,
        st_setsrid(st_makepoint(p_pickup_longitude,p_pickup_latitude),4326)::geography,
        d.service_area_radius_km*1000
      )
  );
$$;
revoke all on function public.driver_is_match_eligible(uuid,double precision,double precision,integer,boolean) from public;

create or replace function public.admin_review_driver_compliance(
  p_driver_id uuid,
  p_license_expires_on date,
  p_franchise_expires_on date,
  p_vehicle_inspection_expires_on date,
  p_service_area_name text,
  p_service_area_latitude double precision,
  p_service_area_longitude double precision,
  p_service_area_radius_km numeric,
  p_approve boolean,
  p_review_note text default null
) returns public.driver_profiles
language plpgsql
security definer
set search_path=public
as $$
declare result public.driver_profiles;
begin
  if not public.is_admin() then raise exception 'Administrator access required'; end if;
  if p_license_expires_on is null or p_franchise_expires_on is null
      or p_vehicle_inspection_expires_on is null then
    raise exception 'Verify all three document expiry dates';
  end if;
  if p_approve and (p_license_expires_on<current_date
      or p_franchise_expires_on<current_date
      or p_vehicle_inspection_expires_on<current_date) then
    raise exception 'Expired documents cannot be approved';
  end if;
  if length(trim(coalesce(p_service_area_name,'')))<2 then raise exception 'Service area is required'; end if;
  if p_service_area_latitude not between -90 and 90
      or p_service_area_longitude not between -180 and 180
      or p_service_area_radius_km not between 1 and 30 then
    raise exception 'Service area coordinates or radius are invalid';
  end if;
  if p_approve and not exists(
    select 1 from public.driver_profiles where profile_id=p_driver_id
      and coalesce(trim(license_document_path),'')<>''
      and coalesce(trim(vehicle_document_path),'')<>''
  ) then raise exception 'Both driver documents are required before approval'; end if;

  update public.driver_profiles set
    license_expires_on=p_license_expires_on,
    franchise_expires_on=p_franchise_expires_on,
    vehicle_inspection_expires_on=p_vehicle_inspection_expires_on,
    service_area_name=trim(p_service_area_name),
    service_area_latitude=p_service_area_latitude,
    service_area_longitude=p_service_area_longitude,
    service_area_radius_km=p_service_area_radius_km,
    approval_status=case when p_approve then 'approved'::public.driver_approval_status else 'pending'::public.driver_approval_status end,
    approved_by=case when p_approve then auth.uid() else null end,
    approved_at=case when p_approve then now() else null end,
    compliance_reviewed_by=auth.uid(),
    compliance_reviewed_at=now(),
    matching_blocked_reason=case when p_approve then null else nullif(trim(coalesce(p_review_note,'')),'') end,
    matching_blocked_until=case when p_approve then null else matching_blocked_until end,
    is_online=false
  where profile_id=p_driver_id returning * into result;
  if result.profile_id is null then raise exception 'Driver profile not found'; end if;
  update public.profiles set status=case when p_approve then 'active'::public.account_status else 'pending'::public.account_status end
    where id=p_driver_id;
  insert into public.notifications(recipient_id,title,body,route_path)
  values(
    p_driver_id,
    case when p_approve then 'Driver account approved' else 'Compliance review updated' end,
    case when p_approve then 'Your documents and service area were verified. You can now go online.'
      else coalesce(nullif(trim(coalesce(p_review_note,'')),''),'Your compliance information needs another review.') end,
    '/driver/account'
  );
  return result;
end;
$$;
revoke all on function public.admin_review_driver_compliance(uuid,date,date,date,text,double precision,double precision,numeric,boolean,text) from public;
grant execute on function public.admin_review_driver_compliance(uuid,date,date,date,text,double precision,double precision,numeric,boolean,text) to authenticated;

create or replace function public.admin_set_driver_status(
  p_driver_id uuid,
  p_status public.driver_approval_status,
  p_reason text default null,
  p_blocked_until timestamptz default null
) returns void
language plpgsql
security definer
set search_path=public
as $$
begin
  if not public.is_admin() then raise exception 'Administrator access required'; end if;
  if p_status='approved' then raise exception 'Use the compliance review to approve a driver'; end if;
  if p_status in ('rejected','suspended') and length(trim(coalesce(p_reason,'')))<5 then
    raise exception 'Provide a clear reason';
  end if;
  update public.driver_profiles set
    approval_status=p_status,
    is_online=false,
    matching_blocked_reason=nullif(trim(coalesce(p_reason,'')),''),
    matching_blocked_until=case when p_status='suspended' then p_blocked_until else null end,
    compliance_reviewed_by=auth.uid(),
    compliance_reviewed_at=now()
  where profile_id=p_driver_id;
  if not found then raise exception 'Driver profile not found'; end if;
  update public.profiles set status=case p_status
    when 'pending' then 'pending'::public.account_status
    when 'rejected' then 'rejected'::public.account_status
    else 'suspended'::public.account_status end
  where id=p_driver_id;
  insert into public.notifications(recipient_id,title,body,route_path)
  values(
    p_driver_id,
    'Driver account update',
    coalesce(nullif(trim(coalesce(p_reason,'')),''),'Your driver account status was updated.'),
    '/driver/account'
  );
end;
$$;
revoke all on function public.admin_set_driver_status(uuid,public.driver_approval_status,text,timestamptz) from public;
grant execute on function public.admin_set_driver_status(uuid,public.driver_approval_status,text,timestamptz) to authenticated;

create or replace function public.set_driver_online(p_online boolean)
returns void
language plpgsql
security definer
set search_path=public
as $$
declare issues text[];
begin
  if p_online then
    issues:=public.driver_compliance_issues(auth.uid());
    if cardinality(issues)>0 then
      raise exception 'Cannot go online: %',array_to_string(issues,'; ');
    end if;
  elsif exists(
    select 1 from public.bookings where driver_id=auth.uid()
      and status in ('accepted','replacement_pending','ongoing')
  ) then
    raise exception 'Finish or safely end the active trip before going offline';
  end if;
  update public.driver_profiles set is_online=p_online,last_seen_at=now()
    where profile_id=auth.uid();
  if not found then raise exception 'Driver profile not found'; end if;
end;
$$;
revoke all on function public.set_driver_online(boolean) from public;
grant execute on function public.set_driver_online(boolean) to authenticated;

create or replace function public.create_ranked_driver_offers(p_booking_id uuid)
returns integer
language plpgsql
security definer
set search_path=public
as $$
declare
  b public.bookings;
  inserted_count integer;
begin
  select * into b from public.bookings where id=p_booking_id;
  if b.id is null or b.status<>'pending' or b.dispatch_expires_at<=now() then return 0; end if;
  update public.booking_offers set status='expired'
    where booking_id=b.id and status='offered' and expires_at<=now();

  insert into public.booking_offers(booking_id,driver_id,expires_at)
  select b.id,d.profile_id,least(b.dispatch_expires_at,now()+interval '2 minutes')
  from public.driver_profiles d
  join public.driver_locations location on location.driver_id=d.profile_id
  where public.driver_is_match_eligible(
      d.profile_id,b.pickup_latitude,b.pickup_longitude,b.passenger_count,b.accessibility_needs<>''
    )
    and location.recorded_at>=now()-interval '2 minutes'
    and st_dwithin(
      st_setsrid(st_makepoint(location.longitude,location.latitude),4326)::geography,
      st_setsrid(st_makepoint(b.pickup_longitude,b.pickup_latitude),4326)::geography,
      15000
    )
    and not exists(
      select 1 from public.bookings active where active.driver_id=d.profile_id
        and active.status in ('accepted','replacement_pending','ongoing')
    )
    and not exists(
      select 1 from public.booking_offers prior
      where prior.booking_id=b.id and prior.driver_id=d.profile_id
    )
  order by st_distance(
    st_setsrid(st_makepoint(location.longitude,location.latitude),4326)::geography,
    st_setsrid(st_makepoint(b.pickup_longitude,b.pickup_latitude),4326)::geography
  ),d.reliability_score desc,d.rating_average desc
  limit 5
  on conflict(booking_id,driver_id) do nothing;
  get diagnostics inserted_count=row_count;
  return inserted_count;
end;
$$;
revoke all on function public.create_ranked_driver_offers(uuid) from public;

create or replace function public.accept_booking(p_booking_id uuid)
returns public.bookings
language plpgsql
security definer
set search_path=public
as $$
declare result public.bookings;
declare b public.bookings;
begin
  select * into b from public.bookings where id=p_booking_id;
  if b.id is null then raise exception 'Booking not found'; end if;
  if not public.driver_is_match_eligible(
      auth.uid(),b.pickup_latitude,b.pickup_longitude,b.passenger_count,b.accessibility_needs<>''
    ) then raise exception 'Driver compliance, capacity, service area, or availability no longer qualifies for this booking'; end if;
  if not exists(
    select 1 from public.booking_offers where booking_id=p_booking_id
      and driver_id=auth.uid() and status='offered' and expires_at>now()
  ) then raise exception 'This driver offer expired or was not assigned to you'; end if;
  if exists(select 1 from public.bookings where driver_id=auth.uid()
      and status in ('accepted','replacement_pending','ongoing')) then
    raise exception 'Finish the active trip first';
  end if;
  update public.bookings set driver_id=auth.uid(),status='accepted',accepted_at=now()
    where id=p_booking_id and status='pending' and driver_id is null and dispatch_expires_at>now()
    returning * into result;
  if result.id is null then raise exception 'This booking request expired or is no longer available'; end if;
  update public.booking_offers set
    status=case when driver_id=auth.uid() then 'accepted' else 'withdrawn' end,
    responded_at=now() where booking_id=result.id and status='offered';
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description,metadata)
  values(result.id,auth.uid(),'driver','booking_accepted','Driver accepted the matched booking offer.',
    jsonb_build_object('accepted_at',result.accepted_at,'reliability_score',(
      select reliability_score from public.driver_profiles where profile_id=auth.uid()
    )));
  insert into public.notifications(recipient_id,title,body,route_path)
  values(result.tourist_id,'Driver found','A verified compatible driver accepted your tour.','/tourist/tracking/'||result.id);
  return result;
end;
$$;
revoke all on function public.accept_booking(uuid) from public;
grant execute on function public.accept_booking(uuid) to authenticated;

comment on function public.driver_compliance_issues(uuid) is
  'Returns every reason a driver cannot go online or receive new matches.';

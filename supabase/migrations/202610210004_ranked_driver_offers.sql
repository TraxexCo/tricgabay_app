-- Nearby compatible drivers receive short-lived booking offers.

alter table public.driver_profiles
  add column if not exists passenger_capacity smallint not null default 3
    check (passenger_capacity between 1 and 3),
  add column if not exists accepts_accessibility_requests boolean not null default true;

alter table public.bookings
  add column if not exists passenger_count smallint not null default 1
    check (passenger_count between 1 and 3),
  add column if not exists luggage_notes text not null default ''
    check (length(luggage_notes)<=300),
  add column if not exists accessibility_needs text not null default ''
    check (length(accessibility_needs)<=300);

create table if not exists public.booking_offers (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  driver_id uuid not null references public.driver_profiles(profile_id) on delete cascade,
  offered_at timestamptz not null default now(),
  expires_at timestamptz not null,
  status text not null default 'offered'
    check (status in ('offered','accepted','declined','expired','withdrawn')),
  responded_at timestamptz,
  unique(booking_id,driver_id)
);
create index if not exists booking_offers_driver_idx
  on public.booking_offers(driver_id,status,expires_at desc);
create index if not exists booking_offers_booking_idx
  on public.booking_offers(booking_id,status,expires_at desc);

alter table public.booking_offers enable row level security;

create or replace function public.has_active_booking_offer(
  p_booking_id uuid,
  p_driver_id uuid
) returns boolean
language sql
stable
security definer
set search_path=public
as $$
  select exists(
    select 1 from public.booking_offers
    where booking_id=p_booking_id and driver_id=p_driver_id
      and status='offered' and expires_at>now()
  );
$$;
revoke all on function public.has_active_booking_offer(uuid,uuid) from public;
grant execute on function public.has_active_booking_offer(uuid,uuid) to authenticated;

create or replace function public.owns_booking_as_tourist(p_booking_id uuid)
returns boolean
language sql
stable
security definer
set search_path=public
as $$
  select exists(
    select 1 from public.bookings
    where id=p_booking_id and tourist_id=auth.uid()
  );
$$;
revoke all on function public.owns_booking_as_tourist(uuid) from public;
grant execute on function public.owns_booking_as_tourist(uuid) to authenticated;

create policy booking_offers_participant_read on public.booking_offers
for select to authenticated using (
  driver_id=auth.uid() or public.is_admin()
  or public.owns_booking_as_tourist(booking_id)
);
revoke insert,update,delete on public.booking_offers from anon,authenticated;

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
  if b.id is null or b.status<>'pending' or b.dispatch_expires_at<=now() then
    return 0;
  end if;
  update public.booking_offers set status='expired'
    where booking_id=b.id and status='offered' and expires_at<=now();

  insert into public.booking_offers(booking_id,driver_id,expires_at)
  select b.id,d.profile_id,least(b.dispatch_expires_at,now()+interval '2 minutes')
  from public.driver_profiles d
  join public.profiles p on p.id=d.profile_id
  join public.driver_locations location on location.driver_id=d.profile_id
  where p.role='driver' and p.status='active'
    and d.approval_status='approved' and d.is_online
    and d.passenger_capacity>=b.passenger_count
    and (b.accessibility_needs='' or d.accepts_accessibility_requests)
    and location.recorded_at>=now()-interval '2 minutes'
    and st_dwithin(
      st_setsrid(st_makepoint(location.longitude,location.latitude),4326)::geography,
      st_setsrid(st_makepoint(b.pickup_longitude,b.pickup_latitude),4326)::geography,
      15000
    )
    and not exists(
      select 1 from public.bookings active
      where active.driver_id=d.profile_id and active.status in ('accepted','ongoing')
    )
    and not exists(
      select 1 from public.booking_offers prior
      where prior.booking_id=b.id and prior.driver_id=d.profile_id
    )
  order by st_distance(
    st_setsrid(st_makepoint(location.longitude,location.latitude),4326)::geography,
    st_setsrid(st_makepoint(b.pickup_longitude,b.pickup_latitude),4326)::geography
  ),d.rating_average desc
  limit 5
  on conflict(booking_id,driver_id) do nothing;
  get diagnostics inserted_count=row_count;
  return inserted_count;
end;
$$;
revoke all on function public.create_ranked_driver_offers(uuid) from public;

create or replace function public.create_booking_with_requirements(
  p_package_id text,
  p_payment_method public.payment_method,
  p_pickup_address text,
  p_pickup_latitude double precision,
  p_pickup_longitude double precision,
  p_stops jsonb,
  p_passenger_count integer,
  p_luggage_notes text,
  p_accessibility_needs text
) returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  result jsonb;
  booking_id uuid;
begin
  if p_passenger_count not between 1 and 3 then
    raise exception 'Choose between 1 and 3 passengers';
  end if;
  if length(trim(coalesce(p_luggage_notes,'')))>300
     or length(trim(coalesce(p_accessibility_needs,'')))>300 then
    raise exception 'Passenger requirement notes are too long';
  end if;
  result := public.create_booking(
    p_package_id,p_payment_method,p_pickup_address,p_pickup_latitude,
    p_pickup_longitude,p_stops
  );
  booking_id := (result->>'booking_id')::uuid;
  update public.bookings set
    passenger_count=p_passenger_count,
    luggage_notes=trim(coalesce(p_luggage_notes,'')),
    accessibility_needs=trim(coalesce(p_accessibility_needs,''))
    where id=booking_id;
  perform public.create_ranked_driver_offers(booking_id);
  return result;
end;
$$;
revoke all on function public.create_booking_with_requirements(
  text,public.payment_method,text,double precision,double precision,jsonb,integer,text,text
) from public;
grant execute on function public.create_booking_with_requirements(
  text,public.payment_method,text,double precision,double precision,jsonb,integer,text,text
) to authenticated;

create or replace function public.refresh_booking_offers(p_booking_id uuid)
returns integer
language plpgsql
security definer
set search_path=public
as $$
declare b public.bookings;
begin
  select * into b from public.bookings where id=p_booking_id;
  if b.id is null or b.tourist_id<>auth.uid() or b.status<>'pending' then
    raise exception 'Only the tourist can refresh a pending booking';
  end if;
  if b.dispatch_expires_at<=now() then return 0; end if;
  return public.create_ranked_driver_offers(b.id);
end;
$$;
revoke all on function public.refresh_booking_offers(uuid) from public;
grant execute on function public.refresh_booking_offers(uuid) to authenticated;

create or replace function public.retry_booking_dispatch(p_booking_id uuid)
returns public.bookings
language plpgsql
security definer
set search_path=public
as $$
declare result public.bookings;
begin
  update public.bookings set dispatch_expires_at=now()+interval '10 minutes'
    where id=p_booking_id and tourist_id=auth.uid() and status='pending'
      and driver_id is null and dispatch_expires_at<=now()
    returning * into result;
  if result.id is null then
    raise exception 'Only an expired pending request can be searched again';
  end if;
  perform public.create_ranked_driver_offers(result.id);
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description,metadata)
  values(
    result.id,auth.uid(),'tourist','dispatch_retried',
    'Tourist opened a new 10-minute driver search window.',
    jsonb_build_object('dispatch_expires_at',result.dispatch_expires_at)
  );
  return result;
end;
$$;
revoke all on function public.retry_booking_dispatch(uuid) from public;
grant execute on function public.retry_booking_dispatch(uuid) to authenticated;

create or replace function public.decline_booking_offer(p_booking_id uuid)
returns void
language plpgsql
security definer
set search_path=public
as $$
begin
  update public.booking_offers set status='declined',responded_at=now()
    where booking_id=p_booking_id and driver_id=auth.uid()
      and status='offered' and expires_at>now();
  if not found then raise exception 'This booking offer is no longer available'; end if;
end;
$$;
revoke all on function public.decline_booking_offer(uuid) from public;
grant execute on function public.decline_booking_offer(uuid) to authenticated;

create or replace function public.accept_booking(p_booking_id uuid)
returns public.bookings
language plpgsql
security definer
set search_path=public
as $$
declare result public.bookings;
begin
  if not public.is_approved_driver() then raise exception 'Approved driver account required'; end if;
  if not exists(select 1 from public.driver_profiles where profile_id=auth.uid() and is_online) then
    raise exception 'Go online before accepting a booking';
  end if;
  if not exists(
    select 1 from public.booking_offers
    where booking_id=p_booking_id and driver_id=auth.uid()
      and status='offered' and expires_at>now()
  ) then raise exception 'This driver offer expired or was not assigned to you'; end if;
  if exists(select 1 from public.bookings where driver_id=auth.uid() and status in ('accepted','ongoing')) then
    raise exception 'Finish the active trip first';
  end if;
  update public.bookings set driver_id=auth.uid(),status='accepted',accepted_at=now()
    where id=p_booking_id and status='pending' and driver_id is null
      and dispatch_expires_at>now()
    returning * into result;
  if result.id is null then raise exception 'This booking request expired or is no longer available'; end if;
  update public.booking_offers set
    status=case when driver_id=auth.uid() then 'accepted' else 'withdrawn' end,
    responded_at=now()
    where booking_id=result.id and status='offered';
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description,metadata)
  values(result.id,auth.uid(),'driver','booking_accepted','Driver accepted the matched booking offer.',jsonb_build_object('accepted_at',result.accepted_at));
  insert into public.notifications(recipient_id,title,body,route_path)
  values(result.tourist_id,'Driver found','A verified compatible driver accepted your tour.','/tourist/tracking/'||result.id);
  return result;
end;
$$;
revoke all on function public.accept_booking(uuid) from public;
grant execute on function public.accept_booking(uuid) to authenticated;

create or replace function public.update_driver_service_profile(
  p_passenger_capacity integer,
  p_accepts_accessibility_requests boolean
) returns void
language plpgsql
security definer
set search_path=public
as $$
declare
  changed boolean := false;
begin
  if public.current_profile_role()<>'driver' then
    raise exception 'Active driver account required';
  end if;
  if p_passenger_capacity not between 1 and 3 then
    raise exception 'Passenger capacity must be between 1 and 3';
  end if;
  select passenger_capacity is distinct from p_passenger_capacity
      or accepts_accessibility_requests is distinct from p_accepts_accessibility_requests
    into changed
    from public.driver_profiles where profile_id=auth.uid();
  update public.driver_profiles set
    passenger_capacity=p_passenger_capacity,
    accepts_accessibility_requests=p_accepts_accessibility_requests,
    approval_status=case when changed then 'pending'::public.driver_approval_status else approval_status end,
    approved_by=case when changed then null else approved_by end,
    approved_at=case when changed then null else approved_at end
    where profile_id=auth.uid();
  if changed then
    update public.profiles set status='pending' where id=auth.uid();
  end if;
end;
$$;
revoke all on function public.update_driver_service_profile(integer,boolean) from public;
grant execute on function public.update_driver_service_profile(integer,boolean) to authenticated;

drop policy if exists bookings_participant_read on public.bookings;
create policy bookings_participant_read on public.bookings for select to authenticated using (
  tourist_id=auth.uid() or driver_id=auth.uid() or public.is_admin()
  or (status='pending' and public.has_active_booking_offer(id,auth.uid()))
);

drop policy if exists stops_participant_read on public.booking_stops;
create policy stops_participant_read on public.booking_stops for select to authenticated using (
  exists(select 1 from public.bookings b where b.id=booking_id and
    (b.tourist_id=auth.uid() or b.driver_id=auth.uid() or public.is_admin()
      or (b.status='pending' and public.has_active_booking_offer(b.id,auth.uid()))))
);

create policy profiles_booking_participant_read on public.profiles
for select to authenticated using (
  exists(select 1 from public.bookings b where
    (b.tourist_id=profiles.id and (
      b.driver_id=auth.uid() or public.has_active_booking_offer(b.id,auth.uid())
    )) or (b.driver_id=profiles.id and b.tourist_id=auth.uid()))
);

create policy driver_profiles_assigned_tourist_read on public.driver_profiles
for select to authenticated using (
  exists(select 1 from public.bookings b
    where b.driver_id=profile_id and b.tourist_id=auth.uid())
);

alter publication supabase_realtime add table public.booking_offers;

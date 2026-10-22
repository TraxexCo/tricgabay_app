-- Audited venue availability, consensual route changes, breakdown pauses,
-- and route-deviation evidence.

alter table public.tourist_spots
  add column if not exists availability_status text not null default 'open'
    check (availability_status in ('open','temporarily_closed')),
  add column if not exists closed_until timestamptz,
  add column if not exists closure_reason text;

alter table public.bookings
  add column if not exists route_adjustment_required boolean not null default false,
  add column if not exists interrupted_at timestamptz,
  add column if not exists interruption_reason text,
  add column if not exists interruption_latitude double precision,
  add column if not exists interruption_longitude double precision,
  add column if not exists tourist_wait_confirmed_at timestamptz,
  add column if not exists driver_ready_at timestamptz,
  add column if not exists last_route_deviation_at timestamptz;

create or replace function public.prevent_closed_booking_stop()
returns trigger
language plpgsql
set search_path=public
as $$
begin
  if exists(
    select 1 from public.tourist_spots s where s.id=new.spot_id
      and s.availability_status='temporarily_closed'
      and (s.closed_until is null or s.closed_until>now())
  ) then raise exception 'A selected attraction is temporarily closed'; end if;
  return new;
end;
$$;
drop trigger if exists reject_closed_booking_stop on public.booking_stops;
create trigger reject_closed_booking_stop before insert on public.booking_stops
for each row execute function public.prevent_closed_booking_stop();

create table public.booking_route_changes (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  requested_by uuid not null references public.profiles(id),
  requested_role public.app_role not null check (requested_role in ('tourist','driver')),
  change_type text not null check (change_type in ('skip','reorder')),
  target_stop_id uuid references public.booking_stops(id) on delete set null,
  target_spot_name_snapshot text,
  proposed_order jsonb,
  reason text not null check (length(trim(reason)) between 5 and 500),
  status text not null default 'pending' check (status in ('pending','approved','rejected','withdrawn')),
  decided_by uuid references public.profiles(id),
  decided_at timestamptz,
  created_at timestamptz not null default now()
);
create unique index one_pending_route_change_per_booking
  on public.booking_route_changes(booking_id) where status='pending';
alter table public.booking_route_changes enable row level security;
create policy route_changes_participant_read on public.booking_route_changes
for select to authenticated using (
  public.is_admin() or exists(
    select 1 from public.bookings b where b.id=booking_id
      and (b.tourist_id=auth.uid() or b.driver_id=auth.uid())
  )
);
revoke insert,update,delete on public.booking_route_changes from anon,authenticated;
alter publication supabase_realtime add table public.booking_route_changes;

create or replace function public.set_spot_availability(
  p_spot_id text,
  p_status text,
  p_reason text default null,
  p_closed_until timestamptz default null
) returns void
language plpgsql
security definer
set search_path=public
as $$
declare affected record;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  if p_status not in ('open','temporarily_closed') then raise exception 'Invalid availability status'; end if;
  if p_status='temporarily_closed' and length(trim(coalesce(p_reason,'')))<5 then
    raise exception 'A closure reason is required';
  end if;
  if p_closed_until is not null and p_closed_until<=now() then
    raise exception 'Closure end time must be in the future';
  end if;
  update public.tourist_spots set
    availability_status=p_status,
    closure_reason=case when p_status='open' then null else trim(p_reason) end,
    closed_until=case when p_status='open' then null else p_closed_until end
    where id=p_spot_id;
  if not found then raise exception 'Tourist spot not found'; end if;

  if p_status='temporarily_closed' then
    for affected in
      select distinct b.id,b.tourist_id,b.driver_id,s.spot_name_snapshot
      from public.bookings b join public.booking_stops s on s.booking_id=b.id
      where s.spot_id=p_spot_id
        and b.status in ('scheduled','pending','accepted','replacement_pending','ongoing')
    loop
      insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description,metadata)
      values(
        affected.id,auth.uid(),'admin','venue_temporarily_closed',
        affected.spot_name_snapshot||' was marked temporarily closed: '||trim(p_reason),
        jsonb_build_object('spot_id',p_spot_id,'closed_until',p_closed_until)
      );
      insert into public.notifications(recipient_id,title,body,route_path)
      values(
        affected.tourist_id,'A booked attraction is temporarily closed',
        affected.spot_name_snapshot||': '||trim(p_reason)||'. Review the booking before travel.',
        '/tourist/bookings/'||affected.id
      );
      if affected.driver_id is not null then
        insert into public.notifications(recipient_id,title,body,route_path)
        values(
          affected.driver_id,'Route venue temporarily closed',
          affected.spot_name_snapshot||': '||trim(p_reason)||'. Coordinate any route change in the booking.',
          '/driver/bookings/'||affected.id
        );
      end if;
    end loop;
  end if;
end;
$$;
revoke all on function public.set_spot_availability(text,text,text,timestamptz) from public;
grant execute on function public.set_spot_availability(text,text,text,timestamptz) to authenticated;

create or replace function public.propose_route_change(
  p_booking_id uuid,
  p_change_type text,
  p_target_stop_id uuid default null,
  p_proposed_order jsonb default null,
  p_reason text default null
) returns public.booking_route_changes
language plpgsql
security definer
set search_path=public
as $$
declare
  b public.bookings;
  actor public.app_role;
  result public.booking_route_changes;
  remaining_count integer;
  target_name text;
begin
  if p_change_type not in ('skip','reorder') then raise exception 'Invalid route change'; end if;
  if length(trim(coalesce(p_reason,'')))<5 then raise exception 'Explain why the route should change'; end if;
  select * into b from public.bookings where id=p_booking_id for update;
  if b.id is null or b.status<>'ongoing' or b.arrival_pending or b.interrupted_at is not null then
    raise exception 'Route changes require an active, unpaused trip with no arrival awaiting confirmation';
  end if;
  if auth.uid()=b.tourist_id then actor='tourist';
  elsif auth.uid()=b.driver_id then actor='driver';
  else raise exception 'Only a participant can propose a route change'; end if;

  select count(*) into remaining_count from public.booking_stops
    where booking_id=b.id and stop_order>b.confirmed_stop_count;
  if p_change_type='skip' then
    if remaining_count<=1 then raise exception 'The final remaining stop cannot be skipped; end the trip for review instead'; end if;
    if not exists(
      select 1 from public.booking_stops where id=p_target_stop_id
        and booking_id=b.id and stop_order>b.confirmed_stop_count
    ) then raise exception 'Only an unvisited stop can be skipped'; end if;
    select spot_name_snapshot into target_name from public.booking_stops
      where id=p_target_stop_id;
  else
    if jsonb_typeof(p_proposed_order)<>'array'
       or jsonb_array_length(p_proposed_order)<>remaining_count
       or exists(
         select 1 from jsonb_array_elements_text(p_proposed_order) item
         where not exists(
           select 1 from public.booking_stops s where s.id=item.value::uuid
             and s.booking_id=b.id and s.stop_order>b.confirmed_stop_count
         )
       )
       or (select count(distinct value) from jsonb_array_elements_text(p_proposed_order))<>remaining_count then
      raise exception 'The proposed order must contain every remaining stop exactly once';
    end if;
  end if;

  insert into public.booking_route_changes(
    booking_id,requested_by,requested_role,change_type,target_stop_id,
    target_spot_name_snapshot,proposed_order,reason
  ) values (
    b.id,auth.uid(),actor,p_change_type,p_target_stop_id,
    target_name,p_proposed_order,trim(p_reason)
  ) returning * into result;
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description,metadata)
  values(
    b.id,auth.uid(),actor,'route_change_proposed',
    initcap(p_change_type)||' request: '||trim(p_reason),
    jsonb_build_object('route_change_id',result.id,'type',p_change_type,'target_stop_id',p_target_stop_id,'proposed_order',p_proposed_order)
  );
  insert into public.notifications(recipient_id,title,body,route_path)
  values(
    case when actor='driver' then b.tourist_id else b.driver_id end,
    'Route change needs your approval',
    'Review the proposed '||p_change_type||' before the tour continues.',
    case when actor='driver' then '/tourist/bookings/' else '/driver/bookings/' end||b.id
  );
  return result;
end;
$$;
revoke all on function public.propose_route_change(uuid,text,uuid,jsonb,text) from public;
grant execute on function public.propose_route_change(uuid,text,uuid,jsonb,text) to authenticated;

create or replace function public.decide_route_change(
  p_route_change_id uuid,
  p_approve boolean
) returns public.bookings
language plpgsql
security definer
set search_path=public
as $$
declare
  request public.booking_route_changes;
  b public.bookings;
  removed_order integer;
  item record;
begin
  select * into request from public.booking_route_changes where id=p_route_change_id for update;
  if request.id is null or request.status<>'pending' then raise exception 'Route change is no longer pending'; end if;
  select * into b from public.bookings where id=request.booking_id for update;
  if b.id is null or b.status<>'ongoing' or b.arrival_pending or b.interrupted_at is not null then
    raise exception 'The trip is not ready for a route decision';
  end if;
  if auth.uid()=request.requested_by
     or auth.uid() not in (b.tourist_id,b.driver_id) then
    raise exception 'The other trip participant must make this decision';
  end if;
  update public.booking_route_changes set
    status=case when p_approve then 'approved' else 'rejected' end,
    decided_by=auth.uid(),decided_at=now()
    where id=request.id;
  if p_approve and request.change_type='skip' then
    select stop_order into removed_order from public.booking_stops
      where id=request.target_stop_id and booking_id=b.id
        and stop_order>b.confirmed_stop_count;
    if removed_order is null then raise exception 'The requested stop is no longer available to skip'; end if;
    delete from public.booking_stops where id=request.target_stop_id;
    update public.booking_stops set stop_order=stop_order+100
      where booking_id=b.id and stop_order>removed_order;
    update public.booking_stops set stop_order=stop_order-101
      where booking_id=b.id and stop_order>100;
    update public.bookings set route_adjustment_required=true where id=b.id returning * into b;
  elsif p_approve and request.change_type='reorder' then
    update public.booking_stops set stop_order=stop_order+100
      where booking_id=b.id and stop_order>b.confirmed_stop_count;
    for item in
      select value::uuid stop_id,ordinality
      from jsonb_array_elements_text(request.proposed_order) with ordinality
    loop
      update public.booking_stops set stop_order=b.confirmed_stop_count+item.ordinality
        where id=item.stop_id and booking_id=b.id;
    end loop;
  end if;
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description,metadata)
  values(
    b.id,auth.uid(),public.current_profile_role(),
    case when p_approve then 'route_change_approved' else 'route_change_rejected' end,
    case when p_approve then 'The proposed route change was approved by the other participant.'
      else 'The proposed route change was rejected; the booked route remains unchanged.' end,
    jsonb_build_object('route_change_id',request.id,'type',request.change_type)
  );
  return b;
end;
$$;
revoke all on function public.decide_route_change(uuid,boolean) from public;
grant execute on function public.decide_route_change(uuid,boolean) to authenticated;

create or replace function public.report_vehicle_breakdown(
  p_booking_id uuid,
  p_reason text
) returns public.bookings
language plpgsql
security definer
set search_path=public
as $$
declare b public.bookings; location public.driver_locations;
begin
  if length(trim(p_reason))<5 then raise exception 'Describe the vehicle problem'; end if;
  select * into location from public.driver_locations where driver_id=auth.uid();
  if location.driver_id is null or location.recorded_at<now()-interval '1 minute' then
    raise exception 'A fresh driver location is required before pausing the trip';
  end if;
  update public.bookings set
    interrupted_at=now(),interruption_reason=trim(p_reason),
    interruption_latitude=location.latitude,interruption_longitude=location.longitude,
    tourist_wait_confirmed_at=null,driver_ready_at=null,arrival_pending=false
    where id=p_booking_id and driver_id=auth.uid() and status='ongoing'
      and interrupted_at is null
    returning * into b;
  if b.id is null then raise exception 'Only the assigned driver can pause an active trip'; end if;
  update public.booking_route_changes set status='withdrawn',decided_at=now()
    where booking_id=b.id and status='pending';
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description,metadata)
  values(
    b.id,auth.uid(),'driver','vehicle_breakdown_reported',
    'Trip paused for a vehicle problem: '||trim(p_reason),
    jsonb_build_object('latitude',location.latitude,'longitude',location.longitude,'recorded_at',location.recorded_at)
  );
  insert into public.notifications(recipient_id,title,body,route_path)
  values(
    b.tourist_id,'Trip paused safely',
    'The driver reported a vehicle problem. Choose whether to wait for recovery or end the trip for review.',
    '/tourist/bookings/'||b.id
  );
  return b;
end;
$$;
revoke all on function public.report_vehicle_breakdown(uuid,text) from public;
grant execute on function public.report_vehicle_breakdown(uuid,text) to authenticated;

create or replace function public.decide_breakdown_wait(
  p_booking_id uuid,
  p_wait boolean
) returns public.bookings
language plpgsql
security definer
set search_path=public
as $$
declare b public.bookings;
begin
  select * into b from public.bookings where id=p_booking_id for update;
  if b.id is null or b.tourist_id<>auth.uid() or b.status<>'ongoing' or b.interrupted_at is null then
    raise exception 'No breakdown decision is awaiting this tourist';
  end if;
  if not p_wait then
    return public.cancel_booking(b.id,'Tourist ended the paused trip after the reported vehicle breakdown.');
  end if;
  update public.bookings set tourist_wait_confirmed_at=now() where id=b.id returning * into b;
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description)
  values(b.id,auth.uid(),'tourist','breakdown_wait_accepted','Tourist chose to wait for the same driver to resolve the vehicle problem.');
  insert into public.notifications(recipient_id,title,body,route_path)
  values(b.driver_id,'Tourist will wait','Resolve the problem safely, then confirm when the vehicle is ready.','/driver/bookings/'||b.id);
  return b;
end;
$$;
revoke all on function public.decide_breakdown_wait(uuid,boolean) from public;
grant execute on function public.decide_breakdown_wait(uuid,boolean) to authenticated;

create or replace function public.resume_after_breakdown(p_booking_id uuid)
returns public.bookings
language plpgsql
security definer
set search_path=public
as $$
declare b public.bookings;
begin
  update public.bookings set
    driver_ready_at=now(),interrupted_at=null,interruption_reason=null,
    interruption_latitude=null,interruption_longitude=null,
    tourist_wait_confirmed_at=null
    where id=p_booking_id and driver_id=auth.uid() and status='ongoing'
      and interrupted_at is not null and tourist_wait_confirmed_at is not null
    returning * into b;
  if b.id is null then raise exception 'The tourist must first agree to wait for recovery'; end if;
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description)
  values(b.id,auth.uid(),'driver','trip_resumed_after_breakdown','Driver confirmed the vehicle was ready and the trip resumed.');
  insert into public.notifications(recipient_id,title,body,route_path)
  values(b.tourist_id,'Trip ready to resume','The driver marked the vehicle ready. Continue only when you feel safe.','/tourist/tracking/'||b.id);
  return b;
end;
$$;
revoke all on function public.resume_after_breakdown(uuid) from public;
grant execute on function public.resume_after_breakdown(uuid) to authenticated;

create or replace function public.report_route_deviation(
  p_booking_id uuid,
  p_distance_meters double precision
) returns void
language plpgsql
security definer
set search_path=public
as $$
declare b public.bookings;
begin
  if p_distance_meters::text in ('NaN','Infinity','-Infinity')
     or p_distance_meters<150 or p_distance_meters>10000 then
    raise exception 'Deviation distance is outside the reportable range';
  end if;
  update public.bookings set last_route_deviation_at=now()
    where id=p_booking_id and driver_id=auth.uid() and status='ongoing'
      and interrupted_at is null
      and (last_route_deviation_at is null or last_route_deviation_at<now()-interval '5 minutes')
    returning * into b;
  if b.id is null then return; end if;
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description,metadata)
  values(
    b.id,auth.uid(),'driver','route_deviation_detected',
    'The driver location moved away from the planned route; navigation was recalculated.',
    jsonb_build_object('distance_meters',round(p_distance_meters::numeric),'detected_at',now())
  );
  insert into public.notifications(recipient_id,title,body,route_path)
  values(
    b.tourist_id,'Route recalculated',
    'The vehicle moved away from the planned route. Live tracking remains active; use Emergency Help if you feel unsafe.',
    '/tourist/tracking/'||b.id
  );
end;
$$;
revoke all on function public.report_route_deviation(uuid,double precision) from public;
grant execute on function public.report_route_deviation(uuid,double precision) to authenticated;

create or replace function public.report_stop_arrival(p_booking_id uuid)
returns public.bookings
language plpgsql
security definer
set search_path=public
as $$
declare result public.bookings; total_stops integer;
begin
  select count(*) into total_stops from public.booking_stops where booking_id=p_booking_id;
  update public.bookings set arrival_pending=true
  where id=p_booking_id and driver_id=auth.uid() and status='ongoing'
    and interrupted_at is null and not arrival_pending
    and confirmed_stop_count<total_stops returning * into result;
  if result.id is null then raise exception 'No stop can be reported while the trip is paused or awaiting confirmation'; end if;
  update public.booking_stops set arrived_at=now()
    where booking_id=result.id and stop_order=result.confirmed_stop_count+1;
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description,metadata)
  values(result.id,auth.uid(),'driver','stop_arrival_reported','Driver reported arrival.',jsonb_build_object('stop_order',result.confirmed_stop_count+1));
  return result;
end;
$$;

create or replace function public.complete_trip(p_booking_id uuid)
returns public.bookings
language plpgsql
security definer
set search_path=public
as $$
declare result public.bookings; total_stops integer;
begin
  select count(*) into total_stops from public.booking_stops where booking_id=p_booking_id;
  update public.bookings set
    status='completed',completed_at=now(),
    final_charge_centavos=case when route_adjustment_required then null else quoted_amount_centavos end,
    payment_status=case
      when route_adjustment_required then 'under_review'::public.payment_status
      when payment_method='cash' then 'cash_awaiting_confirmation'::public.payment_status
      else payment_status end
  where id=p_booking_id and driver_id=auth.uid() and status='ongoing'
    and interrupted_at is null and not arrival_pending and confirmed_stop_count=total_stops
  returning * into result;
  if result.id is null then raise exception 'Resolve pauses and confirm every remaining stop before completion'; end if;
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description)
  values(
    result.id,auth.uid(),'driver','trip_completed',
    case when result.route_adjustment_required
      then 'Trip completed after an approved skipped stop; payment held for fair review.'
      else 'All booked stops were confirmed; trip completed.' end
  );
  if result.route_adjustment_required then
    insert into public.disputes(booking_id,opened_by,reason)
    values(result.id,auth.uid(),'Approved stop skip changed delivered service; final charge requires review.');
  end if;
  return result;
end;
$$;

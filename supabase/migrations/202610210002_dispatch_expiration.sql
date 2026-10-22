-- Pending requests are time-bounded so stale screens cannot accept them.

alter table public.bookings
  add column if not exists dispatch_expires_at timestamptz;

update public.bookings
set dispatch_expires_at=coalesce(created_at,now())+interval '10 minutes'
where dispatch_expires_at is null;

alter table public.bookings
  alter column dispatch_expires_at set default (now()+interval '10 minutes'),
  alter column dispatch_expires_at set not null;

create index if not exists bookings_pending_dispatch_idx
  on public.bookings(dispatch_expires_at)
  where status='pending';

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
  if exists(select 1 from public.bookings where driver_id=auth.uid() and status in ('accepted','ongoing')) then
    raise exception 'Finish the active trip first';
  end if;
  update public.bookings
    set driver_id=auth.uid(),status='accepted',accepted_at=now()
    where id=p_booking_id and status='pending' and driver_id is null
      and dispatch_expires_at>now()
    returning * into result;
  if result.id is null then raise exception 'This booking request expired or is no longer available'; end if;
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description,metadata)
  values(
    result.id,auth.uid(),'driver','booking_accepted',
    'Driver accepted the booking and fixed fare.',
    jsonb_build_object('accepted_at',result.accepted_at)
  );
  insert into public.notifications(recipient_id,title,body,route_path)
  values(
    result.tourist_id,
    'Driver found',
    'A verified driver accepted your tour. Open the live trip map for details.',
    '/tourist/tracking/'||result.id
  );
  return result;
end;
$$;

revoke all on function public.accept_booking(uuid) from public;
grant execute on function public.accept_booking(uuid) to authenticated;

create or replace function public.retry_booking_dispatch(p_booking_id uuid)
returns public.bookings
language plpgsql
security definer
set search_path=public
as $$
declare result public.bookings;
begin
  update public.bookings
    set dispatch_expires_at=now()+interval '10 minutes'
    where id=p_booking_id and tourist_id=auth.uid() and status='pending'
      and driver_id is null and dispatch_expires_at<=now()
    returning * into result;
  if result.id is null then
    raise exception 'Only an expired pending request can be searched again';
  end if;
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

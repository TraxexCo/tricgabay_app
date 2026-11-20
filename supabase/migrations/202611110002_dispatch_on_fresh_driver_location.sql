-- Use the same bounded retry for the periodic job and the driver coming online.
create function dispatch_internal.retry_waiting_bookings(p_driver_id uuid)
returns integer
language plpgsql
set search_path = pg_catalog, public, pg_temp
as $$
declare
  booking_id uuid;
  offers_created integer := 0;
begin
  for booking_id in
    select b.id from public.bookings b
    where b.status = 'pending' and b.driver_id is null and b.dispatch_expires_at > now()
      and not exists (
        select 1 from public.booking_offers live
        where live.booking_id = b.id and live.status = 'offered' and live.expires_at > now()
      )
      and exists (
        select 1 from dispatch_internal.ranked_candidates(b) candidate
        where p_driver_id is null or candidate.driver_id = p_driver_id
      )
    order by b.dispatch_expires_at, b.id
    limit 50
    for update of b skip locked
  loop
    offers_created := offers_created + public.create_ranked_driver_offers(booking_id);
  end loop;
  return offers_created;
end;
$$;
revoke all on function dispatch_internal.retry_waiting_bookings(uuid)
  from public, anon, authenticated, service_role;

create or replace function dispatch_internal.retry_waiting_bookings()
returns integer
language sql
set search_path = pg_catalog, pg_temp
as $$
  select dispatch_internal.retry_waiting_bookings(null::uuid);
$$;

create function dispatch_internal.on_fresh_driver_location()
returns trigger
language plpgsql security definer
set search_path = pg_catalog, pg_temp
as $$
declare
  last_heartbeat timestamptz;
begin
  if new.recorded_at < now() - interval '2 minutes'
     or new.recorded_at > now() + interval '30 seconds' then
    return null;
  end if;

  select d.last_seen_at into last_heartbeat from public.driver_profiles d
  where d.profile_id = new.driver_id and d.is_online;
  if not found then return null; end if;

  if tg_op = 'UPDATE' then
    -- A normal GPS upload timestamps both rows in the same transaction. An
    -- explicit go-online call advances the heartbeat ahead of the previous GPS.
    if old.recorded_at >= now() - interval '2 minutes'
       and not coalesce(last_heartbeat > old.updated_at, false) then
      return null;
    end if;
  end if;

  perform dispatch_internal.retry_waiting_bookings(new.driver_id);
  return null;
end;
$$;
revoke all on function dispatch_internal.on_fresh_driver_location()
  from public, anon, authenticated, service_role;

create trigger dispatch_on_fresh_driver_location
after insert or update of recorded_at on public.driver_locations
for each row execute function dispatch_internal.on_fresh_driver_location();

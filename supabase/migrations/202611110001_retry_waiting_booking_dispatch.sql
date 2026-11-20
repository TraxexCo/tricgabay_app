create schema dispatch_internal;
revoke all on schema dispatch_internal from public, anon, authenticated, service_role;

-- Share the existing eligibility and ranking rules between initial dispatch and
-- the background retry. Bookings without any eligible driver do not fill a batch.
create function dispatch_internal.ranked_candidates(p_booking public.bookings)
returns table(driver_id uuid)
language sql stable
set search_path = pg_catalog, public, extensions, pg_temp
as $$
  select d.profile_id
  from public.driver_profiles d
  join public.driver_locations location on location.driver_id = d.profile_id
  where public.driver_is_match_eligible(
      d.profile_id, p_booking.pickup_latitude, p_booking.pickup_longitude,
      p_booking.passenger_count, p_booking.accessibility_needs <> ''
    )
    and location.recorded_at >= now() - interval '2 minutes'
    and extensions.st_dwithin(
      extensions.st_setsrid(extensions.st_makepoint(location.longitude, location.latitude), 4326)::extensions.geography,
      extensions.st_setsrid(extensions.st_makepoint(p_booking.pickup_longitude, p_booking.pickup_latitude), 4326)::extensions.geography,
      15000
    )
    and not exists (
      select 1 from public.bookings active where active.driver_id = d.profile_id
        and active.status in ('accepted', 'replacement_pending', 'ongoing')
    )
    and not exists (
      select 1 from public.booking_offers prior
      where prior.booking_id = p_booking.id and prior.driver_id = d.profile_id
    )
  order by extensions.st_distance(
    extensions.st_setsrid(extensions.st_makepoint(location.longitude, location.latitude), 4326)::extensions.geography,
    extensions.st_setsrid(extensions.st_makepoint(p_booking.pickup_longitude, p_booking.pickup_latitude), 4326)::extensions.geography
  ), d.reliability_score desc, d.rating_average desc
  limit 5;
$$;
revoke all on function dispatch_internal.ranked_candidates(public.bookings)
  from public, anon, authenticated, service_role;

create or replace function public.create_ranked_driver_offers(p_booking_id uuid)
returns integer
language plpgsql security definer
set search_path = public, extensions
as $$
declare
  b public.bookings;
  inserted_count integer;
begin
  select * into b from public.bookings where id = p_booking_id for update;
  if b.id is null or b.status <> 'pending' or b.driver_id is not null
     or b.dispatch_expires_at <= now() then
    return 0;
  end if;

  update public.booking_offers set status = 'expired'
  where booking_id = b.id and status = 'offered' and expires_at <= now();

  insert into public.booking_offers(booking_id, driver_id, expires_at)
  select b.id, candidate.driver_id, least(b.dispatch_expires_at, now() + interval '2 minutes')
  from dispatch_internal.ranked_candidates(b) candidate
  on conflict(booking_id, driver_id) do nothing;
  get diagnostics inserted_count = row_count;
  return inserted_count;
end;
$$;

create function dispatch_internal.retry_waiting_bookings()
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
      and exists (select 1 from dispatch_internal.ranked_candidates(b))
    order by b.dispatch_expires_at, b.id
    limit 50
    for update of b skip locked
  loop
    offers_created := offers_created + public.create_ranked_driver_offers(booking_id);
  end loop;
  return offers_created;
end;
$$;
revoke all on function dispatch_internal.retry_waiting_bookings()
  from public, anon, authenticated, service_role;

select cron.schedule(
  'tric-gabay-retry-waiting-dispatch', '30 seconds',
  'select dispatch_internal.retry_waiting_bookings()'
);

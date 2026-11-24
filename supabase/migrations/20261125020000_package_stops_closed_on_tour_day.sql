-- A package tour may leave out a stop that is closed on the tour's weekday.
--
-- Sto. Nino Parish Church is closed on Mondays (hours "Tue–Sat ... · Sun ..."),
-- so a Monday tour of a package that includes it used to be unbookable. The app
-- now sends the package's stops minus the stops closed on the tour day, in the
-- same order. The server accepts exactly two lists for a package booking:
--   1. the full published list (older app versions, and any day nothing is closed), or
--   2. the published list minus every stop closed on the weekday of p_scheduled_at
--      (Asia/Manila), in the same order, as long as at least two stops remain.
-- Anything else is still refused with "Package stops do not match the published
-- package". The fare is the package fare either way. The booking stops stored,
-- the stop count check and the idempotency hash (which covers p_stops as sent)
-- are unchanged.

-- Whether hours text is open on an ISO weekday (1 = Monday ... 7 = Sunday).
-- Format, as written by the admin app and the catalog: blocks separated by
-- " · ", each "<days> <h:mm AM>–<h:mm PM>", days like "Mon–Fri", "Sat, Sun",
-- "Tue–Sat". NULL, empty, "Open 24 hours, daily" and anything that does not
-- parse count as open every day, like the app's TourSchedule.isStopOpenOn.
create or replace function public.stop_open_on_weekday(p_hours text, p_weekday integer)
returns boolean
language plpgsql
immutable
set search_path = public
as $$
declare
  dash constant text := chr(8211);
  names constant text[] := array['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
  block text;
  parsed text[];
  part text;
  bounds text[];
  first_day integer;
  last_day integer;
  covered boolean := false;
begin
  if p_hours is null or btrim(p_hours) = '' then return true; end if;
  foreach block in array string_to_array(p_hours, ' ' || chr(183) || ' ') loop
    parsed := regexp_match(
      btrim(block),
      '^(.+?)\s(\d{1,2}:\d{2}\s[AP]M)' || dash || '(\d{1,2}:\d{2}\s[AP]M)$'
    );
    if parsed is null then return true; end if;
    foreach part in array string_to_array(parsed[1], ',') loop
      bounds := string_to_array(btrim(part), dash);
      first_day := array_position(names, btrim(bounds[1]));
      last_day := array_position(names, btrim(bounds[array_length(bounds, 1)]));
      if first_day is null or last_day is null or last_day < first_day then return true; end if;
      if p_weekday between first_day and last_day then covered := true; end if;
    end loop;
  end loop;
  return covered;
end;
$$;

-- The package's stops that are open on the Manila weekday of p_scheduled_at, in
-- package order. With no scheduled time, every stop.
create or replace function public.package_stop_ids_open_on(p_package_id text, p_scheduled_at timestamptz)
returns text[]
language sql
stable
set search_path = public
as $$
  select array_agg(ps.spot_id order by ps.stop_order)
  from public.tour_package_stops ps
  join public.tourist_spots s on s.id = ps.spot_id
  where ps.package_id = p_package_id
    and (
      p_scheduled_at is null
      or public.stop_open_on_weekday(
        s.opening_hours,
        extract(isodow from p_scheduled_at at time zone 'Asia/Manila')::integer
      )
    );
$$;

revoke all on function public.stop_open_on_weekday(text, integer) from public, anon, authenticated;
revoke all on function public.package_stop_ids_open_on(text, timestamptz) from public, anon, authenticated;
grant execute on function public.stop_open_on_weekday(text, integer) to service_role;
grant execute on function public.package_stop_ids_open_on(text, timestamptz) to service_role;

-- create_booking gains the tour time. The six-argument form stays as a wrapper
-- (no time, so only the full list) and is still not callable by clients.
create or replace function public.create_booking(
  p_package_id text,
  p_payment_method public.payment_method,
  p_pickup_address text,
  p_pickup_latitude double precision,
  p_pickup_longitude double precision,
  p_stops jsonb,
  p_scheduled_at timestamptz
) returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  fare public.fare_revisions;
  policy public.cancellation_policies;
  quoted integer;
  created public.bookings;
  pickup_code text;
  stop jsonb;
  stop_count integer;
  expected_ids text[];
  open_ids text[];
  supplied_ids text[];
begin
  perform public.require_active_trip_actor('{tourist}'::text[]);
  if public.current_profile_role() is distinct from 'tourist' then raise exception 'Active tourist account required'; end if;
  if exists(select 1 from public.bookings where tourist_id=auth.uid() and status in ('pending','accepted','ongoing')) then
    raise exception 'Finish or cancel the active booking first';
  end if;
  if length(trim(p_pickup_address))<3 then raise exception 'Pickup address is required'; end if;
  if p_pickup_latitude not between -90 and 90 or p_pickup_longitude not between -180 and 180 then
    raise exception 'Invalid pickup coordinates';
  end if;
  perform public.require_pickup_in_service_area(p_pickup_latitude,p_pickup_longitude);
  stop_count := jsonb_array_length(p_stops);
  if stop_count not between 1 and 12 then raise exception 'Choose between 1 and 12 stops'; end if;
  select * into fare from public.fare_revisions where is_current for share;
  select * into policy from public.cancellation_policies where is_current for share;
  if fare.id is null or policy.id is null then raise exception 'Published fare or cancellation policy is unavailable'; end if;

  if p_package_id is null then
    quoted := fare.custom_fare_centavos;
  else
    if not exists(select 1 from public.tour_packages where id=p_package_id and is_active) then raise exception 'Package unavailable'; end if;
    quoted := (fare.package_fares->>p_package_id)::integer;
    if quoted is null then raise exception 'Package has no published fare'; end if;
    select array_agg(spot_id order by stop_order) into expected_ids from public.tour_package_stops where package_id=p_package_id;
    select array_agg(supplied.value->>'spot_id' order by supplied.ordinality) into supplied_ids
      from jsonb_array_elements(p_stops) with ordinality as supplied(value,ordinality);
    if supplied_ids is distinct from expected_ids then
      -- Not the full list: only the open-that-day list, with at least two stops.
      open_ids := public.package_stop_ids_open_on(p_package_id, p_scheduled_at);
      if p_scheduled_at is null
         or coalesce(cardinality(open_ids), 0) < 2
         or supplied_ids is distinct from open_ids then
        raise exception 'Package stops do not match the published package';
      end if;
    end if;
  end if;

  pickup_code := public.generate_secure_pickup_code();
  insert into public.bookings(
    tourist_id,package_id,fare_revision_id,cancellation_policy_id,
    quoted_amount_centavos,payment_method,payment_status,
    pickup_address,pickup_latitude,pickup_longitude,pickup_code_hash
  ) values (
    auth.uid(),p_package_id,fare.id,policy.id,quoted,p_payment_method,
    'unpaid',trim(p_pickup_address),p_pickup_latitude,p_pickup_longitude,
    crypt(pickup_code,gen_salt('bf'))
  ) returning * into created;

  for stop in select value from jsonb_array_elements(p_stops) loop
    if not exists(select 1 from public.tourist_spots where id=stop->>'spot_id' and is_active) then
      raise exception 'A selected attraction is unavailable';
    end if;
    insert into public.booking_stops(
      booking_id,spot_id,stop_order,spot_name_snapshot,latitude_snapshot,longitude_snapshot
    ) select created.id,s.id,(stop->>'stop_order')::smallint,s.name,s.latitude,s.longitude
      from public.tourist_spots s where s.id=stop->>'spot_id';
  end loop;
  if (select count(*) from public.booking_stops where booking_id=created.id)<>stop_count then
    raise exception 'Duplicate or invalid stops';
  end if;
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description,metadata)
  values(created.id,auth.uid(),'tourist','booking_created','Tourist accepted the fixed fare and cancellation policy.',
    jsonb_build_object('fare_revision',fare.revision,'cancellation_policy_version',policy.version));
  return jsonb_build_object('booking_id',created.id,'reference_code',created.reference_code,
    'pickup_code',pickup_code,'quoted_amount_centavos',quoted);
end;
$$;
revoke all on function public.create_booking(
  text,public.payment_method,text,double precision,double precision,jsonb,timestamptz
) from public, anon, authenticated;

create or replace function public.create_booking(
  p_package_id text,
  p_payment_method public.payment_method,
  p_pickup_address text,
  p_pickup_latitude double precision,
  p_pickup_longitude double precision,
  p_stops jsonb
) returns jsonb
language sql
security definer
set search_path = public, extensions
as $$
  select public.create_booking(
    p_package_id, p_payment_method, p_pickup_address, p_pickup_latitude,
    p_pickup_longitude, p_stops, null::timestamptz
  );
$$;
revoke all on function public.create_booking(
  text,public.payment_method,text,double precision,double precision,jsonb
) from public, anon, authenticated;

-- The scheduling wrapper passes the tour time through. It is patched in place,
-- like 20261122060000_tour_booking_window, so the rest of its current body
-- (payment, outstanding-fare and window checks) stays exactly as deployed.
do $$
declare
  fn regprocedure := 'public.create_booking_with_schedule(text,public.payment_method,text,double precision,double precision,jsonb,integer,text,text,timestamptz,uuid)'::regprocedure;
  definition text := pg_get_functiondef(fn);
  old_call constant text := 'p_pickup_longitude,p_stops' || chr(10) || '  );';
  new_call constant text := 'p_pickup_longitude,p_stops,p_scheduled_at' || chr(10) || '  );';
begin
  if length(definition) - length(replace(definition, old_call, '')) <> length(old_call) then
    raise exception 'Expected exactly one create_booking call in %', fn;
  end if;
  execute replace(definition, old_call, new_call);
end $$;

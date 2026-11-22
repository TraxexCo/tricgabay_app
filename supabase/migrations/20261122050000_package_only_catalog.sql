-- Tours are sold only as ready-made packages, and the catalogue is limited to
-- the places those packages visit (TRIC LAKBAY, TRIC SAYA, TRIC TUKLAS).
--
-- 1. Places outside the package routes are removed. Bookings keep their own
--    copy of each stop's name and coordinates, so past trips still show their
--    stops; their link to the deleted place is cleared first.
-- 2. Administrators with the content capability can create, edit and delete
--    tour packages. A package's price is published as a new fare revision, so
--    bookings already made keep the fare they agreed to.

-- ── 1. Catalogue ────────────────────────────────────────────────────────────

-- The eleven places on the three package routes.
create or replace function pg_temp.package_places() returns text[]
language sql immutable as $$
  select array[
  'bustos-heritage-park', 'sta-cruz-chapel', 'sta-monica-chapel',
  'sto-nino-church', 'zenys-minasa', 'st-peter-chapel', 'sto-nino-chapel',
  'perpetual-help-chapel', 'sto-rosario-chapel',
  'immaculate-conception-chapel', 'galilee-wailing-wall'
]
$$;

update public.booking_stops
set spot_id = null
where spot_id is not null
  and spot_id <> all (pg_temp.package_places());

-- Stops of inactive or experimental packages can't keep a removed place.
delete from public.tour_package_stops
where spot_id <> all (pg_temp.package_places());

delete from public.tourist_spots
where id <> all (pg_temp.package_places());

-- The table's spellings for the three package routes.
update public.tourist_spots set name = 'Nuestra Senora Del Perpetuo'
where id = 'perpetual-help-chapel';
update public.tourist_spots set name = 'Zenny''s Minasa Pasalubong'
where id = 'zenys-minasa';

-- ── 2. Package management ───────────────────────────────────────────────────

create or replace function public.admin_save_tour_package(
  p_package_id text,
  p_name text,
  p_description text,
  p_fare_centavos integer,
  p_spot_ids text[]
) returns text
language plpgsql security definer set search_path = public as $$
declare
  v_name text := btrim(coalesce(p_name, ''));
  v_description text := btrim(coalesce(p_description, ''));
  v_id text := nullif(btrim(coalesce(p_package_id, '')), '');
  v_count integer := coalesce(cardinality(p_spot_ids), 0);
  v_current public.fare_revisions;
  v_existing integer;
begin
  if not public.has_admin_capability('content') then
    raise exception 'Content administrator access required';
  end if;
  if char_length(v_name) not between 3 and 60 then
    raise exception 'Enter a package name of 3 to 60 characters';
  end if;
  if char_length(v_description) > 500 then
    raise exception 'Keep the description under 500 characters';
  end if;
  if p_fare_centavos is null or p_fare_centavos not between 100 and 10000000 then
    raise exception 'Enter a price between 1 and 100,000 pesos';
  end if;
  if v_count not between 2 and 12 then
    raise exception 'Choose 2 to 12 stops';
  end if;
  if (select count(distinct s) from unnest(p_spot_ids) s) <> v_count then
    raise exception 'Each stop can appear only once';
  end if;
  if (select count(*) from public.tourist_spots
      where id = any(p_spot_ids) and is_active) <> v_count then
    raise exception 'Every stop must be an active tourist spot';
  end if;
  if exists (
    select 1 from public.tour_packages
    where is_active and lower(name) = lower(v_name)
      and id is distinct from v_id
  ) then
    raise exception 'Another package already uses this name';
  end if;

  if v_id is null then
    v_id := trim(both '-' from regexp_replace(lower(v_name), '[^a-z0-9]+', '-', 'g'));
    if v_id = '' then v_id := 'package'; end if;
    if exists (select 1 from public.tour_packages where id = v_id) then
      v_id := v_id || '-' || substr(md5(gen_random_uuid()::text), 1, 6);
    end if;
    insert into public.tour_packages(id, name, description, is_active)
    values (v_id, v_name, v_description, true);
  else
    update public.tour_packages
    set name = v_name, description = v_description, updated_at = now()
    where id = v_id and is_active;
    if not found then raise exception 'This package no longer exists'; end if;
  end if;

  delete from public.tour_package_stops where package_id = v_id;
  insert into public.tour_package_stops(package_id, spot_id, stop_order)
  select v_id, s.spot_id, s.ord::smallint
  from unnest(p_spot_ids) with ordinality as s(spot_id, ord);

  -- Publish the price only when it changes; existing bookings keep theirs.
  select * into v_current from public.fare_revisions where is_current;
  v_existing := (v_current.package_fares ->> v_id)::integer;
  if v_existing is distinct from p_fare_centavos then
    update public.fare_revisions set is_current = false where is_current;
    insert into public.fare_revisions(
      custom_fare_centavos, package_fares, is_current, reason, created_by
    ) values (
      coalesce(v_current.custom_fare_centavos, 7000),
      coalesce(v_current.package_fares, '{}'::jsonb)
        || jsonb_build_object(v_id, p_fare_centavos),
      true,
      'Tour package price set: ' || v_name,
      auth.uid()
    );
  end if;
  return v_id;
end;
$$;

-- Deleting hides the package from tourists and admins. The row stays so
-- bookings already made with it keep their name and history.
create or replace function public.admin_delete_tour_package(p_package_id text)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.has_admin_capability('content') then
    raise exception 'Content administrator access required';
  end if;
  update public.tour_packages
  set is_active = false, updated_at = now()
  where id = p_package_id and is_active;
  if not found then raise exception 'This package no longer exists'; end if;
end;
$$;

revoke all on function public.admin_save_tour_package(text, text, text, integer, text[])
  from public, anon;
revoke all on function public.admin_delete_tour_package(text) from public, anon;
grant execute on function public.admin_save_tour_package(text, text, text, integer, text[])
  to authenticated;
grant execute on function public.admin_delete_tour_package(text) to authenticated;

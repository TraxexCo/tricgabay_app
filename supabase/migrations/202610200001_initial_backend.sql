-- Tric-Gabay authoritative backend
-- Financial amounts are integer centavos. Timestamps are UTC timestamptz.

create extension if not exists pgcrypto;
create extension if not exists postgis;

create type public.app_role as enum ('tourist', 'driver', 'admin');
create type public.account_status as enum ('pending', 'active', 'suspended', 'rejected');
create type public.driver_approval_status as enum ('pending', 'approved', 'rejected', 'suspended');
create type public.booking_status as enum ('pending', 'accepted', 'ongoing', 'completed', 'cancelled');
create type public.payment_method as enum ('cash', 'paymongo');
create type public.payment_status as enum (
  'unpaid', 'checkout_created', 'processing', 'paid', 'failed',
  'under_review', 'refund_required', 'refund_processing',
  'partially_refunded', 'refunded', 'cash_awaiting_confirmation',
  'cash_paid', 'waived'
);
create type public.refund_status as enum ('requested', 'approved', 'processing', 'succeeded', 'failed', 'rejected');
create type public.dispute_status as enum ('open', 'resolved', 'rejected');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null check (length(trim(full_name)) between 2 and 120),
  phone text,
  role public.app_role not null,
  status public.account_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.driver_profiles (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  plate_number text not null,
  franchise_number text not null,
  license_document_path text,
  vehicle_document_path text,
  approval_status public.driver_approval_status not null default 'pending',
  approved_by uuid references public.profiles(id),
  approved_at timestamptz,
  rating_average numeric(3,2) not null default 0 check (rating_average between 0 and 5),
  rating_count integer not null default 0 check (rating_count >= 0),
  is_online boolean not null default false,
  last_seen_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.tourist_spots (
  id text primary key,
  name text not null,
  description text not null default '',
  category text not null,
  address text not null,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  image_url text,
  opening_hours text,
  entrance_fee_note text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index tourist_spots_geo_idx on public.tourist_spots using gist
  ((st_setsrid(st_makepoint(longitude, latitude), 4326)::geography));

create table public.tour_packages (
  id text primary key,
  name text not null,
  description text not null default '',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.tour_package_stops (
  package_id text not null references public.tour_packages(id) on delete cascade,
  spot_id text not null references public.tourist_spots(id),
  stop_order smallint not null check (stop_order > 0),
  primary key (package_id, spot_id),
  unique (package_id, stop_order)
);

create table public.fare_revisions (
  id uuid primary key default gen_random_uuid(),
  revision integer generated always as identity unique,
  custom_fare_centavos integer not null check (custom_fare_centavos between 1 and 10000000),
  package_fares jsonb not null default '{}'::jsonb,
  is_current boolean not null default false,
  reason text not null check (length(trim(reason)) >= 5),
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
create unique index one_current_fare_revision on public.fare_revisions (is_current) where is_current;

create table public.cancellation_policies (
  id uuid primary key default gen_random_uuid(),
  version integer generated always as identity unique,
  is_current boolean not null default false,
  free_cancellation_minutes integer not null default 5 check (free_cancellation_minutes between 0 and 120),
  accepted_trip_fee_percent integer not null default 20 check (accepted_trip_fee_percent between 0 and 100),
  driver_wait_minutes integer not null default 10 check (driver_wait_minutes between 1 and 120),
  no_show_fee_percent integer not null default 50 check (no_show_fee_percent between 0 and 100),
  terms text not null,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);
create unique index one_current_cancellation_policy on public.cancellation_policies (is_current) where is_current;

create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  reference_code text not null unique default ('TRIC-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8))),
  tourist_id uuid not null references public.profiles(id),
  driver_id uuid references public.profiles(id),
  package_id text references public.tour_packages(id),
  fare_revision_id uuid not null references public.fare_revisions(id),
  cancellation_policy_id uuid not null references public.cancellation_policies(id),
  quoted_amount_centavos integer not null check (quoted_amount_centavos > 0),
  final_charge_centavos integer check (final_charge_centavos between 0 and quoted_amount_centavos),
  payment_method public.payment_method not null,
  payment_status public.payment_status not null default 'unpaid',
  status public.booking_status not null default 'pending',
  pickup_address text not null,
  pickup_latitude double precision not null check (pickup_latitude between -90 and 90),
  pickup_longitude double precision not null check (pickup_longitude between -180 and 180),
  pickup_code_hash text not null,
  confirmed_stop_count integer not null default 0 check (confirmed_stop_count >= 0),
  arrival_pending boolean not null default false,
  cancellation_reason text,
  cancelled_by uuid references public.profiles(id),
  accepted_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index bookings_tourist_idx on public.bookings(tourist_id, created_at desc);
create index bookings_driver_idx on public.bookings(driver_id, created_at desc);
create index bookings_status_idx on public.bookings(status, created_at desc);

create table public.booking_stops (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  spot_id text references public.tourist_spots(id),
  stop_order smallint not null check (stop_order > 0),
  spot_name_snapshot text not null,
  latitude_snapshot double precision not null,
  longitude_snapshot double precision not null,
  arrived_at timestamptz,
  confirmed_at timestamptz,
  unique (booking_id, stop_order)
);

create table public.trip_events (
  id bigint generated always as identity primary key,
  booking_id uuid not null references public.bookings(id) on delete cascade,
  actor_id uuid references public.profiles(id),
  actor_role public.app_role,
  event_type text not null,
  description text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index trip_events_booking_idx on public.trip_events(booking_id, created_at);

create table public.driver_locations (
  driver_id uuid primary key references public.driver_profiles(profile_id) on delete cascade,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  accuracy_meters double precision check (accuracy_meters is null or accuracy_meters between 0 and 500),
  heading double precision check (heading is null or heading between 0 and 360),
  speed_mps double precision check (speed_mps is null or speed_mps >= 0),
  recorded_at timestamptz not null,
  updated_at timestamptz not null default now()
);
create index driver_locations_geo_idx on public.driver_locations using gist
  ((st_setsrid(st_makepoint(longitude, latitude), 4326)::geography));

create table public.driver_location_history (
  id bigint generated always as identity primary key,
  driver_id uuid not null references public.driver_profiles(profile_id) on delete cascade,
  booking_id uuid references public.bookings(id) on delete cascade,
  latitude double precision not null,
  longitude double precision not null,
  accuracy_meters double precision,
  recorded_at timestamptz not null
);
create index driver_location_history_booking_idx on public.driver_location_history(booking_id, recorded_at);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id),
  provider text not null check (provider in ('paymongo', 'cash')),
  provider_mode text not null default 'test' check (provider_mode = 'test'),
  provider_checkout_id text unique,
  provider_payment_id text unique,
  checkout_url text,
  amount_centavos integer not null check (amount_centavos > 0),
  status public.payment_status not null,
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index one_open_payment_per_booking on public.payments(booking_id)
  where status in ('checkout_created', 'processing', 'paid');
create unique index one_cash_payment_per_booking on public.payments(booking_id)
  where provider = 'cash';

create table public.refunds (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id),
  payment_id uuid not null references public.payments(id),
  provider_refund_id text unique,
  amount_centavos integer not null check (amount_centavos > 0),
  reason text not null check (length(trim(reason)) >= 5),
  status public.refund_status not null default 'requested',
  requested_by uuid not null references public.profiles(id),
  approved_by uuid references public.profiles(id),
  failure_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index one_active_refund_per_booking on public.refunds(booking_id)
  where status in ('requested', 'approved', 'processing');

create table public.disputes (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id),
  opened_by uuid not null references public.profiles(id),
  reason text not null check (length(trim(reason)) >= 5),
  status public.dispute_status not null default 'open',
  resolution text,
  resolved_by uuid references public.profiles(id),
  resolved_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.feedback (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id),
  booking_id uuid references public.bookings(id),
  category text not null,
  message text not null check (length(trim(message)) between 5 and 3000),
  created_at timestamptz not null default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  route_path text,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.push_tokens (
  token text primary key,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  platform text not null,
  updated_at timestamptz not null default now()
);

create table public.payment_webhook_events (
  provider_event_id text primary key,
  event_type text not null,
  livemode boolean not null,
  payload jsonb not null,
  processed_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

create trigger profiles_updated before update on public.profiles for each row execute function public.set_updated_at();
create trigger drivers_updated before update on public.driver_profiles for each row execute function public.set_updated_at();
create trigger spots_updated before update on public.tourist_spots for each row execute function public.set_updated_at();
create trigger packages_updated before update on public.tour_packages for each row execute function public.set_updated_at();
create trigger bookings_updated before update on public.bookings for each row execute function public.set_updated_at();
create trigger payments_updated before update on public.payments for each row execute function public.set_updated_at();
create trigger refunds_updated before update on public.refunds for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare requested text;
begin
  requested := coalesce(new.raw_user_meta_data->>'requested_role', 'tourist');
  if requested not in ('tourist', 'driver') then requested := 'tourist'; end if;
  insert into public.profiles(id, full_name, phone, role, status)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data->>'full_name'), ''), 'New user'),
    new.raw_user_meta_data->>'phone',
    requested::public.app_role,
    case when requested = 'driver' then 'pending'::public.account_status else 'active'::public.account_status end
  );
  return new;
end;
$$;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role = 'admin' and status = 'active');
$$;

create or replace function public.is_approved_driver()
returns boolean language sql stable security definer set search_path = public as $$
  select exists(
    select 1 from public.profiles p join public.driver_profiles d on d.profile_id = p.id
    where p.id = auth.uid() and p.role = 'driver' and p.status = 'active'
      and d.approval_status = 'approved'
  );
$$;

alter table public.profiles enable row level security;
alter table public.driver_profiles enable row level security;
alter table public.tourist_spots enable row level security;
alter table public.tour_packages enable row level security;
alter table public.tour_package_stops enable row level security;
alter table public.fare_revisions enable row level security;
alter table public.cancellation_policies enable row level security;
alter table public.bookings enable row level security;
alter table public.booking_stops enable row level security;
alter table public.trip_events enable row level security;
alter table public.driver_locations enable row level security;
alter table public.driver_location_history enable row level security;
alter table public.payments enable row level security;
alter table public.refunds enable row level security;
alter table public.disputes enable row level security;
alter table public.feedback enable row level security;
alter table public.notifications enable row level security;
alter table public.push_tokens enable row level security;
alter table public.payment_webhook_events enable row level security;

create policy profiles_self_or_admin_read on public.profiles for select to authenticated
using (id = auth.uid() or public.is_admin());
create policy drivers_self_or_admin_read on public.driver_profiles for select to authenticated
using (profile_id = auth.uid() or public.is_admin());
create policy drivers_insert_own on public.driver_profiles for insert to authenticated
with check (profile_id = auth.uid());
create policy public_spots_read on public.tourist_spots for select using (is_active or public.is_admin());
create policy admin_spots_write on public.tourist_spots for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy public_packages_read on public.tour_packages for select using (is_active or public.is_admin());
create policy admin_packages_write on public.tour_packages for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy package_stops_read on public.tour_package_stops for select using (true);
create policy admin_package_stops_write on public.tour_package_stops for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy fares_read on public.fare_revisions for select using (true);
create policy fares_admin_write on public.fare_revisions for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy policies_read on public.cancellation_policies for select using (true);
create policy policies_admin_write on public.cancellation_policies for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy bookings_participant_read on public.bookings for select to authenticated using (
  tourist_id = auth.uid() or driver_id = auth.uid() or public.is_admin()
  or (status = 'pending' and public.is_approved_driver())
);
create policy stops_participant_read on public.booking_stops for select to authenticated using (
  exists(select 1 from public.bookings b where b.id = booking_id and
    (b.tourist_id = auth.uid() or b.driver_id = auth.uid() or public.is_admin()
      or (b.status = 'pending' and public.is_approved_driver())))
);
create policy events_participant_read on public.trip_events for select to authenticated using (
  exists(select 1 from public.bookings b where b.id = booking_id and
    (b.tourist_id = auth.uid() or b.driver_id = auth.uid() or public.is_admin()))
);
create policy current_location_read on public.driver_locations for select to authenticated using (
  driver_id = auth.uid() or public.is_admin() or exists(
    select 1 from public.bookings b where b.driver_id = driver_id and b.tourist_id = auth.uid() and b.status in ('accepted', 'ongoing')
  )
);
create policy history_participant_read on public.driver_location_history for select to authenticated using (
  driver_id = auth.uid() or public.is_admin() or exists(
    select 1 from public.bookings b where b.id = booking_id and b.tourist_id = auth.uid()
  )
);
create policy payments_participant_read on public.payments for select to authenticated using (
  exists(select 1 from public.bookings b where b.id = booking_id and
    (b.tourist_id = auth.uid() or b.driver_id = auth.uid() or public.is_admin()))
);
create policy refunds_participant_read on public.refunds for select to authenticated using (
  requested_by = auth.uid() or public.is_admin() or exists(
    select 1 from public.bookings b where b.id = booking_id and (b.tourist_id = auth.uid() or b.driver_id = auth.uid())
  )
);
create policy disputes_participant_read on public.disputes for select to authenticated using (
  opened_by = auth.uid() or public.is_admin() or exists(
    select 1 from public.bookings b where b.id = booking_id and (b.tourist_id = auth.uid() or b.driver_id = auth.uid())
  )
);
create policy feedback_create on public.feedback for insert to authenticated with check (author_id = auth.uid());
create policy feedback_self_admin_read on public.feedback for select to authenticated using (author_id = auth.uid() or public.is_admin());
create policy notifications_own_read on public.notifications for select to authenticated using (recipient_id = auth.uid());
create policy notifications_own_update on public.notifications for update to authenticated using (recipient_id = auth.uid()) with check (recipient_id = auth.uid());
create policy push_tokens_own on public.push_tokens for all to authenticated using (profile_id = auth.uid()) with check (profile_id = auth.uid());

-- Critical writes are exposed only through validated database functions.
revoke insert, update, delete on public.bookings, public.booking_stops, public.trip_events,
  public.driver_locations, public.driver_location_history, public.payments, public.refunds,
  public.disputes, public.payment_webhook_events from anon, authenticated;

insert into public.fare_revisions(custom_fare_centavos, package_fares, is_current, reason)
values (7000, '{"tric-lakbay":70000,"tric-saya":85000,"tric-tuklas":100000}', true, 'Initial published fixed fares');

insert into public.cancellation_policies(
  is_current, free_cancellation_minutes, accepted_trip_fee_percent,
  driver_wait_minutes, no_show_fee_percent, terms
) values (
  true, 5, 20, 10, 50,
  'Pending bookings are free to cancel. After driver acceptance, tourists have a short grace period; later cancellations may incur the published fee. Driver cancellations are fully refundable. Trips ended after pickup require administrator review. Safety incidents and service failures may receive a full or proportional refund.'
);

create or replace function public.accept_booking(p_booking_id uuid)
returns public.bookings language plpgsql security definer set search_path = public as $$
declare result public.bookings;
begin
  if not public.is_approved_driver() then raise exception 'Approved driver account required'; end if;
  if not exists(select 1 from public.driver_profiles where profile_id = auth.uid() and is_online) then
    raise exception 'Go online before accepting a booking';
  end if;
  if exists(select 1 from public.bookings where driver_id = auth.uid() and status in ('accepted','ongoing')) then
    raise exception 'Finish the active trip first';
  end if;
  update public.bookings set driver_id = auth.uid(), status = 'accepted', accepted_at = now()
  where id = p_booking_id and status = 'pending' and driver_id is null returning * into result;
  if result.id is null then raise exception 'Booking is no longer available'; end if;
  insert into public.trip_events(booking_id, actor_id, actor_role, event_type, description)
  values(result.id, auth.uid(), 'driver', 'booking_accepted', 'Driver accepted the booking and fixed fare.');
  return result;
end;
$$;
grant execute on function public.accept_booking(uuid) to authenticated;

create or replace function public.publish_driver_location(
  p_latitude double precision, p_longitude double precision,
  p_accuracy double precision, p_heading double precision, p_speed double precision,
  p_recorded_at timestamptz
) returns void language plpgsql security definer set search_path = public as $$
declare active_booking uuid;
begin
  if not public.is_approved_driver() then raise exception 'Approved driver account required'; end if;
  if p_recorded_at < now() - interval '2 minutes' or p_recorded_at > now() + interval '30 seconds' then
    raise exception 'Location timestamp is stale or invalid';
  end if;
  if p_accuracy is not null and p_accuracy > 200 then raise exception 'Location accuracy is too low'; end if;
  select id into active_booking from public.bookings
    where driver_id = auth.uid() and status in ('accepted','ongoing') order by created_at desc limit 1;
  insert into public.driver_locations(driver_id, latitude, longitude, accuracy_meters, heading, speed_mps, recorded_at)
  values(auth.uid(), p_latitude, p_longitude, p_accuracy, p_heading, p_speed, p_recorded_at)
  on conflict(driver_id) do update set latitude=excluded.latitude, longitude=excluded.longitude,
    accuracy_meters=excluded.accuracy_meters, heading=excluded.heading, speed_mps=excluded.speed_mps,
    recorded_at=excluded.recorded_at, updated_at=now()
  where public.driver_locations.recorded_at <= excluded.recorded_at;
  if active_booking is not null then
    insert into public.driver_location_history(driver_id, booking_id, latitude, longitude, accuracy_meters, recorded_at)
    values(auth.uid(), active_booking, p_latitude, p_longitude, p_accuracy, p_recorded_at);
  end if;
  update public.driver_profiles set last_seen_at=now() where profile_id=auth.uid();
end;
$$;
grant execute on function public.publish_driver_location(double precision,double precision,double precision,double precision,double precision,timestamptz) to authenticated;

-- Admins create new revisions; existing bookings remain pinned to their original revision.
create or replace function public.publish_fares(
  p_custom_fare_centavos integer, p_package_fares jsonb, p_reason text
) returns public.fare_revisions language plpgsql security definer set search_path = public as $$
declare result public.fare_revisions;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  if p_custom_fare_centavos not between 1 and 10000000 then raise exception 'Invalid custom fare'; end if;
  if length(trim(p_reason)) < 5 then raise exception 'A change reason is required'; end if;
  update public.fare_revisions set is_current=false where is_current;
  insert into public.fare_revisions(custom_fare_centavos, package_fares, is_current, reason, created_by)
  values(p_custom_fare_centavos, p_package_fares, true, trim(p_reason), auth.uid()) returning * into result;
  return result;
end;
$$;
grant execute on function public.publish_fares(integer,jsonb,text) to authenticated;

create or replace function public.set_driver_online(p_online boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_approved_driver() then raise exception 'Approved driver account required'; end if;
  if not p_online and exists(select 1 from public.bookings where driver_id=auth.uid() and status='ongoing') then
    raise exception 'An ongoing trip must be ended safely before going offline';
  end if;
  update public.driver_profiles set is_online=p_online, last_seen_at=now() where profile_id=auth.uid();
end;
$$;
grant execute on function public.set_driver_online(boolean) to authenticated;

-- Realtime publication contains only tables required by the mobile clients.
alter publication supabase_realtime add table public.bookings;
alter publication supabase_realtime add table public.driver_locations;
alter publication supabase_realtime add table public.notifications;

insert into storage.buckets(id, name, public) values ('driver-documents', 'driver-documents', false)
on conflict(id) do nothing;
insert into storage.buckets(id, name, public) values ('tourist-spots', 'tourist-spots', true)
on conflict(id) do nothing;

create policy driver_documents_insert_own on storage.objects for insert to authenticated
with check (bucket_id = 'driver-documents' and (storage.foldername(name))[1] = auth.uid()::text);
create policy driver_documents_read_own_admin on storage.objects for select to authenticated
using (bucket_id = 'driver-documents' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));
create policy spot_images_public_read on storage.objects for select using (bucket_id = 'tourist-spots');
create policy spot_images_admin_write on storage.objects for all to authenticated
using (bucket_id = 'tourist-spots' and public.is_admin()) with check (bucket_id = 'tourist-spots' and public.is_admin());

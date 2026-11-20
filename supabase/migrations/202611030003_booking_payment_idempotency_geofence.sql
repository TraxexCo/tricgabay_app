-- LOCAL FILE ONLY. NOT applied/tested against a real database.
-- New clients require this migration and the enum migration before release.
create table public.service_configuration (
  singleton boolean primary key default true check(singleton),
  centre_latitude double precision not null check(centre_latitude between -90 and 90),
  centre_longitude double precision not null check(centre_longitude between -180 and 180),
  radius_km double precision not null check(radius_km>0 and radius_km<=100),
  minimum_android_build integer not null default 1 check(minimum_android_build>0),
  update_url text not null default ''
);
-- Seed matches the existing driver service-area defaults; operations must review
-- this service radius. It does not assert an administrative boundary polygon.
insert into public.service_configuration values(true,14.9571,120.9188,15,2,'');
alter table public.service_configuration enable row level security;
grant select on public.service_configuration to anon,authenticated;
create policy configuration_read on public.service_configuration for select to anon,authenticated using(true);
revoke insert,update,delete on public.service_configuration from anon,authenticated;
create function public.configure_service(p_lat double precision,p_lng double precision,p_radius double precision,
  p_minimum_build integer,p_update_url text) returns void language plpgsql security definer set search_path=public as $$
begin
  if not public.has_admin_capability('super_admin') then raise exception 'Super administrator required' using errcode='42501'; end if;
  if p_update_url<>'' and p_update_url !~ '^https://play[.]google[.]com/store/apps/details[?]id=' then raise exception 'Invalid store URL'; end if;
  update public.service_configuration set centre_latitude=p_lat,centre_longitude=p_lng,radius_km=p_radius,
    minimum_android_build=p_minimum_build,update_url=p_update_url where singleton;
end $$;
revoke all on function public.configure_service(double precision,double precision,double precision,integer,text) from public,anon;
grant execute on function public.configure_service(double precision,double precision,double precision,integer,text) to authenticated;
create function public.require_pickup_in_service_area(p_lat double precision,p_lng double precision)
returns void language plpgsql security definer set search_path=public,extensions as $$
declare c public.service_configuration;
begin
  select * into strict c from public.service_configuration where singleton;
  if p_lat is null or p_lng is null or not(p_lat between -90 and 90 and p_lng between -180 and 180) then raise exception 'Invalid pickup coordinates'; end if;
  if not st_dwithin(st_setsrid(st_makepoint(p_lng,p_lat),4326)::geography,
    st_setsrid(st_makepoint(c.centre_longitude,c.centre_latitude),4326)::geography,c.radius_km*1000) then
    raise exception 'Pickup is outside the service area' using errcode='P0001';
  end if;
end $$;
revoke all on function public.require_pickup_in_service_area(double precision,double precision) from public,anon,authenticated;
alter table public.bookings add column client_request_id uuid, add column client_request_hash text,
  add column payment_expires_at timestamptz;
create unique index bookings_request_id on public.bookings(tourist_id,client_request_id) where client_request_id is not null;
drop index if exists public.one_live_booking_per_tourist;
create unique index one_live_booking_per_tourist on public.bookings(tourist_id)
where status in ('payment_pending','scheduled','pending','accepted','replacement_pending','ongoing');
create function public.hold_unpaid_online_booking() returns trigger language plpgsql set search_path=public as $$
begin
  if new.payment_method='paymongo' and new.payment_status<>'paid' and new.status in ('pending','scheduled') then
    new.status:='payment_pending'; new.payment_expires_at:=now()+interval '30 minutes';
  end if;
  return new;
end $$;
create trigger hold_online_booking before insert on public.bookings for each row execute function public.hold_unpaid_online_booking();
create or replace function public.create_booking(
  p_package_id text,
  p_payment_method public.payment_method,
  p_pickup_address text,
  p_pickup_latitude double precision,
  p_pickup_longitude double precision,
  p_stops jsonb
) returns jsonb language plpgsql security definer set search_path=public,extensions as $$
declare
  fare public.fare_revisions;
  policy public.cancellation_policies;
  quoted integer;
  created public.bookings;
  pickup_code text;
  stop jsonb;
  stop_count integer;
  expected_ids text[];
  supplied_ids text[];
begin
  if public.current_profile_role()<>'tourist' then raise exception 'Active tourist account required'; end if;
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
    if expected_ids is distinct from supplied_ids then raise exception 'Package stops do not match the published package'; end if;
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
revoke all on function public.create_booking(text,public.payment_method,text,double precision,double precision,jsonb)
  from public,anon;
grant execute on function public.create_booking(text,public.payment_method,text,double precision,double precision,jsonb)
  to authenticated;


-- Remove the old authenticated overload: older clients must not bypass request IDs.
drop function public.create_booking_with_schedule(text,public.payment_method,text,double precision,double precision,jsonb,integer,text,text,timestamptz);
create or replace function public.create_booking_with_schedule(
  p_package_id text,
  p_payment_method public.payment_method,
  p_pickup_address text,
  p_pickup_latitude double precision,
  p_pickup_longitude double precision,
  p_stops jsonb,
  p_passenger_count integer,
  p_luggage_notes text,
  p_accessibility_needs text,
  p_scheduled_at timestamptz default null,
  p_request_id uuid default null
) returns jsonb
language plpgsql
security definer
set search_path=public,extensions
as $$
declare
  result jsonb;
  booking_id uuid;
  existing public.bookings;
  request_hash text;
  future_booking boolean := p_scheduled_at is not null;
begin
  if public.current_profile_role()<>'tourist' then
    raise exception 'Active tourist account required';
  end if;
  if p_request_id is null then raise exception 'Booking request ID required'; end if;
  -- Serialize every booking request for this account, including different UUIDs.
  perform 1 from public.profiles where id=auth.uid() for update;
  request_hash := encode(digest(jsonb_build_array(p_package_id,p_payment_method,
    p_pickup_address,p_pickup_latitude,p_pickup_longitude,p_stops,
    p_passenger_count,p_luggage_notes,p_accessibility_needs,p_scheduled_at)::text,'sha256'),'hex');
  select * into existing from public.bookings
    where tourist_id=auth.uid() and client_request_id=p_request_id;
  if existing.id is not null then
    if existing.client_request_hash<>request_hash then raise exception 'Booking request conflict'; end if;
    return jsonb_build_object('booking_id',existing.id,'pickup_code',null,'reused',true);
  end if;
  if exists(
    select 1 from public.bookings
    where tourist_id=auth.uid()
      and status in ('payment_pending','scheduled','pending','accepted','replacement_pending','ongoing')
  ) then raise exception 'Finish or cancel the active booking first'; end if;
  if future_booking and (
    p_scheduled_at<now()+interval '1 hour'
    or p_scheduled_at>now()+interval '30 days'
  ) then raise exception 'Scheduled pickup must be between 1 hour and 30 days from now'; end if;
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
    client_request_id=p_request_id,client_request_hash=request_hash,
    passenger_count=p_passenger_count,
    luggage_notes=trim(coalesce(p_luggage_notes,'')),
    accessibility_needs=trim(coalesce(p_accessibility_needs,'')),
    scheduled_at=p_scheduled_at,
    status=case when p_payment_method='paymongo' then 'payment_pending'::public.booking_status when future_booking then 'scheduled'::public.booking_status else status end,
    dispatch_expires_at=case
      when future_booking then p_scheduled_at-interval '20 minutes'
      else dispatch_expires_at end
    where id=booking_id;
  if future_booking then
    insert into public.trip_events(
      booking_id,actor_id,actor_role,event_type,description,metadata
    ) values (
      booking_id,auth.uid(),'tourist','booking_scheduled',
      'Tour scheduled; driver matching will begin 30 minutes before pickup.',
      jsonb_build_object('scheduled_at',p_scheduled_at)
    );
  elsif p_payment_method='cash' then
    perform public.create_ranked_driver_offers(booking_id);
  end if;
  return result;
end;
$$;
revoke all on function public.create_booking_with_schedule(
  text,public.payment_method,text,double precision,double precision,jsonb,integer,text,text,timestamptz,uuid
) from public;
grant execute on function public.create_booking_with_schedule(
  text,public.payment_method,text,double precision,double precision,jsonb,integer,text,text,timestamptz,uuid
) to authenticated;


create or replace function public.record_paymongo_checkout(
  p_booking_id uuid,
  p_provider_checkout_id text,
  p_checkout_url text,
  p_amount_centavos integer
) returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  b public.bookings;
  existing public.payments;
begin
  if coalesce(auth.role(),'')<>'service_role' then
    raise exception 'Service role required' using errcode='42501';
  end if;
  if coalesce(trim(p_provider_checkout_id),'')!~'^cs_[A-Za-z0-9_-]+$'
     or coalesce(trim(p_checkout_url),'')!~'^https://checkout[.]paymongo[.]com/'
     or p_amount_centavos is null or p_amount_centavos<=0 then
    raise exception 'Invalid checkout result';
  end if;

  select * into b from public.bookings where id=p_booking_id for update;
  if b.id is null or b.payment_method<>'paymongo'
     or b.status<>'payment_pending' or b.payment_expires_at<=now()
     or b.payment_status in (
       'paid','under_review','refund_required','refund_processing',
       'partially_refunded','refunded','cash_awaiting_confirmation','cash_paid','waived'
     ) then
    raise exception 'Booking is not eligible for online checkout';
  end if;
  if p_amount_centavos<>b.quoted_amount_centavos then
    raise exception 'Checkout amount does not match the booking quote';
  end if;

  select * into existing from public.payments
    where booking_id=b.id and provider='paymongo'
      and status in ('checkout_created','processing','paid')
    order by created_at desc limit 1 for update;
  if existing.id is not null then
    if existing.amount_centavos<>b.quoted_amount_centavos
       or existing.provider_checkout_id<>trim(p_provider_checkout_id)
       or existing.checkout_url<>trim(p_checkout_url)
       or existing.provider_mode<>'test' then
      raise exception 'Stored checkout does not match the provider result';
    end if;
    if b.payment_status not in ('paid','processing','checkout_created') then
      update public.bookings set payment_status=existing.status where id=b.id;
    end if;
    return jsonb_build_object(
      'checkout_url',existing.checkout_url,
      'provider_checkout_id',existing.provider_checkout_id,
      'reused',true
    );
  end if;

  insert into public.payments(
    booking_id,provider,provider_mode,provider_checkout_id,checkout_url,
    amount_centavos,status
  ) values (
    b.id,'paymongo','test',trim(p_provider_checkout_id),trim(p_checkout_url),
    p_amount_centavos,'checkout_created'
  ) returning * into existing;
  update public.bookings set payment_status='checkout_created' where id=b.id;
  return jsonb_build_object(
    'checkout_url',existing.checkout_url,
    'provider_checkout_id',existing.provider_checkout_id,
    'reused',false
  );
end;
$$;
revoke all on function public.record_paymongo_checkout(uuid,text,text,integer)
  from public,anon,authenticated;
grant execute on function public.record_paymongo_checkout(uuid,text,text,integer)
  to service_role;

-- Webhooks and reconciliation already write payment_status under the booking lock.
-- A database trigger therefore handles both delivery paths atomically.
create function public.release_paid_booking() returns trigger language plpgsql security definer set search_path=public as $$
begin
  if old.status='payment_pending' and new.payment_status='paid' then
    if old.payment_expires_at<=now() then
      new.status:='cancelled'; new.final_charge_centavos:=0;
      new.cancellation_reason:='Payment arrived after checkout expiry';
      new.payment_status:='refund_required';
      return new;
    end if;
    new.status:=case when new.scheduled_at>now()+interval '30 minutes' then 'scheduled'::public.booking_status else 'pending'::public.booking_status end;
    new.dispatch_expires_at:=case when new.status='pending' then now()+interval '10 minutes' else new.scheduled_at-interval '20 minutes' end;
  end if;
  return new;
end $$;
create trigger release_paid_booking before update of payment_status on public.bookings for each row execute function public.release_paid_booking();
create function public.dispatch_released_booking() returns trigger language plpgsql security definer set search_path=public as $$
begin
  if old.status='payment_pending' and new.status='pending' and new.payment_status='paid' then
    perform public.create_ranked_driver_offers(new.id);
  end if;
  return new;
end $$;
create trigger dispatch_released_booking after update on public.bookings for each row execute function public.dispatch_released_booking();
create function public.expire_unpaid_bookings() returns integer language plpgsql security definer set search_path=public as $$
declare affected integer;
begin
  update public.bookings set status='cancelled',cancellation_reason='Online checkout expired',
    final_charge_centavos=0
  where status='payment_pending' and payment_expires_at<=now() and payment_status<>'paid';
  get diagnostics affected=row_count;
  return affected;
end $$;
revoke all on function public.expire_unpaid_bookings() from public,anon,authenticated;
grant execute on function public.expire_unpaid_bookings() to service_role;
-- pg_cron is already required by the existing backend scheduler migrations.
select cron.schedule('expire-unpaid-bookings','* * * * *','select public.expire_unpaid_bookings()');
-- Trigger-only routines are not public RPCs.
revoke all on function public.hold_unpaid_online_booking(),public.release_paid_booking(),public.dispatch_released_booking() from public,anon,authenticated;

-- Only the UUID-bearing wrapper may be called by a client.
revoke all on function public.create_booking(text,public.payment_method,text,double precision,double precision,jsonb) from authenticated;
-- Upgrade existing unassigned unpaid requests without silently withdrawing a
-- driver who has already accepted. Resolve such legacy assignments first.
do $$ begin
  if exists(select 1 from public.bookings b where b.payment_method='paymongo'
    and b.status in ('accepted','ongoing') and not exists(
      select 1 from public.payments p where p.booking_id=b.id and p.status='paid')) then
    raise exception 'Resolve legacy unpaid assigned tours before this migration';
  end if;
end $$;
update public.bookings b set status='payment_pending',payment_expires_at=now()+interval '30 minutes'
where payment_method='paymongo' and status in ('pending','scheduled')
  and payment_status in ('unpaid','checkout_created','processing','failed')
  and not exists(select 1 from public.payments p where p.booking_id=b.id and p.status='paid');
update public.booking_offers o set status='withdrawn' from public.bookings b
where o.booking_id=b.id and b.status='payment_pending' and o.status='offered';

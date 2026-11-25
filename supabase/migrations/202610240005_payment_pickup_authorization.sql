-- Batch 8: close ambiguous checkout/recovery windows without pretending that
-- an external provider request and PostgreSQL can share one transaction.

create or replace function public.generate_secure_pickup_code()
returns text
language plpgsql
volatile
set search_path=pg_catalog,public,extensions
as $$
declare
  random_bytes bytea;
  random_value integer;
begin
  -- Rejection sampling avoids modulo bias: 63,000 is exactly 7 * 9,000.
  loop
    random_bytes := gen_random_bytes(2);
    random_value := get_byte(random_bytes,0)*256 + get_byte(random_bytes,1);
    exit when random_value<63000;
  end loop;
  return (1000+(random_value%9000))::text;
end;
$$;
revoke all on function public.generate_secure_pickup_code()
  from public,anon,authenticated,service_role;

-- Recreate the authoritative booking creator so all newly-issued pickup codes
-- use the unbiased CSPRNG helper. Its API and business rules remain unchanged.
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

alter table public.bookings
  add column if not exists pickup_code_recovery_id uuid,
  add column if not exists pickup_code_recovered_at timestamptz;

-- Recovery is a one-time continuation of an interrupted create-booking call,
-- not a general pickup-code reset feature. The client persists the request ID
-- and candidate code before calling, making a lost response safely retryable.
drop function if exists public.recover_booking_pickup_code(uuid);
create or replace function public.recover_booking_pickup_code(
  p_booking_id uuid,
  p_recovery_id uuid,
  p_pickup_code text
) returns text
language plpgsql
security definer
set search_path=public,extensions
as $$
declare
  recovered public.bookings;
begin
  if auth.uid() is null or public.current_profile_role()<>'tourist' then
    raise exception 'Active tourist account required' using errcode='42501';
  end if;
  if p_recovery_id is null or p_pickup_code!~'^[0-9]{4}$' then
    raise exception 'Invalid pickup-code recovery request';
  end if;

  select * into recovered from public.bookings
    where id=p_booking_id for update;
  if recovered.id is null or recovered.tourist_id<>auth.uid()
     or recovered.status not in ('scheduled','pending','accepted') then
    raise exception 'Recoverable booking not found';
  end if;
  if recovered.pickup_code_locked_until is not null
     and recovered.pickup_code_locked_until>now() then
    raise exception 'Pickup code is temporarily locked';
  end if;

  if recovered.pickup_code_recovery_id is not null then
    if recovered.pickup_code_recovery_id=p_recovery_id
       and recovered.pickup_code_hash=crypt(p_pickup_code,recovered.pickup_code_hash) then
      return p_pickup_code;
    end if;
    raise exception 'Pickup code recovery already completed';
  end if;

  update public.bookings set
    pickup_code_hash=crypt(p_pickup_code,gen_salt('bf')),
    pickup_code_recovery_id=p_recovery_id,
    pickup_code_recovered_at=now()
  where id=recovered.id;
  insert into public.trip_events(
    booking_id,actor_id,actor_role,event_type,description,metadata
  ) values (
    recovered.id,auth.uid(),'tourist','pickup_code_recovered',
    'Pickup code recovered after an interrupted booking response.',
    jsonb_build_object('reason','ambiguous_booking_response','recovery_id',p_recovery_id)
  );
  return p_pickup_code;
end;
$$;
revoke all on function public.recover_booking_pickup_code(uuid,uuid,text)
  from public,anon;
grant execute on function public.recover_booking_pickup_code(uuid,uuid,text)
  to authenticated;

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
     or b.status not in ('pending','accepted')
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

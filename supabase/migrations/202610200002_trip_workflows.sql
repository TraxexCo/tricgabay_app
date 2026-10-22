create table public.cash_confirmations (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  direction text not null check (direction in ('payment', 'refund')),
  actor_id uuid not null references public.profiles(id),
  actor_role public.app_role not null check (actor_role in ('tourist', 'driver')),
  amount_centavos integer not null check (amount_centavos > 0),
  created_at timestamptz not null default now(),
  unique (booking_id, direction, actor_role)
);

create table public.booking_reviews (
  booking_id uuid primary key references public.bookings(id) on delete cascade,
  tourist_id uuid not null references public.profiles(id),
  driver_id uuid not null references public.profiles(id),
  rating smallint not null check (rating between 1 and 5),
  review text not null default '',
  created_at timestamptz not null default now()
);

alter table public.cash_confirmations enable row level security;
alter table public.booking_reviews enable row level security;
create policy cash_participant_read on public.cash_confirmations for select to authenticated using (
  actor_id = auth.uid() or public.is_admin() or exists(
    select 1 from public.bookings b where b.id=booking_id and (b.tourist_id=auth.uid() or b.driver_id=auth.uid())
  )
);
create policy reviews_read on public.booking_reviews for select using (true);
revoke insert, update, delete on public.cash_confirmations, public.booking_reviews from anon, authenticated;

create or replace function public.current_profile_role()
returns public.app_role language sql stable security definer set search_path=public as $$
  select role from public.profiles where id=auth.uid() and status='active';
$$;

create or replace function public.create_booking(
  p_package_id text,
  p_payment_method public.payment_method,
  p_pickup_address text,
  p_pickup_latitude double precision,
  p_pickup_longitude double precision,
  p_stops jsonb
) returns jsonb language plpgsql security definer set search_path=public as $$
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
  if public.current_profile_role() <> 'tourist' then raise exception 'Active tourist account required'; end if;
  if exists(select 1 from public.bookings where tourist_id=auth.uid() and status in ('pending','accepted','ongoing')) then
    raise exception 'Finish or cancel the active booking first';
  end if;
  if length(trim(p_pickup_address)) < 3 then raise exception 'Pickup address is required'; end if;
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
      from jsonb_array_elements(p_stops) with ordinality as supplied(value, ordinality);
    if expected_ids is distinct from supplied_ids then raise exception 'Package stops do not match the published package'; end if;
  end if;

  pickup_code := (
    1000 + ((get_byte(gen_random_bytes(2), 0) * 256 + get_byte(gen_random_bytes(2), 1)) % 9000)
  )::text;
  insert into public.bookings(
    tourist_id, package_id, fare_revision_id, cancellation_policy_id,
    quoted_amount_centavos, payment_method, payment_status,
    pickup_address, pickup_latitude, pickup_longitude, pickup_code_hash
  ) values (
    auth.uid(), p_package_id, fare.id, policy.id, quoted, p_payment_method,
    'unpaid', trim(p_pickup_address), p_pickup_latitude, p_pickup_longitude,
    crypt(pickup_code, gen_salt('bf'))
  ) returning * into created;

  for stop in select value from jsonb_array_elements(p_stops) loop
    if not exists(select 1 from public.tourist_spots where id=stop->>'spot_id' and is_active) then
      raise exception 'A selected attraction is unavailable';
    end if;
    insert into public.booking_stops(
      booking_id, spot_id, stop_order, spot_name_snapshot, latitude_snapshot, longitude_snapshot
    ) select created.id, s.id, (stop->>'stop_order')::smallint, s.name, s.latitude, s.longitude
      from public.tourist_spots s where s.id=stop->>'spot_id';
  end loop;
  if (select count(*) from public.booking_stops where booking_id=created.id) <> stop_count then
    raise exception 'Duplicate or invalid stops';
  end if;
  insert into public.trip_events(booking_id, actor_id, actor_role, event_type, description, metadata)
  values(created.id, auth.uid(), 'tourist', 'booking_created', 'Tourist accepted the fixed fare and cancellation policy.',
    jsonb_build_object('fare_revision', fare.revision, 'cancellation_policy_version', policy.version));
  return jsonb_build_object('booking_id', created.id, 'reference_code', created.reference_code,
    'pickup_code', pickup_code, 'quoted_amount_centavos', quoted);
end;
$$;
grant execute on function public.create_booking(text,public.payment_method,text,double precision,double precision,jsonb) to authenticated;

create or replace function public.start_trip(p_booking_id uuid, p_pickup_code text)
returns public.bookings language plpgsql security definer set search_path=public as $$
declare result public.bookings;
begin
  update public.bookings set status='ongoing', started_at=now()
  where id=p_booking_id and driver_id=auth.uid() and status='accepted'
    and pickup_code_hash=crypt(trim(p_pickup_code), pickup_code_hash)
  returning * into result;
  if result.id is null then raise exception 'Booking, status, or pickup code is invalid'; end if;
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description)
  values(result.id,auth.uid(),'driver','trip_started','Pickup code verified; trip started.');
  return result;
end;
$$;
grant execute on function public.start_trip(uuid,text) to authenticated;

create or replace function public.report_stop_arrival(p_booking_id uuid)
returns public.bookings language plpgsql security definer set search_path=public as $$
declare result public.bookings; total_stops integer;
begin
  select count(*) into total_stops from public.booking_stops where booking_id=p_booking_id;
  update public.bookings set arrival_pending=true
  where id=p_booking_id and driver_id=auth.uid() and status='ongoing'
    and not arrival_pending and confirmed_stop_count < total_stops returning * into result;
  if result.id is null then raise exception 'No stop can be reported right now'; end if;
  update public.booking_stops set arrived_at=now()
    where booking_id=result.id and stop_order=result.confirmed_stop_count+1;
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description,metadata)
  values(result.id,auth.uid(),'driver','stop_arrival_reported','Driver reported arrival.',jsonb_build_object('stop_order',result.confirmed_stop_count+1));
  return result;
end;
$$;
grant execute on function public.report_stop_arrival(uuid) to authenticated;

create or replace function public.confirm_stop_arrival(p_booking_id uuid)
returns public.bookings language plpgsql security definer set search_path=public as $$
declare result public.bookings;
begin
  update public.bookings set confirmed_stop_count=confirmed_stop_count+1, arrival_pending=false
  where id=p_booking_id and tourist_id=auth.uid() and status='ongoing' and arrival_pending returning * into result;
  if result.id is null then raise exception 'No arrival is awaiting confirmation'; end if;
  update public.booking_stops set confirmed_at=now()
    where booking_id=result.id and stop_order=result.confirmed_stop_count;
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description,metadata)
  values(result.id,auth.uid(),'tourist','stop_arrival_confirmed','Tourist confirmed arrival.',jsonb_build_object('stop_order',result.confirmed_stop_count));
  return result;
end;
$$;
grant execute on function public.confirm_stop_arrival(uuid) to authenticated;

create or replace function public.complete_trip(p_booking_id uuid)
returns public.bookings language plpgsql security definer set search_path=public as $$
declare result public.bookings; total_stops integer;
begin
  select count(*) into total_stops from public.booking_stops where booking_id=p_booking_id;
  update public.bookings set status='completed', completed_at=now(), final_charge_centavos=quoted_amount_centavos,
    payment_status=case when payment_method='cash' then 'cash_awaiting_confirmation'::public.payment_status else payment_status end
  where id=p_booking_id and driver_id=auth.uid() and status='ongoing'
    and not arrival_pending and confirmed_stop_count=total_stops returning * into result;
  if result.id is null then raise exception 'Every stop must be confirmed before completion'; end if;
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description)
  values(result.id,auth.uid(),'driver','trip_completed','All booked stops were confirmed; trip completed.');
  return result;
end;
$$;
grant execute on function public.complete_trip(uuid) to authenticated;

create or replace function public.cancel_booking(p_booking_id uuid, p_reason text)
returns public.bookings language plpgsql security definer set search_path=public as $$
declare b public.bookings; policy public.cancellation_policies; actor public.app_role; charge integer; paid integer;
begin
  if length(trim(p_reason)) < 5 then raise exception 'A cancellation reason is required'; end if;
  select * into b from public.bookings where id=p_booking_id for update;
  if b.id is null or b.status not in ('pending','accepted','ongoing') then raise exception 'Booking cannot be cancelled'; end if;
  if auth.uid()=b.tourist_id then actor='tourist'; elsif auth.uid()=b.driver_id then actor='driver'; else raise exception 'Only a participant can cancel'; end if;
  select * into policy from public.cancellation_policies where id=b.cancellation_policy_id;
  if b.status='ongoing' then
    charge=null;
  elsif actor='driver' or b.status='pending' or now() <= b.accepted_at + make_interval(mins => policy.free_cancellation_minutes) then
    charge=0;
  else
    charge=round(b.quoted_amount_centavos * policy.accepted_trip_fee_percent / 100.0);
  end if;
  select coalesce(sum(amount_centavos),0) into paid from public.payments where booking_id=b.id and status in ('paid','cash_paid');
  update public.bookings set status='cancelled', completed_at=now(), cancelled_by=auth.uid(),
    cancellation_reason=trim(p_reason), final_charge_centavos=charge,
    payment_status=case
      when charge is null then 'under_review'::public.payment_status
      when paid > charge then 'refund_required'::public.payment_status
      when charge=0 then 'waived'::public.payment_status
      else 'unpaid'::public.payment_status end,
    arrival_pending=false where id=b.id returning * into b;
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description,metadata)
  values(b.id,auth.uid(),actor,'booking_cancelled','Booking cancelled: '||trim(p_reason),jsonb_build_object('final_charge_centavos',charge));
  if charge is null then
    insert into public.disputes(booking_id,opened_by,reason) values(b.id,auth.uid(),'Trip ended after pickup: '||trim(p_reason));
  end if;
  return b;
end;
$$;
grant execute on function public.cancel_booking(uuid,text) to authenticated;

create or replace function public.resolve_booking_charge(p_booking_id uuid, p_charge_centavos integer, p_reason text)
returns public.bookings language plpgsql security definer set search_path=public as $$
declare b public.bookings; paid integer;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  if length(trim(p_reason)) < 10 then raise exception 'A detailed decision reason is required'; end if;
  select * into b from public.bookings where id=p_booking_id for update;
  if b.id is null or b.payment_status <> 'under_review' or p_charge_centavos not between 0 and b.quoted_amount_centavos then
    raise exception 'Booking or final charge is invalid';
  end if;
  select coalesce(sum(amount_centavos),0) into paid from public.payments where booking_id=b.id and status in ('paid','cash_paid');
  update public.bookings set final_charge_centavos=p_charge_centavos,
    payment_status=case when paid>p_charge_centavos then 'refund_required'::public.payment_status
      when p_charge_centavos=0 then 'waived'::public.payment_status
      when paid=p_charge_centavos then 'paid'::public.payment_status else 'unpaid'::public.payment_status end
    where id=b.id returning * into b;
  update public.disputes set status='resolved',resolution=trim(p_reason),resolved_by=auth.uid(),resolved_at=now()
    where booking_id=b.id and status='open';
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description,metadata)
  values(b.id,auth.uid(),'admin','settlement_resolved',trim(p_reason),jsonb_build_object('final_charge_centavos',p_charge_centavos));
  return b;
end;
$$;
grant execute on function public.resolve_booking_charge(uuid,integer,text) to authenticated;

create or replace function public.confirm_cash(p_booking_id uuid, p_direction text)
returns public.bookings language plpgsql security definer set search_path=public as $$
declare b public.bookings; actor public.app_role; amount integer; confirmations integer;
begin
  select * into b from public.bookings where id=p_booking_id for update;
  if b.id is null or b.payment_method <> 'cash' or b.status in ('pending','accepted','ongoing') then raise exception 'Cash cannot be confirmed yet'; end if;
  if auth.uid()=b.tourist_id then actor='tourist'; elsif auth.uid()=b.driver_id then actor='driver'; else raise exception 'Only a participant can confirm cash'; end if;
  if p_direction='payment' then amount=coalesce(b.final_charge_centavos,0);
  elsif p_direction='refund' then
    select greatest(coalesce(sum(amount_centavos),0)-coalesce(b.final_charge_centavos,0),0) into amount from public.payments where booking_id=b.id and status='cash_paid';
  else raise exception 'Invalid cash direction'; end if;
  if amount<=0 then raise exception 'No cash amount is outstanding'; end if;
  insert into public.cash_confirmations(booking_id,direction,actor_id,actor_role,amount_centavos)
  values(b.id,p_direction,auth.uid(),actor,amount) on conflict(booking_id,direction,actor_role) do nothing;
  select count(*) into confirmations from public.cash_confirmations where booking_id=b.id and direction=p_direction;
  if confirmations=2 and p_direction='payment' then
    insert into public.payments(booking_id,provider,amount_centavos,status)
    values(b.id,'cash',amount,'cash_paid') on conflict do nothing;
    update public.bookings set payment_status='cash_paid' where id=b.id returning * into b;
  elsif confirmations=2 and p_direction='refund' then
    update public.bookings set payment_status='refunded' where id=b.id returning * into b;
  else
    update public.bookings set payment_status=case when p_direction='payment' then 'cash_awaiting_confirmation'::public.payment_status else 'refund_required'::public.payment_status end
      where id=b.id returning * into b;
  end if;
  return b;
end;
$$;
grant execute on function public.confirm_cash(uuid,text) to authenticated;

create or replace function public.submit_driver_review(p_booking_id uuid, p_rating integer, p_review text)
returns void language plpgsql security definer set search_path=public as $$
declare b public.bookings;
begin
  select * into b from public.bookings where id=p_booking_id;
  if b.tourist_id<>auth.uid() or b.status<>'completed' or b.driver_id is null then raise exception 'Completed tourist booking required'; end if;
  insert into public.booking_reviews(booking_id,tourist_id,driver_id,rating,review)
  values(b.id,auth.uid(),b.driver_id,p_rating,trim(coalesce(p_review,'')));
  update public.driver_profiles d set rating_count=s.cnt,rating_average=s.avg
  from (select driver_id,count(*) cnt,avg(rating)::numeric(3,2) avg from public.booking_reviews where driver_id=b.driver_id group by driver_id) s
  where d.profile_id=s.driver_id;
end;
$$;
grant execute on function public.submit_driver_review(uuid,integer,text) to authenticated;

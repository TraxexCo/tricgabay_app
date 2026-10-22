-- Evidence-based pickup arrival and tourist no-show handling.
-- Server time, the driver's latest accepted GPS fix, and the booking's
-- snapshotted cancellation policy are authoritative.

alter table public.bookings
  add column if not exists driver_arrived_at timestamptz,
  add column if not exists pickup_wait_expires_at timestamptz;

alter table public.bookings
  drop constraint if exists bookings_pickup_wait_order;
alter table public.bookings
  add constraint bookings_pickup_wait_order check (
    pickup_wait_expires_at is null
    or (driver_arrived_at is not null and pickup_wait_expires_at >= driver_arrived_at)
  );

create or replace function public.report_pickup_arrival(p_booking_id uuid)
returns public.bookings
language plpgsql
security definer
set search_path=public
as $$
declare
  b public.bookings;
  policy public.cancellation_policies;
  location public.driver_locations;
  distance_meters double precision;
begin
  select * into b from public.bookings where id=p_booking_id for update;
  if b.id is null or b.driver_id<>auth.uid() or b.status<>'accepted' then
    raise exception 'Only the assigned driver can report arrival for an accepted booking';
  end if;
  if b.driver_arrived_at is not null then
    return b;
  end if;

  select * into location from public.driver_locations where driver_id=auth.uid();
  if location.driver_id is null or location.recorded_at < now()-interval '60 seconds' then
    raise exception 'A fresh driver location is required before reporting arrival';
  end if;
  if location.accuracy_meters is null or location.accuracy_meters > 100 then
    raise exception 'GPS accuracy is too low. Move to an open area and try again';
  end if;
  distance_meters := st_distance(
    st_setsrid(st_makepoint(location.longitude,location.latitude),4326)::geography,
    st_setsrid(st_makepoint(b.pickup_longitude,b.pickup_latitude),4326)::geography
  );
  if distance_meters > 150 then
    raise exception 'Move within 150 meters of the pickup point before reporting arrival';
  end if;

  select * into policy from public.cancellation_policies where id=b.cancellation_policy_id;
  update public.bookings
    set driver_arrived_at=now(),
        pickup_wait_expires_at=now()+make_interval(mins=>policy.driver_wait_minutes)
    where id=b.id
    returning * into b;

  insert into public.trip_events(
    booking_id,actor_id,actor_role,event_type,description,metadata
  ) values (
    b.id,auth.uid(),'driver','pickup_arrival_verified',
    'Driver arrived within the verified pickup area; the waiting period started.',
    jsonb_build_object(
      'distance_meters',round(distance_meters::numeric,1),
      'accuracy_meters',location.accuracy_meters,
      'wait_expires_at',b.pickup_wait_expires_at
    )
  );
  insert into public.notifications(recipient_id,title,body,route_path)
  values(
    b.tourist_id,
    'Your driver has arrived',
    'Meet your driver at the selected pickup point. The pickup waiting period has started.',
    '/tourist/tracking/'||b.id
  );
  return b;
end;
$$;

revoke all on function public.report_pickup_arrival(uuid) from public;
grant execute on function public.report_pickup_arrival(uuid) to authenticated;

create or replace function public.start_trip(p_booking_id uuid, p_pickup_code text)
returns public.bookings
language plpgsql
security definer
set search_path=public
as $$
declare result public.bookings;
begin
  update public.bookings set status='ongoing',started_at=now()
  where id=p_booking_id and driver_id=auth.uid() and status='accepted'
    and driver_arrived_at is not null
    and pickup_code_hash=crypt(trim(p_pickup_code),pickup_code_hash)
  returning * into result;
  if result.id is null then
    raise exception 'Verified pickup arrival, the accepted booking, and the correct pickup code are required';
  end if;
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description)
  values(result.id,auth.uid(),'driver','trip_started','Pickup arrival and code verified; trip started.');
  return result;
end;
$$;

revoke all on function public.start_trip(uuid,text) from public;
grant execute on function public.start_trip(uuid,text) to authenticated;

create or replace function public.declare_tourist_no_show(p_booking_id uuid)
returns public.bookings
language plpgsql
security definer
set search_path=public
as $$
declare
  b public.bookings;
  policy public.cancellation_policies;
  charge integer;
  paid integer;
begin
  select * into b from public.bookings where id=p_booking_id for update;
  if b.id is null or b.driver_id<>auth.uid() or b.status<>'accepted' then
    raise exception 'Only the assigned driver can report a no-show';
  end if;
  if b.driver_arrived_at is null or b.pickup_wait_expires_at is null then
    raise exception 'Verified pickup arrival is required first';
  end if;
  if now() < b.pickup_wait_expires_at then
    raise exception 'The pickup waiting period has not finished';
  end if;

  select * into policy from public.cancellation_policies where id=b.cancellation_policy_id;
  charge := round(b.quoted_amount_centavos*policy.no_show_fee_percent/100.0);
  select coalesce(sum(amount_centavos),0) into paid
    from public.payments where booking_id=b.id and status in ('paid','cash_paid');

  update public.bookings
    set status='cancelled',completed_at=now(),cancelled_by=auth.uid(),
        cancellation_reason='Tourist no-show after verified pickup wait.',
        final_charge_centavos=charge,
        payment_status=case
          when paid>charge then 'refund_required'::public.payment_status
          when charge=0 then 'waived'::public.payment_status
          else 'unpaid'::public.payment_status end
    where id=b.id
    returning * into b;

  insert into public.trip_events(
    booking_id,actor_id,actor_role,event_type,description,metadata
  ) values (
    b.id,auth.uid(),'driver','tourist_no_show',
    'Tourist reported as a no-show after the verified pickup waiting period.',
    jsonb_build_object(
      'driver_arrived_at',b.driver_arrived_at,
      'wait_expired_at',b.pickup_wait_expires_at,
      'fee_percent',policy.no_show_fee_percent,
      'final_charge_centavos',charge
    )
  );
  insert into public.notifications(recipient_id,title,body,route_path)
  values(
    b.tourist_id,
    'Booking ended as a no-show',
    'The verified pickup waiting period ended. Review the charge or open a dispute from your booking.',
    '/tourist/bookings/'||b.id
  );
  return b;
end;
$$;

revoke all on function public.declare_tourist_no_show(uuid) from public;
grant execute on function public.declare_tourist_no_show(uuid) to authenticated;

-- An administrator may reduce a snapshotted pre-pickup fee after a dispute,
-- but may never create or increase a fee after the trip has already ended.
create or replace function public.resolve_booking_charge(
  p_booking_id uuid,
  p_charge_centavos integer,
  p_reason text
) returns public.bookings
language plpgsql
security definer
set search_path=public
as $$
declare
  b public.bookings;
  paid integer;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  if length(trim(p_reason)) < 10 then raise exception 'A detailed decision reason is required'; end if;
  select * into b from public.bookings where id=p_booking_id for update;
  if b.id is null or b.payment_status<>'under_review'
     or p_charge_centavos not between 0 and b.quoted_amount_centavos then
    raise exception 'Booking or final charge is invalid';
  end if;
  if b.started_at is null and p_charge_centavos>coalesce(b.final_charge_centavos,0) then
    raise exception 'A pre-pickup review cannot increase the snapshotted cancellation charge';
  end if;

  select coalesce(sum(amount_centavos),0) into paid from public.payments
    where booking_id=b.id and status in ('paid','cash_paid');
  update public.bookings set final_charge_centavos=p_charge_centavos,
    payment_status=case
      when paid>p_charge_centavos then 'refund_required'::public.payment_status
      when p_charge_centavos=0 then 'waived'::public.payment_status
      when paid=p_charge_centavos then 'paid'::public.payment_status
      else 'unpaid'::public.payment_status end
    where id=b.id returning * into b;
  update public.disputes set status='resolved',resolution=trim(p_reason),
    resolved_by=auth.uid(),resolved_at=now()
    where booking_id=b.id and status='open';
  insert into public.trip_events(
    booking_id,actor_id,actor_role,event_type,description,metadata
  ) values (
    b.id,auth.uid(),'admin','settlement_resolved',trim(p_reason),
    jsonb_build_object('final_charge_centavos',p_charge_centavos)
  );
  return b;
end;
$$;

revoke all on function public.resolve_booking_charge(uuid,integer,text) from public;
grant execute on function public.resolve_booking_charge(uuid,integer,text) to authenticated;

-- Core integrity fixes discovered by remote database linting.
-- Keep system-generated trip events actor-less: app_role represents accounts,
-- while a null actor_role is already mapped to TripActor.system by the client.

alter function public.create_booking(
  text,public.payment_method,text,double precision,double precision,jsonb
) set search_path = public, extensions;

alter function public.start_trip(uuid,text) set search_path = public, extensions;

create or replace function public.activate_due_scheduled_bookings()
returns integer
language plpgsql
security definer
set search_path=public
as $$
declare
  b record;
  activated integer := 0;
begin
  for b in
    update public.bookings
      set status='pending',dispatch_expires_at=now()+interval '10 minutes'
      where status='scheduled' and scheduled_at<=now()+interval '30 minutes'
      returning id,tourist_id,scheduled_at
  loop
    perform public.create_ranked_driver_offers(b.id);
    insert into public.trip_events(
      booking_id,actor_id,actor_role,event_type,description,metadata
    ) values (
      b.id,null,null,'scheduled_dispatch_started',
      'Scheduled booking entered its driver-matching window.',
      jsonb_build_object('scheduled_at',b.scheduled_at,'actor','system')
    );
    insert into public.notifications(recipient_id,title,body,route_path)
    values(
      b.tourist_id,'Finding your driver',
      'Your scheduled pickup is approaching. Tric-Gabay is now matching a nearby compatible driver.',
      '/tourist/bookings/'||b.id
    );
    activated := activated+1;
  end loop;
  return activated;
end;
$$;
revoke all on function public.activate_due_scheduled_bookings() from public;
grant execute on function public.activate_due_scheduled_bookings() to authenticated;

create or replace function public.finalize_paymongo_refund(
  p_refund_id uuid,
  p_provider_refund_id text,
  p_provider_status text,
  p_status public.refund_status,
  p_failure_reason text,
  p_metadata jsonb
) returns void language plpgsql security definer set search_path=public as $$
declare
  r public.refunds;
  b public.bookings;
  due integer;
  succeeded integer;
begin
  if auth.role()<>'service_role' then raise exception 'Service role required'; end if;
  update public.refunds set
    provider_refund_id=coalesce(p_provider_refund_id,provider_refund_id),
    provider_status=p_provider_status,status=p_status,failure_reason=p_failure_reason,
    provider_metadata=coalesce(p_metadata,'{}'::jsonb),
    processed_at=case when p_status in ('succeeded','failed','rejected') then now() else processed_at end
  where id=p_refund_id returning * into r;
  if r.id is null then raise exception 'Refund not found'; end if;
  select * into b from public.bookings where id=r.booking_id for update;
  due := greatest((select amount_centavos from public.payments where id=r.payment_id)
    -coalesce(b.final_charge_centavos,b.quoted_amount_centavos),0);
  select coalesce(sum(amount_centavos),0) into succeeded from public.refunds
    where payment_id=r.payment_id and status='succeeded';
  update public.bookings set payment_status=case
    when succeeded>=due and due>0 then 'refunded'::public.payment_status
    when succeeded>0 then 'partially_refunded'::public.payment_status
    when p_status in ('failed','rejected') then 'refund_required'::public.payment_status
    else 'refund_processing'::public.payment_status end
  where id=r.booking_id;
  insert into public.trip_events(
    booking_id,actor_id,actor_role,event_type,description,metadata
  ) values (
    r.booking_id,null,null,
    case when p_status='succeeded' then 'refund_completed' else 'refund_provider_update' end,
    case when p_status='succeeded' then 'PayMongo confirmed the refund.'
         when p_status in ('failed','rejected') then 'PayMongo did not complete the refund.'
         else 'PayMongo is processing the refund.' end,
    jsonb_build_object(
      'actor','system','refund_id',r.id,
      'provider_refund_id',p_provider_refund_id,
      'provider_status',p_provider_status,'failure_reason',p_failure_reason
    )
  );
end;
$$;
revoke all on function public.finalize_paymongo_refund(
  uuid,text,text,public.refund_status,text,jsonb
) from public;
grant execute on function public.finalize_paymongo_refund(
  uuid,text,text,public.refund_status,text,jsonb
) to service_role;

-- A driver may publish location only while deliberately online or while still
-- assigned to an accepted/ongoing trip. Older samples can never overwrite a
-- newer position.
create or replace function public.publish_driver_location(
  p_latitude double precision,
  p_longitude double precision,
  p_accuracy double precision,
  p_heading double precision,
  p_speed double precision,
  p_recorded_at timestamptz
) returns void language plpgsql security definer set search_path=public as $$
declare active_booking uuid;
begin
  if not public.is_approved_driver() then raise exception 'Approved driver account required'; end if;
  if not exists(
    select 1 from public.driver_profiles d
    where d.profile_id=auth.uid() and (
      d.is_online or exists(
        select 1 from public.bookings b
        where b.driver_id=auth.uid() and b.status in ('accepted','ongoing')
      )
    )
  ) then raise exception 'Go online before sharing location'; end if;
  if p_recorded_at < now()-interval '2 minutes' or p_recorded_at > now()+interval '30 seconds' then
    raise exception 'Location timestamp is stale or invalid';
  end if;
  if p_latitude not between -90 and 90 or p_longitude not between -180 and 180 then
    raise exception 'Location coordinates are invalid';
  end if;
  if p_accuracy is not null and p_accuracy not between 0 and 200 then
    raise exception 'Location accuracy is too low';
  end if;
  if p_heading is not null and p_heading not between 0 and 360 then
    raise exception 'Location heading is invalid';
  end if;
  if p_speed is not null and p_speed not between 0 and 60 then
    raise exception 'Location speed is invalid';
  end if;
  select id into active_booking from public.bookings
    where driver_id=auth.uid() and status in ('accepted','ongoing')
    order by created_at desc limit 1;
  insert into public.driver_locations(
    driver_id,latitude,longitude,accuracy_meters,heading,speed_mps,recorded_at
  ) values (
    auth.uid(),p_latitude,p_longitude,p_accuracy,p_heading,p_speed,p_recorded_at
  ) on conflict(driver_id) do update set
    latitude=excluded.latitude,longitude=excluded.longitude,
    accuracy_meters=excluded.accuracy_meters,heading=excluded.heading,
    speed_mps=excluded.speed_mps,recorded_at=excluded.recorded_at,updated_at=now()
  where public.driver_locations.recorded_at<=excluded.recorded_at;
  if active_booking is not null then
    insert into public.driver_location_history(
      driver_id,booking_id,latitude,longitude,accuracy_meters,recorded_at
    ) values (
      auth.uid(),active_booking,p_latitude,p_longitude,p_accuracy,p_recorded_at
    );
  end if;
  update public.driver_profiles set last_seen_at=now() where profile_id=auth.uid();
end;
$$;
revoke all on function public.publish_driver_location(
  double precision,double precision,double precision,double precision,
  double precision,timestamptz
) from public;
grant execute on function public.publish_driver_location(
  double precision,double precision,double precision,double precision,
  double precision,timestamptz
) to authenticated;

-- Device tokens are reclaimed atomically when the same installation changes
-- accounts, preventing the previous user's notifications reaching the new
-- signed-in user. Clients cannot write token ownership directly.
create or replace function public.register_push_token(
  p_token text,p_platform text,p_device_label text
) returns void language plpgsql security definer set search_path=public as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if length(trim(p_token)) not between 20 and 4096 then raise exception 'Invalid push token'; end if;
  if p_platform not in ('android','ios','web','macos','windows','linux','other') then
    raise exception 'Invalid push platform';
  end if;
  insert into public.push_tokens(
    token,profile_id,platform,device_label,last_seen_at,revoked_at,updated_at
  ) values (
    trim(p_token),auth.uid(),p_platform,left(trim(coalesce(p_device_label,'')),120),now(),null,now()
  ) on conflict(token) do update set
    profile_id=auth.uid(),platform=excluded.platform,
    device_label=excluded.device_label,last_seen_at=now(),revoked_at=null,updated_at=now();
end;
$$;
revoke all on function public.register_push_token(text,text,text) from public;
grant execute on function public.register_push_token(text,text,text) to authenticated;

create or replace function public.revoke_push_token(p_token text)
returns void language plpgsql security definer set search_path=public as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  update public.push_tokens set revoked_at=now(),updated_at=now()
    where token=p_token and profile_id=auth.uid();
end;
$$;
revoke all on function public.revoke_push_token(text) from public;
grant execute on function public.revoke_push_token(text) to authenticated;

revoke insert,update,delete on public.push_tokens from anon,authenticated;

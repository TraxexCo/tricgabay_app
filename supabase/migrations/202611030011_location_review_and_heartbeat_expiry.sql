alter table public.driver_locations add column is_mocked boolean not null default false;
alter table public.service_configuration add column stale_heartbeat_seconds integer not null default 120 check(stale_heartbeat_seconds between 30 and 3600);
create or replace function public.publish_driver_location_with_flags(
  p_latitude double precision,
  p_longitude double precision,
  p_accuracy double precision,
  p_heading double precision,
  p_speed double precision,
  p_recorded_at timestamptz, p_is_mocked boolean default false
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
    driver_id,latitude,longitude,accuracy_meters,heading,speed_mps,recorded_at,is_mocked
  ) values (
    auth.uid(),p_latitude,p_longitude,p_accuracy,p_heading,p_speed,p_recorded_at,coalesce(p_is_mocked,false)
  ) on conflict(driver_id) do update set
    latitude=excluded.latitude,longitude=excluded.longitude,
    accuracy_meters=excluded.accuracy_meters,heading=excluded.heading,
    speed_mps=excluded.speed_mps,recorded_at=excluded.recorded_at,updated_at=now(),is_mocked=excluded.is_mocked
  where public.driver_locations.recorded_at<=excluded.recorded_at;
  if active_booking is not null then
    insert into public.driver_location_history(
      driver_id,booking_id,latitude,longitude,accuracy_meters,recorded_at
    ) values (
      auth.uid(),active_booking,p_latitude,p_longitude,p_accuracy,p_recorded_at
    );
  end if;
  update public.driver_profiles set last_seen_at=now() where profile_id=auth.uid();
  if p_is_mocked and not exists(select 1 from public.operational_alerts where dedupe_key='mock-location:'||auth.uid()::text and last_seen_at>now()-interval '5 minutes' and resolved_at is null) then
    perform public.raise_operational_alert('warning','location','mock-location:'||auth.uid()::text,
      'Mock location reported','A driver device reported a mocked location. Review the report; service is not automatically blocked.',jsonb_build_object('driver_id',auth.uid(),'is_mocked',true));
  end if;
end;
$$;

revoke all on function public.publish_driver_location_with_flags(double precision,double precision,double precision,double precision,double precision,timestamptz,boolean) from public,anon;
grant execute on function public.publish_driver_location_with_flags(double precision,double precision,double precision,double precision,double precision,timestamptz,boolean) to authenticated;
create or replace function public.publish_driver_location(p_latitude double precision,p_longitude double precision,p_accuracy double precision,p_heading double precision,p_speed double precision,p_recorded_at timestamptz)
returns void language sql security definer set search_path=public as $$
 select public.publish_driver_location_with_flags(p_latitude,p_longitude,p_accuracy,p_heading,p_speed,p_recorded_at,false)
$$;
create function public.expire_stale_online_drivers() returns integer language plpgsql security definer set search_path=public as $$
declare threshold integer; affected integer;
begin
 select stale_heartbeat_seconds into strict threshold from public.service_configuration where singleton;
 update public.driver_profiles set is_online=false where is_online and (last_seen_at is null or last_seen_at<now()-make_interval(secs=>threshold));
 get diagnostics affected=row_count;return affected;
end $$;
revoke all on function public.expire_stale_online_drivers() from public,anon,authenticated;
grant execute on function public.expire_stale_online_drivers() to service_role;
select cron.schedule('expire-stale-online-drivers','* * * * *','select public.expire_stale_online_drivers()');

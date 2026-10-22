-- Limit pickup-code guessing and keep a tourist's profile private until a
-- driver actually accepts the booking.

alter table public.bookings
  add column if not exists pickup_code_failed_attempts integer not null default 0
    check (pickup_code_failed_attempts between 0 and 5),
  add column if not exists pickup_code_locked_until timestamptz;

create or replace function public.start_trip(p_booking_id uuid, p_pickup_code text)
returns public.bookings
language plpgsql
security definer
set search_path=public,extensions
as $$
declare
  result public.bookings;
  next_failed_attempts integer;
begin
  select * into result
    from public.bookings
    where id=p_booking_id
    for update;

  if result.id is null or result.driver_id<>auth.uid()
     or result.status<>'accepted' or result.driver_arrived_at is null then
    raise exception 'Verified pickup arrival and the assigned accepted booking are required';
  end if;

  if result.pickup_code_locked_until is not null
     and result.pickup_code_locked_until>now() then
    return result;
  end if;

  if result.pickup_code_hash<>crypt(trim(p_pickup_code),result.pickup_code_hash) then
    next_failed_attempts := case
      when result.pickup_code_locked_until is not null
           and result.pickup_code_locked_until<=now() then 1
      else least(result.pickup_code_failed_attempts+1,5)
    end;

    update public.bookings set
      pickup_code_failed_attempts=next_failed_attempts,
      pickup_code_locked_until=case
        when next_failed_attempts>=5 then now()+interval '15 minutes'
        else null
      end
      where id=result.id
      returning * into result;

    insert into public.trip_events(
      booking_id,actor_id,actor_role,event_type,description,metadata
    ) values (
      result.id,auth.uid(),'driver',
      case when next_failed_attempts>=5
        then 'pickup_code_temporarily_locked'
        else 'pickup_code_failed' end,
      case when next_failed_attempts>=5
        then 'Pickup-code verification was temporarily locked after repeated failures.'
        else 'A pickup-code verification attempt failed.' end,
      jsonb_build_object(
        'failed_attempts',next_failed_attempts,
        'locked_until',result.pickup_code_locked_until
      )
    );

    if next_failed_attempts>=5 then
      insert into public.notifications(recipient_id,title,body,route_path)
      values(
        result.tourist_id,
        'Pickup code temporarily locked',
        'Several incorrect codes were entered. Confirm the driver and wait 15 minutes before trying again.',
        '/tourist/bookings/'||result.id
      );
    end if;

    -- Return the still-accepted booking so the failed-attempt audit is not
    -- rolled back by an exception. The client treats any non-ongoing result
    -- as a failed verification.
    return result;
  end if;

  update public.bookings set
    status='ongoing',started_at=now(),
    pickup_code_failed_attempts=0,pickup_code_locked_until=null
    where id=result.id
    returning * into result;

  insert into public.trip_events(
    booking_id,actor_id,actor_role,event_type,description
  ) values (
    result.id,auth.uid(),'driver','trip_started',
    'Pickup arrival and code verified; trip started.'
  );
  return result;
end;
$$;

revoke all on function public.start_trip(uuid,text) from public;
grant execute on function public.start_trip(uuid,text) to authenticated;

-- The accepted participant policy already exposes the other party after a
-- match. Remove the broader offer-time policy so an offered driver cannot
-- select the tourist's phone, email, avatar, status, or full name.
drop policy if exists profiles_booking_participant_read on public.profiles;
create policy profiles_booking_participant_read on public.profiles
for select to authenticated using (
  exists(
    select 1 from public.bookings b
    where (b.tourist_id=profiles.id and b.driver_id=auth.uid())
       or (b.driver_id=profiles.id and b.tourist_id=auth.uid())
  )
);

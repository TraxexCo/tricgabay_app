-- LOCAL FILE ONLY: NOT applied/tested against a real database.
alter table public.bookings add column pickup_reissue_id uuid, add column pickup_reissued_at timestamptz;
create or replace function public.reissue_booking_pickup_code(p_booking_id uuid,p_request_id uuid,p_code text)
returns text language plpgsql security definer set search_path=public,extensions as $$
declare b public.bookings;
begin
  if auth.uid() is null or public.current_profile_role()<>'tourist' then raise exception 'Active tourist required' using errcode='42501'; end if;
  if p_request_id is null or p_code is null or p_code !~ '^[0-9]{4}$' then raise exception 'Invalid code request'; end if;
  select * into b from public.bookings where id=p_booking_id for update;
  if b.id is null or b.tourist_id<>auth.uid() or b.status not in ('payment_pending','scheduled','pending','accepted') then
    raise exception 'Code cannot be reissued for this booking' using errcode='42501';
  end if;
  if b.pickup_reissue_id=p_request_id then
    if b.pickup_code_hash=crypt(p_code,b.pickup_code_hash) then return p_code; end if;
    raise exception 'Code request conflict';
  end if;
  -- Rotation never clears failed-attempt counts or an existing verification lock.
  if b.pickup_code_locked_until>now() then raise exception 'Pickup code temporarily locked'; end if;
  if b.pickup_reissued_at>now()-interval '5 minutes' or (
    select count(*) from public.trip_events where booking_id=b.id and event_type='pickup_code_reissued'
      and created_at>now()-interval '1 hour')>=5 then raise exception 'Wait before requesting another pickup code'; end if;
  if b.pickup_code_hash=crypt(p_code,b.pickup_code_hash) then raise exception 'New code must differ from old code'; end if;
  update public.bookings set pickup_code_hash=crypt(p_code,gen_salt('bf')),
    pickup_reissue_id=p_request_id,pickup_reissued_at=now(),
    pickup_code_recovery_id=coalesce(pickup_code_recovery_id,p_request_id),
    pickup_code_recovered_at=coalesce(pickup_code_recovered_at,now()) where id=b.id;
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description)
    values(b.id,auth.uid(),'tourist','pickup_code_reissued','Pickup code reissued; the previous code is invalid.');
  return p_code;
end $$;
revoke all on function public.reissue_booking_pickup_code(uuid,uuid,text) from public,anon;
grant execute on function public.reissue_booking_pickup_code(uuid,uuid,text) to authenticated;

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
     or recovered.status not in ('payment_pending','scheduled','pending','accepted') then
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


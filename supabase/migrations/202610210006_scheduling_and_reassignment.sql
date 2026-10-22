-- Scheduled dispatch, reminders, and consent-based replacement-driver workflow.

alter table public.bookings
  add column if not exists scheduled_at timestamptz,
  add column if not exists replacement_requested_at timestamptz,
  add column if not exists replacement_reason text,
  add column if not exists replacement_requested_by uuid references public.profiles(id);

alter table public.bookings
  add constraint bookings_schedule_consistency check (
    (status='scheduled' and scheduled_at is not null)
    or status<>'scheduled'
  );

create index if not exists bookings_scheduled_due_idx
  on public.bookings(scheduled_at)
  where status='scheduled';
create unique index if not exists one_live_booking_per_tourist
  on public.bookings(tourist_id)
  where status in ('scheduled','pending','accepted','replacement_pending','ongoing');
create unique index if not exists one_live_booking_per_driver
  on public.bookings(driver_id)
  where driver_id is not null
    and status in ('accepted','replacement_pending','ongoing');

create table if not exists public.booking_reminders (
  booking_id uuid not null references public.bookings(id) on delete cascade,
  reminder_kind text not null check (reminder_kind in ('24_hours','1_hour')),
  sent_at timestamptz not null default now(),
  primary key(booking_id,reminder_kind)
);
alter table public.booking_reminders enable row level security;
revoke all on public.booking_reminders from anon,authenticated;

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
  p_scheduled_at timestamptz default null
) returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  result jsonb;
  booking_id uuid;
  future_booking boolean := p_scheduled_at is not null;
begin
  if public.current_profile_role()<>'tourist' then
    raise exception 'Active tourist account required';
  end if;
  if exists(
    select 1 from public.bookings
    where tourist_id=auth.uid()
      and status in ('scheduled','pending','accepted','replacement_pending','ongoing')
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
    passenger_count=p_passenger_count,
    luggage_notes=trim(coalesce(p_luggage_notes,'')),
    accessibility_needs=trim(coalesce(p_accessibility_needs,'')),
    scheduled_at=p_scheduled_at,
    status=case when future_booking then 'scheduled'::public.booking_status else status end,
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
  else
    perform public.create_ranked_driver_offers(booking_id);
  end if;
  return result;
end;
$$;
revoke all on function public.create_booking_with_schedule(
  text,public.payment_method,text,double precision,double precision,jsonb,integer,text,text,timestamptz
) from public;
grant execute on function public.create_booking_with_schedule(
  text,public.payment_method,text,double precision,double precision,jsonb,integer,text,text,timestamptz
) to authenticated;

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
      booking_id,actor_role,event_type,description,metadata
    ) values (
      b.id,'system','scheduled_dispatch_started',
      'Scheduled booking entered its driver-matching window.',
      jsonb_build_object('scheduled_at',b.scheduled_at)
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

create or replace function public.send_scheduled_booking_reminders()
returns integer
language plpgsql
security definer
set search_path=public
as $$
declare sent integer := 0;
begin
  with due as (
    select b.id,b.tourist_id,'24_hours'::text kind
    from public.bookings b
    where b.status='scheduled'
      and b.scheduled_at between now()+interval '23 hours 50 minutes' and now()+interval '24 hours 5 minutes'
    union all
    select b.id,b.tourist_id,'1_hour'::text kind
    from public.bookings b
    where b.status='scheduled'
      and b.scheduled_at between now()+interval '50 minutes' and now()+interval '1 hour 5 minutes'
  ), inserted as (
    insert into public.booking_reminders(booking_id,reminder_kind)
    select id,kind from due on conflict do nothing
    returning booking_id,reminder_kind
  )
  insert into public.notifications(recipient_id,title,body,route_path)
  select b.tourist_id,
    case when i.reminder_kind='24_hours' then 'Tour tomorrow' else 'Tour starts in about an hour' end,
    case when i.reminder_kind='24_hours'
      then 'Review your pickup point and passenger details before tomorrow’s scheduled tour.'
      else 'Be ready at the pickup point. Driver matching begins 30 minutes before pickup.' end,
    '/tourist/bookings/'||b.id
  from inserted i join public.bookings b on b.id=i.booking_id;
  get diagnostics sent=row_count;
  return sent;
end;
$$;
revoke all on function public.send_scheduled_booking_reminders() from public;

create or replace function public.request_driver_replacement(
  p_booking_id uuid,
  p_reason text
) returns public.bookings
language plpgsql
security definer
set search_path=public
as $$
declare b public.bookings;
begin
  if length(trim(p_reason))<5 then raise exception 'Explain why a replacement is needed'; end if;
  update public.bookings set
    status='replacement_pending',
    replacement_requested_at=now(),
    replacement_reason=trim(p_reason),
    replacement_requested_by=auth.uid()
    where id=p_booking_id and driver_id=auth.uid() and status='accepted'
      and started_at is null
    returning * into b;
  if b.id is null then raise exception 'Only the assigned driver can request replacement before pickup'; end if;
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description,metadata)
  values(
    b.id,auth.uid(),'driver','replacement_requested',
    'Driver requested a replacement: '||trim(p_reason),
    jsonb_build_object('previous_driver_id',auth.uid())
  );
  insert into public.notifications(recipient_id,title,body,route_path)
  values(
    b.tourist_id,'Driver needs to be replaced',
    'Choose whether to find another verified driver or cancel free of charge.',
    '/tourist/bookings/'||b.id
  );
  return b;
end;
$$;
revoke all on function public.request_driver_replacement(uuid,text) from public;
grant execute on function public.request_driver_replacement(uuid,text) to authenticated;

create or replace function public.decide_driver_replacement(
  p_booking_id uuid,
  p_find_replacement boolean
) returns public.bookings
language plpgsql
security definer
set search_path=public
as $$
declare
  b public.bookings;
  old_driver uuid;
  paid integer;
begin
  select * into b from public.bookings where id=p_booking_id for update;
  if b.id is null or b.tourist_id<>auth.uid() or b.status<>'replacement_pending' then
    raise exception 'This replacement decision is no longer available';
  end if;
  old_driver := b.driver_id;
  if p_find_replacement then
    update public.bookings set
      status='pending',driver_id=null,accepted_at=null,
      driver_arrived_at=null,pickup_wait_expires_at=null,
      replacement_requested_at=null,replacement_requested_by=null,
      dispatch_expires_at=now()+interval '10 minutes'
      where id=b.id returning * into b;
    update public.booking_offers set status='withdrawn',responded_at=now()
      where booking_id=b.id and status='offered';
    perform public.create_ranked_driver_offers(b.id);
    insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description,metadata)
    values(
      b.id,auth.uid(),'tourist','replacement_approved',
      'Tourist approved a new driver search with the same fixed fare.',
      jsonb_build_object('previous_driver_id',old_driver)
    );
  else
    select coalesce(sum(amount_centavos),0) into paid
      from public.payments where booking_id=b.id and status in ('paid','cash_paid');
    update public.bookings set
      status='cancelled',completed_at=now(),cancelled_by=auth.uid(),
      cancellation_reason='Tourist declined replacement after driver became unavailable.',
      final_charge_centavos=0,
      payment_status=case when paid>0 then 'refund_required'::public.payment_status else 'waived'::public.payment_status end,
      arrival_pending=false
      where id=b.id returning * into b;
    insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description,metadata)
    values(
      b.id,auth.uid(),'tourist','replacement_declined',
      'Tourist declined replacement; booking cancelled without charge.',
      jsonb_build_object('previous_driver_id',old_driver,'final_charge_centavos',0)
    );
  end if;
  insert into public.notifications(recipient_id,title,body,route_path)
  values(
    old_driver,
    case when p_find_replacement then 'Replacement approved' else 'Booking cancelled' end,
    case when p_find_replacement
      then 'The tourist approved a new driver search. You are released from this booking.'
      else 'The tourist chose to cancel without charge.' end,
    '/driver/bookings'
  );
  return b;
end;
$$;
revoke all on function public.decide_driver_replacement(uuid,boolean) from public;
grant execute on function public.decide_driver_replacement(uuid,boolean) to authenticated;

-- Scheduled bookings and replacement decisions are always free to cancel before service.
create or replace function public.cancel_booking(p_booking_id uuid,p_reason text)
returns public.bookings
language plpgsql
security definer
set search_path=public
as $$
declare
  b public.bookings;
  policy public.cancellation_policies;
  actor public.app_role;
  charge integer;
  paid integer;
begin
  if length(trim(p_reason))<5 then raise exception 'A cancellation reason is required'; end if;
  select * into b from public.bookings where id=p_booking_id for update;
  if b.id is null or b.status not in ('scheduled','pending','accepted','replacement_pending','ongoing') then
    raise exception 'Booking cannot be cancelled';
  end if;
  if auth.uid()=b.tourist_id then actor='tourist';
  elsif auth.uid()=b.driver_id then actor='driver';
  else raise exception 'Only a participant can cancel'; end if;
  if b.status='replacement_pending' and actor='driver' then
    raise exception 'Wait for the tourist replacement decision';
  end if;
  select * into policy from public.cancellation_policies where id=b.cancellation_policy_id;
  if b.status='ongoing' then charge=null;
  elsif actor='driver' or b.status in ('scheduled','pending','replacement_pending')
     or now()<=b.accepted_at+make_interval(mins=>policy.free_cancellation_minutes) then charge=0;
  else charge=round(b.quoted_amount_centavos*policy.accepted_trip_fee_percent/100.0);
  end if;
  select coalesce(sum(amount_centavos),0) into paid
    from public.payments where booking_id=b.id and status in ('paid','cash_paid');
  update public.bookings set
    status='cancelled',completed_at=now(),cancelled_by=auth.uid(),
    cancellation_reason=trim(p_reason),final_charge_centavos=charge,
    payment_status=case
      when charge is null then 'under_review'::public.payment_status
      when paid>charge then 'refund_required'::public.payment_status
      when charge=0 then 'waived'::public.payment_status
      else 'unpaid'::public.payment_status end,
    arrival_pending=false
    where id=b.id returning * into b;
  update public.booking_offers set status='withdrawn',responded_at=now()
    where booking_id=b.id and status='offered';
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description,metadata)
  values(
    b.id,auth.uid(),actor,'booking_cancelled','Booking cancelled: '||trim(p_reason),
    jsonb_build_object('final_charge_centavos',charge)
  );
  if charge is null then
    insert into public.disputes(booking_id,opened_by,reason)
    values(b.id,auth.uid(),'Trip ended after pickup: '||trim(p_reason));
  end if;
  return b;
end;
$$;
revoke all on function public.cancel_booking(uuid,text) from public;
grant execute on function public.cancel_booking(uuid,text) to authenticated;

-- Run every five minutes in the database, even when no app is open.
create extension if not exists pg_cron with schema extensions;
select cron.schedule(
  'tric-gabay-scheduled-bookings',
  '*/5 * * * *',
  'select public.send_scheduled_booking_reminders(); select public.activate_due_scheduled_bookings();'
)
where not exists(
  select 1 from cron.job where jobname='tric-gabay-scheduled-bookings'
);

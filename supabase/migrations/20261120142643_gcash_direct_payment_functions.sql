-- Legacy charge-review RPCs can change the status and amount of a completed
-- booking. A recorded direct GCash receipt is final in this workflow.
create function public.protect_confirmed_gcash_booking()
returns trigger
language plpgsql set search_path = public as $$
begin
  if old.payment_method = 'gcash_direct' and old.payment_status = 'gcash_paid'
     and (new.payment_method, new.payment_status, new.final_charge_centavos)
         is distinct from (old.payment_method, old.payment_status, old.final_charge_centavos) then
    raise exception 'Confirmed GCash payment cannot be changed';
  end if;
  return new;
end $$;
revoke all on function public.protect_confirmed_gcash_booking() from public, anon, authenticated;
create trigger protect_confirmed_gcash_booking
before update of payment_method, payment_status, final_charge_centavos on public.bookings
for each row execute function public.protect_confirmed_gcash_booking();

-- Extend the cash dispatch branch while preserving the current function's
-- active-account, request-ID, scheduling and fare validation.
do $$
declare
  definition text;
  cash_branch text := 'elsif p_payment_method=''cash'' then';
begin
  definition := pg_get_functiondef(
    'public.create_booking_with_schedule(text,public.payment_method,text,double precision,double precision,jsonb,integer,text,text,timestamptz,uuid)'::regprocedure
  );
  if strpos(definition, cash_branch) = 0 or
     strpos(substr(definition, strpos(definition, cash_branch) + length(cash_branch)), cash_branch) > 0 then
    raise exception 'Expected one cash dispatch branch in create_booking_with_schedule';
  end if;
  execute replace(definition, cash_branch, 'elsif p_payment_method in (''cash'', ''gcash_direct'') then');
end $$;

create function public.get_booking_driver_gcash(p_booking_id uuid)
returns table (gcash_account_name text, gcash_number text, fare_centavos integer)
language plpgsql stable security definer set search_path = public as $$
begin
  perform public.require_active_trip_actor(array['tourist']);
  return query
    select d.gcash_account_name, d.gcash_number, b.final_charge_centavos
    from public.bookings b join public.driver_gcash_details d on d.driver_id = b.driver_id
    where b.id = p_booking_id and b.tourist_id = auth.uid()
      and b.payment_method = 'gcash_direct' and b.status = 'completed'
      and b.final_charge_centavos > 0 and d.is_active
      and b.payment_status in ('unpaid', 'gcash_awaiting_confirmation', 'disputed')
      and not exists (select 1 from public.payments p where p.booking_id = b.id);
end $$;

-- Lock the booking before mutating payment state. This serializes confirmation,
-- cash fallback and dispute actions even when both participants act concurrently.
create function public.lock_gcash_payment_booking(p_booking_id uuid, p_actor text)
returns public.bookings
language plpgsql security definer set search_path = public as $$
declare b public.bookings;
begin
  perform public.require_active_trip_actor(array[p_actor]);
  select * into b from public.bookings where id = p_booking_id for update;
  if b.id is null or auth.uid() is distinct from
     (case p_actor when 'tourist' then b.tourist_id when 'driver' then b.driver_id end) then
    raise exception 'GCash booking access denied' using errcode = '42501';
  end if;
  if b.status <> 'completed' or b.driver_id is null or coalesce(b.final_charge_centavos, 0) <= 0 then
    raise exception 'GCash payment is unavailable for this trip';
  end if;
  return b;
end $$;
revoke all on function public.lock_gcash_payment_booking(uuid, text) from public, anon, authenticated;

create function public.require_gcash_payment_due(b public.bookings)
returns void
language plpgsql set search_path = public as $$
begin
  if b.payment_method <> 'gcash_direct'
     or b.payment_status not in ('unpaid', 'gcash_awaiting_confirmation', 'disputed')
     or exists (select 1 from public.payments p where p.booking_id = b.id) then
    raise exception 'GCash payment is no longer due';
  end if;
end $$;
revoke all on function public.require_gcash_payment_due(public.bookings) from public, anon, authenticated;

create function public.get_booking_gcash_reference(p_booking_id uuid)
returns text
language plpgsql stable security definer set search_path = public as $$
begin
  perform public.require_active_trip_actor(array['driver']);
  return (
    select c.gcash_reference_no
    from public.bookings b join public.gcash_payment_confirmations c on c.booking_id = b.id
    where b.id = p_booking_id and b.driver_id = auth.uid()
      and b.status = 'completed' and b.payment_method = 'gcash_direct'
      and b.payment_status in ('gcash_awaiting_confirmation', 'disputed', 'gcash_paid')
  );
end $$;

create function public.tourist_mark_gcash_sent(p_booking_id uuid, p_reference_no text default null)
returns void
language plpgsql security definer set search_path = public as $$
declare
  b public.bookings;
  ref text := nullif(btrim(p_reference_no), '');
begin
  b := public.lock_gcash_payment_booking(p_booking_id, 'tourist');
  perform public.require_gcash_payment_due(b);
  if ref is not null and (char_length(ref) not between 8 and 20 or ref !~ '^[A-Za-z0-9]+$') then
    raise exception 'Invalid GCash reference format';
  end if;
  -- A passenger can report a transfer already made even if the driver
  -- subsequently turns off their GCash details.
  insert into public.gcash_payment_confirmations (booking_id, gcash_reference_no, tourist_marked_sent_at)
    values (b.id, ref, now())
  on conflict (booking_id) do update set
    gcash_reference_no = coalesce(excluded.gcash_reference_no, gcash_payment_confirmations.gcash_reference_no),
    tourist_marked_sent_at = case
      when b.payment_status = 'gcash_awaiting_confirmation' then gcash_payment_confirmations.tourist_marked_sent_at
      else excluded.tourist_marked_sent_at end,
    dispute_note = null, disputed_at = null;
  if b.payment_status <> 'gcash_awaiting_confirmation' then
    update public.bookings set payment_status = 'gcash_awaiting_confirmation' where id = b.id;
    insert into public.notifications (recipient_id, booking_id, title, body, route_path)
    values (b.driver_id, b.id, 'GCash payment update',
      'Your tourist reported a payment. Check your GCash before confirming receipt.',
      '/driver/bookings/' || b.id);
  elsif ref is not null then
    -- The existing booking realtime path refreshes the driver's scoped ref read.
    update public.bookings set updated_at = now() where id = b.id;
  end if;
end $$;

create function public.driver_confirm_gcash_received(p_booking_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare b public.bookings;
begin
  b := public.lock_gcash_payment_booking(p_booking_id, 'driver');
  if b.payment_method = 'gcash_direct' and b.payment_status = 'gcash_paid' then
    return;
  end if;
  perform public.require_gcash_payment_due(b);
  insert into public.gcash_payment_confirmations
    (booking_id, driver_confirmed_received_at, driver_confirmed_by)
  values (b.id, now(), auth.uid())
  on conflict (booking_id) do update set
    driver_confirmed_received_at = excluded.driver_confirmed_received_at,
    driver_confirmed_by = excluded.driver_confirmed_by,
    dispute_note = null, disputed_at = null;
  -- The dedicated status records the payment while leaving existing
  -- cash/PayMongo ledger rules untouched.
  insert into public.payments (booking_id, provider, amount_centavos, status, paid_at)
    values (b.id, 'gcash_direct', b.final_charge_centavos, 'gcash_paid', now());
  update public.bookings set payment_status = 'gcash_paid' where id = b.id;
end $$;

create function public.driver_flag_gcash_not_received(p_booking_id uuid, p_note text default null)
returns void
language plpgsql security definer set search_path = public as $$
declare
  b public.bookings;
  note text := nullif(btrim(regexp_replace(p_note, '[[:cntrl:]]', ' ', 'g')), '');
begin
  b := public.lock_gcash_payment_booking(p_booking_id, 'driver');
  perform public.require_gcash_payment_due(b);
  if char_length(note) > 200 then
    raise exception 'GCash dispute note is too long';
  end if;
  insert into public.gcash_payment_confirmations (booking_id, dispute_note, disputed_at)
    values (b.id, note, now())
  on conflict (booking_id) do update set
    dispute_note = excluded.dispute_note,
    disputed_at = coalesce(gcash_payment_confirmations.disputed_at, excluded.disputed_at);
  if b.payment_status <> 'disputed' then
    update public.bookings set payment_status = 'disputed' where id = b.id;
    insert into public.notifications (recipient_id, booking_id, title, body, route_path)
    values (b.tourist_id, b.id, 'GCash payment update',
      'Your driver has not confirmed receipt. Open your trip for payment options.',
      '/tourist/bookings/' || b.id);
  end if;
end $$;
revoke all on function public.get_booking_driver_gcash(uuid),
  public.get_booking_gcash_reference(uuid), public.tourist_mark_gcash_sent(uuid, text),
  public.driver_confirm_gcash_received(uuid), public.driver_flag_gcash_not_received(uuid, text)
  from public, anon, authenticated;
grant execute on function public.get_booking_driver_gcash(uuid),
  public.get_booking_gcash_reference(uuid), public.tourist_mark_gcash_sent(uuid, text),
  public.driver_confirm_gcash_received(uuid), public.driver_flag_gcash_not_received(uuid, text)
  to authenticated;

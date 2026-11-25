-- Direct GCash is the only online payment. Normal trips settle by driver
-- slide-to-confirm. Proof (receipt + reference) is collected only once the
-- driver reports non-receipt. Disputes can be settled by the participants or
-- escalated to a finance/operations admin, whose "not paid" ruling blocks the
-- tourist from new bookings until the fare is settled.

-- ── Columns ─────────────────────────────────────────────────────────────────
alter table public.driver_gcash_details
  add column qr_object_path text check (
    qr_object_path is null
    or qr_object_path ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}\.(jpg|png)$'
  );

alter table public.gcash_payment_confirmations
  add column receipt_object_path text check (
    receipt_object_path is null
    or receipt_object_path ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}\.(jpg|png)$'
  ),
  add column proof_submitted_at timestamptz,
  add column escalated_at timestamptz,
  add column escalated_by uuid references public.profiles(id) on delete set null,
  add column escalation_note text check (char_length(escalation_note) <= 300),
  add column switched_to_cash_at timestamptz;

-- A GCash reference identifies one transfer, so it can settle one booking.
create unique index gcash_reference_unique
  on public.gcash_payment_confirmations (upper(gcash_reference_no))
  where gcash_reference_no is not null;

-- ── Rulings ─────────────────────────────────────────────────────────────────
create table public.payment_rulings (
  booking_id uuid primary key references public.bookings(id) on delete cascade,
  ruling text not null check (ruling in ('paid', 'not_paid', 'waived')),
  reason text not null check (char_length(btrim(reason)) between 5 and 500),
  ruled_by uuid references public.profiles(id) on delete set null,
  ruled_at timestamptz not null default now(),
  settled_at timestamptz
);
alter table public.payment_rulings enable row level security;
revoke all on public.payment_rulings from public, anon, authenticated;
create index payment_rulings_unsettled on public.payment_rulings (booking_id)
  where ruling = 'not_paid' and settled_at is null;

create function public.tourist_has_outstanding_fare(p_tourist_id uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.payment_rulings r
    join public.bookings b on b.id = r.booking_id
    where b.tourist_id = p_tourist_id and r.ruling = 'not_paid' and r.settled_at is null
  );
$$;
revoke all on function public.tourist_has_outstanding_fare(uuid) from public, anon, authenticated;

-- A "not paid" ruling settles once the fare is actually recorded as paid,
-- whether by a later GCash confirmation, a cash confirmation, or a waiver.
create function public.settle_payment_ruling()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.payment_status in ('gcash_paid', 'cash_paid', 'waived')
     and new.payment_status is distinct from old.payment_status then
    update public.payment_rulings set settled_at = now()
      where booking_id = new.id and ruling = 'not_paid' and settled_at is null;
  end if;
  return new;
end $$;
revoke all on function public.settle_payment_ruling() from public, anon, authenticated;
create trigger settle_payment_ruling
after update of payment_status on public.bookings
for each row execute function public.settle_payment_ruling();

-- ── Booking creation: no PayMongo, no booking with an outstanding fare ──────
do $$
declare
  definition text;
  anchor text := 'if p_request_id is null then raise exception ''Booking request ID required''; end if;';
begin
  definition := pg_get_functiondef(
    'public.create_booking_with_schedule(text,public.payment_method,text,double precision,double precision,jsonb,integer,text,text,timestamptz,uuid)'::regprocedure
  );
  if strpos(definition, anchor) = 0 then
    raise exception 'Expected request ID guard in create_booking_with_schedule';
  end if;
  execute replace(definition, anchor, anchor || '
  if p_payment_method = ''paymongo'' then raise exception ''ONLINE_PAYMENT_UNAVAILABLE''; end if;
  if public.tourist_has_outstanding_fare(auth.uid()) then raise exception ''OUTSTANDING_FARE''; end if;');
end $$;

-- ── Storage ─────────────────────────────────────────────────────────────────
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('gcash-receipts', 'gcash-receipts', false, 5242880, array['image/jpeg', 'image/png']),
  ('driver-gcash-qr', 'driver-gcash-qr', false, 5242880, array['image/jpeg', 'image/png'])
on conflict (id) do update set public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create function public.can_read_gcash_receipt(p_booking_id text)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.bookings b
    where b.id::text = p_booking_id
      and (b.tourist_id = auth.uid() or b.driver_id = auth.uid()
           or public.has_admin_capability('finance')
           or public.has_admin_capability('operations'))
  );
$$;
create function public.can_upload_gcash_receipt(p_booking_id text)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.bookings b
    where b.id::text = p_booking_id and b.tourist_id = auth.uid()
      and b.payment_method = 'gcash_direct' and b.payment_status = 'disputed'
  );
$$;
create function public.can_read_driver_gcash_qr(p_driver_id text)
returns boolean
language sql stable security definer set search_path = public as $$
  select p_driver_id = auth.uid()::text or public.is_admin() or exists (
    select 1 from public.bookings b
    where b.driver_id::text = p_driver_id and b.tourist_id = auth.uid()
      and b.status = 'completed' and b.payment_method = 'gcash_direct'
      and b.payment_status in ('unpaid', 'gcash_awaiting_confirmation', 'disputed')
  );
$$;
revoke all on function public.can_read_gcash_receipt(text), public.can_upload_gcash_receipt(text),
  public.can_read_driver_gcash_qr(text) from public, anon;
grant execute on function public.can_read_gcash_receipt(text), public.can_upload_gcash_receipt(text),
  public.can_read_driver_gcash_qr(text) to authenticated;

create policy gcash_receipt_insert on storage.objects for insert to authenticated
with check (bucket_id = 'gcash-receipts'
  and name ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}\.(jpg|png)$'
  and public.can_upload_gcash_receipt((storage.foldername(name))[1]));
create policy gcash_receipt_read on storage.objects for select to authenticated
using (bucket_id = 'gcash-receipts'
  and public.can_read_gcash_receipt((storage.foldername(name))[1]));
create policy driver_gcash_qr_insert on storage.objects for insert to authenticated
with check (bucket_id = 'driver-gcash-qr'
  and name ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}\.(jpg|png)$'
  and (storage.foldername(name))[1] = auth.uid()::text
  and public.current_profile_role() = 'driver');
create policy driver_gcash_qr_read on storage.objects for select to authenticated
using (bucket_id = 'driver-gcash-qr'
  and public.can_read_driver_gcash_qr((storage.foldername(name))[1]));

-- ── Helpers ─────────────────────────────────────────────────────────────────
create function public.notify_gcash_admins(p_booking_id uuid, p_title text, p_body text)
returns void
language sql security definer set search_path = public as $$
  insert into public.notifications (recipient_id, booking_id, title, body, route_path, category)
  select distinct p.id, p_booking_id, p_title, p_body, '/admin/gcash-disputes/' || p_booking_id, 'payment'
  from public.profiles p join public.admin_capabilities c on c.profile_id = p.id
  where p.role = 'admin' and p.status = 'active'
    and c.capability in ('finance', 'operations', 'super_admin');
$$;
revoke all on function public.notify_gcash_admins(uuid, text, text) from public, anon, authenticated;

create function public.record_gcash_event(p_booking_id uuid, p_actor_role text, p_event text, p_description text)
returns void
language sql security definer set search_path = public as $$
  insert into public.trip_events (booking_id, actor_id, actor_role, event_type, description)
  values (p_booking_id, auth.uid(), p_actor_role::public.app_role, p_event, p_description);
$$;
revoke all on function public.record_gcash_event(uuid, text, text, text) from public, anon, authenticated;

-- ── Driver QR ───────────────────────────────────────────────────────────────
create function public.set_driver_gcash_qr(p_object_path text)
returns void
language plpgsql security definer set search_path = public as $$
begin
  perform public.require_active_trip_actor(array['driver']);
  if p_object_path is not null and (
       p_object_path !~ ('^' || auth.uid()::text || '/[0-9a-f-]{36}\.(jpg|png)$')
       or not exists (select 1 from storage.objects o
                      where o.bucket_id = 'driver-gcash-qr' and o.name = p_object_path)) then
    raise exception 'Upload the QR image first';
  end if;
  update public.driver_gcash_details set qr_object_path = p_object_path where driver_id = auth.uid();
  if not found then
    raise exception 'Save your GCash number first';
  end if;
end $$;

-- Additive replacement for get_booking_driver_gcash that also returns the QR path.
create function public.get_booking_gcash_payee(p_booking_id uuid)
returns table (gcash_account_name text, gcash_number text, fare_centavos integer, qr_object_path text)
language plpgsql stable security definer set search_path = public as $$
begin
  perform public.require_active_trip_actor(array['tourist']);
  return query
    select d.gcash_account_name, d.gcash_number, b.final_charge_centavos, d.qr_object_path
    from public.bookings b join public.driver_gcash_details d on d.driver_id = b.driver_id
    where b.id = p_booking_id and b.tourist_id = auth.uid()
      and b.payment_method = 'gcash_direct' and b.status = 'completed'
      and b.final_charge_centavos > 0 and d.is_active
      and b.payment_status in ('unpaid', 'gcash_awaiting_confirmation', 'disputed')
      and not exists (select 1 from public.payments p where p.booking_id = b.id);
end $$;

-- ── Participant actions ─────────────────────────────────────────────────────
-- Once the driver has reported non-receipt, the tourist answers with proof.
create or replace function public.tourist_mark_gcash_sent(p_booking_id uuid, p_reference_no text default null)
returns void
language plpgsql security definer set search_path = public as $$
declare
  b public.bookings;
  ref text := nullif(btrim(p_reference_no), '');
begin
  b := public.lock_gcash_payment_booking(p_booking_id, 'tourist');
  perform public.require_gcash_payment_due(b);
  if b.payment_status = 'disputed' then
    raise exception 'GCASH_PROOF_REQUIRED';
  end if;
  if ref is not null and (char_length(ref) not between 8 and 20 or ref !~ '^[A-Za-z0-9]+$') then
    raise exception 'Invalid GCash reference format';
  end if;
  begin
    insert into public.gcash_payment_confirmations (booking_id, gcash_reference_no, tourist_marked_sent_at)
      values (b.id, ref, now())
    on conflict (booking_id) do update set
      gcash_reference_no = coalesce(excluded.gcash_reference_no, gcash_payment_confirmations.gcash_reference_no),
      tourist_marked_sent_at = coalesce(gcash_payment_confirmations.tourist_marked_sent_at, excluded.tourist_marked_sent_at);
  exception when unique_violation then
    raise exception 'GCASH_REFERENCE_USED';
  end;
  if b.payment_status <> 'gcash_awaiting_confirmation' then
    update public.bookings set payment_status = 'gcash_awaiting_confirmation' where id = b.id;
    insert into public.notifications (recipient_id, booking_id, title, body, route_path, category)
    values (b.driver_id, b.id, 'GCash payment update',
      'Your tourist reported a payment. Check your GCash before confirming receipt.',
      '/driver/bookings/' || b.id, 'payment');
  elsif ref is not null then
    update public.bookings set updated_at = now() where id = b.id;
  end if;
end $$;

create function public.tourist_submit_gcash_proof(p_booking_id uuid, p_reference_no text, p_receipt_path text)
returns void
language plpgsql security definer set search_path = public as $$
declare
  b public.bookings;
  ref text := nullif(btrim(p_reference_no), '');
begin
  b := public.lock_gcash_payment_booking(p_booking_id, 'tourist');
  perform public.require_gcash_payment_due(b);
  if b.payment_status <> 'disputed' then
    raise exception 'Payment proof is only needed after the driver reports non-receipt';
  end if;
  if ref is null or char_length(ref) not between 8 and 20 or ref !~ '^[A-Za-z0-9]+$' then
    raise exception 'Invalid GCash reference format';
  end if;
  if p_receipt_path is null
     or p_receipt_path !~ ('^' || b.id::text || '/[0-9a-f-]{36}\.(jpg|png)$')
     or not exists (select 1 from storage.objects o
                    where o.bucket_id = 'gcash-receipts' and o.name = p_receipt_path) then
    raise exception 'Upload the receipt screenshot first';
  end if;
  begin
    update public.gcash_payment_confirmations set
      gcash_reference_no = ref, receipt_object_path = p_receipt_path, proof_submitted_at = now()
      where booking_id = b.id;
  exception when unique_violation then
    raise exception 'GCASH_REFERENCE_USED';
  end;
  update public.bookings set updated_at = now() where id = b.id;
  insert into public.notifications (recipient_id, booking_id, title, body, route_path, category)
  values (b.driver_id, b.id, 'GCash proof received',
    'Your tourist sent a receipt and reference number. Check your GCash history.',
    '/driver/bookings/' || b.id, 'payment');
  perform public.record_gcash_event(b.id, 'tourist', 'gcash_proof_submitted', 'Tourist submitted GCash payment proof.');
end $$;

-- Confirmation keeps the dispute history instead of erasing it.
create or replace function public.driver_confirm_gcash_received(p_booking_id uuid)
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
    driver_confirmed_by = excluded.driver_confirmed_by;
  insert into public.payments (booking_id, provider, amount_centavos, status, paid_at)
    values (b.id, 'gcash_direct', b.final_charge_centavos, 'gcash_paid', now());
  update public.bookings set payment_status = 'gcash_paid' where id = b.id;
  perform public.record_gcash_event(b.id, 'driver', 'gcash_confirmed', 'Driver confirmed GCash receipt.');
end $$;

-- Switching to cash keeps the GCash record (and any ruling) as evidence.
create or replace function public.tourist_switch_gcash_to_cash(p_booking_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare b public.bookings;
begin
  b := public.lock_gcash_payment_booking(p_booking_id, 'tourist');
  if b.payment_method = 'cash' and b.payment_status = 'cash_awaiting_confirmation' then
    return;
  end if;
  perform public.require_gcash_payment_due(b);
  update public.gcash_payment_confirmations set switched_to_cash_at = now() where booking_id = b.id;
  update public.bookings set payment_method = 'cash', payment_status = 'cash_awaiting_confirmation'
    where id = b.id;
  perform public.record_gcash_event(b.id, 'tourist', 'gcash_switched_to_cash', 'Tourist switched the fare to cash.');
end $$;
revoke all on function public.tourist_switch_gcash_to_cash(uuid) from public, anon;
grant execute on function public.tourist_switch_gcash_to_cash(uuid) to authenticated;

create function public.request_gcash_admin_review(p_booking_id uuid, p_note text default null)
returns void
language plpgsql security definer set search_path = public as $$
declare
  b public.bookings;
  actor text := public.current_profile_role()::text;
  note text := nullif(btrim(regexp_replace(coalesce(p_note, ''), '[[:cntrl:]]', ' ', 'g')), '');
begin
  if actor not in ('tourist', 'driver') then
    raise exception 'GCash booking access denied' using errcode = '42501';
  end if;
  b := public.lock_gcash_payment_booking(p_booking_id, actor);
  if b.payment_method <> 'gcash_direct' or b.payment_status <> 'disputed' then
    raise exception 'Only a disputed GCash payment can go to an admin';
  end if;
  if char_length(note) > 300 then
    raise exception 'Admin review note is too long';
  end if;
  update public.gcash_payment_confirmations set
    escalated_at = coalesce(escalated_at, now()),
    escalated_by = coalesce(escalated_by, auth.uid()),
    escalation_note = coalesce(escalation_note, note)
    where booking_id = b.id and escalated_at is null;
  if not found then
    return;
  end if;
  insert into public.notifications (recipient_id, booking_id, title, body, route_path, category)
  values (case actor when 'tourist' then b.driver_id else b.tourist_id end, b.id,
    'GCash payment sent to admin',
    'An admin will review this payment and decide. You can still settle it together.',
    case actor when 'tourist' then '/driver/bookings/' else '/tourist/bookings/' end || b.id, 'payment');
  perform public.notify_gcash_admins(b.id, 'GCash dispute needs a decision',
    'A tourist and driver could not settle a GCash payment.');
  perform public.record_gcash_event(b.id, actor, 'gcash_escalated', 'GCash payment sent to admin review.');
end $$;

create function public.auto_escalate_gcash_disputes()
returns integer
language plpgsql security definer set search_path = public as $$
declare
  r record;
  n integer := 0;
begin
  for r in
    update public.gcash_payment_confirmations c set escalated_at = now()
    from public.bookings b
    where b.id = c.booking_id and b.payment_method = 'gcash_direct'
      and b.payment_status = 'disputed' and c.escalated_at is null
      and c.disputed_at < now() - interval '24 hours'
    returning b.id, b.tourist_id, b.driver_id
  loop
    n := n + 1;
    insert into public.notifications (recipient_id, booking_id, title, body, route_path, category)
    values
      (r.tourist_id, r.id, 'GCash payment sent to admin',
       'This payment was unresolved for 24 hours, so an admin will decide.', '/tourist/bookings/' || r.id, 'payment'),
      (r.driver_id, r.id, 'GCash payment sent to admin',
       'This payment was unresolved for 24 hours, so an admin will decide.', '/driver/bookings/' || r.id, 'payment');
    perform public.notify_gcash_admins(r.id, 'GCash dispute needs a decision',
      'A GCash payment has been unresolved for 24 hours.');
    insert into public.trip_events (booking_id, actor_id, actor_role, event_type, description)
    values (r.id, null, null, 'gcash_escalated', 'GCash payment escalated automatically after 24 hours.');
  end loop;
  return n;
end $$;
revoke all on function public.auto_escalate_gcash_disputes() from public, anon, authenticated;

-- ── Admin ───────────────────────────────────────────────────────────────────
create function public.require_gcash_ruler()
returns void
language plpgsql stable security definer set search_path = public as $$
begin
  if not (public.has_admin_capability('finance') or public.has_admin_capability('operations')) then
    raise exception 'Finance or operations access required' using errcode = '42501';
  end if;
end $$;
revoke all on function public.require_gcash_ruler() from public, anon, authenticated;

create function public.admin_rule_gcash_dispute(p_booking_id uuid, p_ruling text, p_reason text)
returns void
language plpgsql security definer set search_path = public as $$
declare
  b public.bookings;
  v_reason text := btrim(coalesce(p_reason, ''));
begin
  perform public.require_gcash_ruler();
  if p_ruling not in ('paid', 'not_paid') then
    raise exception 'Choose paid or not paid';
  end if;
  if char_length(v_reason) not between 5 and 500 then
    raise exception 'Enter a reason of at least five characters';
  end if;
  select * into b from public.bookings where id = p_booking_id for update;
  if b.id is null or b.status <> 'completed' or b.payment_method <> 'gcash_direct'
     or b.payment_status <> 'disputed' then
    raise exception 'This GCash payment is no longer disputed';
  end if;
  if exists (select 1 from public.payment_rulings where booking_id = b.id) then
    raise exception 'This dispute already has a ruling';
  end if;
  insert into public.payment_rulings (booking_id, ruling, reason, ruled_by, settled_at)
  values (b.id, p_ruling, v_reason, auth.uid(), case when p_ruling = 'paid' then now() end);
  if p_ruling = 'paid' then
    update public.gcash_payment_confirmations set
      driver_confirmed_received_at = now(), driver_confirmed_by = auth.uid()
      where booking_id = b.id;
    insert into public.payments (booking_id, provider, amount_centavos, status, paid_at)
      values (b.id, 'gcash_direct', b.final_charge_centavos, 'gcash_paid', now());
    update public.bookings set payment_status = 'gcash_paid' where id = b.id;
  end if;
  insert into public.notifications (recipient_id, booking_id, title, body, route_path, category)
  values
    (b.tourist_id, b.id, 'Admin decision on your GCash payment',
     case p_ruling when 'paid' then 'An admin ruled that your fare was paid.'
       else 'An admin ruled that your fare was not received. Pay your driver to book again.' end,
     '/tourist/bookings/' || b.id, 'payment'),
    (b.driver_id, b.id, 'Admin decision on a GCash payment',
     case p_ruling when 'paid' then 'An admin ruled that the fare was paid.'
       else 'An admin ruled that the fare was not received. The tourist cannot book until it is settled.' end,
     '/driver/bookings/' || b.id, 'payment');
  perform public.record_gcash_event(b.id, 'admin', 'gcash_ruled_' || p_ruling, 'Admin ruled on the GCash dispute.');
end $$;

create function public.admin_waive_unpaid_ruling(p_booking_id uuid, p_reason text)
returns void
language plpgsql security definer set search_path = public as $$
declare
  b public.bookings;
  v_reason text := btrim(coalesce(p_reason, ''));
begin
  perform public.require_gcash_ruler();
  if char_length(v_reason) not between 5 and 500 then
    raise exception 'Enter a reason of at least five characters';
  end if;
  select * into b from public.bookings where id = p_booking_id for update;
  if b.id is null or not exists (select 1 from public.payment_rulings
       where booking_id = b.id and ruling = 'not_paid' and settled_at is null) then
    raise exception 'There is no unsettled ruling to waive';
  end if;
  update public.payment_rulings set ruling = 'waived', reason = v_reason,
    ruled_by = auth.uid(), ruled_at = now(), settled_at = now()
    where booking_id = b.id;
  update public.bookings set payment_status = 'waived' where id = b.id;
  insert into public.notifications (recipient_id, booking_id, title, body, route_path, category)
  values (b.tourist_id, b.id, 'Fare waived', 'An admin waived the unpaid fare. You can book again.',
    '/tourist/bookings/' || b.id, 'payment');
  perform public.record_gcash_event(b.id, 'admin', 'gcash_ruling_waived', 'Admin waived the unpaid fare.');
end $$;

create function public.list_gcash_disputes()
returns table (booking_id uuid, reference_label text, tourist_name text, driver_name text,
  fare_centavos integer, payment_status text, disputed_at timestamptz,
  escalated_at timestamptz, has_proof boolean, ruling text, settled_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  perform public.require_gcash_ruler();
  return query
    select b.id, b.reference_code, t.full_name, d.full_name, b.final_charge_centavos,
      b.payment_status::text, c.disputed_at, c.escalated_at,
      c.receipt_object_path is not null, r.ruling, r.settled_at
    from public.gcash_payment_confirmations c
    join public.bookings b on b.id = c.booking_id
    left join public.profiles t on t.id = b.tourist_id
    left join public.profiles d on d.id = b.driver_id
    left join public.payment_rulings r on r.booking_id = b.id
    where c.disputed_at is not null
      and ((b.payment_method = 'gcash_direct' and b.payment_status = 'disputed')
           or (r.ruling = 'not_paid' and r.settled_at is null))
    order by (c.escalated_at is null), coalesce(c.escalated_at, c.disputed_at);
end $$;

create function public.get_gcash_dispute_detail(p_booking_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  b public.bookings;
  result jsonb;
begin
  select * into b from public.bookings where id = p_booking_id;
  if b.id is null or not (
       b.tourist_id = auth.uid() or b.driver_id = auth.uid()
       or public.has_admin_capability('finance') or public.has_admin_capability('operations')) then
    raise exception 'GCash booking access denied' using errcode = '42501';
  end if;
  select jsonb_build_object(
      'reference_no', c.gcash_reference_no,
      'receipt_path', c.receipt_object_path,
      'tourist_marked_sent_at', c.tourist_marked_sent_at,
      'disputed_at', c.disputed_at,
      'dispute_note', c.dispute_note,
      'proof_submitted_at', c.proof_submitted_at,
      'escalated_at', c.escalated_at,
      'escalated_by_role', case when c.escalated_at is null then null
        when c.escalated_by is null then 'system' else e.role::text end,
      'escalation_note', c.escalation_note,
      'switched_to_cash_at', c.switched_to_cash_at,
      'ruling', r.ruling, 'ruling_reason', r.reason, 'ruled_at', r.ruled_at,
      'settled_at', r.settled_at,
      'fare_centavos', b.final_charge_centavos)
    into result
    from public.gcash_payment_confirmations c
    left join public.profiles e on e.id = c.escalated_by
    left join public.payment_rulings r on r.booking_id = c.booking_id
    where c.booking_id = b.id;
  return coalesce(result, jsonb_build_object('fare_centavos', b.final_charge_centavos));
end $$;

create function public.get_my_outstanding_fare()
returns uuid
language sql stable security definer set search_path = public as $$
  select r.booking_id from public.payment_rulings r
  join public.bookings b on b.id = r.booking_id
  where b.tourist_id = auth.uid() and r.ruling = 'not_paid' and r.settled_at is null
  order by r.ruled_at limit 1;
$$;

revoke all on function public.set_driver_gcash_qr(text), public.get_booking_gcash_payee(uuid),
  public.tourist_submit_gcash_proof(uuid, text, text), public.request_gcash_admin_review(uuid, text),
  public.admin_rule_gcash_dispute(uuid, text, text), public.admin_waive_unpaid_ruling(uuid, text),
  public.list_gcash_disputes(), public.get_gcash_dispute_detail(uuid), public.get_my_outstanding_fare()
  from public, anon;
grant execute on function public.set_driver_gcash_qr(text), public.get_booking_gcash_payee(uuid),
  public.tourist_submit_gcash_proof(uuid, text, text), public.request_gcash_admin_review(uuid, text),
  public.admin_rule_gcash_dispute(uuid, text, text), public.admin_waive_unpaid_ruling(uuid, text),
  public.list_gcash_disputes(), public.get_gcash_dispute_detail(uuid), public.get_my_outstanding_fare()
  to authenticated;

-- ── Scheduling ──────────────────────────────────────────────────────────────
select cron.schedule('tric-gabay-gcash-escalation', '*/15 * * * *',
  'select public.auto_escalate_gcash_disputes()');

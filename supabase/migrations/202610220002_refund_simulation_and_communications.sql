-- Test-mode refund completion plus reliable email/push delivery queues.

alter table public.notifications
  add column if not exists booking_id uuid references public.bookings(id),
  add column if not exists category text not null default 'system',
  add column if not exists send_email boolean not null default false,
  add column if not exists lock_screen_body text not null default 'Open Tric-Gabay to view this update.';

alter table public.push_tokens
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists last_seen_at timestamptz not null default now(),
  add column if not exists revoked_at timestamptz,
  add column if not exists device_label text;

create table public.message_deliveries (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  notification_id uuid references public.notifications(id) on delete cascade,
  booking_id uuid references public.bookings(id) on delete cascade,
  channel text not null check(channel in ('email','push')),
  template_key text not null,
  destination text,
  subject text,
  title text not null,
  body text not null,
  route_path text,
  safe_preview text not null default 'Open Tric-Gabay to view this update.',
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'queued' check(status in ('queued','sending','sent','failed','skipped')),
  attempts integer not null default 0 check(attempts>=0),
  next_attempt_at timestamptz not null default now(),
  provider_message_id text,
  last_error text,
  dedupe_key text not null unique,
  sent_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index message_deliveries_due_idx on public.message_deliveries(status,next_attempt_at)
  where status in ('queued','failed');
create index message_deliveries_recipient_idx on public.message_deliveries(recipient_id,created_at desc);
create trigger message_deliveries_updated before update on public.message_deliveries
  for each row execute function public.set_updated_at();
alter table public.message_deliveries enable row level security;
create policy message_deliveries_admin_read on public.message_deliveries
  for select to authenticated using(public.is_admin());
revoke insert,update,delete on public.message_deliveries from anon,authenticated;

create or replace function public.notification_booking_id(p_route text)
returns uuid language plpgsql immutable as $$
declare found text;
begin
  found := substring(coalesce(p_route,'') from '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})');
  return case when found is null then null else found::uuid end;
exception when invalid_text_representation then return null;
end;
$$;

create or replace function public.enqueue_notification_delivery()
returns trigger language plpgsql security definer set search_path=public as $$
declare
  email_address text;
  resolved_booking uuid;
  email_allowed boolean;
begin
  resolved_booking := coalesce(new.booking_id,public.notification_booking_id(new.route_path));
  insert into public.message_deliveries(
    recipient_id,notification_id,booking_id,channel,template_key,title,body,route_path,
    safe_preview,payload,dedupe_key
  ) values(
    new.recipient_id,new.id,resolved_booking,'push',new.category,new.title,new.body,new.route_path,
    new.lock_screen_body,jsonb_build_object('notification_id',new.id,'category',new.category),
    'push:notification:'||new.id::text
  ) on conflict(dedupe_key) do nothing;

  email_allowed := new.send_email or new.title in (
    'Booking confirmed','Tour scheduled','Driver found','Driver assigned',
    'Tour tomorrow','Tour starts in about an hour','Tour completed','Booking cancelled',
    'Refund completed','Refund needs attention','Payment review opened','Payment review resolved',
    'Vehicle problem reported','Route safety update','Trip paused safely','Route recalculated'
  );
  if email_allowed then
    select email into email_address from public.profiles where id=new.recipient_id;
    if email_address is not null and position('@' in email_address)>1 then
      insert into public.message_deliveries(
        recipient_id,notification_id,booking_id,channel,template_key,destination,subject,
        title,body,route_path,safe_preview,payload,dedupe_key
      ) values(
        new.recipient_id,new.id,resolved_booking,'email',new.category,email_address,
        new.title||' · Tric-Gabay',new.title,new.body,new.route_path,new.lock_screen_body,
        jsonb_build_object('notification_id',new.id,'category',new.category),
        'email:notification:'||new.id::text
      ) on conflict(dedupe_key) do nothing;
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists notifications_enqueue_delivery on public.notifications;
create trigger notifications_enqueue_delivery after insert on public.notifications
for each row execute function public.enqueue_notification_delivery();

create or replace function public.enqueue_trip_lifecycle_notification()
returns trigger language plpgsql security definer set search_path=public as $$
declare b public.bookings;
begin
  if new.event_type not in (
    'booking_created','booking_scheduled','trip_completed','booking_cancelled',
    'refund_completed','refund_provider_update','test_refund_simulated',
    'payment_disputed','settlement_resolved'
  ) then return new; end if;
  select * into b from public.bookings where id=new.booking_id;
  if b.id is null then return new; end if;

  if new.event_type in ('booking_created','booking_scheduled') then
    insert into public.notifications(recipient_id,booking_id,title,body,route_path,category,send_email)
    values(b.tourist_id,b.id,
      case when new.event_type='booking_scheduled' then 'Tour scheduled' else 'Booking confirmed' end,
      case when new.event_type='booking_scheduled'
        then 'Your tour is reserved. We will remind you before driver matching begins.'
        else 'Your fixed fare and selected tour stops are saved.' end,
      '/tourist/bookings/'||b.id,'booking',true);
  elsif new.event_type='trip_completed' then
    insert into public.notifications(recipient_id,booking_id,title,body,route_path,category,send_email)
    values(b.tourist_id,b.id,'Tour completed',
      'Your tour is complete. Review the final payment status and share feedback when ready.',
      '/tourist/bookings/'||b.id,'trip_completed',true);
    if b.driver_id is not null then
      insert into public.notifications(recipient_id,booking_id,title,body,route_path,category,send_email)
      values(b.driver_id,b.id,'Tour completed',
        'The tour is complete. Review the payment status in your booking record.',
        '/driver/bookings/'||b.id,'trip_completed',true);
    end if;
  elsif new.event_type='booking_cancelled' then
    insert into public.notifications(recipient_id,booking_id,title,body,route_path,category,send_email)
    values(b.tourist_id,b.id,'Booking cancelled',
      'The booking was cancelled. Open the record to review the final charge or refund status.',
      '/tourist/bookings/'||b.id,'cancellation',true);
    if b.driver_id is not null and b.driver_id<>b.tourist_id then
      insert into public.notifications(recipient_id,booking_id,title,body,route_path,category,send_email)
      values(b.driver_id,b.id,'Booking cancelled',
        'The booking was cancelled. Open the record for the final status.',
        '/driver/bookings/'||b.id,'cancellation',true);
    end if;
  elsif new.event_type in ('refund_completed','test_refund_simulated') then
    insert into public.notifications(recipient_id,booking_id,title,body,route_path,category,send_email)
    values(b.tourist_id,b.id,'Refund completed',
      case when new.event_type='test_refund_simulated'
        then 'Your refund has been completed in the test payment environment.'
        else 'PayMongo confirmed your refund. Processing time at the original payment method may vary.' end,
      '/tourist/bookings/'||b.id,'refund',true);
  elsif new.event_type='refund_provider_update' then
    insert into public.notifications(recipient_id,booking_id,title,body,route_path,category,send_email)
    values(b.tourist_id,b.id,'Refund needs attention',
      'The refund was not completed. An administrator can review and retry it.',
      '/tourist/bookings/'||b.id,'refund',true);
  elsif new.event_type in ('payment_disputed','settlement_resolved') then
    insert into public.notifications(recipient_id,booking_id,title,body,route_path,category,send_email)
    values(b.tourist_id,b.id,
      case when new.event_type='payment_disputed' then 'Payment review opened' else 'Payment review resolved' end,
      case when new.event_type='payment_disputed'
        then 'Payment actions are paused while an administrator reviews the case.'
        else 'An administrator resolved the payment review. Open the booking for the final amount.' end,
      '/tourist/bookings/'||b.id,'payment_review',true);
    if b.driver_id is not null then
      insert into public.notifications(recipient_id,booking_id,title,body,route_path,category,send_email)
      values(b.driver_id,b.id,
        case when new.event_type='payment_disputed' then 'Payment review opened' else 'Payment review resolved' end,
        case when new.event_type='payment_disputed'
          then 'Payment actions are paused while an administrator reviews the case.'
          else 'An administrator resolved the payment review. Open the booking for the final amount.' end,
        '/driver/bookings/'||b.id,'payment_review',true);
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists trip_events_lifecycle_notifications on public.trip_events;
create trigger trip_events_lifecycle_notifications after insert on public.trip_events
for each row execute function public.enqueue_trip_lifecycle_notification();

create or replace function public.claim_message_deliveries(
  p_limit integer default 25,p_channels text[] default array['email','push']::text[]
)
returns setof public.message_deliveries language plpgsql security definer set search_path=public as $$
begin
  if auth.role()<>'service_role' then raise exception 'Service role required'; end if;
  return query
  with due as (
    select id from public.message_deliveries
    where status in ('queued','failed') and next_attempt_at<=now() and attempts<5
      and channel=any(p_channels)
    order by created_at for update skip locked limit greatest(1,least(p_limit,100))
  )
  update public.message_deliveries d set status='sending',attempts=d.attempts+1
  from due where d.id=due.id returning d.*;
end;
$$;
revoke all on function public.claim_message_deliveries(integer,text[]) from public;
grant execute on function public.claim_message_deliveries(integer,text[]) to service_role;

create or replace function public.finish_message_delivery(
  p_id uuid,p_success boolean,p_provider_message_id text,p_error text,p_skip boolean default false
) returns void language plpgsql security definer set search_path=public as $$
begin
  if auth.role()<>'service_role' then raise exception 'Service role required'; end if;
  update public.message_deliveries set
    status=case when p_success then 'sent' when p_skip then 'skipped' else 'failed' end,
    provider_message_id=p_provider_message_id,last_error=p_error,
    sent_at=case when p_success then now() else sent_at end,
    next_attempt_at=case when p_success or p_skip then next_attempt_at
      else now()+make_interval(mins=>least(60,power(2,attempts)::integer)) end
  where id=p_id;
end;
$$;
revoke all on function public.finish_message_delivery(uuid,boolean,text,text,boolean) from public;
grant execute on function public.finish_message_delivery(uuid,boolean,text,text,boolean) to service_role;

create or replace function public.simulate_paymongo_test_refund(
  p_booking_id uuid,p_amount_centavos integer,p_reason text
) returns jsonb language plpgsql security definer set search_path=public as $$
declare b public.bookings; p public.payments; r public.refunds; reserved integer; refundable integer;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  if p_amount_centavos<=0 or length(trim(p_reason))<5 then raise exception 'A valid amount and reason are required'; end if;
  select * into b from public.bookings where id=p_booking_id for update;
  if b.id is null or b.payment_status not in ('refund_required','partially_refunded') then
    raise exception 'This booking does not currently require a refund';
  end if;
  select * into p from public.payments where booking_id=b.id and provider='paymongo' and provider_mode='test' and status='paid'
    order by paid_at desc nulls last limit 1 for update;
  if p.id is null then raise exception 'A paid PayMongo test transaction is required'; end if;
  select coalesce(sum(amount_centavos),0) into reserved from public.refunds
    where payment_id=p.id and status in ('requested','approved','processing','succeeded');
  refundable:=greatest(p.amount_centavos-coalesce(b.final_charge_centavos,b.quoted_amount_centavos)-reserved,0);
  if p_amount_centavos>refundable then raise exception 'Simulation exceeds the remaining refund due'; end if;
  insert into public.refunds(
    booking_id,payment_id,provider_refund_id,amount_centavos,reason,status,
    requested_by,approved_by,provider_status,provider_metadata,processed_at
  ) values(
    b.id,p.id,'test_sim_'||gen_random_uuid()::text,p_amount_centavos,trim(p_reason),'succeeded',
    auth.uid(),auth.uid(),'simulated_succeeded',
    jsonb_build_object('simulated',true,'warning','No real money moved'),now()
  ) returning * into r;
  select coalesce(sum(amount_centavos),0) into reserved from public.refunds where payment_id=p.id and status='succeeded';
  update public.bookings set payment_status=case
    when reserved>=greatest(p.amount_centavos-coalesce(b.final_charge_centavos,b.quoted_amount_centavos),0)
      then 'refunded'::public.payment_status else 'partially_refunded'::public.payment_status end
  where id=b.id;
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description,metadata)
  values(b.id,auth.uid(),'admin','test_refund_simulated',
    'Administrator completed the refund in the PayMongo test environment.',
    jsonb_build_object('refund_id',r.id,'amount_centavos',r.amount_centavos,'simulated',true,'reason',trim(p_reason)));
  return jsonb_build_object('refund_id',r.id,'status','succeeded','simulated',true);
end;
$$;
revoke all on function public.simulate_paymongo_test_refund(uuid,integer,text) from public;
grant execute on function public.simulate_paymongo_test_refund(uuid,integer,text) to authenticated;

-- Replace the generic ledger trigger so simulated refunds remain visibly
-- distinct from provider-confirmed refunds in every audit view.
create or replace function public.record_financial_ledger_entry()
returns trigger language plpgsql security definer set search_path=public as $$
declare p public.payments;
begin
  if tg_table_name='payments' and new.status in ('paid','cash_paid')
     and (tg_op='INSERT' or old.status is distinct from new.status) then
    insert into public.financial_ledger_entries(
      booking_id,payment_id,entry_type,direction,amount_centavos,provider,
      provider_mode,provider_reference,idempotency_key,description,metadata,occurred_at
    ) values(
      new.booking_id,new.id,'payment_received','credit',new.amount_centavos,new.provider,
      new.provider_mode,coalesce(new.provider_payment_id,new.id::text),
      'payment:'||new.id::text||':received','Payment received',
      jsonb_build_object('payment_status',new.status),coalesce(new.paid_at,new.updated_at,new.created_at)
    ) on conflict(idempotency_key) do nothing;
  elsif tg_table_name='refunds' and new.status='succeeded'
     and (tg_op='INSERT' or old.status is distinct from new.status) then
    select * into p from public.payments where id=new.payment_id;
    insert into public.financial_ledger_entries(
      booking_id,payment_id,refund_id,entry_type,direction,amount_centavos,provider,
      provider_mode,provider_reference,idempotency_key,description,metadata,occurred_at
    ) values(
      new.booking_id,new.payment_id,new.id,'refund_completed','debit',new.amount_centavos,p.provider,
      p.provider_mode,coalesce(new.provider_refund_id,new.id::text),
      'refund:'||new.id::text||':completed',
      case when new.provider_status='simulated_succeeded' then 'Simulated test refund' else 'Refund completed' end,
      jsonb_build_object('refund_reason',new.reason,'simulated',new.provider_status='simulated_succeeded')
        ||coalesce(new.provider_metadata,'{}'::jsonb),
      coalesce(new.processed_at,new.updated_at,new.created_at)
    ) on conflict(idempotency_key) do nothing;
  end if;
  return new;
end;
$$;

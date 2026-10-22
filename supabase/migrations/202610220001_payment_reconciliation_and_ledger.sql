-- Provider reconciliation, honest refund execution, and immutable accounting.

alter table public.payments
  add column if not exists provider_status text,
  add column if not exists provider_error_code text,
  add column if not exists provider_error_message text,
  add column if not exists last_reconciled_at timestamptz,
  add column if not exists provider_metadata jsonb not null default '{}'::jsonb;

alter table public.refunds
  add column if not exists provider_status text,
  add column if not exists provider_metadata jsonb not null default '{}'::jsonb,
  add column if not exists processed_at timestamptz;

create table if not exists public.financial_ledger_entries (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id),
  payment_id uuid references public.payments(id),
  refund_id uuid references public.refunds(id),
  entry_type text not null check (entry_type in ('payment_received','refund_completed')),
  direction text not null check (direction in ('credit','debit')),
  amount_centavos integer not null check (amount_centavos > 0),
  currency text not null default 'PHP' check (currency = 'PHP'),
  provider text not null check (provider in ('paymongo','cash')),
  provider_mode text not null default 'test' check (provider_mode = 'test'),
  provider_reference text,
  idempotency_key text not null unique,
  description text not null,
  metadata jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null,
  created_at timestamptz not null default now(),
  check ((entry_type='payment_received' and payment_id is not null and refund_id is null)
      or (entry_type='refund_completed' and refund_id is not null and payment_id is not null))
);
create index if not exists financial_ledger_booking_idx
  on public.financial_ledger_entries(booking_id, occurred_at desc);

alter table public.financial_ledger_entries enable row level security;
drop policy if exists ledger_participant_read on public.financial_ledger_entries;
create policy ledger_participant_read on public.financial_ledger_entries
for select to authenticated using (
  exists(select 1 from public.bookings b where b.id=booking_id and
    (b.tourist_id=auth.uid() or b.driver_id=auth.uid() or public.is_admin()))
);
revoke insert, update, delete on public.financial_ledger_entries from anon, authenticated;

create or replace function public.prevent_financial_ledger_mutation()
returns trigger language plpgsql as $$
begin
  raise exception 'Financial ledger entries are immutable';
end;
$$;
drop trigger if exists financial_ledger_immutable on public.financial_ledger_entries;
create trigger financial_ledger_immutable
before update or delete on public.financial_ledger_entries
for each row execute function public.prevent_financial_ledger_mutation();

create or replace function public.record_financial_ledger_entry()
returns trigger language plpgsql security definer set search_path=public as $$
declare p public.payments;
begin
  if tg_table_name='payments' and new.status in ('paid','cash_paid')
     and (tg_op='INSERT' or old.status is distinct from new.status) then
    insert into public.financial_ledger_entries(
      booking_id,payment_id,entry_type,direction,amount_centavos,provider,
      provider_mode,provider_reference,idempotency_key,description,metadata,occurred_at
    ) values (
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
    ) values (
      new.booking_id,new.payment_id,new.id,'refund_completed','debit',new.amount_centavos,p.provider,
      p.provider_mode,coalesce(new.provider_refund_id,new.id::text),
      'refund:'||new.id::text||':completed','Refund completed',
      jsonb_build_object('refund_reason',new.reason),coalesce(new.processed_at,new.updated_at,new.created_at)
    ) on conflict(idempotency_key) do nothing;
  end if;
  return new;
end;
$$;
drop trigger if exists payments_to_financial_ledger on public.payments;
create trigger payments_to_financial_ledger
after insert or update of status on public.payments
for each row execute function public.record_financial_ledger_entry();
drop trigger if exists refunds_to_financial_ledger on public.refunds;
create trigger refunds_to_financial_ledger
after insert or update of status on public.refunds
for each row execute function public.record_financial_ledger_entry();

insert into public.financial_ledger_entries(
  booking_id,payment_id,entry_type,direction,amount_centavos,provider,provider_mode,
  provider_reference,idempotency_key,description,metadata,occurred_at
)
select booking_id,id,'payment_received','credit',amount_centavos,provider,provider_mode,
  coalesce(provider_payment_id,id::text),'payment:'||id::text||':received','Payment received',
  jsonb_build_object('payment_status',status),coalesce(paid_at,updated_at,created_at)
from public.payments where status in ('paid','cash_paid')
on conflict(idempotency_key) do nothing;

insert into public.financial_ledger_entries(
  booking_id,payment_id,refund_id,entry_type,direction,amount_centavos,provider,provider_mode,
  provider_reference,idempotency_key,description,metadata,occurred_at
)
select r.booking_id,r.payment_id,r.id,'refund_completed','debit',r.amount_centavos,p.provider,p.provider_mode,
  coalesce(r.provider_refund_id,r.id::text),'refund:'||r.id::text||':completed','Refund completed',
  jsonb_build_object('refund_reason',r.reason),coalesce(r.processed_at,r.updated_at,r.created_at)
from public.refunds r join public.payments p on p.id=r.payment_id
where r.status='succeeded'
on conflict(idempotency_key) do nothing;

create or replace function public.reserve_paymongo_refund(
  p_booking_id uuid,
  p_amount_centavos integer,
  p_reason text
) returns jsonb language plpgsql security definer set search_path=public as $$
declare
  b public.bookings;
  p public.payments;
  r public.refunds;
  reserved integer;
  refundable integer;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  if p_amount_centavos<=0 or length(trim(p_reason))<5 then
    raise exception 'A valid refund amount and reason are required';
  end if;
  select * into b from public.bookings where id=p_booking_id for update;
  if b.id is null or b.payment_status not in ('refund_required','partially_refunded') then
    raise exception 'This booking does not currently require an online refund';
  end if;
  select * into p from public.payments where booking_id=b.id and provider='paymongo' and status='paid'
    order by paid_at desc nulls last limit 1 for update;
  if p.id is null or p.provider_payment_id is null then
    raise exception 'No refundable PayMongo payment was found';
  end if;
  select coalesce(sum(amount_centavos),0) into reserved from public.refunds
    where payment_id=p.id and status in ('requested','approved','processing','succeeded');
  refundable := greatest(
    p.amount_centavos-coalesce(b.final_charge_centavos,b.quoted_amount_centavos)-reserved,0
  );
  if p_amount_centavos>refundable then
    raise exception 'Refund exceeds the unsettled amount due to the tourist';
  end if;
  insert into public.refunds(
    booking_id,payment_id,amount_centavos,reason,status,requested_by,approved_by,
    provider_status,provider_metadata
  ) values (
    b.id,p.id,p_amount_centavos,trim(p_reason),'processing',auth.uid(),auth.uid(),
    'requesting',jsonb_build_object('provider_mode',p.provider_mode)
  ) returning * into r;
  update public.bookings set payment_status='refund_processing' where id=b.id;
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description,metadata)
  values(b.id,auth.uid(),'admin','refund_requested',
    'Administrator sent a refund request to PayMongo.',
    jsonb_build_object('refund_id',r.id,'amount_centavos',p_amount_centavos,'reason',trim(p_reason)));
  return jsonb_build_object(
    'refund_id',r.id,'payment_id',p.id,'provider_payment_id',p.provider_payment_id,
    'provider_mode',p.provider_mode,'amount_centavos',p_amount_centavos
  );
end;
$$;
revoke all on function public.reserve_paymongo_refund(uuid,integer,text) from public;
grant execute on function public.reserve_paymongo_refund(uuid,integer,text) to authenticated;

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
  insert into public.trip_events(booking_id,actor_role,event_type,description,metadata)
  values(r.booking_id,'system',
    case when p_status='succeeded' then 'refund_completed' else 'refund_provider_update' end,
    case when p_status='succeeded' then 'PayMongo confirmed the refund.'
         when p_status in ('failed','rejected') then 'PayMongo did not complete the refund.'
         else 'PayMongo is processing the refund.' end,
    jsonb_build_object('refund_id',r.id,'provider_refund_id',p_provider_refund_id,
      'provider_status',p_provider_status,'failure_reason',p_failure_reason));
end;
$$;
revoke all on function public.finalize_paymongo_refund(uuid,text,text,public.refund_status,text,jsonb) from public;
grant execute on function public.finalize_paymongo_refund(uuid,text,text,public.refund_status,text,jsonb) to service_role;

-- The former function created a local-only result. Remove its callable surface so
-- every future online refund must pass through the provider edge function.
revoke all on function public.approve_test_refund(uuid,integer,text) from authenticated;

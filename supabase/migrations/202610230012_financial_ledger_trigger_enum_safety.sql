-- A trigger function shared by payments and refunds must not compare the
-- dynamically typed NEW.status field with values from the other table's enum.
-- PostgreSQL plans those expressions for the invoking row type before it can
-- short-circuit on TG_TABLE_NAME, which made every new refund fail while
-- attempting to coerce the payment value "paid" to refund_status.
create or replace function public.record_financial_ledger_entry()
returns trigger language plpgsql security definer set search_path=public as $$
declare p public.payments;
begin
  if tg_table_name='payments' then
    if new.status in ('paid','cash_paid')
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
    end if;
  elsif tg_table_name='refunds' then
    if new.status='succeeded'
       and (tg_op='INSERT' or old.status is distinct from new.status) then
      select * into p from public.payments where id=new.payment_id;
      insert into public.financial_ledger_entries(
        booking_id,payment_id,refund_id,entry_type,direction,amount_centavos,provider,
        provider_mode,provider_reference,idempotency_key,description,metadata,occurred_at
      ) values(
        new.booking_id,new.payment_id,new.id,'refund_completed','debit',new.amount_centavos,p.provider,
        p.provider_mode,coalesce(new.provider_refund_id,new.id::text),
        'refund:'||new.id::text||':completed','Refund completed',
        jsonb_build_object('refund_reason',new.reason,'test_mode',p.provider_mode='test')
          ||coalesce(new.provider_metadata,'{}'::jsonb),
        coalesce(new.processed_at,new.updated_at,new.created_at)
      ) on conflict(idempotency_key) do nothing;
    end if;
  end if;
  return new;
end;
$$;

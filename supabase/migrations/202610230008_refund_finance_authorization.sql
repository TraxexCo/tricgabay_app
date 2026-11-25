-- P0 remediation: only finance-capable administrators may reserve an online
-- refund. has_admin_capability() also admits the existing super_admin bypass
-- and verifies that the caller is an active administrator.

create or replace function public.reserve_paymongo_refund(
  p_booking_id uuid,
  p_amount_centavos integer,
  p_reason text
) returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  b public.bookings;
  p public.payments;
  r public.refunds;
  reserved integer;
  refundable integer;
begin
  if not public.has_admin_capability('finance') then
    raise exception 'Finance administrator access required' using errcode='42501';
  end if;
  if p_amount_centavos<=0 or length(trim(p_reason))<5 then
    raise exception 'A valid refund amount and reason are required';
  end if;

  select * into b from public.bookings where id=p_booking_id for update;
  if b.id is null or b.payment_status not in ('refund_required','partially_refunded') then
    raise exception 'This booking does not currently require an online refund';
  end if;

  select * into p from public.payments
    where booking_id=b.id and provider='paymongo' and provider_mode='test' and status='paid'
    order by paid_at desc nulls last limit 1 for update;
  if p.id is null or p.provider_payment_id is null then
    raise exception 'No refundable PayMongo test payment was found';
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
  insert into public.trip_events(
    booking_id,actor_id,actor_role,event_type,description,metadata
  ) values (
    b.id,auth.uid(),'admin','refund_requested',
    'Finance administrator sent a refund request to PayMongo.',
    jsonb_build_object(
      'refund_id',r.id,
      'amount_centavos',p_amount_centavos,
      'reason',trim(p_reason),
      'authorization','finance'
    )
  );

  return jsonb_build_object(
    'refund_id',r.id,
    'payment_id',p.id,
    'provider_payment_id',p.provider_payment_id,
    'provider_mode',p.provider_mode,
    'amount_centavos',p_amount_centavos
  );
end;
$$;

revoke all on function public.reserve_paymongo_refund(uuid,integer,text)
  from public,anon;
grant execute on function public.reserve_paymongo_refund(uuid,integer,text)
  to authenticated;


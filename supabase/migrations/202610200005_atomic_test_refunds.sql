create or replace function public.approve_test_refund(
  p_booking_id uuid,
  p_amount_centavos integer,
  p_reason text
) returns jsonb language plpgsql security definer set search_path=public as $$
declare
  b public.bookings;
  payment public.payments;
  refund public.refunds;
  reserved integer;
  available integer;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  if p_amount_centavos <= 0 or length(trim(p_reason)) < 5 then
    raise exception 'A valid refund amount and reason are required';
  end if;

  select * into b from public.bookings where id=p_booking_id for update;
  if b.id is null or b.payment_status not in ('refund_required','partially_refunded') then
    raise exception 'This booking does not currently require an online refund';
  end if;
  select * into payment from public.payments
    where booking_id=b.id and provider='paymongo' and provider_mode='test' and status='paid'
    order by paid_at desc nulls last limit 1 for update;
  if payment.id is null or payment.provider_payment_id is null then
    raise exception 'No refundable PayMongo test payment was found';
  end if;
  select coalesce(sum(amount_centavos),0) into reserved from public.refunds
    where payment_id=payment.id and status in ('requested','approved','processing','succeeded');
  available := greatest(payment.amount_centavos-coalesce(b.final_charge_centavos,payment.amount_centavos)-reserved,0);
  if p_amount_centavos > available then
    raise exception 'Refund exceeds the unsettled amount due to the tourist';
  end if;

  insert into public.refunds(
    booking_id,payment_id,amount_centavos,reason,status,requested_by,approved_by
  ) values (
    b.id,payment.id,p_amount_centavos,trim(p_reason),'approved',auth.uid(),auth.uid()
  ) returning * into refund;
  update public.bookings set payment_status='refund_processing' where id=b.id;
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description,metadata)
  values(
    b.id,auth.uid(),'admin','test_refund_approved',
    'Administrator approved a PayMongo test-mode refund; no real funds moved.',
    jsonb_build_object('refund_id',refund.id,'amount_centavos',p_amount_centavos,'reason',trim(p_reason))
  );
  return jsonb_build_object('refund_id',refund.id,'status','approved');
end;
$$;
revoke all on function public.approve_test_refund(uuid,integer,text) from public;
grant execute on function public.approve_test_refund(uuid,integer,text) to authenticated;

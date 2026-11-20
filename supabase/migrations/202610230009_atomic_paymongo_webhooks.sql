-- P0 remediation: provider event deduplication and payment/booking changes
-- commit in one transaction. A successful payment is terminal for the charge
-- and cannot be downgraded by a delayed failure event.

alter table public.payment_webhook_events
  add column if not exists processing_result text,
  add column if not exists correlation_id uuid;

create or replace function public.process_paymongo_payment_event(
  p_provider_event_id text,
  p_event_type text,
  p_resource_id text,
  p_checkout_id text,
  p_provider_payment_id text,
  p_amount_centavos integer,
  p_currency text,
  p_provider_status text,
  p_error_code text,
  p_error_message text,
  p_paid_at timestamptz,
  p_payload jsonb,
  p_correlation_id uuid
) returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  payment_row public.payments;
  booking_row public.bookings;
  inserted_event text;
  result text;
begin
  if auth.role()<>'service_role' then
    raise exception 'Service role required' using errcode='42501';
  end if;
  if coalesce(trim(p_provider_event_id),'')='' or coalesce(trim(p_event_type),'')='' then
    raise exception 'Invalid provider event';
  end if;

  insert into public.payment_webhook_events(
    provider_event_id,event_type,livemode,payload,processing_result,correlation_id
  ) values (
    p_provider_event_id,p_event_type,false,coalesce(p_payload,'{}'::jsonb),'processing',p_correlation_id
  ) on conflict(provider_event_id) do nothing
  returning provider_event_id into inserted_event;

  if inserted_event is null then
    return jsonb_build_object('result','duplicate','event_id',p_provider_event_id);
  end if;

  if p_event_type not in (
    'checkout_session.payment.paid','payment.failed','payment.processing'
  ) then
    update public.payment_webhook_events set processing_result='ignored_event_type'
      where provider_event_id=p_provider_event_id;
    return jsonb_build_object('result','ignored','reason','unsupported_event_type');
  end if;

  select * into payment_row
  from public.payments payment_candidate
  where payment_candidate.provider='paymongo'
    and payment_candidate.provider_mode='test'
    and (
      (nullif(trim(coalesce(p_checkout_id,'')),'') is not null
        and payment_candidate.provider_checkout_id=p_checkout_id)
      or
      (nullif(trim(coalesce(p_provider_payment_id,'')),'') is not null
        and payment_candidate.provider_payment_id=p_provider_payment_id)
    )
  order by payment_candidate.created_at desc
  limit 1
  for update;

  if payment_row.id is null then
    -- The provider may beat the checkout-creation transaction to our database.
    -- Raising rolls back the event insert too, so a provider retry can apply it.
    raise exception 'Payment is not ready for provider event' using errcode='40001';
  end if;

  select * into booking_row from public.bookings
    where id=payment_row.booking_id for update;
  if booking_row.id is null then
    raise exception 'Payment booking is missing';
  end if;

  if nullif(trim(coalesce(p_provider_payment_id,'')),'') is not null
      and payment_row.provider_payment_id is not null
      and payment_row.provider_payment_id<>p_provider_payment_id then
    if payment_row.status='paid' or booking_row.payment_status='paid' then
      result := 'ignored_identifier_after_success';
    else
      update public.payments set
        provider_status='identifier_mismatch',
        provider_error_code=null,
        provider_error_message='Provider payment identifier did not match the stored payment.',
        provider_metadata=coalesce(p_payload,'{}'::jsonb),
        last_reconciled_at=now()
      where id=payment_row.id;
      update public.bookings set payment_status='under_review'
        where id=booking_row.id
          and payment_status not in ('refund_processing','partially_refunded','refunded');
      result := 'rejected_identifier_mismatch';
    end if;
    update public.payment_webhook_events set processing_result=result
      where provider_event_id=p_provider_event_id;
    return jsonb_build_object(
      'result',result,
      'event_id',p_provider_event_id,
      'payment_id',payment_row.id,
      'booking_id',booking_row.id
    );
  end if;

  if p_event_type='checkout_session.payment.paid' then
    if payment_row.status='paid' then
      result := 'ignored_already_paid';
    elsif payment_row.status in ('refund_processing','partially_refunded','refunded')
        or booking_row.payment_status in ('refund_processing','partially_refunded','refunded') then
      result := 'ignored_success_after_refund';
    elsif p_amount_centavos is distinct from payment_row.amount_centavos
        or upper(coalesce(p_currency,''))<>'PHP'
        or nullif(trim(coalesce(p_provider_payment_id,'')),'') is null then
      update public.payments set
        provider_status='amount_mismatch',
        provider_error_code=null,
        provider_error_message='Provider amount or currency did not match the fixed fare.',
        provider_metadata=coalesce(p_payload,'{}'::jsonb),
        last_reconciled_at=now()
      where id=payment_row.id;
      update public.bookings set payment_status='under_review'
        where id=booking_row.id and payment_status<>'paid';
      result := 'rejected_payment_mismatch';
    else
      update public.payments set
        provider_payment_id=p_provider_payment_id,
        provider_status='paid',
        provider_error_code=null,
        provider_error_message=null,
        provider_metadata=coalesce(p_payload,'{}'::jsonb),
        last_reconciled_at=now(),
        status='paid',
        paid_at=coalesce(p_paid_at,now())
      where id=payment_row.id;
      update public.bookings set payment_status='paid' where id=booking_row.id;
      result := 'applied_paid';
    end if;
  elsif p_event_type='payment.failed' then
    if payment_row.status in ('paid','cash_paid') or booking_row.payment_status='paid' then
      result := 'ignored_failure_after_success';
    elsif payment_row.provider_status in ('amount_mismatch','identifier_mismatch')
        or booking_row.payment_status='under_review' then
      result := 'ignored_failure_during_review';
    elsif payment_row.status in ('refund_processing','partially_refunded','refunded')
        or booking_row.payment_status in ('refund_processing','partially_refunded','refunded') then
      result := 'ignored_failure_after_refund';
    else
      update public.payments set
        provider_status=coalesce(nullif(trim(p_provider_status),''),'failed'),
        provider_error_code=nullif(trim(coalesce(p_error_code,'')),''),
        provider_error_message=nullif(trim(coalesce(p_error_message,'')),''),
        provider_metadata=coalesce(p_payload,'{}'::jsonb),
        last_reconciled_at=now(),
        status='failed'
      where id=payment_row.id;
      update public.bookings set payment_status='failed'
        where id=booking_row.id
          and payment_status not in ('paid','refund_processing','partially_refunded','refunded');
      result := 'applied_failed';
    end if;
  else
    if payment_row.status in ('paid','cash_paid') or booking_row.payment_status='paid' then
      result := 'ignored_processing_after_success';
    elsif payment_row.provider_status in ('amount_mismatch','identifier_mismatch')
        or booking_row.payment_status='under_review' then
      result := 'ignored_processing_during_review';
    elsif payment_row.status in ('refund_processing','partially_refunded','refunded')
        or booking_row.payment_status in ('refund_processing','partially_refunded','refunded') then
      result := 'ignored_processing_after_refund';
    else
      update public.payments set
        provider_status=coalesce(nullif(trim(p_provider_status),''),'processing'),
        provider_error_code=null,
        provider_error_message=null,
        provider_metadata=coalesce(p_payload,'{}'::jsonb),
        last_reconciled_at=now(),
        status='processing'
      where id=payment_row.id;
      update public.bookings set payment_status='processing'
        where id=booking_row.id
          and payment_status not in ('paid','refund_processing','partially_refunded','refunded');
      result := 'applied_processing';
    end if;
  end if;

  update public.payment_webhook_events set processing_result=result
    where provider_event_id=p_provider_event_id;
  return jsonb_build_object(
    'result',result,
    'event_id',p_provider_event_id,
    'payment_id',payment_row.id,
    'booking_id',booking_row.id
  );
end;
$$;

revoke all on function public.process_paymongo_payment_event(
  text,text,text,text,text,integer,text,text,text,text,timestamptz,jsonb,uuid
) from public,anon,authenticated;
grant execute on function public.process_paymongo_payment_event(
  text,text,text,text,text,integer,text,text,text,text,timestamptz,jsonb,uuid
) to service_role;

create or replace function public.process_paymongo_refund_event(
  p_provider_event_id text,
  p_event_type text,
  p_refunds jsonb,
  p_payload jsonb,
  p_correlation_id uuid
) returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  inserted_event text;
  item jsonb;
  refund_row public.refunds;
  current_provider_refund_id text;
  current_provider_status text;
  local_status public.refund_status;
  applied integer := 0;
begin
  if auth.role()<>'service_role' then
    raise exception 'Service role required' using errcode='42501';
  end if;
  if p_event_type not in ('payment.refunded','payment.refund.updated')
      or jsonb_typeof(p_refunds)<>'array' then
    raise exception 'Invalid refund provider event';
  end if;

  insert into public.payment_webhook_events(
    provider_event_id,event_type,livemode,payload,processing_result,correlation_id
  ) values (
    p_provider_event_id,p_event_type,false,coalesce(p_payload,'{}'::jsonb),'processing',p_correlation_id
  ) on conflict(provider_event_id) do nothing
  returning provider_event_id into inserted_event;
  if inserted_event is null then
    return jsonb_build_object('result','duplicate','event_id',p_provider_event_id);
  end if;

  for item in select value from jsonb_array_elements(p_refunds)
  loop
    current_provider_refund_id := item->>'id';
    current_provider_status := coalesce(item#>>'{attributes,status}',item->>'status','processing');
    select * into refund_row from public.refunds refund_candidate
      where refund_candidate.provider_refund_id=current_provider_refund_id
      for update;
    if refund_row.id is null then
      continue;
    end if;
    local_status := case
      when current_provider_status in ('succeeded','refunded') then 'succeeded'::public.refund_status
      when current_provider_status='failed' then 'failed'::public.refund_status
      else 'processing'::public.refund_status
    end;
    perform public.finalize_paymongo_refund(
      refund_row.id,
      current_provider_refund_id,
      current_provider_status,
      local_status,
      item#>>'{attributes,failure_reason}',
      item
    );
    applied := applied+1;
  end loop;

  if applied=0 then
    -- Do not consume an event that arrived before the local refund row exists.
    -- The event insert and every partial change in this function roll back.
    raise exception 'Refund is not ready for provider event' using errcode='40001';
  end if;

  update public.payment_webhook_events
    set processing_result='applied_refund'
    where provider_event_id=p_provider_event_id;
  return jsonb_build_object(
    'result','applied_refund',
    'event_id',p_provider_event_id,
    'applied_refunds',applied
  );
end;
$$;

revoke all on function public.process_paymongo_refund_event(text,text,jsonb,jsonb,uuid)
  from public,anon,authenticated;
grant execute on function public.process_paymongo_refund_event(text,text,jsonb,jsonb,uuid)
  to service_role;


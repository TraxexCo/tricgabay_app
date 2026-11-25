-- Bind authoritative PayMongo refund updates to a locally reserved refund even
-- when the original create-refund response timed out before returning its ID.

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
  current_provider_payment_id text;
  current_provider_status text;
  current_amount_centavos integer;
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
    refund_row := null;
    current_provider_refund_id := nullif(trim(coalesce(item->>'id','')),'');
    current_provider_payment_id := nullif(trim(coalesce(
      item#>>'{attributes,payment_id}',
      coalesce(p_payload,'{}'::jsonb)->>'provider_payment_id',
      ''
    )),'');
    current_provider_status := coalesce(
      nullif(trim(item#>>'{attributes,status}'),''),
      nullif(trim(item->>'status'),''),
      'processing'
    );
    current_amount_centavos := case
      when coalesce(item#>>'{attributes,amount}','') ~ '^[0-9]+$'
        then (item#>>'{attributes,amount}')::integer
      else null
    end;

    if current_provider_refund_id is null then
      continue;
    end if;

    select * into refund_row
    from public.refunds refund_candidate
    where refund_candidate.provider_refund_id=current_provider_refund_id
    for update;

    if refund_row.id is null and current_provider_payment_id is not null then
      select refund_candidate.* into refund_row
      from public.refunds refund_candidate
      join public.payments payment_candidate
        on payment_candidate.id=refund_candidate.payment_id
      where refund_candidate.provider_refund_id is null
        and refund_candidate.status='processing'
        and payment_candidate.provider='paymongo'
        and payment_candidate.provider_mode='test'
        and payment_candidate.provider_payment_id=current_provider_payment_id
        and (
          current_amount_centavos is null
          or refund_candidate.amount_centavos=current_amount_centavos
        )
      order by refund_candidate.created_at
      limit 1
      for update of refund_candidate;

      if refund_row.id is not null then
        update public.refunds
        set provider_refund_id=current_provider_refund_id
        where id=refund_row.id
        returning * into refund_row;
      end if;
    end if;

    if refund_row.id is null then
      continue;
    end if;

    local_status := case
      when current_provider_status in ('succeeded','refunded') then 'succeeded'::public.refund_status
      when current_provider_status in ('failed','cancelled') then 'failed'::public.refund_status
      else 'processing'::public.refund_status
    end;
    perform public.finalize_paymongo_refund(
      refund_row.id,
      current_provider_refund_id,
      current_provider_status,
      local_status,
      item#>>'{attributes,failure_reason}',
      jsonb_strip_nulls(jsonb_build_object(
        'provider_refund_id',current_provider_refund_id,
        'provider_payment_id',current_provider_payment_id,
        'provider_status',current_provider_status,
        'amount_centavos',current_amount_centavos
      ))
    );
    applied := applied+1;
  end loop;

  if applied=0 then
    -- Roll the event insert back so a later provider retry can attach after the
    -- local reservation or payment identity becomes available.
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

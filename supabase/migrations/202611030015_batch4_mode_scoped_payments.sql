-- Live readiness is implemented, but the deployment flag remains OFF.
alter table public.service_configuration add column live_payments_enabled boolean not null default false;
alter table public.payments drop constraint payments_provider_mode_check;
alter table public.payments add constraint payments_provider_mode_check check(provider_mode in ('test','live'));
alter table public.financial_ledger_entries drop constraint financial_ledger_entries_provider_mode_check;
alter table public.financial_ledger_entries add constraint financial_ledger_entries_provider_mode_check check(provider_mode in ('test','live'));
alter table public.payments drop constraint payments_provider_checkout_id_key;
alter table public.payments drop constraint payments_provider_payment_id_key;
alter table public.payments add unique(provider_mode,provider_checkout_id);
alter table public.payments add unique(provider_mode,provider_payment_id);
alter table public.refunds add column provider_mode text;
update public.refunds r set provider_mode=p.provider_mode from public.payments p where p.id=r.payment_id;
alter table public.refunds alter column provider_mode set not null;
alter table public.refunds add check(provider_mode in ('test','live'));
alter table public.refunds drop constraint refunds_provider_refund_id_key;
alter table public.refunds add unique(provider_mode,provider_refund_id);
alter table public.payment_webhook_events add column provider_mode text not null default 'test' check(provider_mode in ('test','live'));
alter table public.payment_webhook_events drop constraint payment_webhook_events_pkey;
alter table public.payment_webhook_events add primary key(provider_mode,provider_event_id);
alter table public.payment_webhook_events add check(livemode=(provider_mode='live'));
create function public.require_provider_mode(p_mode text) returns void
language plpgsql stable security definer set search_path=public as $$
begin
 if p_mode is null or p_mode not in ('test','live') then raise exception 'Invalid provider mode'; end if;
 if p_mode='live' and not (select live_payments_enabled from public.service_configuration where singleton) then
   raise exception 'Live payments are not enabled for this deployment' using errcode='42501';
 end if;
end $$;
revoke all on function public.require_provider_mode(text) from public,anon,authenticated;
grant execute on function public.require_provider_mode(text) to service_role;
create function public.guard_payment_mode() returns trigger
language plpgsql security definer set search_path=public as $$
begin
 if tg_op='UPDATE' and new.provider_mode is distinct from old.provider_mode then raise exception 'Payment mode is immutable'; end if;
 if tg_op='INSERT' then perform public.require_provider_mode(new.provider_mode); end if;
 return new;
end $$;
revoke all on function public.guard_payment_mode() from public,anon,authenticated;
create trigger guard_payment_mode before insert or update on public.payments for each row execute function public.guard_payment_mode();
create function public.guard_refund_mode() returns trigger
language plpgsql security definer set search_path=public as $$
declare payment_mode text;
begin
 select provider_mode into strict payment_mode from public.payments where id=new.payment_id;
 if new.provider_mode is not null and new.provider_mode<>payment_mode then raise exception 'Refund mode must match its payment'; end if;
 new.provider_mode:=payment_mode;
 if tg_op='INSERT' or new.status is distinct from old.status then perform public.require_provider_mode(payment_mode); end if;
 return new;
end $$;
revoke all on function public.guard_refund_mode() from public,anon,authenticated;
create trigger guard_refund_mode before insert or update on public.refunds for each row execute function public.guard_refund_mode();

CREATE OR REPLACE FUNCTION public.process_paymongo_payment_event_in_mode(p_provider_event_id text, p_event_type text, p_resource_id text, p_checkout_id text, p_provider_payment_id text, p_amount_centavos integer, p_currency text, p_provider_status text, p_error_code text, p_error_message text, p_paid_at timestamp with time zone, p_payload jsonb, p_correlation_id uuid, p_mode text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  payment_row public.payments;
  booking_row public.bookings;
  inserted_event text;
  result text;
begin
  if auth.role()<>'service_role' then
    raise exception 'Service role required' using errcode='42501';
  end if;
  perform public.require_provider_mode(p_mode);
  if coalesce(trim(p_provider_event_id),'')='' or coalesce(trim(p_event_type),'')='' then
    raise exception 'Invalid provider event';
  end if;

  insert into public.payment_webhook_events(
    provider_mode,provider_event_id,event_type,livemode,payload,processing_result,correlation_id
  ) values (
    p_mode,p_provider_event_id,p_event_type,(p_mode='live'),coalesce(p_payload,'{}'::jsonb),'processing',p_correlation_id
  ) on conflict(provider_mode,provider_event_id) do nothing
  returning provider_event_id into inserted_event;

  if inserted_event is null then
    return jsonb_build_object('result','duplicate','event_id',p_provider_event_id);
  end if;

  if p_event_type not in (
    'checkout_session.payment.paid','payment.failed','payment.processing'
  ) then
    update public.payment_webhook_events set processing_result='ignored_event_type'
      where provider_event_id=p_provider_event_id and provider_mode=p_mode;
    return jsonb_build_object('result','ignored','reason','unsupported_event_type');
  end if;

  select * into payment_row
  from public.payments payment_candidate
  where payment_candidate.provider='paymongo'
    and payment_candidate.provider_mode=p_mode
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
      where provider_event_id=p_provider_event_id and provider_mode=p_mode;
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
    where provider_event_id=p_provider_event_id and provider_mode=p_mode;
  return jsonb_build_object(
    'result',result,
    'event_id',p_provider_event_id,
    'payment_id',payment_row.id,
    'booking_id',booking_row.id
  );
end;
$function$
;

CREATE OR REPLACE FUNCTION public.process_paymongo_refund_event_in_mode(p_provider_event_id text, p_event_type text, p_refunds jsonb, p_payload jsonb, p_correlation_id uuid, p_mode text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
  perform public.require_provider_mode(p_mode);
  if p_event_type not in ('payment.refunded','payment.refund.updated')
      or jsonb_typeof(p_refunds)<>'array' then
    raise exception 'Invalid refund provider event';
  end if;

  insert into public.payment_webhook_events(
    provider_mode,provider_event_id,event_type,livemode,payload,processing_result,correlation_id
  ) values (
    p_mode,p_provider_event_id,p_event_type,(p_mode='live'),coalesce(p_payload,'{}'::jsonb),'processing',p_correlation_id
  ) on conflict(provider_mode,provider_event_id) do nothing
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
    where refund_candidate.provider_refund_id=current_provider_refund_id and refund_candidate.provider_mode=p_mode
    for update;

    if refund_row.id is null and current_provider_payment_id is not null then
      select refund_candidate.* into refund_row
      from public.refunds refund_candidate
      join public.payments payment_candidate
        on payment_candidate.id=refund_candidate.payment_id
      where refund_candidate.provider_refund_id is null
        and refund_candidate.status='processing'
        and payment_candidate.provider='paymongo'
        and payment_candidate.provider_mode=p_mode
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
  where provider_event_id=p_provider_event_id and provider_mode=p_mode;
  return jsonb_build_object(
    'result','applied_refund',
    'event_id',p_provider_event_id,
    'applied_refunds',applied
  );
end;
$function$
;

CREATE OR REPLACE FUNCTION public.reserve_paymongo_refund(p_booking_id uuid, p_amount_centavos integer, p_reason text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
    where booking_id=b.id and provider='paymongo' and status='paid'
    order by paid_at desc nulls last limit 1 for update;
  if p.id is null or p.provider_payment_id is null then
    raise exception 'No refundable PayMongo payment was found';
  end if;

  perform public.require_provider_mode(p.provider_mode);
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
$function$
;

CREATE OR REPLACE FUNCTION public.record_paymongo_checkout(p_booking_id uuid, p_provider_checkout_id text, p_checkout_url text, p_amount_centavos integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  b public.bookings;
  existing public.payments;
  resolved_mode text;
begin
  if coalesce(auth.role(),'')<>'service_role' then
    raise exception 'Service role required' using errcode='42501';
  end if;
  select paymongo_mode into strict resolved_mode from public.service_configuration where singleton;
  -- Explicit mode gate: readiness code does not enable live operation.
  perform public.require_provider_mode(resolved_mode);
  if coalesce(trim(p_provider_checkout_id),'')!~'^cs_[A-Za-z0-9_-]+$'
     or coalesce(trim(p_checkout_url),'')!~'^https://checkout[.]paymongo[.]com/'
     or p_amount_centavos is null or p_amount_centavos<=0 then
    raise exception 'Invalid checkout result';
  end if;

  select * into b from public.bookings where id=p_booking_id for update;
  if b.id is null or b.payment_method<>'paymongo'
     or b.status<>'payment_pending' or b.payment_expires_at<=now()
     or b.payment_status in (
       'paid','under_review','refund_required','refund_processing',
       'partially_refunded','refunded','cash_awaiting_confirmation','cash_paid','waived'
     ) then
    raise exception 'Booking is not eligible for online checkout';
  end if;
  if p_amount_centavos<>b.quoted_amount_centavos then
    raise exception 'Checkout amount does not match the booking quote';
  end if;

  select * into existing from public.payments
    where booking_id=b.id and provider='paymongo'
      and status in ('checkout_created','processing','paid')
    order by created_at desc limit 1 for update;
  if existing.id is not null then
    if existing.amount_centavos<>b.quoted_amount_centavos
       or existing.provider_checkout_id<>trim(p_provider_checkout_id)
       or existing.checkout_url<>trim(p_checkout_url)
       or existing.provider_mode<>resolved_mode then
      raise exception 'Stored checkout does not match the provider result';
    end if;
    if b.payment_status not in ('paid','processing','checkout_created') then
      update public.bookings set payment_status=existing.status where id=b.id;
    end if;
    return jsonb_build_object(
      'checkout_url',existing.checkout_url,
      'provider_checkout_id',existing.provider_checkout_id,
      'reused',true
    );
  end if;

  insert into public.payments(
    booking_id,provider,provider_mode,provider_checkout_id,checkout_url,
    amount_centavos,status
  ) values (
    b.id,'paymongo',resolved_mode,trim(p_provider_checkout_id),trim(p_checkout_url),
    p_amount_centavos,'checkout_created'
  ) returning * into existing;
  update public.bookings set payment_status='checkout_created' where id=b.id;
  return jsonb_build_object(
    'checkout_url',existing.checkout_url,
    'provider_checkout_id',existing.provider_checkout_id,
    'reused',false
  );
end;
$function$
;

create or replace function public.process_paymongo_payment_event(p_provider_event_id text,p_event_type text,p_resource_id text,p_checkout_id text,p_provider_payment_id text,p_amount_centavos integer,p_currency text,p_provider_status text,p_error_code text,p_error_message text,p_paid_at timestamptz,p_payload jsonb,p_correlation_id uuid) returns jsonb
language sql security definer set search_path=public as $$
 select public.process_paymongo_payment_event_in_mode($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,'test')
$$;
create or replace function public.process_paymongo_refund_event(p_provider_event_id text,p_event_type text,p_refunds jsonb,p_payload jsonb,p_correlation_id uuid) returns jsonb
language sql security definer set search_path=public as $$
 select public.process_paymongo_refund_event_in_mode($1,$2,$3,$4,$5,'test')
$$;
revoke all on function public.process_paymongo_payment_event_in_mode(text,text,text,text,text,integer,text,text,text,text,timestamptz,jsonb,uuid,text),public.process_paymongo_refund_event_in_mode(text,text,jsonb,jsonb,uuid,text) from public,anon,authenticated;
grant execute on function public.process_paymongo_payment_event_in_mode(text,text,text,text,text,integer,text,text,text,text,timestamptz,jsonb,uuid,text),public.process_paymongo_refund_event_in_mode(text,text,jsonb,jsonb,uuid,text) to service_role;

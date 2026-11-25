-- Keep provider checkout creation and the local booking/payment state in one
-- transaction. The Edge Function owns the external provider call; this RPC
-- atomically commits the authoritative local result and safely reuses a
-- checkout recorded by a concurrent/retried request.
create or replace function public.record_paymongo_checkout(
  p_booking_id uuid,
  p_provider_checkout_id text,
  p_checkout_url text,
  p_amount_centavos integer
) returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  b public.bookings;
  existing public.payments;
begin
  if auth.role()<>'service_role' then
    raise exception 'Service role required' using errcode='42501';
  end if;
  if nullif(trim(p_provider_checkout_id),'') is null
     or nullif(trim(p_checkout_url),'') is null
     or p_checkout_url !~ '^https://'
     or p_amount_centavos<=0 then
    raise exception 'Invalid checkout result';
  end if;

  select * into b from public.bookings where id=p_booking_id for update;
  if b.id is null or b.payment_method<>'paymongo'
     or b.status not in ('pending','accepted')
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
       or existing.checkout_url is null then
      raise exception 'Stored checkout does not match the booking quote';
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
    b.id,'paymongo','test',trim(p_provider_checkout_id),trim(p_checkout_url),
    p_amount_centavos,'checkout_created'
  ) returning * into existing;
  update public.bookings set payment_status='checkout_created' where id=b.id;
  return jsonb_build_object(
    'checkout_url',existing.checkout_url,
    'provider_checkout_id',existing.provider_checkout_id,
    'reused',false
  );
end;
$$;
revoke all on function public.record_paymongo_checkout(uuid,text,text,integer)
  from public,anon,authenticated;
grant execute on function public.record_paymongo_checkout(uuid,text,text,integer)
  to service_role;

-- A client may lose the response after booking creation commits. The tourist
-- can recover the one authoritative active booking and rotate (never reveal)
-- its pickup code. This turns an ambiguous transport failure into a safe,
-- inspectable outcome without replaying booking creation.
create or replace function public.recover_booking_pickup_code(p_booking_id uuid)
returns text
language plpgsql
security definer
set search_path=public,extensions
as $$
declare
  recovered_code text;
  recovered public.bookings;
begin
  if public.current_profile_role()<>'tourist' then
    raise exception 'Active tourist account required' using errcode='42501';
  end if;
  recovered_code := (
    1000 + ((get_byte(gen_random_bytes(2),0)*256 + get_byte(gen_random_bytes(2),1)) % 9000)
  )::text;
  update public.bookings set
    pickup_code_hash=crypt(recovered_code,gen_salt('bf')),
    pickup_code_failed_attempts=0,
    pickup_code_locked_until=null
  where id=p_booking_id and tourist_id=auth.uid()
    and status in ('scheduled','pending','accepted')
  returning * into recovered;
  if recovered.id is null then
    raise exception 'Recoverable booking not found';
  end if;
  insert into public.trip_events(
    booking_id,actor_id,actor_role,event_type,description,metadata
  ) values (
    recovered.id,auth.uid(),'tourist','pickup_code_recovered',
    'Pickup code rotated after an interrupted booking response.',
    jsonb_build_object('reason','ambiguous_booking_response')
  );
  return recovered_code;
end;
$$;
revoke all on function public.recover_booking_pickup_code(uuid)
  from public,anon;
grant execute on function public.recover_booking_pickup_code(uuid)
  to authenticated;

-- Reassert final execution boundaries after replacements. Supabase grants new
-- functions to API roles, so revoking only PUBLIC is not sufficient.
revoke all on function public.claim_message_deliveries(integer,text[])
  from public,anon,authenticated;
grant execute on function public.claim_message_deliveries(integer,text[])
  to service_role;
revoke all on function public.finish_message_delivery(uuid,uuid,boolean,text,text,boolean)
  from public,anon,authenticated;
grant execute on function public.finish_message_delivery(uuid,uuid,boolean,text,text,boolean)
  to service_role;
revoke all on function public.finalize_paymongo_refund(uuid,text,text,public.refund_status,text,jsonb)
  from public,anon,authenticated;
grant execute on function public.finalize_paymongo_refund(uuid,text,text,public.refund_status,text,jsonb)
  to service_role;
revoke all on function public.send_scheduled_booking_reminders()
  from public,anon,authenticated;
grant execute on function public.send_scheduled_booking_reminders()
  to service_role;

revoke all on function public.approve_test_refund(uuid,integer,text)
  from public,anon,authenticated,service_role;
revoke all on function public.set_admin_capabilities(uuid,text[])
  from public,anon;
grant execute on function public.set_admin_capabilities(uuid,text[])
  to authenticated;
revoke all on function public.admin_set_tourist_status(uuid,public.account_status,text)
  from public,anon;
grant execute on function public.admin_set_tourist_status(uuid,public.account_status,text)
  to authenticated;

revoke all on function public.enqueue_notification_delivery()
  from public,anon,authenticated,service_role;
revoke all on function public.enqueue_trip_lifecycle_notification()
  from public,anon,authenticated,service_role;
revoke all on function public.handle_new_user()
  from public,anon,authenticated,service_role;
revoke all on function public.record_financial_ledger_entry()
  from public,anon,authenticated,service_role;
revoke all on function public.refresh_driver_reliability_trigger()
  from public,anon,authenticated,service_role;
revoke all on function public.refresh_driver_reliability_metrics(uuid)
  from public,anon,authenticated,service_role;
revoke all on function public.create_ranked_driver_offers(uuid)
  from public,anon,authenticated,service_role;

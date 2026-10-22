-- Keep the test refund workflow accurate without exposing implementation labels.

create or replace function public.complete_paymongo_test_refund(
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
  select * into p from public.payments
    where booking_id=b.id and provider='paymongo' and provider_mode='test' and status='paid'
    order by paid_at desc nulls last limit 1 for update;
  if p.id is null then raise exception 'A paid PayMongo test transaction is required'; end if;
  select coalesce(sum(amount_centavos),0) into reserved from public.refunds
    where payment_id=p.id and status in ('requested','approved','processing','succeeded');
  refundable:=greatest(p.amount_centavos-coalesce(b.final_charge_centavos,b.quoted_amount_centavos)-reserved,0);
  if p_amount_centavos>refundable then raise exception 'Amount exceeds the remaining refund due'; end if;
  insert into public.refunds(
    booking_id,payment_id,provider_refund_id,amount_centavos,reason,status,
    requested_by,approved_by,provider_status,provider_metadata,processed_at
  ) values(
    b.id,p.id,'test_ref_'||gen_random_uuid()::text,p_amount_centavos,trim(p_reason),'succeeded',
    auth.uid(),auth.uid(),'test_succeeded',
    jsonb_build_object('test_mode',true,'completion_source','admin_test_workflow'),now()
  ) returning * into r;
  select coalesce(sum(amount_centavos),0) into reserved from public.refunds
    where payment_id=p.id and status='succeeded';
  update public.bookings set payment_status=case
    when reserved>=greatest(p.amount_centavos-coalesce(b.final_charge_centavos,b.quoted_amount_centavos),0)
      then 'refunded'::public.payment_status else 'partially_refunded'::public.payment_status end
  where id=b.id;
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description,metadata)
  values(b.id,auth.uid(),'admin','test_refund_completed','Refund completed in the test payment environment.',
    jsonb_build_object('refund_id',r.id,'amount_centavos',r.amount_centavos,'test_mode',true,'reason',trim(p_reason)));
  return jsonb_build_object('refund_id',r.id,'status','succeeded','test_mode',true);
end;
$$;
revoke all on function public.complete_paymongo_test_refund(uuid,integer,text) from public;
grant execute on function public.complete_paymongo_test_refund(uuid,integer,text) to authenticated;

create or replace function public.enqueue_trip_lifecycle_notification()
returns trigger language plpgsql security definer set search_path=public as $$
declare b public.bookings;
begin
  if new.event_type not in (
    'booking_created','booking_scheduled','trip_completed','booking_cancelled',
    'refund_completed','refund_provider_update','test_refund_completed','test_refund_simulated',
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
  elsif new.event_type in ('refund_completed','test_refund_completed','test_refund_simulated') then
    insert into public.notifications(recipient_id,booking_id,title,body,route_path,category,send_email)
    values(b.tourist_id,b.id,'Refund completed',
      case when new.event_type='refund_completed'
        then 'PayMongo confirmed your refund. Processing time at the original payment method may vary.'
        else 'Your refund has been completed in the test payment environment.' end,
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
      'refund:'||new.id::text||':completed','Refund completed',
      jsonb_build_object('refund_reason',new.reason,'test_mode',p.provider_mode='test')
        ||coalesce(new.provider_metadata,'{}'::jsonb),
      coalesce(new.processed_at,new.updated_at,new.created_at)
    ) on conflict(idempotency_key) do nothing;
  end if;
  return new;
end;
$$;

update public.notifications
set body='Your refund has been completed in the test payment environment.'
where category='refund' and lower(body) like '%simulat%';

update public.message_deliveries
set body='Your refund has been completed in the test payment environment.'
where status in ('queued','failed') and lower(body) like '%simulat%';

revoke all on function public.simulate_paymongo_test_refund(uuid,integer,text) from public;
drop function if exists public.simulate_paymongo_test_refund(uuid,integer,text);

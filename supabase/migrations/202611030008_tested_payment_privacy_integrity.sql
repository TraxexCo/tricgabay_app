-- Batch 3: exercised against the isolated Supabase PostgreSQL chain.
alter table public.service_configuration add column paymongo_mode text not null default 'test' check(paymongo_mode in ('test','live'));
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
  resolved_mode text;
begin
  if coalesce(auth.role(),'')<>'service_role' then
    raise exception 'Service role required' using errcode='42501';
  end if;
  select paymongo_mode into strict resolved_mode from public.service_configuration where singleton;
  -- All downstream webhook/refund paths are test-only today. Fail closed until
  -- a complete live-mode rollout is implemented; never relabel live as test.
  if resolved_mode<>'test' then raise exception 'Live payments are not enabled for this deployment'; end if;
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
$$;
revoke all on function public.record_paymongo_checkout(uuid,text,text,integer)
  from public,anon,authenticated;
grant execute on function public.record_paymongo_checkout(uuid,text,text,integer)
  to service_role;


create or replace function public.release_paid_booking() returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.payment_status='paid' and old.status='cancelled' then
    new.payment_status:=case when old.payment_status in ('refund_processing','partially_refunded','refunded') then old.payment_status else 'refund_required'::public.payment_status end;
    new.final_charge_centavos:=coalesce(old.final_charge_centavos,0);
    return new;
  end if;
  if old.status='payment_pending' and new.payment_status='paid' then
    if old.payment_expires_at<=now() then
      new.status:='cancelled'; new.final_charge_centavos:=0;
      new.cancellation_reason:='Payment arrived after checkout expiry';
      new.payment_status:='refund_required';
      return new;
    end if;
    new.status:=case when new.scheduled_at>now()+interval '30 minutes' then 'scheduled'::public.booking_status else 'pending'::public.booking_status end;
    new.dispatch_expires_at:=case when new.status='pending' then now()+interval '10 minutes' else new.scheduled_at-interval '20 minutes' end;
  end if;
  return new;
end $$;

create or replace function public.set_updated_at() returns trigger language plpgsql set search_path=public as $$
begin
  if auth.role()='service_role' and current_setting('app.privacy_erasure',true)='on' then
    new.updated_at:=old.updated_at;
  else new.updated_at:=now(); end if;
  return new;
end $$;
create or replace function public.prepare_account_deletion(p_user_id uuid,p_request_id uuid)
returns void language plpgsql security definer set search_path=public,extensions as $$
declare anonymous_id uuid; owner_role public.app_role; fk record; booking_ids uuid[]; previous_erasure text;
begin
  if coalesce(auth.role(),'')<>'service_role' then raise exception 'Service role required' using errcode='42501'; end if;
  if p_user_id is null or p_request_id is null then raise exception 'Invalid deletion request'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_user_id::text,0));
  if exists(select 1 from public.account_deletion_requests where user_id=p_user_id) then return; end if;
  select role into owner_role from public.profiles where id=p_user_id for update;
  if owner_role is null or owner_role='admin' then raise exception 'This account needs administrator-assisted deletion'; end if;
  if exists(select 1 from public.bookings where (tourist_id=p_user_id or driver_id=p_user_id)
    and status in ('payment_pending','scheduled','pending','accepted','replacement_pending','ongoing')) then
    raise exception 'Finish or cancel active bookings before deleting the account'; end if;
  previous_erasure:=current_setting('app.privacy_erasure',true);
  perform set_config('app.privacy_erasure','on',true);
  anonymous_id:=gen_random_uuid();
  insert into public.profiles(id,full_name,phone,email,role,status) values(anonymous_id,'Deleted account',null,null,owner_role,'suspended');
  select array_agg(id) into booking_ids from public.bookings where tourist_id=p_user_id or driver_id=p_user_id;
  -- Retain monetary amounts, provider references and trip dates for reconciliation
  -- and disputes. Remove contact, free-form text and precise location immediately.
  -- No claim of a statutory retention duration or automated purge is made here;
  -- the operator must approve and implement the financial-record retention policy.
  delete from public.driver_location_history where driver_id=p_user_id or booking_id=any(booking_ids);
  delete from public.driver_locations where driver_id=p_user_id;
  delete from public.driver_profiles where profile_id=p_user_id;
  delete from public.feedback where author_id=p_user_id;
  delete from public.message_deliveries where recipient_id=p_user_id or booking_id=any(booking_ids);
  delete from public.notifications where recipient_id=p_user_id;
  update public.notifications set title='Trip update',body='View your retained trip record',lock_screen_body='Open Tric-Gabay to view this update.' where booking_id=any(booking_ids);
  delete from public.push_tokens where profile_id=p_user_id;
  delete from public.admin_capabilities where profile_id=p_user_id;
  delete from public.privacy_consents where profile_id=p_user_id;
  update public.bookings set pickup_address='Removed on account deletion',pickup_latitude=0,pickup_longitude=0,
    luggage_notes='',accessibility_needs='',cancellation_reason=null,interruption_reason=null,replacement_reason=null,client_request_hash=null,
    pickup_code_hash=crypt(gen_random_uuid()::text,gen_salt('bf')) where id=any(booking_ids);
  update public.booking_reviews set review='' where booking_id=any(booking_ids);
  update public.booking_route_changes set reason='Personal text removed on account deletion' where booking_id=any(booking_ids);
  update public.dispute_statements set statement='Personal text removed on account deletion'
    where author_id=p_user_id or dispute_id in(select id from public.disputes where booking_id=any(booking_ids));
  update public.disputes set reason='Personal text removed on account deletion',resolution=null where booking_id=any(booking_ids);
  update public.trip_events set description='Personal text removed on account deletion',metadata='{}' where booking_id=any(booking_ids) or actor_id=p_user_id;
  update public.refunds set reason='Personal text removed on account deletion',provider_metadata='{}',failure_reason=null where booking_id=any(booking_ids);
  update public.payments set provider_metadata='{}' where booking_id=any(booking_ids);
  update public.financial_ledger_entries set metadata='{}',description='Personal text removed on account deletion' where booking_id=any(booking_ids);
  -- Explicitly reviewed participant links only. A future unknown FK fails
  -- the final profile delete and rolls back; it never mutates a new audit table.
  for fk in select * from (values
    ('admin_capabilities','granted_by'),
    ('booking_reviews','driver_id'),
    ('booking_reviews','tourist_id'),
    ('booking_route_changes','decided_by'),
    ('booking_route_changes','requested_by'),
    ('bookings','cancelled_by'),
    ('bookings','driver_id'),
    ('bookings','replacement_requested_by'),
    ('bookings','tourist_id'),
    ('cancellation_policies','created_by'),
    ('cash_confirmations','actor_id'),
    ('dispute_statements','author_id'),
    ('disputes','resolved_by'),
    ('disputes','opened_by'),
    ('driver_profiles','approved_by'),
    ('driver_profiles','compliance_reviewed_by'),
    ('fare_revisions','created_by'),
    ('operational_alerts','resolved_by'),
    ('refunds','approved_by'),
    ('refunds','requested_by'),
    ('trip_events','actor_id')
  ) as allowed(table_name,column_name)
  loop
    execute format('update public.%I set %I=$1 where %I=$2',fk.table_name,fk.column_name,fk.column_name) using anonymous_id,p_user_id;
  end loop;
  delete from public.profiles where id=p_user_id;
  insert into public.account_deletion_requests(user_id,request_id,anonymous_id) values(p_user_id,p_request_id,anonymous_id);
  perform set_config('app.privacy_erasure',coalesce(previous_erasure,''),true);
end $$;


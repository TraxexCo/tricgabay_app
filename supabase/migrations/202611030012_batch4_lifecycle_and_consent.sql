-- Batch 4: preserve settlement decisions and record explicit consent evidence.
create or replace function public.release_paid_booking() returns trigger
language plpgsql security definer set search_path=public as $$
declare retained bigint; charge integer;
begin
  if new.payment_status='paid' and old.status='cancelled' then
    new.final_charge_centavos:=coalesce(old.final_charge_centavos,0);
    if old.payment_status in ('refund_required','refund_processing','partially_refunded','refunded') then
      new.payment_status:=old.payment_status;
    else
      select coalesce(sum(case when direction='credit' then amount_centavos else -amount_centavos end),0)
        into retained from public.financial_ledger_entries where booking_id=new.id;
      charge:=coalesce(old.final_charge_centavos,0);
      -- A replay does not create a refund when the retained funds equal the
      -- agreed cancellation charge. Only an actual excess requires a return.
      if retained>charge then new.payment_status:='refund_required';
      elsif retained=charge and charge>0 then new.payment_status:='paid';
      else new.payment_status:=old.payment_status; end if;
    end if;
    return new;
  end if;
  if old.status='payment_pending' and new.payment_status='paid' then
    if old.payment_expires_at<=now() then
      new.status:='cancelled'; new.final_charge_centavos:=0;
      new.cancellation_reason:='Payment arrived after checkout expiry';
      new.payment_status:='refund_required'; return new;
    end if;
    new.status:=case when new.scheduled_at>now()+interval '30 minutes' then 'scheduled'::public.booking_status else 'pending'::public.booking_status end;
    new.dispatch_expires_at:=case when new.status='pending' then now()+interval '10 minutes' else new.scheduled_at-interval '20 minutes' end;
  end if;
  return new;
end $$;

create or replace function public.expire_stale_online_drivers() returns integer
language plpgsql security definer set search_path=public as $$
declare threshold integer; affected integer:=0; stale record; assignment uuid;
begin
  select stale_heartbeat_seconds into strict threshold from public.service_configuration where singleton;
  for stale in update public.driver_profiles set is_online=false
    where is_online and (last_seen_at is null or last_seen_at<now()-make_interval(secs=>threshold)) returning profile_id
  loop
    affected:=affected+1;
    select id into assignment from public.bookings where driver_id=stale.profile_id
      and status in ('accepted','replacement_pending','ongoing') order by created_at desc limit 1;
    if assignment is not null then
      perform public.raise_operational_alert('critical','dispatch','assigned-driver-stale:'||stale.profile_id,
        'Assigned driver stopped reporting','Driver availability was disabled. Check the active trip and contact the participants.',
        jsonb_build_object('driver_id',stale.profile_id,'booking_id',assignment));
    end if;
  end loop;
  return affected;
end $$;

create table public.consent_history (
  id uuid primary key default gen_random_uuid(),
  -- Intentionally no FK: historical evidence does not rewrite or cascade when
  -- an identity is deleted. The UUID alone is a pseudonymous reference.
  subject_id uuid not null, notice_version text not null,
  notice_language text not null check(notice_language in ('en','fil','und')),
  accepted_at timestamptz not null default now(),
  source text not null check(source in ('signup','acceptance','legacy_snapshot')),
  notice_digest text not null
);
alter table public.consent_history enable row level security;
revoke all on public.consent_history from public,anon,authenticated;
grant select on public.consent_history to authenticated;
create policy consent_history_own_support_read on public.consent_history for select to authenticated
  using(subject_id=auth.uid() or public.has_admin_capability('support'));
create function public.prevent_consent_history_mutation() returns trigger
language plpgsql set search_path=public as $$
begin raise exception 'Consent history is append-only' using errcode='42501'; end $$;
revoke all on function public.prevent_consent_history_mutation() from public,anon,authenticated;
create trigger consent_history_immutable before update or delete on public.consent_history
  for each row execute function public.prevent_consent_history_mutation();
insert into public.consent_history(subject_id,notice_version,notice_language,accepted_at,source,notice_digest)
select profile_id,notice_version,'und',accepted_at,'legacy_snapshot','legacy-notice-not-snapshotted'
from public.privacy_consents;

create function public.record_own_privacy_consent_with_language(p_version text,p_language text) returns void
language plpgsql security definer set search_path=public,extensions as $$
declare config public.service_configuration;
begin
  select * into strict config from public.service_configuration where singleton;
  if auth.uid() is null or p_version is distinct from config.privacy_notice_version
    or p_language is null or p_language not in ('en','fil','und') then
    raise exception 'Read and accept the current privacy notice' using errcode='42501';
  end if;
  insert into public.privacy_consents(profile_id,notice_version) values(auth.uid(),p_version)
    on conflict(profile_id) do update set notice_version=excluded.notice_version,accepted_at=now();
  insert into public.consent_history(subject_id,notice_version,notice_language,source,notice_digest)
    values(auth.uid(),p_version,p_language,'acceptance',encode(digest(
      case p_language when 'fil' then config.privacy_notice_fil when 'en' then config.privacy_notice_en
      else jsonb_build_array(config.privacy_notice_en,config.privacy_notice_fil)::text end,'sha256'),'hex'));
end $$;
revoke all on function public.record_own_privacy_consent_with_language(text,text) from public,anon;
grant execute on function public.record_own_privacy_consent_with_language(text,text) to authenticated;
-- Keep old clients operable, but never invent which language they displayed.
create or replace function public.record_own_privacy_consent(p_version text) returns void
language sql security definer set search_path=public as $$
  select public.record_own_privacy_consent_with_language(p_version,'und')
$$;
create or replace function public.record_signup_consent() returns trigger
language plpgsql security definer set search_path=public,extensions as $$
declare config public.service_configuration; shown_language text;
begin
  select * into strict config from public.service_configuration where singleton;
  if new.raw_user_meta_data->>'privacy_notice_version'=config.privacy_notice_version then
    shown_language:=coalesce(new.raw_user_meta_data->>'privacy_notice_language','und');
    if shown_language not in ('en','fil') then shown_language:='und'; end if;
    insert into public.privacy_consents(profile_id,notice_version) values(new.id,config.privacy_notice_version) on conflict do nothing;
    insert into public.consent_history(subject_id,notice_version,notice_language,source,notice_digest)
      values(new.id,config.privacy_notice_version,shown_language,'signup',encode(digest(
        case shown_language when 'fil' then config.privacy_notice_fil when 'en' then config.privacy_notice_en
        else jsonb_build_array(config.privacy_notice_en,config.privacy_notice_fil)::text end,'sha256'),'hex'));
  end if;
  return new;
end $$;

-- Replace only the reviewed erasure predicates; other-party evidence survives.
do $$
declare definition text;
begin
  definition:=pg_get_functiondef('public.prepare_account_deletion(uuid,uuid)'::regprocedure);
  if position('where author_id=p_user_id or dispute_id in' in definition)=0 then
    raise exception 'Unexpected deletion function; review the erasure change';
  end if;
  definition:=replace(definition,
    'where author_id=p_user_id or dispute_id in(select id from public.disputes where booking_id=any(booking_ids))',
    'where author_id=p_user_id');
  definition:=replace(definition,
    'update public.disputes set reason=''Personal text removed on account deletion'',resolution=null where booking_id=any(booking_ids);',
    'update public.disputes set reason=''Personal text removed on account deletion'' where opened_by=p_user_id;
     update public.disputes set resolution=null where resolved_by=p_user_id;');
  execute definition;
end $$;

create function public.monitor_checkout_expiries() returns integer
language plpgsql security definer set search_path=public as $$
declare item record; alerts integer:=0;
begin
  update public.checkout_expiry_requests set state='blocked',last_result='attempts_exhausted',claim_id=null,claim_until=null
    where attempts>=10 and (state='queued' or (state='processing' and claim_until<=now()));
  for item in select * from public.checkout_expiry_requests where state='blocked'
    or (state='processing' and claim_until<now()-interval '2 minutes')
  loop
    perform public.raise_operational_alert('critical','payment','checkout-expiry:'||item.payment_id,
      'Checkout expiry needs attention','An expiry job is blocked or its worker lease has stalled. Reconcile the provider before retrying.',
      jsonb_build_object('payment_id',item.payment_id,'state',item.state,'attempts',item.attempts));
    alerts:=alerts+1;
  end loop;
  return alerts;
end $$;
revoke all on function public.monitor_checkout_expiries() from public,anon,authenticated;
grant execute on function public.monitor_checkout_expiries() to service_role;
create function public.alert_blocked_checkout_expiry() returns trigger
language plpgsql security definer set search_path=public as $$
begin
  if new.state='blocked' and old.state is distinct from 'blocked' then
    perform public.raise_operational_alert('critical','payment','checkout-expiry:'||new.payment_id,
      'Checkout expiry needs attention','Expiry attempts are exhausted. Reconcile the provider before retrying.',
      jsonb_build_object('payment_id',new.payment_id,'state',new.state,'attempts',new.attempts));
  end if;
  return new;
end $$;
revoke all on function public.alert_blocked_checkout_expiry() from public,anon,authenticated;
create trigger alert_blocked_checkout_expiry after update on public.checkout_expiry_requests
  for each row execute function public.alert_blocked_checkout_expiry();
select cron.schedule('monitor-checkout-expiries','* * * * *','select public.monitor_checkout_expiries()');

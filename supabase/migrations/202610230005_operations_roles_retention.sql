-- Operational hardening: least-privilege administrator capabilities,
-- app-independent communication dispatch, health alerts, and retention jobs.

create table public.admin_capabilities (
  profile_id uuid not null references public.profiles(id) on delete cascade,
  capability text not null check (capability in (
    'super_admin','finance','driver_compliance','content','support','operations'
  )),
  granted_by uuid references public.profiles(id),
  granted_at timestamptz not null default now(),
  primary key(profile_id,capability)
);
alter table public.admin_capabilities enable row level security;
revoke all on public.admin_capabilities from anon,authenticated;
grant select on public.admin_capabilities to authenticated;

create or replace function public.has_admin_capability(p_capability text)
returns boolean language sql stable security definer set search_path=public as $$
  select exists(
    select 1
    from public.profiles p
    join public.admin_capabilities c on c.profile_id=p.id
    where p.id=auth.uid() and p.role='admin' and p.status='active'
      and (c.capability=p_capability or c.capability='super_admin')
  );
$$;
revoke all on function public.has_admin_capability(text) from public;
grant execute on function public.has_admin_capability(text) to authenticated;

create policy admin_capabilities_own_or_super_read on public.admin_capabilities
for select to authenticated using (
  profile_id=auth.uid() or public.has_admin_capability('super_admin')
);

-- Existing administrators remain operable. Future administrators receive no
-- authority until an existing super administrator explicitly assigns it.
insert into public.admin_capabilities(profile_id,capability,granted_by)
select p.id,c.capability,p.id
from public.profiles p
cross join unnest(array[
  'super_admin','finance','driver_compliance','content','support','operations'
]) as c(capability)
where p.role='admin'
on conflict do nothing;

create or replace function public.set_admin_capabilities(
  p_admin_id uuid,p_capabilities text[]
) returns void language plpgsql security definer set search_path=public as $$
declare invalid text;
begin
  if not public.has_admin_capability('super_admin') then
    raise exception 'Super administrator access required';
  end if;
  if p_admin_id=auth.uid() and not ('super_admin'=any(p_capabilities)) then
    raise exception 'A super administrator cannot remove their own recovery access';
  end if;
  if not exists(select 1 from public.profiles where id=p_admin_id and role='admin') then
    raise exception 'Administrator profile not found';
  end if;
  select value into invalid from unnest(p_capabilities) value
    where value not in ('super_admin','finance','driver_compliance','content','support','operations')
    limit 1;
  if invalid is not null then raise exception 'Invalid administrator capability'; end if;
  delete from public.admin_capabilities where profile_id=p_admin_id;
  insert into public.admin_capabilities(profile_id,capability,granted_by)
    select p_admin_id,value,auth.uid() from unnest(p_capabilities) value
    on conflict do nothing;
end;
$$;
revoke all on function public.set_admin_capabilities(uuid,text[]) from public;
grant execute on function public.set_admin_capabilities(uuid,text[]) to authenticated;

-- Wrap privileged RPCs. Their original implementations retain all business
-- validation but are no longer executable by application roles directly.
alter function public.publish_fares(integer,jsonb,text)
  rename to _publish_fares_admin_impl;
revoke all on function public._publish_fares_admin_impl(integer,jsonb,text) from public,authenticated;
create function public.publish_fares(integer,jsonb,text)
returns public.fare_revisions language plpgsql security definer set search_path=public as $$
begin
  if not public.has_admin_capability('finance') then raise exception 'Finance administrator access required'; end if;
  return public._publish_fares_admin_impl($1,$2,$3);
end; $$;
grant execute on function public.publish_fares(integer,jsonb,text) to authenticated;

alter function public.publish_cancellation_policy(integer,integer,integer,integer,integer,text,text)
  rename to _publish_cancellation_policy_admin_impl;
revoke all on function public._publish_cancellation_policy_admin_impl(integer,integer,integer,integer,integer,text,text) from public,authenticated;
create function public.publish_cancellation_policy(integer,integer,integer,integer,integer,text,text)
returns public.cancellation_policies language plpgsql security definer set search_path=public as $$
begin
  if not public.has_admin_capability('finance') then raise exception 'Finance administrator access required'; end if;
  return public._publish_cancellation_policy_admin_impl($1,$2,$3,$4,$5,$6,$7);
end; $$;
grant execute on function public.publish_cancellation_policy(integer,integer,integer,integer,integer,text,text) to authenticated;

alter function public.resolve_booking_charge(uuid,integer,text)
  rename to _resolve_booking_charge_admin_impl;
revoke all on function public._resolve_booking_charge_admin_impl(uuid,integer,text) from public,authenticated;
create function public.resolve_booking_charge(uuid,integer,text)
returns public.bookings language plpgsql security definer set search_path=public as $$
begin
  if not public.has_admin_capability('finance') then raise exception 'Finance administrator access required'; end if;
  return public._resolve_booking_charge_admin_impl($1,$2,$3);
end; $$;
grant execute on function public.resolve_booking_charge(uuid,integer,text) to authenticated;

alter function public.complete_paymongo_test_refund(uuid,integer,text)
  rename to _complete_paymongo_test_refund_admin_impl;
revoke all on function public._complete_paymongo_test_refund_admin_impl(uuid,integer,text) from public,authenticated;
create function public.complete_paymongo_test_refund(uuid,integer,text)
returns jsonb language plpgsql security definer set search_path=public as $$
begin
  if not public.has_admin_capability('finance') then raise exception 'Finance administrator access required'; end if;
  return public._complete_paymongo_test_refund_admin_impl($1,$2,$3);
end; $$;
grant execute on function public.complete_paymongo_test_refund(uuid,integer,text) to authenticated;

alter function public.admin_review_driver_compliance(uuid,date,date,date,text,double precision,double precision,numeric,boolean,text)
  rename to _admin_review_driver_compliance_impl;
revoke all on function public._admin_review_driver_compliance_impl(uuid,date,date,date,text,double precision,double precision,numeric,boolean,text) from public,authenticated;
create function public.admin_review_driver_compliance(uuid,date,date,date,text,double precision,double precision,numeric,boolean,text)
returns public.driver_profiles language plpgsql security definer set search_path=public as $$
begin
  if not public.has_admin_capability('driver_compliance') then raise exception 'Driver compliance access required'; end if;
  return public._admin_review_driver_compliance_impl($1,$2,$3,$4,$5,$6,$7,$8,$9,$10);
end; $$;
grant execute on function public.admin_review_driver_compliance(uuid,date,date,date,text,double precision,double precision,numeric,boolean,text) to authenticated;

alter function public.admin_set_driver_status(uuid,public.driver_approval_status,text,timestamptz)
  rename to _admin_set_driver_status_impl;
revoke all on function public._admin_set_driver_status_impl(uuid,public.driver_approval_status,text,timestamptz) from public,authenticated;
create function public.admin_set_driver_status(uuid,public.driver_approval_status,text,timestamptz)
returns void language plpgsql security definer set search_path=public as $$
begin
  if not public.has_admin_capability('driver_compliance') then raise exception 'Driver compliance access required'; end if;
  perform public._admin_set_driver_status_impl($1,$2,$3,$4);
end; $$;
grant execute on function public.admin_set_driver_status(uuid,public.driver_approval_status,text,timestamptz) to authenticated;

alter function public.set_spot_availability(text,text,text,timestamptz)
  rename to _set_spot_availability_admin_impl;
revoke all on function public._set_spot_availability_admin_impl(text,text,text,timestamptz) from public,authenticated;
create function public.set_spot_availability(text,text,text,timestamptz)
returns void language plpgsql security definer set search_path=public as $$
begin
  if not public.has_admin_capability('content') then raise exception 'Content administrator access required'; end if;
  perform public._set_spot_availability_admin_impl($1,$2,$3,$4);
end; $$;
grant execute on function public.set_spot_availability(text,text,text,timestamptz) to authenticated;

alter function public.send_announcement(text,text)
  rename to _send_announcement_admin_impl;
revoke all on function public._send_announcement_admin_impl(text,text) from public,authenticated;
create function public.send_announcement(text,text)
returns integer language plpgsql security definer set search_path=public as $$
begin
  if not public.has_admin_capability('support') then raise exception 'Support administrator access required'; end if;
  return public._send_announcement_admin_impl($1,$2);
end; $$;
grant execute on function public.send_announcement(text,text) to authenticated;

create or replace function public.admin_set_tourist_status(
  p_tourist_id uuid,p_status public.account_status,p_reason text
) returns void language plpgsql security definer set search_path=public as $$
begin
  if not public.has_admin_capability('support') then raise exception 'Support administrator access required'; end if;
  if p_status not in ('active','suspended') then raise exception 'Unsupported tourist status'; end if;
  if p_status='suspended' and length(trim(p_reason))<5 then raise exception 'A reason is required'; end if;
  if exists(select 1 from public.bookings where tourist_id=p_tourist_id and status='ongoing') then
    raise exception 'Resolve the active trip safely before suspending this tourist';
  end if;
  update public.profiles set status=p_status where id=p_tourist_id and role='tourist';
  if not found then raise exception 'Tourist profile not found'; end if;
  insert into public.notifications(recipient_id,title,body,category)
  values(p_tourist_id,'Account status updated',coalesce(nullif(trim(p_reason),''),'Your account is active.'),'account');
end; $$;
revoke all on function public.admin_set_tourist_status(uuid,public.account_status,text) from public;
grant execute on function public.admin_set_tourist_status(uuid,public.account_status,text) to authenticated;

drop policy if exists admin_spots_write on public.tourist_spots;
create policy admin_spots_write on public.tourist_spots for all to authenticated
using(public.has_admin_capability('content')) with check(public.has_admin_capability('content'));
drop policy if exists admin_packages_write on public.tour_packages;
create policy admin_packages_write on public.tour_packages for all to authenticated
using(public.has_admin_capability('content')) with check(public.has_admin_capability('content'));
drop policy if exists admin_package_stops_write on public.tour_package_stops;
create policy admin_package_stops_write on public.tour_package_stops for all to authenticated
using(public.has_admin_capability('content')) with check(public.has_admin_capability('content'));
drop policy if exists fares_admin_write on public.fare_revisions;
create policy fares_admin_write on public.fare_revisions for all to authenticated
using(public.has_admin_capability('finance')) with check(public.has_admin_capability('finance'));
drop policy if exists policies_admin_write on public.cancellation_policies;
create policy policies_admin_write on public.cancellation_policies for all to authenticated
using(public.has_admin_capability('finance')) with check(public.has_admin_capability('finance'));
drop policy if exists admin_profiles_update on public.profiles;
drop policy if exists admin_driver_profiles_update on public.driver_profiles;

-- A private scheduler token is generated inside Postgres and is never exposed
-- through the Data API. The Edge Function compares the incoming token by using
-- its service-role client.
create table public.internal_scheduler_tokens (
  name text primary key,
  token text not null,
  created_at timestamptz not null default now(),
  rotated_at timestamptz not null default now()
);
alter table public.internal_scheduler_tokens enable row level security;
revoke all on public.internal_scheduler_tokens from anon,authenticated;
insert into public.internal_scheduler_tokens(name,token)
values('communications',encode(extensions.gen_random_bytes(32),'hex'))
on conflict(name) do nothing;

create table public.operational_alerts (
  id uuid primary key default gen_random_uuid(),
  severity text not null check(severity in ('info','warning','critical')),
  category text not null,
  dedupe_key text not null,
  title text not null,
  detail text not null,
  metadata jsonb not null default '{}'::jsonb,
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  occurrences integer not null default 1,
  resolved_at timestamptz,
  resolved_by uuid references public.profiles(id)
);
create unique index operational_alerts_open_dedupe
  on public.operational_alerts(dedupe_key) where resolved_at is null;
alter table public.operational_alerts enable row level security;
create policy operational_alerts_operations_read on public.operational_alerts
  for select to authenticated using(public.has_admin_capability('operations'));
revoke insert,update,delete on public.operational_alerts from anon,authenticated;

create or replace function public.raise_operational_alert(
  p_severity text,p_category text,p_dedupe_key text,p_title text,p_detail text,p_metadata jsonb default '{}'
) returns void language plpgsql security definer set search_path=public as $$
begin
  insert into public.operational_alerts(severity,category,dedupe_key,title,detail,metadata)
  values(p_severity,p_category,p_dedupe_key,p_title,p_detail,coalesce(p_metadata,'{}'))
  on conflict(dedupe_key) where resolved_at is null do update set
    severity=excluded.severity,title=excluded.title,detail=excluded.detail,
    metadata=excluded.metadata,last_seen_at=now(),
    occurrences=public.operational_alerts.occurrences+1;
end; $$;
revoke all on function public.raise_operational_alert(text,text,text,text,text,jsonb) from public,anon,authenticated;

create or replace function public.check_operational_health()
returns void language plpgsql security definer set search_path=public as $$
declare failed_count integer; stale_count integer; payment_count integer;
begin
  select count(*) into failed_count from public.message_deliveries
    where status='failed' and attempts>=5 and updated_at<now()-interval '15 minutes';
  if failed_count>0 then perform public.raise_operational_alert(
    'critical','communications','communications:exhausted','Message deliveries exhausted retries',
    failed_count||' email/push deliveries need administrator attention.',jsonb_build_object('count',failed_count)); end if;

  select count(*) into stale_count from public.bookings b
    where b.status in ('accepted','ongoing') and b.driver_id is not null and not exists(
      select 1 from public.driver_locations l where l.driver_id=b.driver_id and l.recorded_at>now()-interval '3 minutes'
    );
  if stale_count>0 then perform public.raise_operational_alert(
    'warning','tracking','tracking:stale-active','Active trips have stale driver tracking',
    stale_count||' active bookings have no driver location in the last three minutes.',jsonb_build_object('count',stale_count)); end if;

  select count(*) into payment_count from public.bookings
    where payment_status in ('processing','refund_processing') and updated_at<now()-interval '30 minutes';
  if payment_count>0 then perform public.raise_operational_alert(
    'warning','payments','payments:stuck','Payment operations appear stuck',
    payment_count||' payment or refund operations have been processing for over 30 minutes.',jsonb_build_object('count',payment_count)); end if;
end; $$;
revoke all on function public.check_operational_health() from public,anon,authenticated;

create table public.internal_runtime_settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);
alter table public.internal_runtime_settings enable row level security;
revoke all on public.internal_runtime_settings from anon,authenticated;
insert into public.internal_runtime_settings(key,value)
values('retention_enabled','false'::jsonb)
on conflict(key) do nothing;

create or replace function public.retention_candidate_counts()
returns jsonb language sql stable security definer set search_path=public as $$
  select jsonb_build_object(
    'location_rows',(select count(*) from public.driver_location_history h join public.bookings b on b.id=h.booking_id where b.status in ('completed','cancelled') and h.recorded_at<now()-interval '90 days'),
    'delivery_rows',(select count(*) from public.message_deliveries where status in ('sent','skipped') and created_at<now()-interval '180 days'),
    'notification_rows',(select count(*) from public.notifications where created_at<now()-interval '365 days'),
    'token_rows',(select count(*) from public.push_tokens where revoked_at is not null and revoked_at<now()-interval '30 days'),
    'webhook_rows',(select count(*) from public.payment_webhook_events where processed_at<now()-interval '730 days')
  );
$$;
revoke all on function public.retention_candidate_counts() from public,anon,authenticated;

create or replace function public.cleanup_retained_data()
returns jsonb language plpgsql security definer set search_path=public as $$
declare location_rows integer; delivery_rows integer; notification_rows integer; token_rows integer; webhook_rows integer;
begin
  if coalesce((select (value#>>'{}')::boolean from public.internal_runtime_settings where key='retention_enabled'),false)=false then
    return jsonb_build_object('executed',false,'reason','retention_disabled','candidates',public.retention_candidate_counts());
  end if;
  delete from public.driver_location_history h using public.bookings b
    where h.booking_id=b.id and b.status in ('completed','cancelled')
      and h.recorded_at<now()-interval '90 days';
  get diagnostics location_rows=row_count;
  delete from public.message_deliveries
    where status in ('sent','skipped') and created_at<now()-interval '180 days';
  get diagnostics delivery_rows=row_count;
  delete from public.notifications where created_at<now()-interval '365 days';
  get diagnostics notification_rows=row_count;
  delete from public.push_tokens where revoked_at is not null and revoked_at<now()-interval '30 days';
  get diagnostics token_rows=row_count;
  delete from public.payment_webhook_events where processed_at<now()-interval '730 days';
  get diagnostics webhook_rows=row_count;
  return jsonb_build_object('executed',true,'location_rows',location_rows,'delivery_rows',delivery_rows,
    'notification_rows',notification_rows,'token_rows',token_rows,'webhook_rows',webhook_rows);
end; $$;
revoke all on function public.cleanup_retained_data() from public,anon,authenticated;

create extension if not exists pg_net with schema extensions;
create or replace function public.invoke_communications_dispatcher()
returns bigint language plpgsql security definer set search_path=public,extensions as $$
declare scheduler_token text; request_id bigint;
begin
  select token into scheduler_token from public.internal_scheduler_tokens where name='communications';
  select net.http_post(
    url:='https://xcsrjuqzwequmeqzedzd.supabase.co/functions/v1/dispatch-communications',
    headers:=jsonb_build_object('Content-Type','application/json','x-tricgabay-scheduler',scheduler_token),
    body:='{"limit":50}'::jsonb,
    timeout_milliseconds:=20000
  ) into request_id;
  return request_id;
end; $$;
revoke all on function public.invoke_communications_dispatcher() from public,anon,authenticated;

select cron.schedule('tric-gabay-communications','* * * * *','select public.invoke_communications_dispatcher();')
where not exists(select 1 from cron.job where jobname='tric-gabay-communications');
select cron.schedule('tric-gabay-operational-health','*/5 * * * *','select public.check_operational_health();')
where not exists(select 1 from cron.job where jobname='tric-gabay-operational-health');
select cron.schedule('tric-gabay-retention','17 3 * * *','select public.cleanup_retained_data();')
where not exists(select 1 from cron.job where jobname='tric-gabay-retention');

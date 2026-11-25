create table public.emergency_contacts (
  id text primary key, name_en text not null, name_fil text not null,
  phone text, is_placeholder boolean not null default true,
  priority integer not null default 100, is_active boolean not null default true,
  verified_at timestamptz, updated_by uuid, updated_at timestamptz not null default now(),
  check((is_placeholder and phone is null) or
    (not is_placeholder and phone ~ '^\+?[0-9][0-9 -]{1,28}[0-9]$' and verified_at is not null))
);
alter table public.emergency_contacts enable row level security;
revoke all on public.emergency_contacts from public,anon,authenticated;
grant select on public.emergency_contacts to anon,authenticated;
create policy emergency_contacts_read on public.emergency_contacts for select using(is_active or public.has_admin_capability('operations'));
insert into public.emergency_contacts(id,name_en,name_fil,phone,is_placeholder,priority,verified_at) values
('national','National emergency hotline','Pambansang hotline ng emergency','911',false,0,now()),
('mdrrmo','Bustos MDRRMO — owner must supply number','Bustos MDRRMO — ilalagay ng may-ari ang numero',null,true,10,null),
('pnp','Bustos PNP — owner must supply number','Bustos PNP — ilalagay ng may-ari ang numero',null,true,20,null),
('bfp','Bustos BFP — owner must supply number','Bustos BFP — ilalagay ng may-ari ang numero',null,true,30,null),
('hospital','Local hospital — owner must supply number','Lokal na ospital — ilalagay ng may-ari ang numero',null,true,40,null),
('tourism','Bustos tourism office — owner must supply number','Tanggapan ng turismo — ilalagay ng may-ari ang numero',null,true,50,null);
create table public.emergency_contact_audit (
  id uuid primary key default gen_random_uuid(),contact_id text not null,actor_id uuid not null,
  previous_phone text,new_phone text,was_placeholder boolean not null,is_placeholder boolean not null,
  created_at timestamptz not null default now()
);
alter table public.emergency_contact_audit enable row level security;
revoke all on public.emergency_contact_audit from public,anon,authenticated;
grant select on public.emergency_contact_audit to authenticated;
create policy emergency_contact_audit_operations_read on public.emergency_contact_audit for select to authenticated using(public.has_admin_capability('operations'));
create trigger emergency_contact_audit_immutable before update or delete on public.emergency_contact_audit for each row execute function public.prevent_consent_history_mutation();
create function public.update_emergency_contact(p_id text,p_phone text,p_name_en text,p_name_fil text) returns void
language plpgsql security definer set search_path=public as $$
declare previous public.emergency_contacts; normalized text:=nullif(trim(p_phone),'');
begin
  if not public.has_admin_capability('operations') then raise exception 'Operations capability required' using errcode='42501'; end if;
  if length(trim(coalesce(p_name_en,''))) not between 2 and 160 or length(trim(coalesce(p_name_fil,''))) not between 2 and 160
    or (normalized is not null and normalized !~ '^\+?[0-9][0-9 -]{1,28}[0-9]$') then raise exception 'Invalid contact details'; end if;
  select * into strict previous from public.emergency_contacts where id=p_id for update;
  update public.emergency_contacts set phone=normalized,is_placeholder=(normalized is null),name_en=trim(p_name_en),name_fil=trim(p_name_fil),
    verified_at=case when normalized is null then null else now() end,updated_by=auth.uid(),updated_at=now() where id=p_id;
  insert into public.emergency_contact_audit(contact_id,actor_id,previous_phone,new_phone,was_placeholder,is_placeholder)
    values(p_id,auth.uid(),previous.phone,normalized,previous.is_placeholder,normalized is null);
end $$;
revoke all on function public.update_emergency_contact(text,text,text,text) from public,anon;
grant execute on function public.update_emergency_contact(text,text,text,text) to authenticated;

create table public.data_subject_requests (
  id uuid primary key default gen_random_uuid(),subject_id uuid not null,request_id uuid not null,
  notice_language text not null check(notice_language in ('en','fil')),
  status text not null default 'pending' check(status in ('pending','fulfilled','cancelled')),
  requested_at timestamptz not null default now(),fulfilled_at timestamptz,fulfilled_by uuid,
  unique(subject_id,request_id)
);
create table public.data_subject_exports (
  request_id uuid primary key references public.data_subject_requests(id),subject_id uuid not null,
  payload jsonb not null,created_at timestamptz not null default now()
);
create table public.data_subject_request_audit (
  id uuid primary key default gen_random_uuid(),request_id uuid not null,subject_id uuid not null,
  actor_id uuid,action text not null check(action in ('requested','fulfilled','account_deleted')),
  created_at timestamptz not null default now()
);
alter table public.data_subject_requests enable row level security;
alter table public.data_subject_exports enable row level security;
alter table public.data_subject_request_audit enable row level security;
revoke all on public.data_subject_requests,public.data_subject_exports,public.data_subject_request_audit from public,anon,authenticated;
grant select on public.data_subject_requests,public.data_subject_exports,public.data_subject_request_audit to authenticated;
create policy data_subject_requests_own_support_read on public.data_subject_requests for select to authenticated using(subject_id=auth.uid() or public.has_admin_capability('support'));
create policy data_subject_exports_own_read on public.data_subject_exports for select to authenticated using(subject_id=auth.uid());
create policy data_subject_request_audit_read on public.data_subject_request_audit for select to authenticated using(subject_id=auth.uid() or public.has_admin_capability('support'));
create trigger data_subject_request_audit_immutable before update or delete on public.data_subject_request_audit for each row execute function public.prevent_consent_history_mutation();
create function public.request_own_data_export(p_request_id uuid,p_language text) returns uuid
language plpgsql security definer set search_path=public as $$
declare result uuid;
begin
  if auth.uid() is null or not exists(select 1 from public.profiles where id=auth.uid()) then raise exception 'Authentication required' using errcode='42501'; end if;
  if p_request_id is null or p_language is null or p_language not in ('en','fil') then raise exception 'Valid request ID and language required'; end if;
  perform 1 from public.profiles where id=auth.uid() for update;
  select id into result from public.data_subject_requests where subject_id=auth.uid() and request_id=p_request_id;
  if result is not null then return result; end if;
  if (select count(*) from public.data_subject_requests where subject_id=auth.uid() and requested_at>now()-interval '1 day')>=3 then raise exception 'Export request limit reached'; end if;
  insert into public.data_subject_requests(subject_id,request_id,notice_language) values(auth.uid(),p_request_id,p_language) returning id into result;
  insert into public.data_subject_request_audit(request_id,subject_id,actor_id,action) values(result,auth.uid(),auth.uid(),'requested');
  return result;
end $$;
revoke all on function public.request_own_data_export(uuid,text) from public,anon;
grant execute on function public.request_own_data_export(uuid,text) to authenticated;
create function public.build_data_subject_export(p_subject_id uuid) returns jsonb
language sql stable security definer set search_path=public as $$
  select jsonb_build_object('schema_version',1,'generated_at',now(),
    'profile',(select to_jsonb(p)-'auth_user_id' from public.profiles p where id=p_subject_id),
    'driver_application',(select to_jsonb(d) from public.driver_profiles d where profile_id=p_subject_id),
    'bookings',coalesce((select jsonb_agg(to_jsonb(b)-'pickup_code_hash'-'client_request_hash') from public.bookings b where tourist_id=p_subject_id or driver_id=p_subject_id),'[]'),
    'payments',coalesce((select jsonb_agg(to_jsonb(p)-'provider_metadata') from public.payments p join public.bookings b on b.id=p.booking_id where b.tourist_id=p_subject_id or b.driver_id=p_subject_id),'[]'),
    'own_dispute_statements',coalesce((select jsonb_agg(to_jsonb(s)) from public.dispute_statements s where author_id=p_subject_id),'[]'),
    'own_feedback',coalesce((select jsonb_agg(to_jsonb(f)) from public.feedback f where author_id=p_subject_id),'[]'),
    'consent_history',coalesce((select jsonb_agg(to_jsonb(c)) from public.consent_history c where subject_id=p_subject_id),'[]'))
$$;
revoke all on function public.build_data_subject_export(uuid) from public,anon,authenticated;
grant execute on function public.build_data_subject_export(uuid) to service_role;
create function public.fulfil_data_subject_request(p_request_id uuid) returns void
language plpgsql security definer set search_path=public as $$
declare request public.data_subject_requests;
begin
  if not public.has_admin_capability('support') then raise exception 'Support capability required' using errcode='42501'; end if;
  select * into strict request from public.data_subject_requests where id=p_request_id for update;
  if request.status='fulfilled' then return; end if;
  if request.status<>'pending' or not exists(select 1 from public.profiles where id=request.subject_id) then raise exception 'Request cannot be fulfilled'; end if;
  insert into public.data_subject_exports(request_id,subject_id,payload) values(request.id,request.subject_id,public.build_data_subject_export(request.subject_id));
  update public.data_subject_requests set status='fulfilled',fulfilled_at=now(),fulfilled_by=auth.uid() where id=request.id;
  insert into public.data_subject_request_audit(request_id,subject_id,actor_id,action) values(request.id,request.subject_id,auth.uid(),'fulfilled');
end $$;
revoke all on function public.fulfil_data_subject_request(uuid) from public,anon;
grant execute on function public.fulfil_data_subject_request(uuid) to authenticated;
create function public.erase_data_subject_exports(p_subject_id uuid) returns void
language plpgsql security definer set search_path=public as $$
begin
  if coalesce(auth.role(),'')<>'service_role' then raise exception 'Service role required' using errcode='42501'; end if;
  delete from public.data_subject_exports where subject_id=p_subject_id;
  insert into public.data_subject_request_audit(request_id,subject_id,action)
    select id,subject_id,'account_deleted' from public.data_subject_requests where subject_id=p_subject_id and status<>'cancelled';
  update public.data_subject_requests set status='cancelled' where subject_id=p_subject_id;
end $$;
revoke all on function public.erase_data_subject_exports(uuid) from public,anon,authenticated;
grant execute on function public.erase_data_subject_exports(uuid) to service_role;
do $$
declare definition text;
begin
  definition:=pg_get_functiondef('public.prepare_account_deletion(uuid,uuid)'::regprocedure);
  if position('delete from public.privacy_consents where profile_id=p_user_id;' in definition)=0 then raise exception 'Unexpected deletion definition'; end if;
  execute replace(definition,'delete from public.privacy_consents where profile_id=p_user_id;',
    'delete from public.privacy_consents where profile_id=p_user_id; perform public.erase_data_subject_exports(p_user_id);');
end $$;

-- Service-only view: no identity, contact, location or payment identifiers.
create view public.operations_health with (security_barrier=true) as
select 'failed_payments'::text metric,count(*)::bigint value from public.payments where status='failed' and updated_at>now()-interval '1 day'
union all select 'blocked_expiry',count(*) from public.checkout_expiry_requests where state='blocked' or (state='processing' and claim_until<now()-interval '2 minutes')
union all select 'cron_failures',count(*) from cron.job_run_details where status='failed' and start_time>now()-interval '15 minutes'
union all select 'stale_online_drivers',count(*) from public.driver_profiles d cross join public.service_configuration c where d.is_online and (d.last_seen_at is null or d.last_seen_at<now()-make_interval(secs=>c.stale_heartbeat_seconds))
union all select 'notification_failures',count(*) from public.message_deliveries where status='failed' and updated_at>now()-interval '1 day';
revoke all on public.operations_health from public,anon,authenticated;
grant select on public.operations_health to service_role;
create function public.collect_operations_health() returns jsonb
language plpgsql security definer set search_path=public as $$
declare metric record; result jsonb;
begin
  if coalesce(auth.role(),'')<>'service_role' then raise exception 'Service role required' using errcode='42501'; end if;
  perform public.monitor_checkout_expiries();
  for metric in select * from public.operations_health where value>0 loop
    perform public.raise_operational_alert('critical','health','health:'||metric.metric,
      'Service health needs attention',metric.metric||' requires review.',jsonb_build_object('metric',metric.metric,'count',metric.value));
  end loop;
  select jsonb_object_agg(h.metric,h.value) into result from public.operations_health h;
  return result;
end $$;
revoke all on function public.collect_operations_health() from public,anon,authenticated;
grant execute on function public.collect_operations_health() to service_role;
create function public.get_operations_health() returns jsonb
language plpgsql stable security definer set search_path=public as $$
begin
  if not public.has_admin_capability('operations') then raise exception 'Operations capability required' using errcode='42501'; end if;
  return (select jsonb_object_agg(h.metric,h.value) from public.operations_health h);
end $$;
revoke all on function public.get_operations_health() from public,anon;
grant execute on function public.get_operations_health() to authenticated;
select cron.schedule('collect-operations-health','* * * * *',$job$select set_config('request.jwt.claim.role','service_role',true);select public.collect_operations_health();$job$);

-- The database owns the current notice version and content. Clients display
-- this exact version and submit it; they cannot silently consent to a new one.
alter table public.service_configuration
  add column privacy_notice_version text not null default '2026-11-03',
  add column privacy_notice_en text not null default 'Tric Gabay uses your name, email and phone to manage your account and trip contact. Pickup and trip location are used for matching, navigation and safety; background location is requested only for driver service. Driver identity and vehicle documents are reviewed by authorised administrators. Supabase stores account and trip records; Mapbox processes route coordinates; PayMongo handles online checkout; Firebase supports notifications. Optional crash and performance diagnostics may include device and app information; the app does not attach contact details, pickup codes, precise location or payment details to diagnostic reports. You may decline diagnostics and still book. Account deletion removes profile details, documents and avatars, and disconnects retained trip and financial records from your account. Financial transaction identifiers and amounts remain under the operator retention policy; provider copies and backups follow their own policies. For privacy or deletion help, use Help & support in your account.',
  add column privacy_notice_fil text not null default 'Ginagamit ng Tric Gabay ang pangalan, email at telepono mo para sa account at pakikipag-ugnayan sa biyahe. Ginagamit ang eksaktong lokasyon para sa pickup, paghahanap ng driver, ruta at kaligtasan. Kailangan lamang ang background location habang nagseserbisyo ang driver. Sinusuri ng awtorisadong administrador ang mga dokumento ng driver at sasakyan. Supabase ang imbakan, Mapbox ang tagapagproseso ng ruta, PayMongo ang online checkout, at Firebase ang mga abiso. Opsyonal ang crash diagnostics; maaari kang tumanggi at mag-book pa rin. Hindi isinasama sa diagnostic reports ang contact details, pickup code, eksaktong lokasyon o detalye ng bayad. Inaalis ng account deletion ang login, personal na profile, dokumento at avatar. Inihihiwalay sa account ang mga kailangang panatilihing tala ng biyahe at transaksiyon. Nananatili ang mga halaga at provider reference ayon sa patakaran ng operator; hiwalay ang mga patakaran ng provider at backup. Gamitin ang Help & support para sa mga tanong sa privacy.';
create function public.get_privacy_notice() returns jsonb language sql stable security definer set search_path=public as $$
 select jsonb_build_object('version',privacy_notice_version,'english',privacy_notice_en,'filipino',privacy_notice_fil) from public.service_configuration where singleton
$$;
revoke all on function public.get_privacy_notice() from public;
grant execute on function public.get_privacy_notice() to anon,authenticated;
create function public.get_privacy_consent_status() returns jsonb language plpgsql stable security definer set search_path=public as $$
declare notice jsonb; accepted boolean;
begin
 if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
 notice:=public.get_privacy_notice();
 select exists(select 1 from public.privacy_consents where profile_id=auth.uid() and notice_version=notice->>'version') into accepted;
 return notice||jsonb_build_object('accepted',accepted);
end $$;
revoke all on function public.get_privacy_consent_status() from public,anon;
grant execute on function public.get_privacy_consent_status() to authenticated;
create or replace function public.record_own_privacy_consent(p_version text) returns void language plpgsql security definer set search_path=public as $$
declare current_version text;
begin
 select privacy_notice_version into strict current_version from public.service_configuration where singleton;
 if auth.uid() is null or p_version is null or p_version<>current_version then raise exception 'Read and accept the current privacy notice' using errcode='42501'; end if;
 insert into public.privacy_consents(profile_id,notice_version) values(auth.uid(),p_version)
 on conflict(profile_id) do update set notice_version=excluded.notice_version,accepted_at=now();
end $$;
create or replace function public.record_signup_consent() returns trigger language plpgsql security definer set search_path=public as $$
declare current_version text;
begin
 select privacy_notice_version into strict current_version from public.service_configuration where singleton;
 if new.raw_user_meta_data->>'privacy_notice_version'=current_version then
   insert into public.privacy_consents(profile_id,notice_version) values(new.id,current_version) on conflict do nothing;
 end if;
 return new;
end $$;
create table public.announcement_audit (
 id uuid primary key default gen_random_uuid(), sender_id uuid not null references public.profiles(id),
 request_id uuid not null, audience text not null check(audience in ('tourists','drivers','all')),
 payload_hash text not null, recipient_count integer not null check(recipient_count>=0),
 created_at timestamptz not null default now(), unique(sender_id,request_id)
);
alter table public.announcement_audit enable row level security;
revoke all on public.announcement_audit from anon,authenticated;
grant select on public.announcement_audit to authenticated;
create policy announcement_audit_read on public.announcement_audit for select to authenticated using(
 (sender_id=auth.uid() and public.has_admin_capability('support')) or public.has_admin_capability('super_admin'));
create function public.prevent_announcement_audit_mutation() returns trigger language plpgsql as $$
begin raise exception 'Announcement audit is append-only'; end $$;
create trigger announcement_audit_immutable before update or delete on public.announcement_audit for each row execute function public.prevent_announcement_audit_mutation();
revoke all on function public.prevent_announcement_audit_mutation() from public,anon,authenticated;
drop function public.send_announcement(text,text,text);
create function public.send_announcement(p_title text,p_body text,p_audience text,p_request_id uuid)
returns integer language plpgsql security definer set search_path=public,extensions as $$
declare inserted integer; previous public.announcement_audit; fingerprint text;
begin
 if not public.has_admin_capability('support') then raise exception 'Support capability required' using errcode='42501'; end if;
 if p_request_id is null then raise exception 'Announcement request ID required'; end if;
 if p_audience is null or p_audience not in ('tourists','drivers','all') then raise exception 'Choose an audience'; end if;
 if p_title is null or p_body is null or length(trim(p_title)) not between 3 and 150 or length(trim(p_body)) not between 5 and 2000 then raise exception 'Invalid announcement length'; end if;
 perform 1 from public.profiles where id=auth.uid() for update;
 fingerprint:=encode(digest(jsonb_build_array(trim(p_title),trim(p_body),p_audience)::text,'sha256'),'hex');
 select * into previous from public.announcement_audit where sender_id=auth.uid() and request_id=p_request_id;
 if previous.id is not null then
   if previous.payload_hash<>fingerprint then raise exception 'Announcement request conflict'; end if;
   return previous.recipient_count;
 end if;
 if (select count(*) from public.announcement_audit where sender_id=auth.uid() and created_at>now()-interval '10 minutes')>=3 then raise exception 'Announcement rate limit reached'; end if;
 insert into public.notifications(recipient_id,title,body)
 select id,trim(p_title),trim(p_body) from public.profiles where status='active'
 and ((p_audience='all' and role in ('tourist','driver')) or (p_audience='tourists' and role='tourist') or (p_audience='drivers' and role='driver'));
 get diagnostics inserted=row_count;
 insert into public.announcement_audit(sender_id,request_id,audience,payload_hash,recipient_count)
 values(auth.uid(),p_request_id,p_audience,fingerprint,inserted);
 return inserted;
end $$;
revoke all on function public.send_announcement(text,text,text,uuid) from public,anon;
grant execute on function public.send_announcement(text,text,text,uuid) to authenticated;

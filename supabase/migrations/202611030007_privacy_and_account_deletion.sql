-- LOCAL FILE ONLY. NOT applied/tested against a real database.
create table public.privacy_consents (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  notice_version text not null, accepted_at timestamptz not null default now()
);
alter table public.privacy_consents enable row level security;
revoke all on public.privacy_consents from anon,authenticated;
create function public.record_signup_consent() returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.raw_user_meta_data->>'privacy_notice_version'='2026-11-03' then
    insert into public.privacy_consents(profile_id,notice_version) values(new.id,'2026-11-03') on conflict do nothing;
  end if;
  return new;
end $$;
-- AFTER INSERT names sort after existing profile-creation trigger names only
-- if declared accordingly; defer this trigger until transaction end instead.
create constraint trigger zz_signup_consent after insert on auth.users deferrable initially deferred
for each row execute function public.record_signup_consent();
revoke all on function public.record_signup_consent() from public,anon,authenticated;

-- A retained, anonymous participant needs an identity independent of Auth.
-- Keep real profiles lifecycle-controlled by Auth via the explicit deletion flow.
alter table public.profiles drop constraint profiles_id_fkey;
-- Real profiles retain the Auth cascade through an explicit nullable link;
-- anonymous retained participants deliberately have no Auth identity.
alter table public.profiles add column auth_user_id uuid unique references auth.users(id) on delete cascade;
update public.profiles set auth_user_id=id;
create function public.attach_profile_auth_identity() returns trigger language plpgsql security definer set search_path=public as $$
begin
  if exists(select 1 from auth.users where id=new.id) then new.auth_user_id:=new.id; end if;
  return new;
end $$;
create trigger attach_profile_auth_identity before insert on public.profiles for each row execute function public.attach_profile_auth_identity();
revoke all on function public.attach_profile_auth_identity() from public,anon,authenticated;
create table public.account_deletion_requests (
  user_id uuid primary key,request_id uuid not null unique,anonymous_id uuid not null,
  prepared_at timestamptz not null default now()
);
alter table public.account_deletion_requests enable row level security;
revoke all on public.account_deletion_requests from anon,authenticated;
grant select on public.account_deletion_requests to service_role;

-- Financial values remain immutable. Privacy deletion may erase free-form
-- metadata/description only; no amount, provider identity or timestamp can change.
create or replace function public.prevent_financial_ledger_mutation() returns trigger language plpgsql set search_path=public as $$
begin
  if tg_op='UPDATE' and auth.role()='service_role' and current_setting('app.privacy_erasure',true)='on'
    and (to_jsonb(new)-'metadata'-'description')=(to_jsonb(old)-'metadata'-'description')
    and new.metadata='{}'::jsonb and new.description='Personal text removed on account deletion' then return new; end if;
  raise exception 'Financial ledger entries are immutable';
end $$;
revoke all on function public.prevent_financial_ledger_mutation() from public,anon,authenticated;

create function public.prepare_account_deletion(p_user_id uuid,p_request_id uuid)
returns void language plpgsql security definer set search_path=public,extensions as $$
declare anonymous_id uuid; owner_role public.app_role; fk record; booking_ids uuid[];
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
  update public.disputes set reason='Personal text removed on account deletion',resolution=null where booking_id=any(booking_ids);
  update public.trip_events set description='Personal text removed on account deletion',metadata='{}' where booking_id=any(booking_ids) or actor_id=p_user_id;
  update public.refunds set reason='Personal text removed on account deletion',provider_metadata='{}',failure_reason=null where booking_id=any(booking_ids);
  update public.payments set provider_metadata='{}' where booking_id=any(booking_ids);
  perform set_config('app.privacy_erasure','on',true);
  update public.financial_ledger_entries set metadata='{}',description='Personal text removed on account deletion' where booking_id=any(booking_ids);
  -- Disconnect every public FK, including future financial/audit participant FKs,
  -- without changing any financial amount. Owning private rows were removed above.
  for fk in select cl.relname as table_name,att.attname as column_name
    from pg_constraint c join pg_class cl on cl.oid=c.conrelid
    join pg_namespace n on n.oid=cl.relnamespace
    join pg_attribute att on att.attrelid=cl.oid and att.attnum=c.conkey[1]
    where c.contype='f' and c.confrelid='public.profiles'::regclass and n.nspname='public'
      and array_length(c.conkey,1)=1
  loop
    execute format('update public.%I set %I=$1 where %I=$2',fk.table_name,fk.column_name,fk.column_name) using anonymous_id,p_user_id;
  end loop;
  delete from public.profiles where id=p_user_id;
  insert into public.account_deletion_requests(user_id,request_id,anonymous_id) values(p_user_id,p_request_id,anonymous_id);
end $$;
revoke all on function public.prepare_account_deletion(uuid,uuid) from public,anon,authenticated;
grant execute on function public.prepare_account_deletion(uuid,uuid) to service_role;
create function public.finish_account_deletion(p_user_id uuid) returns void language plpgsql security definer set search_path=public as $$
begin
  if coalesce(auth.role(),'')<>'service_role' then raise exception 'Service role required' using errcode='42501'; end if;
  delete from public.account_deletion_requests where user_id=p_user_id;
end $$;
revoke all on function public.finish_account_deletion(uuid) from public,anon,authenticated;
grant execute on function public.finish_account_deletion(uuid) to service_role;

create function public.record_own_privacy_consent(p_version text) returns void language plpgsql security definer set search_path=public as $$
begin
  if auth.uid() is null or p_version<>'2026-11-03' or p_version is null then raise exception 'Valid consent required' using errcode='42501'; end if;
  insert into public.privacy_consents(profile_id,notice_version) values(auth.uid(),p_version)
    on conflict(profile_id) do update set notice_version=excluded.notice_version,accepted_at=now();
end $$;
revoke all on function public.record_own_privacy_consent(text) from public,anon;
grant execute on function public.record_own_privacy_consent(text) to authenticated;

create function public.protect_profile_auth_identity() returns trigger language plpgsql set search_path=public as $$
begin
  if new.auth_user_id is distinct from old.auth_user_id then raise exception 'Auth identity link is immutable'; end if;
  return new;
end $$;
create trigger protect_profile_auth_identity before update of auth_user_id on public.profiles for each row execute function public.protect_profile_auth_identity();
revoke all on function public.protect_profile_auth_identity() from public,anon,authenticated;

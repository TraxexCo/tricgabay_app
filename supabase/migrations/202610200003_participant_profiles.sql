-- Participants need the other party's public trip identity, but not unrelated accounts.
create policy profiles_trip_participant_read on public.profiles for select to authenticated using (
  exists(
    select 1 from public.bookings b
    where (b.tourist_id=auth.uid() and b.driver_id=profiles.id)
       or (b.driver_id=auth.uid() and b.tourist_id=profiles.id)
  )
);
create policy assigned_driver_profile_read on public.driver_profiles for select to authenticated using (
  exists(
    select 1 from public.bookings b
    where b.tourist_id=auth.uid() and b.driver_id=driver_profiles.profile_id
  )
);

create table public.dispute_statements (
  id uuid primary key default gen_random_uuid(),
  dispute_id uuid not null references public.disputes(id) on delete cascade,
  author_id uuid not null references public.profiles(id),
  statement text not null check (length(trim(statement)) between 5 and 3000),
  created_at timestamptz not null default now()
);
alter table public.dispute_statements enable row level security;
create policy dispute_statements_participant_read on public.dispute_statements for select to authenticated using (
  author_id=auth.uid() or public.is_admin() or exists(
    select 1 from public.disputes d join public.bookings b on b.id=d.booking_id
    where d.id=dispute_id and (b.tourist_id=auth.uid() or b.driver_id=auth.uid())
  )
);
revoke insert,update,delete on public.dispute_statements from anon,authenticated;

create or replace function public.open_dispute(p_booking_id uuid, p_reason text)
returns uuid language plpgsql security definer set search_path=public as $$
declare b public.bookings; result uuid; actor public.app_role;
begin
  if length(trim(p_reason))<5 then raise exception 'A dispute reason is required'; end if;
  select * into b from public.bookings where id=p_booking_id for update;
  if b.id is null or b.status in ('pending','accepted','ongoing') then raise exception 'End the trip before opening a dispute'; end if;
  if auth.uid()=b.tourist_id then actor='tourist'; elsif auth.uid()=b.driver_id then actor='driver'; else raise exception 'Only a participant can dispute'; end if;
  if exists(select 1 from public.disputes where booking_id=b.id and status='open') then raise exception 'A review is already open'; end if;
  insert into public.disputes(booking_id,opened_by,reason) values(b.id,auth.uid(),trim(p_reason)) returning id into result;
  update public.bookings set payment_status='under_review' where id=b.id;
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description)
  values(b.id,auth.uid(),actor,'payment_disputed','Payment disputed: '||trim(p_reason));
  return result;
end;
$$;
grant execute on function public.open_dispute(uuid,text) to authenticated;

create or replace function public.add_dispute_statement(p_booking_id uuid, p_statement text)
returns void language plpgsql security definer set search_path=public as $$
declare dispute_id uuid; b public.bookings; actor public.app_role;
begin
  if length(trim(p_statement))<5 then raise exception 'A statement is required'; end if;
  select * into b from public.bookings where id=p_booking_id;
  if auth.uid()=b.tourist_id then actor='tourist'; elsif auth.uid()=b.driver_id then actor='driver'; elsif public.is_admin() then actor='admin'; else raise exception 'Access denied'; end if;
  select id into dispute_id from public.disputes where booking_id=b.id and status='open' order by created_at desc limit 1;
  if dispute_id is null then raise exception 'No open dispute'; end if;
  insert into public.dispute_statements(dispute_id,author_id,statement) values(dispute_id,auth.uid(),trim(p_statement));
  insert into public.trip_events(booking_id,actor_id,actor_role,event_type,description)
  values(b.id,auth.uid(),actor,'case_statement','Case statement: '||trim(p_statement));
end;
$$;
grant execute on function public.add_dispute_statement(uuid,text) to authenticated;

alter table public.tourist_spots add column if not exists history text not null default '';
alter table public.tourist_spots add column if not exists tips jsonb not null default '[]'::jsonb;
alter table public.tourist_spots add column if not exists distance_from_town double precision not null default 0;
alter table public.profiles add column if not exists avatar_path text;
alter table public.profiles add column if not exists email text;
update public.profiles p set email=u.email from auth.users u where u.id=p.id and p.email is null;
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare requested text;
begin
  requested := coalesce(new.raw_user_meta_data->>'requested_role', 'tourist');
  if requested not in ('tourist', 'driver') then requested := 'tourist'; end if;
  insert into public.profiles(id, full_name, phone, email, role, status)
  values (new.id, coalesce(nullif(trim(new.raw_user_meta_data->>'full_name'), ''), 'New user'),
    new.raw_user_meta_data->>'phone', new.email, requested::public.app_role,
    case when requested='driver' then 'pending'::public.account_status else 'active'::public.account_status end);
  return new;
end;
$$;

create policy admin_profiles_update on public.profiles for update to authenticated
using (public.is_admin()) with check (public.is_admin());
create policy admin_driver_profiles_update on public.driver_profiles for update to authenticated
using (public.is_admin()) with check (public.is_admin());

create or replace function public.send_announcement(p_title text, p_body text)
returns integer language plpgsql security definer set search_path=public as $$
declare inserted integer;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  if length(trim(p_title))<3 or length(trim(p_body))<5 then raise exception 'Title and message are required'; end if;
  insert into public.notifications(recipient_id,title,body)
    select id,trim(p_title),trim(p_body) from public.profiles where status='active' and role in ('tourist','driver');
  get diagnostics inserted = row_count;
  return inserted;
end;
$$;
grant execute on function public.send_announcement(text,text) to authenticated;

create or replace function public.update_own_profile(
  p_full_name text, p_phone text, p_avatar_path text,
  p_plate_number text default null, p_franchise_number text default null
) returns void language plpgsql security definer set search_path=public as $$
declare profile_role public.app_role; vehicle_changed boolean := false;
begin
  if length(trim(p_full_name))<2 then raise exception 'Full name is required'; end if;
  select role into profile_role from public.profiles where id=auth.uid();
  if profile_role is null then raise exception 'Profile not found'; end if;
  update public.profiles set full_name=trim(p_full_name),phone=trim(p_phone),
    avatar_path=coalesce(p_avatar_path,avatar_path) where id=auth.uid();
  if profile_role='driver' and p_plate_number is not null and p_franchise_number is not null then
    select plate_number<>upper(trim(p_plate_number)) or franchise_number<>trim(p_franchise_number)
      into vehicle_changed from public.driver_profiles where profile_id=auth.uid();
    update public.driver_profiles set plate_number=upper(trim(p_plate_number)),franchise_number=trim(p_franchise_number),
      approval_status=case when vehicle_changed then 'pending'::public.driver_approval_status else approval_status end,
      is_online=case when vehicle_changed then false else is_online end where profile_id=auth.uid();
    if vehicle_changed then update public.profiles set status='pending' where id=auth.uid(); end if;
  end if;
end;
$$;
grant execute on function public.update_own_profile(text,text,text,text,text) to authenticated;

insert into storage.buckets(id,name,public) values('profile-images','profile-images',true) on conflict(id) do nothing;
create policy profile_images_public_read on storage.objects for select using(bucket_id='profile-images');
create policy profile_images_own_write on storage.objects for insert to authenticated
with check(bucket_id='profile-images' and (storage.foldername(name))[1]=auth.uid()::text);

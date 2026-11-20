-- Minimal Storage schema used only by the isolated PostgreSQL migration-chain
-- harness when the Supabase Storage service is intentionally not started.
-- Hosted/local Supabase creates these objects itself; this file is not a
-- product migration or a pgTAP test.
create schema if not exists storage;
-- The Supabase PostgreSQL image pre-creates this schema for supabase_admin,
-- while the real Storage migrations operate as supabase_storage_admin.
-- Align the disposable fixture with that service-owned boundary.
alter schema storage owner to supabase_storage_admin;
set role supabase_storage_admin;

create table if not exists storage.buckets (
  id text primary key,
  name text not null unique,
  public boolean not null default false,
  file_size_limit bigint,
  allowed_mime_types text[]
);

create table if not exists storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text not null references storage.buckets(id),
  name text not null,
  owner_id text,
  metadata jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(bucket_id,name)
);
alter table storage.objects enable row level security;
grant select on storage.buckets to anon,authenticated;
grant select on storage.objects to anon,authenticated;
grant insert,update,delete on storage.objects to authenticated;

create or replace function storage.foldername(name text)
returns text[] language sql immutable set search_path=pg_catalog as $$
  select (string_to_array(name,'/'))[1:greatest(array_length(string_to_array(name,'/'),1)-1,0)];
$$;

create or replace function storage.extension(name text)
returns text language sql immutable set search_path=pg_catalog as $$
  select lower(nullif(regexp_replace(name,'^.*[.]','','g'),name));
$$;
reset role;

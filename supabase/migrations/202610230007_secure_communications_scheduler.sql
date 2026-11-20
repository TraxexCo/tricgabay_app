-- Authenticate scheduled Edge calls at both layers: Supabase's JWT gateway
-- receives the public anonymous client token, while the function also requires
-- the independent private scheduler token stored in a server-only table.
create or replace function public.invoke_communications_dispatcher()
returns bigint
language plpgsql
security definer
set search_path=public,extensions
as $$
declare
  scheduler_token text;
  request_id bigint;
  gateway_anon_key text;
  worker_url text;
begin
  select decrypted_secret into gateway_anon_key from vault.decrypted_secrets where name='tric_gabay_anon_key' order by created_at desc limit 1;
  select decrypted_secret into worker_url from vault.decrypted_secrets where name='tric_gabay_dispatcher_url' order by created_at desc limit 1;
  if gateway_anon_key is null or worker_url is null then return null; end if;
  if worker_url !~ '^https://[a-z0-9-]+[.]supabase[.]co/functions/v1/dispatch-communications$' then raise exception 'Invalid communications worker URL'; end if;
  select token into scheduler_token
  from public.internal_scheduler_tokens
  where name='communications';

  select net.http_post(
    url:=worker_url,
    headers:=jsonb_build_object(
      'Content-Type','application/json',
      'apikey',gateway_anon_key,
      'Authorization','Bearer '||gateway_anon_key,
      'x-tricgabay-scheduler',scheduler_token
    ),
    body:='{"limit":50}'::jsonb,
    timeout_milliseconds:=20000
  ) into request_id;
  return request_id;
end;
$$;
revoke all on function public.invoke_communications_dispatcher() from public,anon,authenticated;

select cron.schedule(
  'tric-gabay-communications',
  '* * * * *',
  'select public.invoke_communications_dispatcher();'
)
where not exists(select 1 from cron.job where jobname='tric-gabay-communications');

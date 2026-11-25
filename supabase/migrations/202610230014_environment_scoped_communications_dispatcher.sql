-- Never let a local or copied database call a hard-coded hosted project.
-- Each environment must explicitly provide its own dispatcher URL and public
-- gateway key in Supabase Vault. Missing configuration is a safe no-op.
create or replace function public.invoke_communications_dispatcher()
returns bigint
language plpgsql
security definer
set search_path=public,extensions
as $$
declare
  scheduler_token text;
  dispatcher_url text;
  gateway_anon_key text;
  request_id bigint;
begin
  select decrypted_secret into dispatcher_url
  from vault.decrypted_secrets
  where name='tric_gabay_communications_url'
  order by created_at desc
  limit 1;

  select decrypted_secret into gateway_anon_key
  from vault.decrypted_secrets
  where name='tric_gabay_anon_key'
  order by created_at desc
  limit 1;

  if dispatcher_url is null or gateway_anon_key is null then
    return null;
  end if;

  if dispatcher_url !~ '^https://[a-z0-9-]+[.]supabase[.]co/functions/v1/dispatch-communications$'
     or length(gateway_anon_key)<20 then
    raise exception 'Communications dispatcher Vault configuration is invalid';
  end if;

  select token into scheduler_token
  from public.internal_scheduler_tokens
  where name='communications';

  select net.http_post(
    url:=dispatcher_url,
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

revoke all on function public.invoke_communications_dispatcher()
  from public,anon,authenticated;
grant execute on function public.invoke_communications_dispatcher()
  to service_role;

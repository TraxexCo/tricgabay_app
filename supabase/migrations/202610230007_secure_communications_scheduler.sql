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
  gateway_anon_key constant text := 'REDACTED';
begin
  select token into scheduler_token
  from public.internal_scheduler_tokens
  where name='communications';

  select net.http_post(
    url:='https://xcsrjuqzwequmeqzedzd.supabase.co/functions/v1/dispatch-communications',
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

-- LOCAL FILE ONLY: NOT applied/tested against a real database.
create function public.get_client_configuration() returns jsonb language sql stable security definer set search_path=public as $$
  select jsonb_build_object('minimum_android_build',minimum_android_build,'update_url',update_url,
    'server_time',statement_timestamp()) from public.service_configuration where singleton
$$;
revoke all on function public.get_client_configuration() from public;
grant execute on function public.get_client_configuration() to anon,authenticated;

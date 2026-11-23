-- Admins can close an operational alert once they have dealt with it, and
-- service-health alerts close themselves when the problem is gone. Without
-- this the dashboard banner never cleared.

create or replace function public.resolve_operational_alert(p_alert_id uuid)
returns void language plpgsql security definer set search_path=public as $$
begin
  if not public.has_admin_capability('operations') then
    raise exception 'Operations capability required' using errcode='42501';
  end if;
  update public.operational_alerts
     set resolved_at=now(), resolved_by=auth.uid()
   where id=p_alert_id and resolved_at is null;
end $$;
revoke all on function public.resolve_operational_alert(uuid) from public,anon;
grant execute on function public.resolve_operational_alert(uuid) to authenticated;

create or replace function public.collect_operations_health() returns jsonb
language plpgsql security definer set search_path=public as $$
declare metric record; result jsonb;
begin
  if coalesce(auth.role(),'')<>'service_role' then raise exception 'Service role required' using errcode='42501'; end if;
  perform public.monitor_checkout_expiries();
  for metric in select * from public.operations_health where value>0 loop
    perform public.raise_operational_alert('critical','health','health:'||metric.metric,
      'Service health needs attention',metric.metric||' requires review.',jsonb_build_object('metric',metric.metric,'count',metric.value));
  end loop;
  -- Close health alerts whose metric is back to zero.
  update public.operational_alerts a
     set resolved_at=now()
   where a.resolved_at is null
     and a.category='health'
     and not exists(
       select 1 from public.operations_health h
        where h.value>0 and a.dedupe_key='health:'||h.metric);
  select jsonb_object_agg(h.metric,h.value) into result from public.operations_health h;
  return result;
end $$;
revoke all on function public.collect_operations_health() from public,anon,authenticated;
grant execute on function public.collect_operations_health() to service_role;

-- Tourists booking "now" had no way to know that nobody could take the trip:
-- the request simply waited for offers to expire. This returns only a count
-- of approved, compliant drivers who are online, so the booking review can
-- warn before the tourist sends the request. No driver details are exposed.

create or replace function public.count_online_drivers()
returns integer
language sql
stable
security definer
set search_path to 'public'
as $$
  select count(*)::integer
  from public.driver_profiles d
  where d.is_online
    and cardinality(public.driver_compliance_issues(d.profile_id)) = 0;
$$;

revoke all on function public.count_online_drivers() from public, anon;
grant execute on function public.count_online_drivers() to authenticated;

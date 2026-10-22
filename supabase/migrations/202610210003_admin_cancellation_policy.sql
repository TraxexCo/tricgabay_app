-- Administrators publish immutable cancellation-policy revisions.
-- Existing bookings keep their original policy id.

alter table public.cancellation_policies
  add column if not exists change_reason text not null default 'Published policy';

create or replace function public.publish_cancellation_policy(
  p_expected_version integer,
  p_free_cancellation_minutes integer,
  p_accepted_trip_fee_percent integer,
  p_driver_wait_minutes integer,
  p_no_show_fee_percent integer,
  p_terms text,
  p_reason text
) returns public.cancellation_policies
language plpgsql
security definer
set search_path=public
as $$
declare
  current_policy public.cancellation_policies;
  published public.cancellation_policies;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  if p_free_cancellation_minutes not between 0 and 120 then raise exception 'Grace period must be between 0 and 120 minutes'; end if;
  if p_accepted_trip_fee_percent not between 0 and 100 then raise exception 'Cancellation fee must be between 0 and 100 percent'; end if;
  if p_driver_wait_minutes not between 1 and 120 then raise exception 'Driver wait must be between 1 and 120 minutes'; end if;
  if p_no_show_fee_percent not between 0 and 100 then raise exception 'No-show fee must be between 0 and 100 percent'; end if;
  if length(trim(p_terms))<20 then raise exception 'Policy terms must clearly explain the rule'; end if;
  if length(trim(p_reason))<5 then raise exception 'A change reason is required'; end if;

  select * into current_policy from public.cancellation_policies
    where is_current for update;
  if current_policy.id is null or current_policy.version<>p_expected_version then
    raise exception 'The policy changed while you were editing';
  end if;
  update public.cancellation_policies set is_current=false where id=current_policy.id;
  insert into public.cancellation_policies(
    is_current,free_cancellation_minutes,accepted_trip_fee_percent,
    driver_wait_minutes,no_show_fee_percent,terms,change_reason,created_by
  ) values (
    true,p_free_cancellation_minutes,p_accepted_trip_fee_percent,
    p_driver_wait_minutes,p_no_show_fee_percent,trim(p_terms),trim(p_reason),auth.uid()
  ) returning * into published;
  return published;
end;
$$;

revoke all on function public.publish_cancellation_policy(
  integer,integer,integer,integer,integer,text,text
) from public;
grant execute on function public.publish_cancellation_policy(
  integer,integer,integer,integer,integer,text,text
) to authenticated;

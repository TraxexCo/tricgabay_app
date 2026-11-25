-- Scheduled activation is an operations job, not a mobile-client action.
-- pg_cron invokes it as the database owner; service_role retains an explicit
-- recovery path for controlled operations tooling.
revoke all on function public.activate_due_scheduled_bookings()
  from public, anon, authenticated;
grant execute on function public.activate_due_scheduled_bookings()
  to service_role;

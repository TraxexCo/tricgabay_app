-- Phone notifications (booking cancelled, driver found, trip updates...)
-- waited for the once-a-minute communications job, so they could arrive up
-- to a minute late. Ask the dispatcher to send as soon as deliveries are
-- queued, as ride offers already do (20261121041257). pg_net sends the
-- request after the transaction commits, so the worker sees the new rows.
-- One request per statement, not per row; any failure is ignored so the
-- user's action never fails because of messaging, and the minute job stays
-- as the fallback for retries.
create or replace function public.dispatch_queued_messages_now()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  begin
    perform public.invoke_communications_dispatcher();
  exception when others then
    null;
  end;
  return null;
end;
$$;

revoke all on function public.dispatch_queued_messages_now() from public, anon, authenticated;

drop trigger if exists message_deliveries_dispatch_now on public.message_deliveries;
create trigger message_deliveries_dispatch_now
  after insert on public.message_deliveries
  for each statement
  execute function public.dispatch_queued_messages_now();

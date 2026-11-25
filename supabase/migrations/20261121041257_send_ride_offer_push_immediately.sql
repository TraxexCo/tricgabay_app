-- A ride offer lasts two minutes, but the communications job runs once a
-- minute. Ask the dispatcher to send right away; pg_net queues the request
-- and sends it after commit. Any failure is ignored so the booking itself
-- never fails because of messaging; the minute job is still the fallback.
create or replace function public.notify_driver_of_ride_offer()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if new.status = 'offered' then
    insert into public.notifications(recipient_id, title, body, route_path, booking_id)
    values (
      new.driver_id,
      'New ride request',
      'A tourist nearby wants a tour. Open Tric-Gabay to accept before the offer expires.',
      '/driver/incoming/' || new.booking_id,
      new.booking_id
    );
    begin
      perform public.invoke_communications_dispatcher();
    exception when others then
      null;
    end;
  end if;
  return new;
end;
$$;

revoke all on function public.notify_driver_of_ride_offer() from public, anon, authenticated;

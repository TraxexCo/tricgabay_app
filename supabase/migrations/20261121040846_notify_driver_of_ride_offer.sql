-- Drivers were never told about a new ride offer: tourists get "Booking
-- confirmed" and "Driver found", but an offer reached the driver only if the
-- Jobs screen happened to be open, and it expires after two minutes.
-- A notification row is enough: notifications_enqueue_delivery turns it into
-- a push message, and /driver/incoming/<booking id> is an allowed deep link.

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
  end if;
  return new;
end;
$$;

revoke all on function public.notify_driver_of_ride_offer() from public, anon, authenticated;

create trigger booking_offers_notify_driver
  after insert on public.booking_offers
  for each row execute function public.notify_driver_of_ride_offer();

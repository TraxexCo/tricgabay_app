-- 20261125010000 expired scheduled bookings whose start time had passed. An
-- immediate booking (no scheduled_at) has the same problem: when its 10-minute
-- driver search window (dispatch_expires_at) ends without a driver it stays
-- `pending` for ever and keeps the tourist's single live booking slot.
-- Example: TRIC-ADC02BB8DF7249EF, created 2026-11-11, still pending.
--
-- expire_stale_pending_bookings() now also cancels a pending booking with no
-- driver and no scheduled_at once its dispatch_expires_at is more than 30
-- minutes in the past. The cancel rules, the system-actor booking_cancelled
-- event and the cron job (every five minutes) are the same as for scheduled
-- bookings. Accepted, replacement_pending, ongoing and completed bookings are
-- never touched, and neither is a pending booking whose search window is still
-- open or ended less than 30 minutes ago.
--
-- The 30-minute grace is also how long a tourist can still use "search again"
-- (retry_booking_dispatch) on an expired immediate booking.

create or replace function public.expire_stale_pending_bookings()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  stale record;
  paid integer;
  expired integer := 0;
begin
  for stale in
    select id, scheduled_at, dispatch_expires_at
    from public.bookings
    where status = 'pending'
      and driver_id is null
      and (
        -- scheduled: the tour start is more than 30 minutes behind us
        (scheduled_at is not null and scheduled_at < now() - interval '30 minutes')
        -- immediate: the driver search ended more than 30 minutes ago
        or (scheduled_at is null and dispatch_expires_at < now() - interval '30 minutes')
      )
    order by coalesce(scheduled_at, dispatch_expires_at), id
    for update skip locked
  loop
    update public.booking_offers
      set status = 'expired', responded_at = coalesce(responded_at, now())
      where booking_id = stale.id and status = 'offered';

    select coalesce(sum(amount_centavos), 0) into paid
      from public.payments
      where booking_id = stale.id and status in ('paid', 'cash_paid');

    update public.bookings
      set status = 'cancelled',
          completed_at = now(),
          cancelled_by = null,
          cancellation_reason = case
            when stale.scheduled_at is not null
              then 'No driver accepted before the scheduled start'
            else 'No driver accepted during the driver search' end,
          final_charge_centavos = 0,
          payment_status = case
            when paid > 0 then 'refund_required'::public.payment_status
            else 'waived'::public.payment_status end,
          arrival_pending = false
      where id = stale.id and status = 'pending' and driver_id is null;

    insert into public.trip_events(booking_id, actor_id, actor_role, event_type, description, metadata)
    values (
      stale.id, null, null, 'booking_cancelled',
      case when stale.scheduled_at is not null
        then 'Booking expired: no driver accepted before the scheduled start.'
        else 'Booking expired: no driver accepted during the driver search.' end,
      jsonb_build_object(
        'actor', 'system',
        'reason', case when stale.scheduled_at is not null
          then 'scheduled_start_passed' else 'dispatch_window_expired' end,
        'scheduled_at', stale.scheduled_at,
        'dispatch_expires_at', stale.dispatch_expires_at,
        'final_charge_centavos', 0
      )
    );
    expired := expired + 1;
  end loop;
  return expired;
end;
$$;

-- create or replace keeps the existing grants (service_role only); state them
-- anyway so the migration is self-describing.
revoke all on function public.expire_stale_pending_bookings() from public, anon, authenticated;
grant execute on function public.expire_stale_pending_bookings() to service_role;

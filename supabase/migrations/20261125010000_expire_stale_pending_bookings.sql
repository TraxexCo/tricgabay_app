-- A scheduled tour that nobody accepted stayed `pending` for ever once its start
-- time had passed. The driver search window (dispatch_expires_at) only stops
-- drivers from accepting; the booking itself kept the tourist's single live
-- booking slot, so every new booking failed with "Finish or cancel the active
-- booking first". Example: TRIC-FA829F3B45514B80, scheduled 2026-11-23 08:00
-- Manila, still pending two days later.
--
-- This cancels a pending booking that has no driver once its scheduled start
-- is more than 30 minutes behind us. Accepted, replacement_pending, ongoing and
-- completed bookings are never touched. The cancellation follows the existing
-- free-cancellation rules (cancel_booking on a pending booking): no charge,
-- 'waived' unless money was already paid, in which case 'refund_required'.
--
-- The trip event has no account behind it (actor_id and actor_role are null, as
-- for scheduled_dispatch_started) and carries metadata.actor = 'system'. The
-- existing booking_cancelled event trigger sends the tourist their notification.

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
    select id, scheduled_at
    from public.bookings
    where status = 'pending'
      and driver_id is null
      and scheduled_at is not null
      and scheduled_at < now() - interval '30 minutes'
    order by scheduled_at, id
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
          cancellation_reason = 'No driver accepted before the scheduled start',
          final_charge_centavos = 0,
          payment_status = case
            when paid > 0 then 'refund_required'::public.payment_status
            else 'waived'::public.payment_status end,
          arrival_pending = false
      where id = stale.id and status = 'pending' and driver_id is null;

    insert into public.trip_events(booking_id, actor_id, actor_role, event_type, description, metadata)
    values (
      stale.id, null, null, 'booking_cancelled',
      'Booking expired: no driver accepted before the scheduled start.',
      jsonb_build_object(
        'actor', 'system',
        'reason', 'scheduled_start_passed',
        'scheduled_at', stale.scheduled_at,
        'final_charge_centavos', 0
      )
    );
    expired := expired + 1;
  end loop;
  return expired;
end;
$$;

revoke all on function public.expire_stale_pending_bookings() from public, anon, authenticated;
grant execute on function public.expire_stale_pending_bookings() to service_role;

-- Same cadence as activate_due_scheduled_bookings (every five minutes).
select cron.schedule(
  'tric-gabay-expire-stale-pending-bookings',
  '*/5 * * * *',
  'select public.expire_stale_pending_bookings()'
);

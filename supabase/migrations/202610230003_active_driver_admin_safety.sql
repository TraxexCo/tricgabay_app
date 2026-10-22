-- Administrative driver action must never strand an accepted or ongoing tour.

create or replace function public.admin_set_driver_status(
  p_driver_id uuid,
  p_status public.driver_approval_status,
  p_reason text default null,
  p_blocked_until timestamptz default null
) returns void
language plpgsql
security definer
set search_path=public
as $$
declare
  b public.bookings;
  reason text := trim(coalesce(p_reason,''));
begin
  if not public.is_admin() then raise exception 'Administrator access required'; end if;
  if p_status='approved' then raise exception 'Use the compliance review to approve a driver'; end if;
  if p_status in ('rejected','suspended') and length(reason)<5 then
    raise exception 'Provide a clear reason';
  end if;
  select * into b from public.bookings
    where driver_id=p_driver_id
      and status in ('accepted','replacement_pending','ongoing')
    order by created_at desc limit 1 for update;

  if b.id is not null and b.status='ongoing' then
    update public.bookings set
      status='cancelled',completed_at=now(),cancelled_by=auth.uid(),
      cancellation_reason='Administrator ended the trip for safety review: '||reason,
      final_charge_centavos=null,payment_status='under_review',arrival_pending=false
    where id=b.id;
    insert into public.disputes(booking_id,opened_by,reason)
    values(
      b.id,auth.uid(),
      'Administrator ended an ongoing trip after a driver status action: '||reason
    );
    insert into public.trip_events(
      booking_id,actor_id,actor_role,event_type,description,metadata
    ) values (
      b.id,auth.uid(),'admin','admin_safety_stop',
      'Administrator safely ended the trip and opened payment review.',
      jsonb_build_object('driver_id',p_driver_id,'reason',reason)
    );
    insert into public.notifications(
      recipient_id,booking_id,title,body,route_path,category,send_email
    ) values (
      b.tourist_id,b.id,'Trip paused for safety review',
      'The driver became unavailable. The trip ended safely and payment is on hold for administrator review.',
      '/tourist/bookings/'||b.id,'safety',true
    );
  elsif b.id is not null then
    update public.bookings set
      status='replacement_pending',replacement_requested_at=now(),
      replacement_reason='Administrator made the assigned driver unavailable: '||reason,
      replacement_requested_by=auth.uid(),arrival_pending=false
    where id=b.id;
    update public.booking_offers set status='withdrawn',responded_at=now()
      where booking_id=b.id and status='offered';
    insert into public.trip_events(
      booking_id,actor_id,actor_role,event_type,description,metadata
    ) values (
      b.id,auth.uid(),'admin','admin_driver_unavailable',
      'Assigned driver became unavailable before pickup; tourist decision required.',
      jsonb_build_object('driver_id',p_driver_id,'reason',reason)
    );
    insert into public.notifications(
      recipient_id,booking_id,title,body,route_path,category,send_email
    ) values (
      b.tourist_id,b.id,'Choose a replacement or cancel',
      'Your assigned driver became unavailable. Choose another verified driver or cancel without charge.',
      '/tourist/bookings/'||b.id,'driver',true
    );
  end if;

  update public.driver_profiles set
    approval_status=p_status,is_online=false,
    matching_blocked_reason=nullif(reason,''),
    matching_blocked_until=case when p_status='suspended' then p_blocked_until else null end,
    compliance_reviewed_by=auth.uid(),compliance_reviewed_at=now()
  where profile_id=p_driver_id;
  if not found then raise exception 'Driver profile not found'; end if;
  update public.profiles set status=case p_status
    when 'pending' then 'pending'::public.account_status
    when 'rejected' then 'rejected'::public.account_status
    else 'suspended'::public.account_status end
  where id=p_driver_id;
  insert into public.notifications(recipient_id,title,body,route_path)
  values(
    p_driver_id,'Driver account update',
    coalesce(nullif(reason,''),'Your driver account status was updated.'),
    '/driver/account'
  );
end;
$$;
revoke all on function public.admin_set_driver_status(
  uuid,public.driver_approval_status,text,timestamptz
) from public;
grant execute on function public.admin_set_driver_status(
  uuid,public.driver_approval_status,text,timestamptz
) to authenticated;

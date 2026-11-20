-- Renaming the original administrator functions preserved historical ACLs,
-- including an explicit anon grant. Restrict both implementation functions
-- and their capability-checking wrappers to the minimum application roles.
revoke all on function public._publish_fares_admin_impl(integer,jsonb,text)
  from public,anon,authenticated;
revoke all on function public._publish_cancellation_policy_admin_impl(integer,integer,integer,integer,integer,text,text)
  from public,anon,authenticated;
revoke all on function public._resolve_booking_charge_admin_impl(uuid,integer,text)
  from public,anon,authenticated;
revoke all on function public._complete_paymongo_test_refund_admin_impl(uuid,integer,text)
  from public,anon,authenticated;
revoke all on function public._admin_review_driver_compliance_impl(uuid,date,date,date,text,double precision,double precision,numeric,boolean,text)
  from public,anon,authenticated;
revoke all on function public._admin_set_driver_status_impl(uuid,public.driver_approval_status,text,timestamptz)
  from public,anon,authenticated;
revoke all on function public._set_spot_availability_admin_impl(text,text,text,timestamptz)
  from public,anon,authenticated;
revoke all on function public._send_announcement_admin_impl(text,text)
  from public,anon,authenticated;

revoke all on function public.publish_fares(integer,jsonb,text) from public,anon;
revoke all on function public.publish_cancellation_policy(integer,integer,integer,integer,integer,text,text) from public,anon;
revoke all on function public.resolve_booking_charge(uuid,integer,text) from public,anon;
revoke all on function public.complete_paymongo_test_refund(uuid,integer,text) from public,anon;
revoke all on function public.admin_review_driver_compliance(uuid,date,date,date,text,double precision,double precision,numeric,boolean,text) from public,anon;
revoke all on function public.admin_set_driver_status(uuid,public.driver_approval_status,text,timestamptz) from public,anon;
revoke all on function public.set_spot_availability(text,text,text,timestamptz) from public,anon;
revoke all on function public.send_announcement(text,text) from public,anon;

grant execute on function public.publish_fares(integer,jsonb,text) to authenticated;
grant execute on function public.publish_cancellation_policy(integer,integer,integer,integer,integer,text,text) to authenticated;
grant execute on function public.resolve_booking_charge(uuid,integer,text) to authenticated;
grant execute on function public.complete_paymongo_test_refund(uuid,integer,text) to authenticated;
grant execute on function public.admin_review_driver_compliance(uuid,date,date,date,text,double precision,double precision,numeric,boolean,text) to authenticated;
grant execute on function public.admin_set_driver_status(uuid,public.driver_approval_status,text,timestamptz) to authenticated;
grant execute on function public.set_spot_availability(text,text,text,timestamptz) to authenticated;
grant execute on function public.send_announcement(text,text) to authenticated;

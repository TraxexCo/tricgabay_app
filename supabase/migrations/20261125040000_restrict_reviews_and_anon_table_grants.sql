-- Security hardening found in the pre-release audit.
--
-- 1. booking_reviews was readable by everyone (policy reviews_read USING (true)),
--    so the public anon key could list every review together with tourist_id,
--    booking_id and driver_id. The app only ever reads a review through its own
--    booking (the bookings query embeds booking_reviews(rating,review)), and
--    driver ratings come from driver_profiles, so reviews no longer need to be
--    public.
--
--    Who can read a review now: the tourist who wrote it, the driver it is about,
--    and operations, finance or support admins (super_admin counts as all of
--    them) - the same people who can read the booking and its trip events.
--    Anyone else, and the anon role, gets nothing. Writing is unchanged:
--    submit_driver_review() (SECURITY DEFINER) is the only way to add a review.
--
-- 2. anon held TRUNCATE, TRIGGER and REFERENCES on public tables (the Supabase
--    default grants). RLS does not apply to TRUNCATE, and none of the three is
--    ever needed by an API caller. They are revoked from anon on every existing
--    table and from the default privileges of tables created later.
--    SELECT, INSERT, UPDATE and DELETE grants are left to RLS as before, and
--    rls_auto_enable() is not touched.

-- 1. Reviews -----------------------------------------------------------------
drop policy if exists reviews_read on public.booking_reviews;
create policy reviews_participant_capability_read on public.booking_reviews
  for select to authenticated
  using (
    tourist_id = auth.uid()
    or driver_id = auth.uid()
    or public.has_admin_capability('operations')
    or public.has_admin_capability('finance')
    or public.has_admin_capability('support')
  );
-- The policy above already hides every row from anon; remove the privilege too,
-- so an anonymous request is refused outright instead of returning no rows.
revoke all on public.booking_reviews from anon;

-- 2. Unneeded anon table privileges -------------------------------------------
revoke truncate, trigger, references on all tables in schema public from anon;

-- Tables created from now on. Migrations run as postgres, so that is the role
-- whose defaults apply. supabase_admin (the dashboard) has its own defaults,
-- which only that role - or a superuser - may change, so a failure there is
-- reported rather than treated as an error.
alter default privileges for role postgres in schema public
  revoke truncate, trigger, references on tables from anon;
do $$
begin
  execute 'alter default privileges for role supabase_admin in schema public
           revoke truncate, trigger, references on tables from anon';
exception
  when insufficient_privilege or undefined_object then
    raise notice 'Default privileges of supabase_admin were left unchanged: %', sqlerrm;
end $$;

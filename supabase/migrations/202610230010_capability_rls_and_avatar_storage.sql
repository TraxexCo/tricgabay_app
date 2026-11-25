-- P1 remediation: align public-table and Storage RLS with the existing
-- administrator capability model. Participant ownership remains unchanged.

drop policy if exists profiles_self_or_admin_read on public.profiles;
create policy profiles_self_or_capability_read on public.profiles
for select to authenticated using (
  id=auth.uid()
  or public.has_admin_capability('support')
  or public.has_admin_capability('driver_compliance')
  or public.has_admin_capability('operations')
  or public.has_admin_capability('finance')
);

drop policy if exists drivers_self_or_admin_read on public.driver_profiles;
create policy drivers_self_or_capability_read on public.driver_profiles
for select to authenticated using (
  profile_id=auth.uid()
  or public.has_admin_capability('driver_compliance')
  or public.has_admin_capability('operations')
);

drop policy if exists public_spots_read on public.tourist_spots;
create policy public_spots_read on public.tourist_spots
for select using (is_active or public.has_admin_capability('content'));

drop policy if exists public_packages_read on public.tour_packages;
create policy public_packages_read on public.tour_packages
for select using (is_active or public.has_admin_capability('content'));

drop policy if exists bookings_participant_read on public.bookings;
create policy bookings_participant_capability_read on public.bookings
for select to authenticated using (
  tourist_id=auth.uid()
  or driver_id=auth.uid()
  or public.has_admin_capability('operations')
  or public.has_admin_capability('finance')
  or public.has_admin_capability('support')
  or (status='pending' and public.has_active_booking_offer(id,auth.uid()))
);

drop policy if exists stops_participant_read on public.booking_stops;
create policy stops_participant_capability_read on public.booking_stops
for select to authenticated using (
  exists(
    select 1 from public.bookings b where b.id=booking_id and (
      b.tourist_id=auth.uid()
      or b.driver_id=auth.uid()
      or public.has_admin_capability('operations')
      or public.has_admin_capability('finance')
      or public.has_admin_capability('support')
      or (b.status='pending' and public.has_active_booking_offer(b.id,auth.uid()))
    )
  )
);

drop policy if exists events_participant_read on public.trip_events;
create policy events_participant_capability_read on public.trip_events
for select to authenticated using (
  exists(
    select 1 from public.bookings b where b.id=booking_id and (
      b.tourist_id=auth.uid()
      or b.driver_id=auth.uid()
      or public.has_admin_capability('operations')
      or public.has_admin_capability('finance')
      or public.has_admin_capability('support')
    )
  )
);

drop policy if exists current_location_read on public.driver_locations;
create policy current_location_participant_operations_read on public.driver_locations
for select to authenticated using (
  driver_id=auth.uid()
  or public.has_admin_capability('operations')
  or exists(
    select 1 from public.bookings b
    where b.driver_id=driver_id and b.tourist_id=auth.uid()
      and b.status in ('accepted','ongoing')
  )
);

drop policy if exists history_participant_read on public.driver_location_history;
create policy history_participant_operations_read on public.driver_location_history
for select to authenticated using (
  driver_id=auth.uid()
  or public.has_admin_capability('operations')
  or exists(
    select 1 from public.bookings b
    where b.id=booking_id and b.tourist_id=auth.uid()
  )
);

drop policy if exists payments_participant_read on public.payments;
create policy payments_participant_finance_read on public.payments
for select to authenticated using (
  public.has_admin_capability('finance')
  or exists(
    select 1 from public.bookings b where b.id=booking_id
      and (b.tourist_id=auth.uid() or b.driver_id=auth.uid())
  )
);

drop policy if exists refunds_participant_read on public.refunds;
create policy refunds_participant_finance_read on public.refunds
for select to authenticated using (
  public.has_admin_capability('finance')
  or requested_by=auth.uid()
  or exists(
    select 1 from public.bookings b where b.id=booking_id
      and (b.tourist_id=auth.uid() or b.driver_id=auth.uid())
  )
);

drop policy if exists disputes_participant_read on public.disputes;
create policy disputes_participant_finance_read on public.disputes
for select to authenticated using (
  public.has_admin_capability('finance')
  or opened_by=auth.uid()
  or exists(
    select 1 from public.bookings b where b.id=booking_id
      and (b.tourist_id=auth.uid() or b.driver_id=auth.uid())
  )
);

drop policy if exists ledger_participant_read on public.financial_ledger_entries;
create policy ledger_participant_finance_read on public.financial_ledger_entries
for select to authenticated using (
  public.has_admin_capability('finance')
  or exists(
    select 1 from public.bookings b where b.id=booking_id
      and (b.tourist_id=auth.uid() or b.driver_id=auth.uid())
  )
);

drop policy if exists feedback_self_admin_read on public.feedback;
create policy feedback_self_support_read on public.feedback
for select to authenticated using (
  author_id=auth.uid() or public.has_admin_capability('support')
);

drop policy if exists cash_participant_read on public.cash_confirmations;
create policy cash_participant_finance_read on public.cash_confirmations
for select to authenticated using (
  actor_id=auth.uid()
  or public.has_admin_capability('finance')
  or exists(
    select 1 from public.bookings b where b.id=booking_id
      and (b.tourist_id=auth.uid() or b.driver_id=auth.uid())
  )
);

drop policy if exists dispute_statements_participant_read on public.dispute_statements;
create policy dispute_statements_participant_capability_read on public.dispute_statements
for select to authenticated using (
  author_id=auth.uid()
  or public.has_admin_capability('finance')
  or public.has_admin_capability('support')
  or exists(
    select 1 from public.disputes d
    join public.bookings b on b.id=d.booking_id
    where d.id=dispute_id
      and (b.tourist_id=auth.uid() or b.driver_id=auth.uid())
  )
);

drop policy if exists booking_offers_participant_read on public.booking_offers;
create policy booking_offers_participant_operations_read on public.booking_offers
for select to authenticated using (
  driver_id=auth.uid()
  or public.has_admin_capability('operations')
  or exists(
    select 1 from public.bookings b
    where b.id=booking_id and b.tourist_id=auth.uid()
  )
);

drop policy if exists route_changes_participant_read on public.booking_route_changes;
create policy route_changes_participant_operations_read on public.booking_route_changes
for select to authenticated using (
  requested_by=auth.uid()
  or public.has_admin_capability('operations')
  or exists(
    select 1 from public.bookings b where b.id=booking_id
      and (b.tourist_id=auth.uid() or b.driver_id=auth.uid())
  )
);

drop policy if exists message_deliveries_admin_read on public.message_deliveries;
create policy message_deliveries_operations_read on public.message_deliveries
for select to authenticated using (public.has_admin_capability('operations'));

-- Compliance documents are private. Drivers retain access to their own folder;
-- only compliance-capable administrators may inspect other drivers' files.
drop policy if exists driver_documents_read_own_admin on storage.objects;
create policy driver_documents_read_own_compliance on storage.objects
for select to authenticated using (
  bucket_id='driver-documents' and (
    (storage.foldername(name))[1]=auth.uid()::text
    or public.has_admin_capability('driver_compliance')
  )
);

-- Public attraction and brand files remain publicly readable, but only content
-- administrators may create, replace, or remove them.
drop policy if exists spot_images_admin_write on storage.objects;
create policy spot_images_content_insert on storage.objects
for insert to authenticated with check (
  bucket_id='tourist-spots' and public.has_admin_capability('content')
);
create policy spot_images_content_update on storage.objects
for update to authenticated using (
  bucket_id='tourist-spots' and public.has_admin_capability('content')
) with check (
  bucket_id='tourist-spots' and public.has_admin_capability('content')
);
create policy spot_images_content_delete on storage.objects
for delete to authenticated using (
  bucket_id='tourist-spots' and public.has_admin_capability('content')
);

drop policy if exists app_assets_admin_insert on storage.objects;
drop policy if exists app_assets_admin_update on storage.objects;
create policy app_assets_content_insert on storage.objects
for insert to authenticated with check (
  bucket_id='app-assets' and public.has_admin_capability('content')
);
create policy app_assets_content_update on storage.objects
for update to authenticated using (
  bucket_id='app-assets' and public.has_admin_capability('content')
) with check (
  bucket_id='app-assets' and public.has_admin_capability('content')
);
create policy app_assets_content_delete on storage.objects
for delete to authenticated using (
  bucket_id='app-assets' and public.has_admin_capability('content')
);

-- Avatars are private account data in this build. The deterministic path is
-- exact, so upsert cannot be used to create arbitrary objects in the bucket.
update storage.buckets set public=false where id='profile-images';
drop policy if exists profile_images_public_read on storage.objects;
drop policy if exists profile_images_own_write on storage.objects;
create policy profile_images_own_read on storage.objects
for select to authenticated using (
  bucket_id='profile-images' and name=auth.uid()::text||'/avatar.jpg'
);
create policy profile_images_own_insert on storage.objects
for insert to authenticated with check (
  bucket_id='profile-images' and name=auth.uid()::text||'/avatar.jpg'
);
create policy profile_images_own_update on storage.objects
for update to authenticated using (
  bucket_id='profile-images' and name=auth.uid()::text||'/avatar.jpg'
) with check (
  bucket_id='profile-images' and name=auth.uid()::text||'/avatar.jpg'
);
create policy profile_images_own_delete on storage.objects
for delete to authenticated using (
  bucket_id='profile-images' and name=auth.uid()::text||'/avatar.jpg'
);


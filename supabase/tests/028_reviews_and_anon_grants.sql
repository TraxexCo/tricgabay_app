-- Reviews are no longer public, and anon no longer holds TRUNCATE, TRIGGER or
-- REFERENCES on public tables. What the app needs still works: a tourist and the
-- driver read their own review, operations/finance/support admins read all.
begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select plan(27);

-- Fixtures: three tourists, two drivers, three admins.
insert into auth.users(id, email, raw_user_meta_data) values
  ('e5280000-0000-4000-8000-000000000001', 'rev-tourist-a@example.test', '{"full_name":"Tourist A"}'),
  ('e5280000-0000-4000-8000-000000000002', 'rev-tourist-b@example.test', '{"full_name":"Tourist B"}'),
  ('e5280000-0000-4000-8000-000000000003', 'rev-tourist-c@example.test', '{"full_name":"Tourist C"}'),
  ('e5280000-0000-4000-8000-000000000004', 'rev-driver-a@example.test', '{"full_name":"Driver A","requested_role":"driver"}'),
  ('e5280000-0000-4000-8000-000000000005', 'rev-driver-b@example.test', '{"full_name":"Driver B","requested_role":"driver"}'),
  ('e5280000-0000-4000-8000-000000000006', 'rev-admin-ops@example.test', '{"full_name":"Admin ops"}'),
  ('e5280000-0000-4000-8000-000000000007', 'rev-admin-content@example.test', '{"full_name":"Admin content"}'),
  ('e5280000-0000-4000-8000-000000000008', 'rev-admin-support@example.test', '{"full_name":"Admin support"}');
update public.profiles set status = 'active' where id::text like 'e5280000-%';
update public.profiles set role = 'admin'
  where id in ('e5280000-0000-4000-8000-000000000006', 'e5280000-0000-4000-8000-000000000007', 'e5280000-0000-4000-8000-000000000008');
insert into public.admin_capabilities(profile_id, capability) values
  ('e5280000-0000-4000-8000-000000000006', 'operations'),
  ('e5280000-0000-4000-8000-000000000007', 'content'),
  ('e5280000-0000-4000-8000-000000000008', 'support');
insert into public.driver_profiles(profile_id, plate_number, franchise_number, license_document_path,
  vehicle_document_path, approval_status, license_expires_on, franchise_expires_on,
  vehicle_inspection_expires_on, service_area_name, service_area_latitude, service_area_longitude,
  service_area_radius_km, is_online, last_seen_at)
select id, 'REV-' || right(id::text, 2), 'REV-FR-' || right(id::text, 2),
  id::text || '/license.jpg', id::text || '/vehicle.jpg', 'approved',
  current_date + 365, current_date + 365, current_date + 365, 'Review fixture',
  14.9571, 120.9188, 15, false, null
from public.profiles where id::text like 'e5280000-%' and role = 'driver';
insert into public.fare_revisions(id, custom_fare_centavos, reason)
values ('e5280000-0000-4000-8000-0000000000f1', 10000, 'Review fixture');
insert into public.cancellation_policies(id, terms)
values ('e5280000-0000-4000-8000-0000000000f2', 'Review fixture');
-- 101: A with driver A, 102: B with driver B, 103: C with driver A (reviewed later).
insert into public.bookings(id, tourist_id, driver_id, fare_revision_id, cancellation_policy_id,
  quoted_amount_centavos, payment_method, status, pickup_address, pickup_latitude,
  pickup_longitude, pickup_code_hash, accepted_at, started_at, completed_at)
values
  ('e5280000-0000-4000-8000-000000000101', 'e5280000-0000-4000-8000-000000000001', 'e5280000-0000-4000-8000-000000000004',
   'e5280000-0000-4000-8000-0000000000f1', 'e5280000-0000-4000-8000-0000000000f2', 10000, 'cash', 'completed',
   'Review fixture', 14.9571, 120.9188, 'x', now(), now(), now()),
  ('e5280000-0000-4000-8000-000000000102', 'e5280000-0000-4000-8000-000000000002', 'e5280000-0000-4000-8000-000000000005',
   'e5280000-0000-4000-8000-0000000000f1', 'e5280000-0000-4000-8000-0000000000f2', 10000, 'cash', 'completed',
   'Review fixture', 14.9571, 120.9188, 'x', now(), now(), now()),
  ('e5280000-0000-4000-8000-000000000103', 'e5280000-0000-4000-8000-000000000003', 'e5280000-0000-4000-8000-000000000004',
   'e5280000-0000-4000-8000-0000000000f1', 'e5280000-0000-4000-8000-0000000000f2', 10000, 'cash', 'completed',
   'Review fixture', 14.9571, 120.9188, 'x', now(), now(), now());
insert into public.booking_reviews(booking_id, tourist_id, driver_id, rating, review) values
  ('e5280000-0000-4000-8000-000000000101', 'e5280000-0000-4000-8000-000000000001', 'e5280000-0000-4000-8000-000000000004', 5, 'Review A'),
  ('e5280000-0000-4000-8000-000000000102', 'e5280000-0000-4000-8000-000000000002', 'e5280000-0000-4000-8000-000000000005', 4, 'Review B');

-- Structure: nothing public on reviews ---------------------------------------
select is(has_table_privilege('anon', 'public.booking_reviews', 'select'), false,
  'anon has no SELECT on booking_reviews');
select is((select count(*)::integer from pg_policies where schemaname = 'public' and tablename = 'booking_reviews'
  and ('anon' = any(roles) or 'public' = any(roles))), 0, 'no review policy applies to anon or public');

-- anon, as the public key would ---------------------------------------------
select set_config('request.jwt.claim.role', 'anon', true);
select set_config('request.jwt.claim.sub', '', true);
set local role anon;
select throws_ok($$select tourist_id from public.booking_reviews$$, '42501', null, 'anon cannot read tourist_id');
select throws_ok($$select booking_id from public.booking_reviews$$, '42501', null, 'anon cannot read booking_id');
select throws_ok($$select driver_id, rating, review from public.booking_reviews$$, '42501', null, 'anon cannot read any review');
select throws_ok($$select count(*) from public.booking_reviews$$, '42501', null, 'anon cannot even count reviews');
reset role;

-- Grants -----------------------------------------------------------------------
select is((select count(*)::integer from information_schema.table_privileges
  where table_schema = 'public' and grantee = 'anon' and privilege_type in ('TRUNCATE', 'TRIGGER', 'REFERENCES')),
  0, 'anon holds no TRUNCATE, TRIGGER or REFERENCES on any public table');
select is((select count(*)::integer from pg_default_acl d, aclexplode(d.defaclacl) a
  where d.defaclrole = 'postgres'::regrole and d.defaclnamespace = 'public'::regnamespace and d.defaclobjtype = 'r'
    and a.grantee = (select oid from pg_roles where rolname = 'anon')
    and a.privilege_type in ('TRUNCATE', 'TRIGGER', 'REFERENCES')),
  0, 'tables created by postgres from now on do not give anon those privileges either');
select is(has_table_privilege('anon', 'public.tourist_spots', 'select'), true,
  'anon can still read the public catalogue (RLS decides which rows)');
select is(has_table_privilege('anon', 'public.bookings', 'insert'), false, 'anon still cannot write bookings');
set local role postgres;
create table public.zz_default_privilege_probe(id integer);
reset role;
select is(has_table_privilege('anon', 'public.zz_default_privilege_probe', 'truncate')
  or has_table_privilege('anon', 'public.zz_default_privilege_probe', 'trigger')
  or has_table_privilege('anon', 'public.zz_default_privilege_probe', 'references'), false,
  'a table created by postgres now gets none of the three for anon');

-- Tourist A, as the app: own review only ------------------------------------------
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config('request.jwt.claim.sub', 'e5280000-0000-4000-8000-000000000001', true);
set local role authenticated;
select is((select review from public.booking_reviews where booking_id = 'e5280000-0000-4000-8000-000000000101'),
  'Review A', 'a tourist reads their own review');
select is((select count(*)::integer from public.booking_reviews where booking_id::text like 'e5280000-%'), 1,
  'a tourist sees exactly one fixture review');
select is((select count(*)::integer from public.booking_reviews where booking_id = 'e5280000-0000-4000-8000-000000000102'),
  0, 'a tourist cannot read another tourist''s review');
select is((select count(*)::integer from public.booking_reviews
  where tourist_id <> 'e5280000-0000-4000-8000-000000000001' and booking_id::text like 'e5280000-%'),
  0, 'a tourist cannot learn other tourists'' ids or bookings from reviews');
select throws_ok($$insert into public.booking_reviews(booking_id, tourist_id, driver_id, rating, review)
  values ('e5280000-0000-4000-8000-000000000103', 'e5280000-0000-4000-8000-000000000001', 'e5280000-0000-4000-8000-000000000004', 1, 'forged')$$,
  '42501', null, 'a tourist still cannot write reviews directly');

-- Driver A: the review about them; driver B: only theirs ---------------------------
select set_config('request.jwt.claim.sub', 'e5280000-0000-4000-8000-000000000004', true);
select is((select rating::integer from public.booking_reviews where booking_id = 'e5280000-0000-4000-8000-000000000101'),
  5, 'a driver reads the review about them');
select is((select count(*)::integer from public.booking_reviews where booking_id = 'e5280000-0000-4000-8000-000000000102'),
  0, 'a driver cannot read reviews about other drivers');
select set_config('request.jwt.claim.sub', 'e5280000-0000-4000-8000-000000000005', true);
select is((select count(*)::integer from public.booking_reviews where booking_id::text like 'e5280000-%'), 1,
  'the other driver sees only their own review');

-- Admins ---------------------------------------------------------------------------
select set_config('request.jwt.claim.sub', 'e5280000-0000-4000-8000-000000000006', true);
select is((select count(*)::integer from public.booking_reviews where booking_id::text like 'e5280000-%'), 2,
  'an operations admin sees every review');
select is((select count(*)::integer from public.booking_reviews
  where booking_id::text like 'e5280000-%' and tourist_id is not null and booking_id is not null), 2,
  'and still sees tourist_id and booking_id');
select set_config('request.jwt.claim.sub', 'e5280000-0000-4000-8000-000000000008', true);
select is((select count(*)::integer from public.booking_reviews where booking_id::text like 'e5280000-%'), 2,
  'a support admin sees every review');
select set_config('request.jwt.claim.sub', 'e5280000-0000-4000-8000-000000000007', true);
select is((select count(*)::integer from public.booking_reviews where booking_id::text like 'e5280000-%'), 0,
  'a content admin (no booking access) sees none');

-- Submitting a review still works and still updates the driver's rating -------------
select set_config('request.jwt.claim.sub', 'e5280000-0000-4000-8000-000000000003', true);
select lives_ok($$select public.submit_driver_review('e5280000-0000-4000-8000-000000000103', 3, 'Review C')$$,
  'a tourist can still submit a review for a completed booking');
select is((select review from public.booking_reviews where booking_id = 'e5280000-0000-4000-8000-000000000103'),
  'Review C', 'and read it back');
reset role;
select is((select rating_count::integer from public.driver_profiles where profile_id = 'e5280000-0000-4000-8000-000000000004'),
  2, 'the driver rating count includes reviews by other tourists');
select is((select rating_average from public.driver_profiles where profile_id = 'e5280000-0000-4000-8000-000000000004'),
  4.00::numeric, 'and the average is across both reviews');

select * from finish();
rollback;

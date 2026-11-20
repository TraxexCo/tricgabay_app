-- Demo data for presentations. Idempotent: every row uses a fixed id under
-- the 'de300000-' prefix and inserts with ON CONFLICT DO NOTHING.
--
-- Accounts use @demo.tricgabay.test emails and have NO password, so nobody can
-- sign in as them. They exist only to fill lists, reports and the dispute queue.
-- Owner accounts are never touched.

-- ── Accounts: 6 drivers (d1..d6) and 10 tourists (t1..t10) ─────────────────
with people(n, kind, name, phone) as (values
  (1,'driver','Ramon Dela Cruz','09170000001'), (2,'driver','Jun Santiago','09170000002'),
  (3,'driver','Mario Villanueva','09170000003'), (4,'driver','Ernesto Bautista','09170000004'),
  (5,'driver','Rodel Mercado','09170000005'), (6,'driver','Allan Pascual','09170000006'),
  (11,'tourist','Angela Reyes',null), (12,'tourist','Paolo Garcia',null),
  (13,'tourist','Bea Mendoza',null), (14,'tourist','Carlo Ramos',null),
  (15,'tourist','Denise Torres',null), (16,'tourist','Enzo Navarro',null),
  (17,'tourist','Faith Aquino',null), (18,'tourist','Gino Castillo',null),
  (19,'tourist','Hannah Lim',null), (20,'tourist','Ivan Soriano',null))
insert into auth.users (id, email, raw_user_meta_data, created_at)
select ('de300000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid,
  'demo-' || kind || '-' || n || '@demo.tricgabay.test',
  jsonb_build_object('full_name', name, 'requested_role', kind, 'phone', phone),
  now() - interval '75 days'
from people
on conflict (id) do nothing;

update public.profiles set status = 'active'
where id::text like 'de300000-0000-4000-8000-%' and status <> 'active';

insert into public.driver_profiles (profile_id, plate_number, franchise_number, approval_status,
  approved_at, passenger_capacity, accepts_accessibility_requests, license_expires_on,
  franchise_expires_on, vehicle_inspection_expires_on, service_area_name,
  service_area_latitude, service_area_longitude, service_area_radius_km)
select ('de300000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid,
  'TRC-' || (4100 + n), 'BUS-FR-' || (200 + n), 'approved', now() - interval '70 days',
  3, n % 2 = 0, current_date + 400, current_date + 300, current_date + 200,
  'Bustos', 14.9571, 120.9188, 15
from generate_series(1, 6) n
on conflict (profile_id) do nothing;

insert into public.driver_gcash_details (driver_id, gcash_number, gcash_account_name, is_active)
select p.id, p.phone, p.full_name, true
from public.profiles p
where p.id::text like 'de300000-0000-4000-8000-00000000000%' and p.role = 'driver'
on conflict (driver_id) do nothing;

-- ── Completed trips over the last 60 days ───────────────────────────────────
-- Trip i: tourist t((i % 10) + 1), driver d((i % 6) + 1); odd trips cash,
-- even trips GCash. 36 trips, 1–4 stops each.
with fare as (select id from public.fare_revisions order by created_at desc limit 1),
     policy as (select id from public.cancellation_policies order by created_at desc limit 1),
     trips as (
       select i,
         ('de310000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid as booking_id,
         ('de300000-0000-4000-8000-' || lpad((11 + i % 10)::text, 12, '0'))::uuid as tourist_id,
         ('de300000-0000-4000-8000-' || lpad((1 + i % 6)::text, 12, '0'))::uuid as driver_id,
         (array[15000, 20000, 25000, 30000, 35000])[1 + i % 5] as cents,
         case when i % 2 = 1 then 'cash' else 'gcash_direct' end::public.payment_method as method,
         now() - make_interval(days => 60 - (i * 5 / 3), hours => 8 + i % 9) as started
       from generate_series(1, 36) i)
insert into public.bookings (id, tourist_id, driver_id, fare_revision_id, cancellation_policy_id,
  quoted_amount_centavos, final_charge_centavos, payment_method, payment_status, status,
  pickup_address, pickup_latitude, pickup_longitude, pickup_code_hash, passenger_count,
  accepted_at, started_at, completed_at, created_at, confirmed_stop_count)
select t.booking_id, t.tourist_id, t.driver_id, (select id from fare), (select id from policy),
  t.cents, t.cents, t.method,
  case when t.method = 'cash' then 'cash_paid' else 'gcash_paid' end::public.payment_status,
  'completed', 'Bustos Town Plaza', 14.9571 + (t.i % 7) * 0.001, 120.9188 - (t.i % 5) * 0.001,
  'demo', 1 + t.i % 3,
  t.started - interval '12 minutes', t.started, t.started + make_interval(hours => 2 + t.i % 3),
  t.started - interval '20 minutes', 1 + t.i % 4
from trips t
on conflict (id) do nothing;

with spots as (
  select id, name, latitude, longitude, row_number() over (order by id) - 1 as k,
    count(*) over () as total
  from public.tourist_spots where is_active)
insert into public.booking_stops (id, booking_id, spot_id, stop_order, spot_name_snapshot,
  latitude_snapshot, longitude_snapshot, arrived_at, confirmed_at)
select ('de320000-0000-4000-8000-' || lpad((b.i * 10 + s.n)::text, 12, '0'))::uuid,
  b.id, sp.id, s.n, sp.name, sp.latitude, sp.longitude,
  b.started_at + make_interval(mins => 25 * s.n), b.started_at + make_interval(mins => 25 * s.n + 3)
from (select id, started_at, confirmed_stop_count,
        right(id::text, 12)::int as i
      from public.bookings where id::text like 'de310000-%') b
cross join lateral generate_series(1, b.confirmed_stop_count) s(n)
join spots sp on sp.k = (b.i * 3 + s.n * 7) % sp.total
on conflict (id) do nothing;

insert into public.payments (booking_id, provider, amount_centavos, status, paid_at)
select b.id, case when b.payment_method = 'cash' then 'cash' else 'gcash_direct' end,
  b.final_charge_centavos, b.payment_status, b.completed_at + interval '5 minutes'
from public.bookings b
where b.id::text like 'de310000-%' and b.status = 'completed'
  and b.payment_status in ('cash_paid', 'gcash_paid')
  and not exists (select 1 from public.payments p where p.booking_id = b.id);

insert into public.cash_confirmations (booking_id, direction, actor_id, actor_role, amount_centavos, created_at)
select b.id, 'payment', who.actor, who.role::public.app_role, b.final_charge_centavos,
  b.completed_at + interval '4 minutes'
from public.bookings b
cross join lateral (values (b.tourist_id, 'tourist'), (b.driver_id, 'driver')) who(actor, role)
where b.id::text like 'de310000-%' and b.payment_status = 'cash_paid'
on conflict (booking_id, direction, actor_role) do nothing;

insert into public.gcash_payment_confirmations (booking_id, gcash_reference_no,
  tourist_marked_sent_at, driver_confirmed_received_at, driver_confirmed_by)
select b.id, '10' || lpad(right(b.id::text, 6), 11, '7'), b.completed_at + interval '2 minutes',
  b.completed_at + interval '5 minutes', b.driver_id
from public.bookings b
where b.id::text like 'de310000-%' and b.payment_status = 'gcash_paid'
on conflict (booking_id) do nothing;

-- Reviews on roughly three of every four trips.
insert into public.booking_reviews (booking_id, tourist_id, driver_id, rating, review, created_at)
select b.id, b.tourist_id, b.driver_id,
  (array[5, 5, 4, 5, 3, 4, 5])[1 + right(b.id::text, 2)::int % 7],
  (array['Very friendly driver and knew the history of each stop.',
         'Smooth ride, arrived on time.',
         'Good tour, the dam was beautiful.',
         'Driver waited patiently at every stop.',
         'Tricycle was a bit cramped for three, but fun.',
         'Great pasalubong recommendations!',
         'Would book again for the heritage tour.'])[1 + right(b.id::text, 2)::int % 7],
  b.completed_at + interval '30 minutes'
from public.bookings b
where b.id::text like 'de310000-%' and b.status = 'completed'
  and right(b.id::text, 2)::int % 4 <> 0
on conflict (booking_id) do nothing;

update public.driver_profiles d set
  rating_average = r.avg, rating_count = r.cnt, completed_trip_count = r.trips
from (select b.driver_id, round(avg(v.rating)::numeric, 2) as avg, count(v.*)::int as cnt,
        count(distinct b.id)::int as trips
      from public.bookings b left join public.booking_reviews v on v.booking_id = b.id
      where b.id::text like 'de310000-%' and b.status = 'completed'
      group by b.driver_id) r
where d.profile_id = r.driver_id;

-- ── Two cancelled requests (no charge) ──────────────────────────────────────
insert into public.bookings (id, tourist_id, fare_revision_id, cancellation_policy_id,
  quoted_amount_centavos, final_charge_centavos, payment_method, payment_status, status,
  pickup_address, pickup_latitude, pickup_longitude, pickup_code_hash, cancellation_reason,
  cancelled_by, created_at)
select ('de310000-0000-4000-8000-' || lpad((100 + n)::text, 12, '0'))::uuid,
  ('de300000-0000-4000-8000-' || lpad((12 + n)::text, 12, '0'))::uuid,
  (select id from public.fare_revisions order by created_at desc limit 1),
  (select id from public.cancellation_policies order by created_at desc limit 1),
  20000, 0, 'cash', 'waived', 'cancelled', 'Bustos Town Plaza', 14.9571, 120.9188, 'demo',
  'Plans changed', ('de300000-0000-4000-8000-' || lpad((12 + n)::text, 12, '0'))::uuid,
  now() - make_interval(days => 10 * n)
from generate_series(1, 2) n
on conflict (id) do nothing;

-- ── GCash disputes for the admin demo ───────────────────────────────────────
-- 201: escalated with a reference number (needs an admin decision).
-- 202: fresh dispute the tourist and driver can still settle themselves.
insert into public.bookings (id, tourist_id, driver_id, fare_revision_id, cancellation_policy_id,
  quoted_amount_centavos, final_charge_centavos, payment_method, payment_status, status,
  pickup_address, pickup_latitude, pickup_longitude, pickup_code_hash, passenger_count,
  accepted_at, started_at, completed_at, created_at, confirmed_stop_count)
select ('de310000-0000-4000-8000-' || lpad((200 + n)::text, 12, '0'))::uuid,
  ('de300000-0000-4000-8000-' || lpad((16 + n)::text, 12, '0'))::uuid,
  ('de300000-0000-4000-8000-' || lpad((1 + n)::text, 12, '0'))::uuid,
  (select id from public.fare_revisions order by created_at desc limit 1),
  (select id from public.cancellation_policies order by created_at desc limit 1),
  25000, 25000, 'gcash_direct', 'disputed', 'completed', 'Bustos Town Plaza',
  14.9571, 120.9188, 'demo', 2,
  now() - make_interval(hours => 30 - 20 * (n - 1)) - interval '3 hours',
  now() - make_interval(hours => 30 - 20 * (n - 1)) - interval '170 minutes',
  now() - make_interval(hours => 30 - 20 * (n - 1)),
  now() - make_interval(hours => 30 - 20 * (n - 1)) - interval '200 minutes', 0
from generate_series(1, 2) n
on conflict (id) do nothing;

insert into public.gcash_payment_confirmations (booking_id, gcash_reference_no,
  tourist_marked_sent_at, dispute_note, disputed_at, proof_submitted_at,
  escalated_at, escalated_by, escalation_note)
values
  ('de310000-0000-4000-8000-000000000201', '1009876543210', now() - interval '29 hours',
   'Not in my GCash history yet', now() - interval '28 hours', null,
   now() - interval '4 hours', 'de300000-0000-4000-8000-000000000017',
   'I sent it right after the tour. Reference is on my GCash history.'),
  ('de310000-0000-4000-8000-000000000202', null, null,
   'Amount looked short', now() - interval '9 hours', null, null, null, null)
on conflict (booking_id) do nothing;

insert into public.trip_events (booking_id, actor_id, actor_role, event_type, description, created_at)
select c.booking_id, null, null, 'demo_seed', 'Demo GCash dispute for presentations.', c.disputed_at
from public.gcash_payment_confirmations c
where c.booking_id::text like 'de310000-0000-4000-8000-0000000002%'
  and not exists (select 1 from public.trip_events e
                  where e.booking_id = c.booking_id and e.event_type = 'demo_seed');

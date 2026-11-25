-- A package booking may leave out a stop that is closed on the tour's weekday
-- (Asia/Manila). It accepts the full published list or that list minus the closed
-- stops (at least two left), in order, and nothing else.
begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;
select plan(39);

-- Day parser ---------------------------------------------------------------
select is(public.stop_open_on_weekday(U&'Mon\2013Fri 8:00 AM\20135:00 PM', 1), true, 'Mon-Fri covers Monday');
select is(public.stop_open_on_weekday(U&'Mon\2013Fri 8:00 AM\20135:00 PM', 5), true, 'Mon-Fri covers Friday');
select is(public.stop_open_on_weekday(U&'Mon\2013Fri 8:00 AM\20135:00 PM', 6), false, 'Mon-Fri does not cover Saturday');
select is(public.stop_open_on_weekday(U&'Sat, Sun 7:00 AM\20135:00 PM', 7), true, 'a comma list covers Sunday');
select is(public.stop_open_on_weekday(U&'Sat, Sun 7:00 AM\20135:00 PM', 1), false, 'a comma list does not cover Monday');
select is(public.stop_open_on_weekday(U&'Tue\2013Sat 8:00 AM\201312:00 PM', 1), false, 'Tue-Sat does not cover Monday');
select is(public.stop_open_on_weekday(U&'Tue\2013Sat 8:00 AM\201312:00 PM', 2), true, 'Tue-Sat covers Tuesday');
select is(public.stop_open_on_weekday(
  U&'Tue\2013Sat 8:00 AM\201312:00 PM \00B7 Tue\2013Sat 2:00 PM\20135:00 PM \00B7 Sun 9:30 AM\201312:00 PM', 1), false,
  'the church hours (two sittings and a Sunday block) are closed on Monday');
select is(public.stop_open_on_weekday(
  U&'Tue\2013Sat 8:00 AM\201312:00 PM \00B7 Tue\2013Sat 2:00 PM\20135:00 PM \00B7 Sun 9:30 AM\201312:00 PM', 7), true,
  'the church hours cover Sunday through the last block');
select is(public.stop_open_on_weekday(U&'Mon\2013Fri 7:00 AM\20136:00 PM \00B7 Sat, Sun 7:00 AM\20135:00 PM', 6), true,
  'a second block can cover the day the first one does not');
select is(public.stop_open_on_weekday('Open 24 hours, daily', 1), true, 'open 24 hours is open every day');
select is(public.stop_open_on_weekday('whenever the owner is in', 1), true, 'text that cannot be parsed counts as open');
select is(public.stop_open_on_weekday(U&'Funday 8:00 AM\20135:00 PM', 1), true, 'an unknown day name counts as open');
select is(public.stop_open_on_weekday(U&'Fri\2013Mon 8:00 AM\20135:00 PM', 2), true, 'a backwards day range cannot be read, so it counts as open');
select is(public.stop_open_on_weekday(null, 1), true, 'no hours counts as open');
select is(public.stop_open_on_weekday('', 1), true, 'empty hours counts as open');

-- Fixtures -----------------------------------------------------------------
insert into auth.users(id, email, raw_user_meta_data)
select ('e5260000-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
  'package-days-' || i || '@example.test', jsonb_build_object('full_name', 'Package day fixture')
from generate_series(1, 6) i;
update public.profiles set status = 'active' where id::text like 'e5260000-%';

update public.fare_revisions set is_current = false where is_current;
insert into public.fare_revisions(custom_fare_centavos, package_fares, is_current, reason)
values (10000, '{"day-pkg": 50000, "thin-pkg": 40000}', true, 'Package day fixture');
update public.cancellation_policies set is_current = false where is_current;
insert into public.cancellation_policies(is_current, terms) values (true, 'Package day fixture');

insert into public.tourist_spots(id, name, category, address, latitude, longitude, opening_hours) values
  ('day-park',   'Day park',   'park',   'Fixture', 14.9571, 120.9188, U&'Mon\2013Fri 8:00 AM\20135:00 PM'),
  ('day-church', 'Day church', 'church', 'Fixture', 14.9572, 120.9189,
    U&'Tue\2013Sat 8:00 AM\201312:00 PM \00B7 Tue\2013Sat 2:00 PM\20135:00 PM \00B7 Sun 9:30 AM\201312:00 PM'),
  ('day-market', 'Day market', 'market', 'Fixture', 14.9573, 120.9190, 'Open 24 hours, daily');
insert into public.tour_packages(id, name) values ('day-pkg', 'Day package'), ('thin-pkg', 'Thin package');
insert into public.tour_package_stops(package_id, spot_id, stop_order) values
  ('day-pkg', 'day-park', 1), ('day-pkg', 'day-church', 2), ('day-pkg', 'day-market', 3),
  ('thin-pkg', 'day-church', 1), ('thin-pkg', 'day-park', 2);

-- A Monday and the Tuesday after it, 10:00 Manila time, in the booking window.
create temp table tour_days as
select (date_trunc('week', (now() at time zone 'Asia/Manila') + interval '9 days') + interval '10 hours')
         at time zone 'Asia/Manila' as monday,
       (date_trunc('week', (now() at time zone 'Asia/Manila') + interval '9 days') + interval '1 day 10 hours')
         at time zone 'Asia/Manila' as tuesday;
grant select on tour_days to authenticated;

select is((select extract(isodow from monday at time zone 'Asia/Manila')::integer from tour_days), 1, 'fixture Monday is a Monday');
select is(public.package_stop_ids_open_on('day-pkg', (select monday from tour_days)),
  array['day-park', 'day-market'], 'Monday leaves out the church, keeping order');
select is(public.package_stop_ids_open_on('day-pkg', (select tuesday from tour_days)),
  array['day-park', 'day-church', 'day-market'], 'Tuesday keeps every stop');
select is(public.package_stop_ids_open_on('day-pkg', null),
  array['day-park', 'day-church', 'day-market'], 'no tour time keeps every stop');

select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

-- Monday, church omitted: works. -------------------------------------------
select set_config('request.jwt.claim.sub', 'e5260000-0000-4000-8000-000000000001', true);
create temp table omitted as select public.create_booking_with_schedule(
  'day-pkg', 'cash', 'Meeting point', 14.9571, 120.9188,
  '[{"spot_id":"day-park","stop_order":1},{"spot_id":"day-market","stop_order":2}]',
  1, '', '', (select monday from tour_days), 'e5260000-0000-4000-8000-0000000000a1') as result;
select is((select count(*)::integer from public.booking_stops where booking_id = (select (result->>'booking_id')::uuid from omitted)),
  2, 'Monday with the church omitted books two stops');
select is((select quoted_amount_centavos from public.bookings where id = (select (result->>'booking_id')::uuid from omitted)),
  50000, 'the package fare does not change');
select is((select status::text from public.bookings where id = (select (result->>'booking_id')::uuid from omitted)),
  'scheduled', 'the booking is scheduled for Monday');

-- Idempotency: the same request and stops return the booking; other stops conflict.
select is((select public.create_booking_with_schedule(
  'day-pkg', 'cash', 'Meeting point', 14.9571, 120.9188,
  '[{"spot_id":"day-park","stop_order":1},{"spot_id":"day-market","stop_order":2}]',
  1, '', '', (select monday from tour_days), 'e5260000-0000-4000-8000-0000000000a1')->>'booking_id'),
  (select result->>'booking_id' from omitted), 'repeating the request returns the same booking');
select throws_ok($$select public.create_booking_with_schedule(
  'day-pkg', 'cash', 'Meeting point', 14.9571, 120.9188,
  '[{"spot_id":"day-park","stop_order":1},{"spot_id":"day-church","stop_order":2},{"spot_id":"day-market","stop_order":3}]',
  1, '', '', (select monday from tour_days), 'e5260000-0000-4000-8000-0000000000a1')$$,
  'P0001', 'Booking request conflict', 'the same request ID with the full list is a conflict (the hash covers the stops)');

-- Monday, all stops (older app): works. ------------------------------------
select set_config('request.jwt.claim.sub', 'e5260000-0000-4000-8000-000000000002', true);
create temp table full_list as select public.create_booking_with_schedule(
  'day-pkg', 'cash', 'Meeting point', 14.9571, 120.9188,
  '[{"spot_id":"day-park","stop_order":1},{"spot_id":"day-church","stop_order":2},{"spot_id":"day-market","stop_order":3}]',
  1, '', '', (select monday from tour_days), 'e5260000-0000-4000-8000-0000000000a2') as result;
select is((select count(*)::integer from public.booking_stops where booking_id = (select (result->>'booking_id')::uuid from full_list)),
  3, 'Monday with every stop (older app) books three stops');
select is((select quoted_amount_centavos from public.bookings where id = (select (result->>'booking_id')::uuid from full_list)),
  50000, 'the fare is the same with the full list');

-- Tuesday: the church is open, so leaving it out is refused. --------------------
select set_config('request.jwt.claim.sub', 'e5260000-0000-4000-8000-000000000003', true);
select throws_ok($$select public.create_booking_with_schedule(
  'day-pkg', 'cash', 'Meeting point', 14.9571, 120.9188,
  '[{"spot_id":"day-park","stop_order":1},{"spot_id":"day-market","stop_order":2}]',
  1, '', '', (select tuesday from tour_days), 'e5260000-0000-4000-8000-0000000000a3')$$,
  'P0001', 'Package stops do not match the published package', 'Tuesday with the church omitted fails');
select is((select count(*)::integer from public.bookings where client_request_id = 'e5260000-0000-4000-8000-0000000000a3'),
  0, 'a refused list stores nothing');
select lives_ok($$select public.create_booking_with_schedule(
  'day-pkg', 'cash', 'Meeting point', 14.9571, 120.9188,
  '[{"spot_id":"day-park","stop_order":1},{"spot_id":"day-church","stop_order":2},{"spot_id":"day-market","stop_order":3}]',
  1, '', '', (select tuesday from tour_days), 'e5260000-0000-4000-8000-0000000000a4')$$,
  'Tuesday with every stop works');

-- Monday, other lists: refused. ---------------------------------------------
select set_config('request.jwt.claim.sub', 'e5260000-0000-4000-8000-000000000004', true);
select throws_ok($$select public.create_booking_with_schedule(
  'day-pkg', 'cash', 'Meeting point', 14.9571, 120.9188,
  '[{"spot_id":"day-park","stop_order":1}]',
  1, '', '', (select monday from tour_days), 'e5260000-0000-4000-8000-0000000000a5')$$,
  'P0001', 'Package stops do not match the published package', 'Monday with one stop left fails');
select throws_ok($$select public.create_booking_with_schedule(
  'day-pkg', 'cash', 'Meeting point', 14.9571, 120.9188,
  '[{"spot_id":"day-market","stop_order":1},{"spot_id":"day-park","stop_order":2}]',
  1, '', '', (select monday from tour_days), 'e5260000-0000-4000-8000-0000000000a6')$$,
  'P0001', 'Package stops do not match the published package', 'the open stops in the wrong order fail');
select throws_ok($$select public.create_booking_with_schedule(
  'day-pkg', 'cash', 'Meeting point', 14.9571, 120.9188,
  '[{"spot_id":"day-park","stop_order":1},{"spot_id":"day-church","stop_order":2}]',
  1, '', '', (select monday from tour_days), 'e5260000-0000-4000-8000-0000000000a7')$$,
  'P0001', 'Package stops do not match the published package', 'dropping an open stop (not the closed one) fails');
select throws_ok($$select public.create_booking_with_schedule(
  'day-pkg', 'cash', 'Meeting point', 14.9571, 120.9188,
  '[{"spot_id":"day-park","stop_order":1},{"spot_id":"day-market","stop_order":2},{"spot_id":"day-market","stop_order":3}]',
  1, '', '', (select monday from tour_days), 'e5260000-0000-4000-8000-0000000000a8')$$,
  'P0001', 'Package stops do not match the published package', 'a repeated stop fails');
select throws_ok($$select public.create_booking_with_schedule(
  'day-pkg', 'cash', 'Meeting point', 14.9571, 120.9188,
  '[{"spot_id":"day-park","stop_order":1},{"spot_id":"day-market","stop_order":2}]',
  1, '', '', null, 'e5260000-0000-4000-8000-0000000000a9')$$,
  'P0001', 'Package stops do not match the published package', 'without a tour time only the full list is accepted');

-- Closing the church would leave one stop: only the full list is allowed. -----
select set_config('request.jwt.claim.sub', 'e5260000-0000-4000-8000-000000000005', true);
select throws_ok($$select public.create_booking_with_schedule(
  'thin-pkg', 'cash', 'Meeting point', 14.9571, 120.9188,
  '[{"spot_id":"day-park","stop_order":1}]',
  1, '', '', (select monday from tour_days), 'e5260000-0000-4000-8000-0000000000b1')$$,
  'P0001', 'Package stops do not match the published package', 'a package that would be left with one stop cannot drop below two');
select lives_ok($$select public.create_booking_with_schedule(
  'thin-pkg', 'cash', 'Meeting point', 14.9571, 120.9188,
  '[{"spot_id":"day-church","stop_order":1},{"spot_id":"day-park","stop_order":2}]',
  1, '', '', (select monday from tour_days), 'e5260000-0000-4000-8000-0000000000b2')$$,
  'that package still books with its full list');

-- Clients still cannot call the inner creators. -----------------------------------
select is(has_function_privilege('authenticated',
  'public.create_booking(text,public.payment_method,text,double precision,double precision,jsonb,timestamptz)', 'execute'),
  false, 'clients cannot call the seven-argument creator');
select is(has_function_privilege('authenticated',
  'public.create_booking(text,public.payment_method,text,double precision,double precision,jsonb)', 'execute'),
  false, 'clients still cannot call the six-argument creator');

reset role;
select * from finish();
rollback;

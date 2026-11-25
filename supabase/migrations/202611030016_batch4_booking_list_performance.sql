-- The synthetic 100k seed exposed collisions in the old 32-bit reference.
-- Existing references stay valid. References are labels, never authorization.
alter table public.bookings alter column reference_code set default
  ('TRIC-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,16)));
-- Stable list ordering matches the client's created_at DESC, id DESC order.
create index bookings_created_id_idx on public.bookings(created_at desc,id desc);
create index bookings_tourist_created_id_idx on public.bookings(tourist_id,created_at desc,id desc);
create index bookings_driver_created_id_idx on public.bookings(driver_id,created_at desc,id desc);
create index bookings_active_created_id_idx on public.bookings(created_at desc,id desc)
  where status in ('payment_pending','scheduled','pending','accepted','replacement_pending','ongoing');
create index bookings_driver_active_created_id_idx on public.bookings(driver_id,created_at desc,id desc)
  where status in ('payment_pending','scheduled','pending','accepted','replacement_pending','ongoing');

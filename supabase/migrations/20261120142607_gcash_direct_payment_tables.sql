create table public.driver_gcash_details (
  driver_id uuid primary key references public.driver_profiles(profile_id) on delete cascade,
  gcash_number text not null check (gcash_number ~ '^09[0-9]{9}$'),
  gcash_account_name text not null check (
    gcash_account_name = btrim(gcash_account_name)
    and char_length(gcash_account_name) between 2 and 120
    and gcash_account_name !~ '[[:cntrl:]]'
  ),
  is_active boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.driver_gcash_details enable row level security;
revoke all on public.driver_gcash_details from public, anon, authenticated;
grant select on public.driver_gcash_details to authenticated;
grant insert (driver_id, gcash_number, gcash_account_name, is_active),
      update (driver_id, gcash_number, gcash_account_name, is_active)
  on public.driver_gcash_details to authenticated;
create policy driver_gcash_read on public.driver_gcash_details for select to authenticated
using ((driver_id = auth.uid() and public.current_profile_role() = 'driver') or public.is_admin());
create policy driver_gcash_insert on public.driver_gcash_details for insert to authenticated
with check (driver_id = auth.uid() and public.current_profile_role() = 'driver');
create policy driver_gcash_update on public.driver_gcash_details for update to authenticated
using (driver_id = auth.uid() and public.current_profile_role() = 'driver')
with check (driver_id = auth.uid() and public.current_profile_role() = 'driver');
create trigger driver_gcash_updated before update on public.driver_gcash_details
for each row execute function public.set_updated_at();

-- Keep private details and reference numbers out of published booking rows.
-- Only the booking's coarse payment status needs to go through realtime.
create table public.gcash_payment_confirmations (
  booking_id uuid primary key references public.bookings(id) on delete cascade,
  gcash_reference_no text check (gcash_reference_no ~ '^[A-Za-z0-9]{8,20}$'),
  tourist_marked_sent_at timestamptz,
  driver_confirmed_received_at timestamptz,
  driver_confirmed_by uuid references public.profiles(id) on delete set null,
  dispute_note text check (char_length(dispute_note) <= 200),
  disputed_at timestamptz
);
alter table public.gcash_payment_confirmations enable row level security;
revoke all on public.gcash_payment_confirmations from public, anon, authenticated;

create unique index one_gcash_payment_per_booking on public.payments(booking_id)
  where provider = 'gcash_direct';

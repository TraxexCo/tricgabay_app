alter table public.payments drop constraint payments_provider_check;
alter table public.payments add constraint payments_provider_check
  check (provider in ('cash', 'paymongo', 'gcash_direct'));

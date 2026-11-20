revoke all on public.driver_gcash_details from public, anon, authenticated;
grant select on public.driver_gcash_details to authenticated;
grant insert (driver_id, gcash_number, gcash_account_name, is_active),
      update (driver_id, gcash_number, gcash_account_name, is_active)
  on public.driver_gcash_details to authenticated;
revoke all on public.gcash_payment_confirmations from public, anon, authenticated;

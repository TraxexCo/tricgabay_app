-- Part 1 of the GCash direct payment migration (applied in parts; see KNOWN_ISSUES).
alter type public.payment_method add value if not exists 'gcash_direct';
alter type public.payment_status add value if not exists 'gcash_awaiting_confirmation';
alter type public.payment_status add value if not exists 'gcash_paid';
alter type public.payment_status add value if not exists 'disputed';

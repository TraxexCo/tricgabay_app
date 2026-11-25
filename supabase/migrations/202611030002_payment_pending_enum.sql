-- Apply separately before the functions migration: PostgreSQL cannot use a new
-- enum value until the transaction adding it has committed. NOT DB-tested.
alter type public.booking_status add value if not exists 'payment_pending';

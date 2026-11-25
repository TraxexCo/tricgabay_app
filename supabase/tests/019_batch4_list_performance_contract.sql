begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;
select plan(4);
select has_index('public','bookings','bookings_created_id_idx','admin list has stable order index');
select has_index('public','bookings','bookings_driver_active_created_id_idx','driver active list has participant partial index');
select ok((select pg_get_expr(adbin,adrelid) like '%16%' from pg_attrdef where adrelid='public.bookings'::regclass and adnum=(select attnum from pg_attribute where attrelid='public.bookings'::regclass and attname='reference_code')),'new references use 64 random bits instead of collision-prone 32 bits');
select is((select live_payments_enabled from public.service_configuration),false,'live payment flag remains off outside rolled-back tests');
select * from finish();rollback;

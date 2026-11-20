-- Publication membership does not grant SELECT; existing RLS still applies.
do $$
declare table_name text;
begin
  foreach table_name in array array['tourist_spots','profiles','driver_profiles',
    'fare_revisions','cancellation_policies','payments','refunds',
    'cash_confirmations','booking_reviews','trip_events','booking_stops',
    'feedback','admin_capabilities','operational_alerts']
  loop
    if not exists (select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public'
        and tablename = table_name) then
      execute format('alter publication supabase_realtime add table public.%I', table_name);
    end if;
  end loop;
end $$;

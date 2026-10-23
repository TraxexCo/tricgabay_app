begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(12);
select has_table('public', 'admin_capabilities', 'admin capability assignments exist');
select has_table('public', 'operational_alerts', 'operational alerts exist');
select has_table('public', 'message_deliveries', 'durable communication queue exists');
select has_table('public', 'payment_ledger', 'append-only payment ledger exists');
select has_table('public', 'driver_locations', 'live location storage exists');
select has_function('public', 'has_admin_capability', array['text'], 'capability guard exists');
select has_function('public', 'cleanup_retained_data', array[]::text[], 'retention job exists');
select has_function('public', 'check_operational_health', array[]::text[], 'health job exists');
select is(public.has_admin_capability('finance'), false, 'anonymous users have no finance capability');
select ok(
  (public.cleanup_retained_data()->>'enabled')::boolean = false,
  'retention deletion is disabled until policy approval'
);
select ok(to_regprocedure('public.admin_set_tourist_status(uuid,text,text)') is not null,
  'tourist moderation uses a server transition');
select ok(to_regprocedure('public.set_admin_capabilities(uuid,text[])') is not null,
  'capabilities are managed through an audited RPC');

select * from finish();
rollback;

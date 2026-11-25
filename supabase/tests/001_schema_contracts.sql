begin;
create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select plan(20);
select has_table('public', 'admin_capabilities', 'admin capability assignments exist');
select has_table('public', 'operational_alerts', 'operational alerts exist');
select has_table('public', 'message_deliveries', 'durable communication queue exists');
select has_table('public', 'financial_ledger_entries', 'append-only payment ledger exists');
select has_table('public', 'driver_locations', 'live location storage exists');
select has_function('public', 'has_admin_capability', array['text'], 'capability guard exists');
select has_function(
  'public', 'reserve_paymongo_refund', array['uuid','integer','text'],
  'finance-gated refund reservation exists'
);
select has_function(
  'public', 'process_paymongo_payment_event',
  array['text','text','text','text','text','integer','text','text','text','text','timestamp with time zone','jsonb','uuid'],
  'atomic PayMongo payment event processor exists'
);
select has_function(
  'public', 'process_paymongo_refund_event',
  array['text','text','jsonb','jsonb','uuid'],
  'atomic PayMongo refund event processor exists'
);
select has_function('public', 'cleanup_retained_data', array[]::text[], 'retention job exists');
select has_function('public', 'check_operational_health', array[]::text[], 'health job exists');
select is(public.has_admin_capability('finance'), false, 'anonymous users have no finance capability');
select ok(
  (public.cleanup_retained_data()->>'executed')::boolean = false,
  'retention deletion is disabled until policy approval'
);
select ok(to_regprocedure('public.admin_set_tourist_status(uuid,public.account_status,text)') is not null,
  'tourist moderation uses a server transition');
select ok(to_regprocedure('public.set_admin_capabilities(uuid,text[])') is not null,
  'capabilities are managed through an audited RPC');
select ok(
  not (select public from storage.buckets where id='profile-images'),
  'profile avatars are stored in a private bucket'
);
select ok(
  not has_function_privilege(
    'anon',
    'public.complete_paymongo_test_refund(uuid,integer,text)',
    'EXECUTE'
  ),
  'anonymous callers cannot execute administrator refund wrappers'
);
select is(
  (
    select count(*)::integer
    from pg_proc p
    join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public'
      and p.proname like '\_%\_impl' escape '\'
      and has_function_privilege('anon',p.oid,'EXECUTE')
  ),
  0,
  'anonymous callers cannot execute internal administrator implementations'
);
select is(
  public.invoke_communications_dispatcher(),
  null::bigint,
  'an unconfigured local environment never calls a hosted communications endpoint'
);
select ok(
  not has_function_privilege(
    'authenticated',
    'public.activate_due_scheduled_bookings()',
    'EXECUTE'
  ),
  'mobile users cannot invoke the global scheduled-booking activation job'
);

select * from finish();
rollback;

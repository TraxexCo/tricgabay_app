begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;
select no_plan();
insert into auth.users(id,email,raw_user_meta_data) values
('b4900000-0000-4000-8000-000000000001','suspended-b4@example.test','{"full_name":"Suspended Fixture"}'),
('b4900000-0000-4000-8000-000000000002','pending-b4@example.test','{"full_name":"Pending Fixture","requested_role":"driver"}');
update public.profiles set status='suspended' where id='b4900000-0000-4000-8000-000000000001';
set local role authenticated;
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','b4900000-0000-4000-8000-000000000001',true);
select is(public.current_profile_role(),null::public.app_role,'suspended account does not have an active role');
select throws_ok($$select public.create_booking_with_schedule(null,'cash','Fixture pickup',14.9571,120.9188,'[]',1,'','',null,gen_random_uuid())$$,'42501',null,'suspended user is rejected before booking business rules');
select throws_ok($$select public.reissue_booking_pickup_code(gen_random_uuid(),gen_random_uuid(),'2468')$$,'42501',null,'suspended user cannot rotate pickup credentials');
select set_config('request.jwt.claim.sub','b4900000-0000-4000-8000-000000000002',true);
select throws_ok($$select public.create_booking_with_schedule(null,'cash','Fixture pickup',14.9571,120.9188,'[]',1,'','',null,gen_random_uuid())$$,'42501',null,'pending driver cannot exploit a NULL role to book as a tourist');
select throws_ok($$select public.complete_trip(gen_random_uuid())$$,'42501',null,'pending driver cannot invoke trip completion');
select throws_ok($$select public.update_driver_service_profile(3,true)$$,'42501',null,'pending driver cannot use active-driver service updates');
reset role;
select set_config('request.jwt.claim.role','anon',true);
set local role anon;
select throws_ok($$select public.set_driver_online(false)$$,'42501',null,'legacy RPC no longer inherits anonymous execution');
select throws_ok($$select public.create_booking_with_requirements(null,'cash','Fixture',14.9571,120.9188,'[]',1,'','')$$,'42501',null,'legacy booking wrapper no longer inherits anonymous execution');
select is(public.has_admin_capability('finance'),false,'public capability predicate safely returns false');
reset role;
select * from finish();rollback;

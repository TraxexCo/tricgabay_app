begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;
select no_plan();
insert into auth.users(id,email,raw_user_meta_data) values
('b3400000-0000-4000-8000-000000000001','mode-owner@example.test','{"full_name":"Mode Owner"}'),
('b3400000-0000-4000-8000-000000000002','notice-admin@example.test','{"full_name":"Notice Admin"}'),
('b3400000-0000-4000-8000-000000000003','notice-driver@example.test','{"full_name":"Notice Driver","requested_role":"driver"}');
update public.profiles set role='admin' where id='b3400000-0000-4000-8000-000000000002';
update public.profiles set status='active' where id='b3400000-0000-4000-8000-000000000003';
insert into public.admin_capabilities(profile_id,capability) values('b3400000-0000-4000-8000-000000000002','support');
insert into public.fare_revisions(id,custom_fare_centavos,reason) values('b3410000-0000-4000-8000-000000000001',10000,'Provider mode fixture');
insert into public.cancellation_policies(id,terms) values('b3410000-0000-4000-8000-000000000002','Provider mode fixture');
insert into public.bookings(id,tourist_id,fare_revision_id,cancellation_policy_id,quoted_amount_centavos,payment_method,payment_status,pickup_address,pickup_latitude,pickup_longitude,pickup_code_hash)
values('b3420000-0000-4000-8000-000000000001','b3400000-0000-4000-8000-000000000001','b3410000-0000-4000-8000-000000000001','b3410000-0000-4000-8000-000000000002',10000,'paymongo','unpaid','Mode fixture',14.9571,120.9188,crypt('1234',gen_salt('bf')));
select is((select paymongo_mode from public.service_configuration),'test','provider mode defaults safely to test');
select set_config('request.jwt.claim.role','service_role',true);
update public.service_configuration set paymongo_mode='live';
select throws_ok($$select public.record_paymongo_checkout('b3420000-0000-4000-8000-000000000001','cs_mode','https://checkout.paymongo.com/cs_mode',10000)$$,'42501','Live payments are not enabled for this deployment','live configuration cannot silently record a test checkout');
select is((select count(*)::integer from public.payments where booking_id='b3420000-0000-4000-8000-000000000001'),0,'mode mismatch leaves no payment');
update public.service_configuration set paymongo_mode='test';
select lives_ok($$select public.record_paymongo_checkout('b3420000-0000-4000-8000-000000000001','cs_mode','https://checkout.paymongo.com/cs_mode',10000)$$,'test configuration records a test checkout');
select is((select provider_mode from public.payments where booking_id='b3420000-0000-4000-8000-000000000001'),'test','stored checkout uses configured mode');
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','b3400000-0000-4000-8000-000000000002',true);
select is(public.send_announcement('Driver notice','Fixture driver message','drivers','b3430000-0000-4000-8000-000000000001'),1,'driver audience has one recipient');
select is(public.send_announcement('Driver notice','Fixture driver message','drivers','b3430000-0000-4000-8000-000000000001'),1,'double submit returns the original count');
select is((select count(*)::integer from public.notifications where title='Driver notice'),1,'double submit sends only once');
select is((select count(*)::integer from public.announcement_audit),1,'double submit creates one audit row');
select is((select sender_id::text||':'||audience||':'||recipient_count::text from public.announcement_audit),'b3400000-0000-4000-8000-000000000002:drivers:1','audit records admin audience and count');
select throws_ok($$select public.send_announcement('Changed','Fixture driver message','drivers','b3430000-0000-4000-8000-000000000001')$$,'P0001','Announcement request conflict','same announcement UUID with different text is rejected');
select is(public.send_announcement('All notice','Fixture message','all','b3430000-0000-4000-8000-000000000002'),2,'all audience excludes administrators');
select is(public.send_announcement('Tourist notice','Fixture message','tourists','b3430000-0000-4000-8000-000000000003'),1,'tourist audience enforced');
select throws_ok($$select public.send_announcement('Fourth notice','Fixture message','all','b3430000-0000-4000-8000-000000000004')$$,'P0001','Announcement rate limit reached','fourth new request is rate-limited');
select throws_ok($$update public.announcement_audit set recipient_count=0$$,'P0001','Announcement audit is append-only','audit cannot be rewritten');
select set_config('request.jwt.claim.sub','b3400000-0000-4000-8000-000000000001',true);
select is((public.get_privacy_consent_status()->>'accepted')::boolean,false,'existing user without receipt needs re-consent');
insert into public.privacy_consents(profile_id,notice_version) values('b3400000-0000-4000-8000-000000000001','old-version');
select is((public.get_privacy_consent_status()->>'accepted')::boolean,false,'old receipt does not satisfy current notice');
select public.record_own_privacy_consent(public.get_privacy_notice()->>'version');
select is((public.get_privacy_consent_status()->>'accepted')::boolean,true,'accepting exact current notice records consent');
update public.service_configuration set privacy_notice_version='fixture-next-version';
select is((public.get_privacy_consent_status()->>'accepted')::boolean,false,'server notice change requires consent again');
select throws_ok($$select public.record_own_privacy_consent('old-version')$$,'42501','Read and accept the current privacy notice','client cannot record an obsolete version');
select public.record_own_privacy_consent(public.get_privacy_notice()->>'version');
select is((public.get_privacy_consent_status()->>'accepted')::boolean,true,'new server version can be accepted');
select is((select count(*)::integer from public.privacy_consents where profile_id='b3400000-0000-4000-8000-000000000002'),0,'consent RPC never records another account');
select * from finish();rollback;

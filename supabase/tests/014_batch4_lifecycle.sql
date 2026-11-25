begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;
select no_plan();
select set_config('request.jwt.claim.role','service_role',true);
insert into auth.users(id,email,raw_user_meta_data)
select ('b4000000-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,'batch4-'||i||'@example.test',
  jsonb_build_object('full_name','Batch Four Fixture','requested_role',case when i=6 then 'driver' else 'tourist' end)
from generate_series(1,6)i;
update public.profiles set status='active' where id::text like 'b4000000%';
insert into public.driver_profiles(profile_id,plate_number,franchise_number,license_document_path,vehicle_document_path,approval_status,is_online,last_seen_at,license_expires_on,franchise_expires_on,vehicle_inspection_expires_on,service_area_name,service_area_latitude,service_area_longitude,service_area_radius_km)
values('b4000000-0000-4000-8000-000000000006','B4-DRIVER','B4-FRANCHISE','b4/license.jpg','b4/vehicle.jpg','approved',false,null,current_date+365,current_date+365,current_date+365,'Batch four',14.9571,120.9188,15);
select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','b4000000-0000-4000-8000-000000000006',true);
select public.set_driver_online(true);
select is((select is_online from public.driver_profiles where profile_id=auth.uid()),true,'go-online succeeds for compliant driver');
select ok((select last_seen_at>=now()-interval '1 second' from public.driver_profiles where profile_id=auth.uid()),'go-online stamps last_seen_at even without a location sample');
select public.expire_stale_online_drivers();
select is((select is_online from public.driver_profiles where profile_id=auth.uid()),true,'newly-online driver survives the expiry job');
select set_config('request.jwt.claim.role','service_role',true);
insert into public.fare_revisions(id,custom_fare_centavos,reason) values('b4100000-0000-4000-8000-000000000001',12500,'Batch four');
insert into public.cancellation_policies(id,terms) values('b4100000-0000-4000-8000-000000000002','Batch four');
insert into public.bookings(id,tourist_id,driver_id,fare_revision_id,cancellation_policy_id,quoted_amount_centavos,final_charge_centavos,payment_method,payment_status,status,pickup_address,pickup_latitude,pickup_longitude,pickup_code_hash)
select ('b4200000-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,('b4000000-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,
  case when i=5 then 'b4000000-0000-4000-8000-000000000006'::uuid else null end,
  'b4100000-0000-4000-8000-000000000001','b4100000-0000-4000-8000-000000000002',12500,
  case when i=1 then 2500 else 0 end,'paymongo',
  case i when 1 then 'paid'::public.payment_status when 2 then 'refund_required'::public.payment_status when 3 then 'refunded'::public.payment_status else 'checkout_created'::public.payment_status end,
  case when i=5 then 'ongoing'::public.booking_status else 'cancelled'::public.booking_status end,
  'Batch four',14.9571,120.9188,crypt('1234',gen_salt('bf')) from generate_series(1,5)i;
insert into public.payments(id,booking_id,provider,provider_mode,provider_checkout_id,provider_payment_id,amount_centavos,status,paid_at)
select ('b4300000-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,('b4200000-0000-4000-8000-'||lpad(i::text,12,'0'))::uuid,
  'paymongo','test','cs_b4_'||i,'pay_b4_'||i,case when i=1 then 2500 else 12500 end,'paid',now() from generate_series(1,4)i;
select public.process_paymongo_payment_event('evt_b4_replay_fee','checkout_session.payment.paid',null,'cs_b4_1','pay_b4_1',2500,'PHP','paid',null,null,now(),'{}',gen_random_uuid());
select is((select payment_status::text from public.bookings where id='b4200000-0000-4000-8000-000000000001'),'paid','real paid-event replay preserves a retained cancellation fee');
update public.bookings set payment_status='paid' where id::text like 'b4200000%' and right(id::text,1) in ('1','2','3','4');
select is((select payment_status::text from public.bookings where id='b4200000-0000-4000-8000-000000000001'),'paid','trigger replay with net funds equal to fee creates no refund');
select is((select payment_status::text from public.bookings where id='b4200000-0000-4000-8000-000000000002'),'refund_required','cancelled full-refund obligation survives paid replay');
select is((select payment_status::text from public.bookings where id='b4200000-0000-4000-8000-000000000003'),'refunded','already-refunded booking cannot regress on paid replay');
select is((select payment_status::text from public.bookings where id='b4200000-0000-4000-8000-000000000004'),'refund_required','expiry-cancelled booking with received funds requires full refund');
select is((select count(*)::integer from public.financial_ledger_entries where booking_id='b4200000-0000-4000-8000-000000000001'),1,'replay creates no duplicate money movement');
update public.driver_profiles set last_seen_at=now()-interval '5 minutes' where profile_id='b4000000-0000-4000-8000-000000000006';
select public.expire_stale_online_drivers();
select is((select is_online from public.driver_profiles where profile_id='b4000000-0000-4000-8000-000000000006'),false,'stale assigned driver stops advertising availability');
select is((select status::text from public.bookings where id='b4200000-0000-4000-8000-000000000005'),'ongoing','heartbeat expiry does not silently cancel an ongoing trip');
select is((select count(*)::integer from public.operational_alerts where dedupe_key='assigned-driver-stale:b4000000-0000-4000-8000-000000000006'),1,'stale assigned driver creates an operational alert');

select set_config('request.jwt.claim.role','authenticated',true);
select set_config('request.jwt.claim.sub','b4000000-0000-4000-8000-000000000001',true);
select public.record_own_privacy_consent_with_language((public.get_privacy_notice()->>'version'),'fil');
select public.record_own_privacy_consent_with_language((public.get_privacy_notice()->>'version'),'en');
select is((select count(*)::integer from public.consent_history where subject_id=auth.uid()),2,'every acceptance appends history alongside the current row');
select is((select count(*)::integer from public.privacy_consents where profile_id=auth.uid()),1,'current consent remains one row');
select is((select array_agg(notice_language order by notice_language)::text from public.consent_history where subject_id=auth.uid()),'{en,fil}','history records the actual notice language');
select ok((select bool_and(accepted_at=now() and length(notice_digest)=64) from public.consent_history where subject_id=auth.uid()),'server timestamp and displayed-notice digest recorded');
select throws_ok($$update public.consent_history set notice_language='und'$$,'42501','Consent history is append-only','even the owner cannot rewrite historical evidence');
select throws_ok($$delete from public.consent_history$$,'42501','Consent history is append-only','consent history cannot be deleted');
select throws_ok($$select public.record_own_privacy_consent_with_language('old-version','fil')$$,'42501',null,'old notice versions rejected');
select throws_ok($$select public.record_own_privacy_consent_with_language(public.get_privacy_notice()->>'version','xx')$$,'42501',null,'invented language rejected');

select set_config('request.jwt.claim.role','service_role',true);
insert into public.disputes(id,booking_id,opened_by,reason,status,resolution)
values('b4400000-0000-4000-8000-000000000001','b4200000-0000-4000-8000-000000000001','b4000000-0000-4000-8000-000000000006','Other party original dispute','resolved','Administrator decision');
insert into public.dispute_statements(dispute_id,author_id,statement) values
('b4400000-0000-4000-8000-000000000001','b4000000-0000-4000-8000-000000000001','Deleting party private text'),
('b4400000-0000-4000-8000-000000000001','b4000000-0000-4000-8000-000000000006','Other party evidence remains');
create temp table other_party_before as select to_jsonb(s) value from public.dispute_statements s where author_id='b4000000-0000-4000-8000-000000000006';
select public.prepare_account_deletion('b4000000-0000-4000-8000-000000000001','b4500000-0000-4000-8000-000000000001');
select is((select to_jsonb(s) from public.dispute_statements s where author_id='b4000000-0000-4000-8000-000000000006'),(select value from other_party_before),'other party statement including identity and timestamps stays unchanged');
select is((select statement from public.dispute_statements where author_id<>'b4000000-0000-4000-8000-000000000006'),'Personal text removed on account deletion','only the deleting author statement is redacted');
select is((select reason||':'||resolution from public.disputes where id='b4400000-0000-4000-8000-000000000001'),'Other party original dispute:Administrator decision','other author dispute and admin resolution are retained');
select is((select count(*)::integer from public.consent_history where subject_id='b4000000-0000-4000-8000-000000000001'),2,'deletion cannot rewrite append-only pseudonymous consent evidence');

insert into public.checkout_expiry_requests(payment_id,booking_id,state,attempts,claim_id,claim_until)
values('b4300000-0000-4000-8000-000000000002','b4200000-0000-4000-8000-000000000002','processing',10,gen_random_uuid(),now()-interval '1 minute'),
('b4300000-0000-4000-8000-000000000003','b4200000-0000-4000-8000-000000000003','processing',2,gen_random_uuid(),now()-interval '3 minutes');
select public.monitor_checkout_expiries();
select is((select state from public.checkout_expiry_requests where payment_id='b4300000-0000-4000-8000-000000000002'),'blocked','last-attempt worker crash becomes blocked instead of stranded');
select is((select count(*)::integer from public.operational_alerts where dedupe_key like 'checkout-expiry:b4300000%'),2,'blocked and stuck jobs both raise operational alerts');
select public.monitor_checkout_expiries();
select is((select count(*)::integer from public.operational_alerts where dedupe_key like 'checkout-expiry:b4300000%'),2,'monitor repeats deduplicate alerts');
select ok(exists(select 1 from cron.job where jobname='monitor-checkout-expiries'),'expiry monitoring scheduled independently from the worker');
select * from finish();
rollback;

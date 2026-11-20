begin;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;
select plan(10);

insert into auth.users(id,email,raw_user_meta_data)
values ('50000000-0000-4000-8000-000000000001','delivery@test.local','{"full_name":"Delivery"}');
insert into public.message_deliveries(
  id,recipient_id,channel,template_key,title,body,dedupe_key
) values (
  '50000000-0000-4000-8000-000000000010',
  '50000000-0000-4000-8000-000000000001','email','test','Test','Body','delivery:test:one'
);

set local role service_role;
select set_config('request.jwt.claim.role','service_role',true);
create temporary table claimed_delivery as
  select * from public.claim_message_deliveries(1,array['email']);

select is((select count(*)::integer from claimed_delivery),1,'due delivery is claimed once');
select is((select status from claimed_delivery),'sending','claim moves delivery to sending');
select is((select attempts from claimed_delivery),1,'claim increments the attempt exactly once');
select isnt((select claim_token from claimed_delivery),null::uuid,'claim issues an attempt token');
select is(
  public.finish_message_delivery(
    '50000000-0000-4000-8000-000000000010',gen_random_uuid(),true,'stale',null,false
  ),false,'a stale worker token cannot finalize the delivery'
);
select is(
  (select status from public.message_deliveries where id='50000000-0000-4000-8000-000000000010'),
  'sending','rejected stale finalization leaves current truth unchanged'
);
select is(
  public.finish_message_delivery(
    '50000000-0000-4000-8000-000000000010',
    (select claim_token from claimed_delivery),true,'provider-1',null,false
  ),true,'the current lease holder can finalize the delivery'
);
select is(
  (select status from public.message_deliveries where id='50000000-0000-4000-8000-000000000010'),
  'sent','successful finalization is durable'
);

insert into public.message_deliveries(
  id,recipient_id,channel,template_key,title,body,dedupe_key,status,attempts,next_attempt_at
) values (
  '50000000-0000-4000-8000-000000000011',
  '50000000-0000-4000-8000-000000000001','email','test','Max','Body','delivery:test:max',
  'failed',5,now()-interval '1 hour'
);
select is_empty(
  $$select id from public.claim_message_deliveries(10,array['email'])
    where id='50000000-0000-4000-8000-000000000011'$$,
  'retry ceiling prevents a sixth provider attempt'
);

insert into public.message_deliveries(
  id,recipient_id,channel,template_key,title,body,dedupe_key,status,attempts,
  claim_token,claimed_at
) values (
  '50000000-0000-4000-8000-000000000012',
  '50000000-0000-4000-8000-000000000001','push','test','Stale','Body','delivery:test:stale',
  'sending',1,'50000000-0000-4000-8000-000000000099',now()-interval '6 minutes'
);
select isnt(
  (select claim_token from public.claim_message_deliveries(10,array['push'])
   where id='50000000-0000-4000-8000-000000000012'),
  '50000000-0000-4000-8000-000000000099'::uuid,
  'abandoned sending work receives a new lease before retry'
);

select * from finish();
rollback;

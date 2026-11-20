create table public.checkout_expiry_requests (
 payment_id uuid primary key references public.payments(id),booking_id uuid not null references public.bookings(id),
 state text not null default 'queued' check(state in ('queued','processing','expired','paid','blocked')),
 requested_at timestamptz not null default now(),next_attempt_at timestamptz not null default now(),
 attempts integer not null default 0,claim_id uuid,claim_until timestamptz,last_result text
);
alter table public.checkout_expiry_requests enable row level security;
revoke all on public.checkout_expiry_requests from anon,authenticated;
create function public.enqueue_checkout_expiry() returns trigger language plpgsql security definer set search_path=public as $$
begin
 if new.status='cancelled' and old.status='payment_pending' then
   insert into public.checkout_expiry_requests(payment_id,booking_id)
   select id,new.id from public.payments where booking_id=new.id and provider='paymongo' and provider_checkout_id is not null
   on conflict(payment_id) do nothing;
 end if;
 return new;
end $$;
create trigger enqueue_checkout_expiry after update on public.bookings for each row execute function public.enqueue_checkout_expiry();
revoke all on function public.enqueue_checkout_expiry() from public,anon,authenticated;
create function public.claim_checkout_expiries(p_claim_id uuid,p_limit integer default 20) returns setof jsonb language plpgsql security definer set search_path=public as $$
declare row record;
begin
 if coalesce(auth.role(),'')<>'service_role' then raise exception 'Service role required' using errcode='42501'; end if;
 if p_claim_id is null then raise exception 'Claim ID required'; end if;
 for row in update public.checkout_expiry_requests q set state='processing',claim_id=p_claim_id,claim_until=now()+interval '2 minutes',attempts=attempts+1
 where q.payment_id in(select payment_id from public.checkout_expiry_requests where attempts<10 and next_attempt_at<=now()
   and (state='queued' or (state='processing' and claim_until<=now())) order by requested_at for update skip locked limit greatest(1,least(p_limit,50))) returning *
 loop
  return next (select jsonb_build_object('payment_id',p.id,'booking_id',p.booking_id,'checkout_id',p.provider_checkout_id,'mode',p.provider_mode,'amount',p.amount_centavos,'status',p.status) from public.payments p where p.id=row.payment_id);
 end loop;
end $$;
create function public.finish_checkout_expiry(p_payment_id uuid,p_claim_id uuid,p_outcome text) returns boolean language plpgsql security definer set search_path=public as $$
begin
 if coalesce(auth.role(),'')<>'service_role' then raise exception 'Service role required' using errcode='42501'; end if;
 if p_outcome not in ('expired','paid','processing','retry') then raise exception 'Invalid expiry outcome'; end if;
 update public.checkout_expiry_requests set state=case when p_outcome in ('expired','paid') then p_outcome when attempts>=10 then 'blocked' else 'queued' end,
 next_attempt_at=now()+interval '1 minute',last_result=p_outcome,claim_id=null,claim_until=null
 where payment_id=p_payment_id and claim_id=p_claim_id and state='processing' and claim_until>now();
 return found;
end $$;
revoke all on function public.claim_checkout_expiries(uuid,integer),public.finish_checkout_expiry(uuid,uuid,text) from public,anon,authenticated;
grant execute on function public.claim_checkout_expiries(uuid,integer),public.finish_checkout_expiry(uuid,uuid,text) to service_role;
insert into public.internal_scheduler_tokens(name,token) values('checkout_expiry',encode(extensions.gen_random_bytes(32),'hex')) on conflict(name) do nothing;
create function public.invoke_checkout_expiry_worker() returns bigint language plpgsql security definer set search_path=public,extensions as $$
declare worker_url text;gateway_key text;scheduler_token text;request_id bigint;
begin
 select decrypted_secret into worker_url from vault.decrypted_secrets where name='tric_gabay_checkout_expiry_url' order by created_at desc limit 1;
 select decrypted_secret into gateway_key from vault.decrypted_secrets where name='tric_gabay_anon_key' order by created_at desc limit 1;
 if worker_url is null or gateway_key is null then return null; end if;
 if worker_url !~ '^https://[a-z0-9-]+[.]supabase[.]co/functions/v1/expire-paymongo-checkouts$' then raise exception 'Invalid expiry worker URL'; end if;
 select token into scheduler_token from public.internal_scheduler_tokens where name='checkout_expiry';
 select net.http_post(url:=worker_url,headers:=jsonb_build_object('Content-Type','application/json','apikey',gateway_key,'x-tricgabay-scheduler',scheduler_token),body:='{}'::jsonb,timeout_milliseconds:=20000) into request_id;
 return request_id;
end $$;
revoke all on function public.invoke_checkout_expiry_worker() from public,anon,authenticated;
grant execute on function public.invoke_checkout_expiry_worker() to service_role;
select cron.schedule('expire-paymongo-provider-checkouts','* * * * *','select public.invoke_checkout_expiry_worker()');

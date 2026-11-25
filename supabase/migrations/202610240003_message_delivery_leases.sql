-- A delivery result may only be committed by the worker that claimed that
-- specific attempt. This prevents a slow/stale worker from overwriting a
-- newer retry and lets abandoned leases be reclaimed after a bounded timeout.
alter table public.message_deliveries
  add column claim_token uuid,
  add column claimed_at timestamptz;

-- Any row left in-flight by the pre-lease worker is immediately eligible for
-- safe recovery after this migration.
update public.message_deliveries set
  claim_token=gen_random_uuid(),claimed_at=now()-interval '6 minutes'
where status='sending';

alter table public.message_deliveries add constraint message_delivery_active_lease
  check(status<>'sending' or (claim_token is not null and claimed_at is not null));

create index message_deliveries_stale_claim_idx
  on public.message_deliveries(claimed_at)
  where status='sending';

create or replace function public.claim_message_deliveries(
  p_limit integer default 25,p_channels text[] default array['email','push']::text[]
)
returns setof public.message_deliveries language plpgsql security definer set search_path=public as $$
begin
  if auth.role()<>'service_role' then raise exception 'Service role required'; end if;
  return query
  with due as (
    select id from public.message_deliveries
    where attempts<5 and channel=any(p_channels) and (
      (status in ('queued','failed') and next_attempt_at<=now())
      or (status='sending' and claimed_at<=now()-interval '5 minutes')
    )
    order by created_at for update skip locked limit greatest(1,least(p_limit,100))
  )
  update public.message_deliveries d set
    status='sending', attempts=d.attempts+1,
    claim_token=gen_random_uuid(), claimed_at=now()
  from due where d.id=due.id returning d.*;
end;
$$;

drop function public.finish_message_delivery(uuid,boolean,text,text,boolean);
create function public.finish_message_delivery(
  p_id uuid,p_claim_token uuid,p_success boolean,p_provider_message_id text,
  p_error text,p_skip boolean default false
) returns boolean language plpgsql security definer set search_path=public as $$
declare changed integer;
begin
  if auth.role()<>'service_role' then raise exception 'Service role required'; end if;
  update public.message_deliveries set
    status=case when p_success then 'sent' when p_skip then 'skipped' else 'failed' end,
    provider_message_id=p_provider_message_id,last_error=left(p_error,1000),
    sent_at=case when p_success then now() else sent_at end,
    next_attempt_at=case when p_success or p_skip then next_attempt_at
      else now()+make_interval(mins=>least(60,power(2,attempts)::integer)) end,
    claim_token=null,claimed_at=null
  where id=p_id and status='sending' and claim_token=p_claim_token;
  get diagnostics changed=row_count;
  return changed=1;
end;
$$;
revoke all on function public.finish_message_delivery(uuid,uuid,boolean,text,text,boolean) from public;
grant execute on function public.finish_message_delivery(uuid,uuid,boolean,text,text,boolean) to service_role;


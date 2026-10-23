-- Keep delivery polling paused until the Edge gateway's private scheduler
-- authentication is deployed. Queue rows remain durable and can be dispatched
-- manually by an authenticated administrator in the meantime.
do $$
declare
  job_id bigint;
begin
  select jobid into job_id
  from cron.job
  where jobname = 'tric-gabay-communications';

  if job_id is not null then
    perform cron.unschedule(job_id);
  end if;
end
$$;

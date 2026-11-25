-- Run as an authorized operations administrator:
select public.get_operations_health();
select severity,category,title,detail,metadata,first_seen_at,last_seen_at
from public.operational_alerts where resolved_at is null order by last_seen_at desc limit 100;

-- Server/operator queries below require service/database-owner privileges.
-- Do not grant mobile clients access to cron or the provider expiry queue.
select * from public.operations_health order by metric;
select state,attempts,count(*) from public.checkout_expiry_requests
where state='blocked' or (state='processing' and claim_until<now()-interval '2 minutes')
group by state,attempts;
select j.jobname,d.status,d.return_message,d.start_time,d.end_time
from cron.job_run_details d join cron.job j on j.jobid=d.jobid
where d.status='failed' and d.start_time>now()-interval '1 day' order by d.start_time desc;
select d.profile_id,d.last_seen_at,exists(select 1 from public.bookings b where b.driver_id=d.profile_id
and b.status in ('accepted','replacement_pending','ongoing')) assigned
from public.driver_profiles d cross join public.service_configuration c
where d.is_online and (d.last_seen_at is null or d.last_seen_at<now()-make_interval(secs=>c.stale_heartbeat_seconds));
select channel,status,count(*) from public.message_deliveries
where status='failed' and updated_at>now()-interval '1 day' group by channel,status;
select status,provider_mode,count(*) from public.payments where status='failed'
and updated_at>now()-interval '1 day' group by status,provider_mode;

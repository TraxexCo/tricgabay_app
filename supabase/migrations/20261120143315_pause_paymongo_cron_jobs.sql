-- PayMongo is retired: pause (do not remove) its scheduled jobs.
select cron.alter_job(jobid, active := false) from cron.job
  where jobname in ('expire-paymongo-provider-checkouts', 'monitor-checkout-expiries');

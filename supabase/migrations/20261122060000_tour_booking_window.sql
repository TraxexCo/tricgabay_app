-- Tours can be booked up to a year ahead (was 30 days), so the calendar on
-- the booking screen can offer the coming months. The app limits the day
-- to Monday-Friday outside public holidays and the start to 8:00 AM-1:00 PM
-- (Manila), matching the Municipal Arts, Culture and Tourism Office hours.
do $$
declare
  fn regprocedure;
  definition text;
begin
  for fn in
    select p.oid::regprocedure from pg_proc p
    join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname='create_booking_with_schedule'
  loop
    definition:=pg_get_functiondef(fn);
    if position('interval ''30 days''' in definition)=0 then
      raise exception 'Expected the 30-day window in %', fn;
    end if;
    definition:=replace(definition,'interval ''30 days''','interval ''365 days''');
    definition:=replace(
      definition,
      'between 1 hour and 30 days from now',
      'between 1 hour and 1 year from now'
    );
    execute definition;
  end loop;
end $$;

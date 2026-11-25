-- Keep managed PostGIS objects outside the Data API's public schema.
-- RESTRICT is deliberate: unexpected dependencies abort, never cascade.
set local search_path = pg_catalog, public, extensions;
alter function public.prevent_announcement_audit_mutation() set search_path = pg_catalog, public, extensions;
alter function public.notification_booking_id(text) set search_path = pg_catalog, public, extensions;
alter function public.driver_is_match_eligible(uuid,double precision,double precision,integer,boolean) set search_path = public, extensions;
alter function public.create_ranked_driver_offers(uuid) set search_path = public, extensions;
alter function public.report_pickup_arrival(uuid) set search_path = public, extensions;

do $migration$
declare
 installed_schema text;
 installed_version text;
 item record;
 index_count integer;
begin
 select n.nspname,e.extversion into installed_schema,installed_version
 from pg_extension e join pg_namespace n on n.oid=e.extnamespace where e.extname='postgis';
 if installed_schema='extensions' then return; end if;
 if installed_schema is distinct from 'public' then
   raise exception 'Expected PostGIS in public or extensions; found %',installed_schema;
 end if;
 if exists (
   select 1 from pg_attribute a join pg_class c on c.oid=a.attrelid
   join pg_type t on t.oid=a.atttypid
   where c.relkind in ('r','p') and a.attnum>0 and not a.attisdropped
   and t.typname in ('geometry','geography')
   and not exists(select 1 from pg_depend d where d.classid='pg_class'::regclass and d.objid=c.oid and d.deptype='e')
 ) then raise exception 'Spatial table columns require a separate relocation plan'; end if;
 create temporary table saved_spatial_references on commit drop as select * from public.spatial_ref_sys;
 create temporary table saved_spatial_indexes on commit drop as
   select c.relname,pg_get_indexdef(c.oid) as definition from pg_class c
   join pg_namespace n on n.oid=c.relnamespace
   where n.nspname='public' and c.relkind='i' and c.relname in ('tourist_spots_geo_idx','driver_locations_geo_idx');
 select count(*) into index_count from saved_spatial_indexes;
 if index_count<>2 then raise exception 'Expected both application spatial indexes'; end if;
 for item in select * from saved_spatial_indexes loop
   execute format('drop index public.%I',item.relname);
 end loop;
 -- The managed owner's grants cannot be revoked by postgres. Rebuild at the
 -- same version in an unexposed schema, preserving custom reference systems.
 drop extension postgis restrict;
 execute format('create extension postgis with schema extensions version %L',installed_version);
 insert into extensions.spatial_ref_sys select * from saved_spatial_references on conflict(srid) do nothing;
 for item in select * from saved_spatial_indexes loop
   execute replace(replace(replace(item.definition,'public.st_','extensions.st_'),
     'public.geography','extensions.geography'),'public.geometry','extensions.geometry');
 end loop;
 if not exists(select 1 from extensions.spatial_ref_sys where srid=4326) then
   raise exception 'Required WGS84 reference missing';
 end if;
end
$migration$;
notify pgrst, 'reload schema';

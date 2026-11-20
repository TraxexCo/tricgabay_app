-- Isolated local owner step; hosted postgres cannot revoke managed grants.
-- The final migration isolates PostGIS in the unexposed extensions schema.
do $$
declare item record; extension_schema text;
begin
 select n.nspname into strict extension_schema from pg_extension e
 join pg_namespace n on n.oid=e.extnamespace where e.extname='postgis';
 for item in select p.oid::regprocedure signature,p.proname from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname=extension_schema and p.proname in ('st_estimatedextent','addgeometrycolumn','dropgeometrycolumn','dropgeometrytable','populate_geometry_columns','updategeometrysrid','postgis_extensions_upgrade')
 loop
   if item.proname='st_estimatedextent' then
     execute format('alter function %s set search_path=pg_catalog,%I,pg_temp',item.signature,extension_schema);
   end if;
   execute format('revoke execute on function %s from public,anon,authenticated',item.signature);
   execute format('grant execute on function %s to service_role',item.signature);
 end loop;
 execute format('revoke insert,update,delete,truncate,references,trigger on %I.spatial_ref_sys,%I.geography_columns,%I.geometry_columns from public,anon,authenticated',extension_schema,extension_schema,extension_schema);
end $$;

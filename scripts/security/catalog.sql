select jsonb_build_object(
 'relations',(select jsonb_agg(jsonb_build_object('key',n.nspname||'.'||c.relname,'kind',c.relkind,'rls',c.relrowsecurity,
   'privileges',(select jsonb_object_agg(role,jsonb_build_object('select',has_table_privilege(role,c.oid,'SELECT'),'insert',has_table_privilege(role,c.oid,'INSERT'),'update',has_table_privilege(role,c.oid,'UPDATE'),'delete',has_table_privilege(role,c.oid,'DELETE'))) from unnest(array['anon','authenticated','service_role'])role),
   'columns',(select jsonb_agg(jsonb_build_object('name',a.attname,'type',format_type(a.atttypid,a.atttypmod),'generated',a.attgenerated,'identity',a.attidentity) order by a.attnum) from pg_attribute a where a.attrelid=c.oid and a.attnum>0 and not a.attisdropped),
   'policies',(select jsonb_agg(jsonb_build_object('name',polname,'command',polcmd,'roles',(select array_agg(rolname order by rolname) from pg_roles where oid=any(polroles)),'using',pg_get_expr(polqual,polrelid),'check',pg_get_expr(polwithcheck,polrelid)) order by polname) from pg_policy where polrelid=c.oid)) order by n.nspname,c.relname)
   from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname in ('public','storage') and c.relkind in ('r','p','v','m')),
 'functions',(select jsonb_agg(jsonb_build_object('key',format('%I.%I(%s)',n.nspname,p.proname,oidvectortypes(p.proargtypes)),'name',p.proname,'schema',n.nspname,
   'definer',p.prosecdef,'search_path',(select split_part(x,'=',2) from unnest(p.proconfig)x where x like 'search_path=%'),
   'privileges',(select jsonb_object_agg(role,has_function_privilege(role,p.oid,'EXECUTE')) from unnest(array['anon','authenticated','service_role'])role),
   'execute_roles',case when p.prosecdef then (select jsonb_agg(rolname order by rolname) from pg_roles where has_function_privilege(oid,p.oid,'EXECUTE')) end,
   'public_execute',exists(select 1 from aclexplode(coalesce(p.proacl,acldefault('f',p.proowner)))a where a.grantee=0 and a.privilege_type='EXECUTE'),
   'argtypes',oidvectortypes(p.proargtypes),'result',pg_get_function_result(p.oid),'strict',p.proisstrict,'volatility',p.provolatile,
   'extension',(select e.extname from pg_depend d join pg_extension e on e.oid=d.refobjid where d.classid='pg_proc'::regclass and d.objid=p.oid and d.deptype='e'),
   'definition_hash',md5(pg_get_functiondef(p.oid))) order by n.nspname,p.proname,oidvectortypes(p.proargtypes))
   from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname in ('public','storage') and p.prokind='f'),
 'buckets',(select jsonb_agg(jsonb_build_object('key',id,'public',public,'max_bytes',file_size_limit,'mime_types',allowed_mime_types) order by id) from storage.buckets)
);

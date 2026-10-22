insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('app-assets','app-assets',true,1048576,array['image/png'])
on conflict(id) do update set public=true,file_size_limit=1048576,allowed_mime_types=array['image/png'];

drop policy if exists app_assets_public_read on storage.objects;
create policy app_assets_public_read on storage.objects for select
using(bucket_id='app-assets');

drop policy if exists app_assets_admin_insert on storage.objects;
create policy app_assets_admin_insert on storage.objects for insert to authenticated
with check(bucket_id='app-assets' and public.is_admin());

drop policy if exists app_assets_admin_update on storage.objects;
create policy app_assets_admin_update on storage.objects for update to authenticated
using(bucket_id='app-assets' and public.is_admin())
with check(bucket_id='app-assets' and public.is_admin());

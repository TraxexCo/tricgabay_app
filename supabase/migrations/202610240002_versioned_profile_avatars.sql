-- Preserve the legacy object while allowing safe, unique replacements under
-- <owner>/avatars/<random>.(jpg|png). Ownership stays at the first path segment.
drop policy if exists profile_images_own_read on storage.objects;
drop policy if exists profile_images_own_insert on storage.objects;
drop policy if exists profile_images_own_update on storage.objects;
drop policy if exists profile_images_own_delete on storage.objects;

create policy profile_images_own_read on storage.objects
for select to authenticated using (
  bucket_id='profile-images' and (
    name=auth.uid()::text||'/avatar.jpg'
    or (
      name like auth.uid()::text||'/avatars/%'
      and storage.extension(name) in ('jpg','png')
    )
  )
);
create policy profile_images_own_insert on storage.objects
for insert to authenticated with check (
  bucket_id='profile-images'
  and name like auth.uid()::text||'/avatars/%'
  and storage.extension(name) in ('jpg','png')
);
create policy profile_images_own_update on storage.objects
for update to authenticated using (
  bucket_id='profile-images'
  and name like auth.uid()::text||'/avatars/%'
  and storage.extension(name) in ('jpg','png')
) with check (
  bucket_id='profile-images'
  and name like auth.uid()::text||'/avatars/%'
  and storage.extension(name) in ('jpg','png')
);
create policy profile_images_own_delete on storage.objects
for delete to authenticated using (
  bucket_id='profile-images' and (
    name=auth.uid()::text||'/avatar.jpg'
    or (
      name like auth.uid()::text||'/avatars/%'
      and storage.extension(name) in ('jpg','png')
    )
  )
);

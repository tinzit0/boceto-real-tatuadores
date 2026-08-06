-- Ejecutar en Supabase Dashboard > SQL Editor.
-- Necesario para permitir que los clientes suban comprobantes y referencias
-- usando la clave pública (anon) de la página.

-- La página usa getPublicUrl() para mostrar las imágenes en el panel.
update storage.buckets
set public = true
where id = 'tattoo-ideas';

drop policy if exists "Public can upload tattoo files" on storage.objects;
create policy "Public can upload tattoo files"
on storage.objects
for insert
to anon, authenticated
with check (bucket_id = 'tattoo-ideas');

-- getPublicUrl() requiere que los objetos puedan leerse públicamente.
drop policy if exists "Public can read tattoo files" on storage.objects;
create policy "Public can read tattoo files"
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'tattoo-ideas');

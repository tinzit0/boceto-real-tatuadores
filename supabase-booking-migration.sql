-- Ejecutar una vez en Supabase > SQL Editor antes de publicar el index.html nuevo.
-- Separa el correo del usuario de Instagram y protege en base de datos el margen de 5 horas.

alter table public.hipso_bookings
    add column if not exists client_instagram text;

-- Los registros antiguos guardaban Instagram dentro de client_email.
update public.hipso_bookings
set client_instagram = client_email,
    client_email = ''
where coalesce(client_instagram, '') = ''
  and coalesce(client_email, '') <> '';

create or replace function public.hipso_enforce_booking_buffer()
returns trigger
language plpgsql
set search_path = public
as $$
begin
    if coalesce(new.status, '') ilike '%Cancelada%' then
        return new;
    end if;

    -- Serializa intentos para el mismo día y evita carreras entre dos clientes.
    perform pg_advisory_xact_lock(hashtext(new.date::text));

    if exists (
        select 1
        from public.hipso_bookings existing
        where existing.date = new.date
          and existing.id is distinct from new.id
          and coalesce(existing.status, '') not ilike '%Cancelada%'
          and abs(extract(epoch from (existing.time::time - new.time::time)) / 60) <= 300
    ) then
        raise exception 'Debe existir un margen superior a 5 horas entre reservas'
            using errcode = '23505';
    end if;

    return new;
end;
$$;

drop trigger if exists hipso_booking_buffer_trigger on public.hipso_bookings;
create trigger hipso_booking_buffer_trigger
before insert or update of date, time, status
on public.hipso_bookings
for each row
execute function public.hipso_enforce_booking_buffer();

-- Lo mínimo de Supabase que el esquema de ANPAEL necesita para crearse en un
-- Postgres común (tests de integración con Testcontainers). No es Supabase:
-- auth.uid() siempre devuelve null, que es justo lo que ve el backend en
-- producción (ADR-001: se conecta con un solo rol de base, sin usuario de
-- Supabase Auth), así que el trigger forzar_autoria() se comporta igual.
--
-- Corre antes que esquema_*.sql (orden alfabético de /docker-entrypoint-initdb.d).

-- los roles que nombran las políticas RLS y los GRANT de las migraciones
create role anon nologin;
create role authenticated nologin;
create role service_role nologin;

-- persona.id_auth_user tiene FK a auth.users; persona_actual()/forzar_autoria() llaman a auth.uid()
create schema auth;
create table auth.users (id uuid primary key);
create function auth.uid() returns uuid language sql stable as $$ select null::uuid $$;

-- donde Supabase instala las extensiones (btree_gist, migración 20260929120000)
create schema extensions;

-- v_pendiente lee la bitácora de la migración desde Excel
create schema stg;
create table stg.mig_pendiente (
    id_pendiente integer not null,
    hoja         text,
    fila_excel   integer,
    motivo       text not null,
    detalle      text,
    resuelto_en  text
);

-- el dump trae su propio CREATE SCHEMA public
drop schema public cascade;

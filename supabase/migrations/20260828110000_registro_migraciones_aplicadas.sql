-- Registro de qué migración corrió y cuándo. supabase/migrations/README.md
-- ya señala el problema ("no queda registro de qué se corrió ni en qué
-- orden") sin resolverlo: esto lo cierra. No reemplaza el orden de los
-- archivos -eso lo sigue dando el timestamp del nombre-, solo permite
-- preguntar, en cualquier entorno, con certeza:
--
--     select version from _migraciones_aplicadas order by version;
--
-- en vez de tener que inferirlo a mano consultando columnas/filas de a una.
--
-- CONVENCIÓN A PARTIR DE ACÁ: toda migración nueva termina con
--
--     insert into _migraciones_aplicadas (version)
--     values ('<nombre_de_archivo_sin_extension>')
--     on conflict (version) do nothing;
--
-- Los 6 archivos anteriores a este no se editan para agregarles esa línea
-- -"un archivo que ya corrió no se edita nunca"-, por eso se backfillean
-- acá, una sola vez.

set search_path to public;

create table if not exists _migraciones_aplicadas (
    version     text primary key,
    aplicada_en timestamptz not null default now()
);

comment on table _migraciones_aplicadas is
  'Qué migración de supabase/migrations/ ya corrió en esta base. aplicada_en '
  'de las primeras 7 filas es la fecha del backfill, no la fecha real en que '
  'corrieron -esa no quedó registrada en ningún lado.';

-- Nueva por default en este esquema: postgres/supabase_admin le dan GRANT
-- completo a anon/authenticated/service_role apenas se crea (default ACL de
-- public). Nadie fuera del backend/SQL Editor necesita leer esto.
revoke all on _migraciones_aplicadas from authenticated, anon;

insert into _migraciones_aplicadas (version) values
  ('20260824100000_agregar_login_persona'),
  ('20260825120000_causa_baja_regularizacion_inicial'),
  ('20260826090000_v_animal_evento_revision_sanidad'),
  ('20260826110000_v_animal_lista_id_rodeo'),
  ('20260826120000_v_animal_lista_id_categoria'),
  ('20260828100000_causa_baja_tipo_regularizacion'),
  ('20260828110000_registro_migraciones_aplicadas')
on conflict (version) do nothing;

-- Comprobación: las 7 versiones están, en orden, y nadie de afuera puede leerlas.
select version, aplicada_en from _migraciones_aplicadas order by version;
-- esperado: 7 filas

select grantee, privilege_type
  from information_schema.table_privileges
 where table_name = '_migraciones_aplicadas' and grantee in ('authenticated', 'anon');
-- esperado: 0 filas

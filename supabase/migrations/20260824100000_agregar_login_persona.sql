-- ADR-001 (sub-decisión credenciales, RESUELTA 2026-08-24, Opción A1):
-- Spring Security valida el login con credenciales propias en `persona`,
-- sin depender de la API de Supabase Auth. Ver docs/decisiones.md.
--
-- `persona` hoy solo tiene id_persona, id_auth_user, nombre y rol: no hay
-- ningún campo para identificar el login, así que se agrega `usuario`
-- separado de `nombre` (nombre es para mostrar, puede repetirse o corregirse
-- sin que eso rompa el acceso de nadie).
--
-- Las dos columnas nullable a propósito: hoy existe una sola `persona`
-- cargada (PROPIETARIO) y todavía no tiene ni usuario ni contraseña. Se
-- completan a mano en un paso aparte, no acá. Cuando los cuatro roles
-- tengan login, se puede evaluar NOT NULL en una migración nueva — no se
-- edita esta.

set search_path to public;

alter table persona
  add column usuario text,
  add column password_hash text;

alter table persona
  add constraint persona_usuario_key unique (usuario);

comment on column persona.usuario is
  'Identificador de login, distinto de nombre. Único cuando no es null.';

comment on column persona.password_hash is
  'Hash BCrypt de la contraseña. Lo valida Spring Security (ADR-001, Opción A1). Nunca texto plano, nunca se expone fuera del backend.';

-- Nadie por fuera del backend necesita leer el hash. Si `persona` tiene
-- GRANT de SELECT para estos roles (mig_20_permisos.sql, o para la app HTML
-- de ADR-004), esta columna queda afuera explícitamente. No falla si el
-- rol nunca tuvo ese privilegio.
revoke select (password_hash) on persona from authenticated, anon;

-- Comprobación: las columnas existen, con el tipo esperado.
select column_name, data_type, is_nullable
  from information_schema.columns
 where table_name = 'persona' and column_name in ('usuario', 'password_hash')
 order by column_name;
-- esperado: 2 filas · text · YES ambas

-- Comprobación: el hash no quedó legible desde afuera del backend.
select grantee, privilege_type
  from information_schema.column_privileges
 where table_name = 'persona' and column_name = 'password_hash';
-- esperado: 0 filas para 'authenticated' y 'anon'

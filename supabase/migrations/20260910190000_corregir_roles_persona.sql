-- persona_rol_check tenía un catálogo de roles (PROPIETARIO, ENCARGADO,
-- PEON, VETERINARIO, ASESOR, OTRO) que nunca coincidió con el modelo real
-- que ya usan backend y frontend (RolPersona.java, stores/auth.ts):
-- PROPIETARIO, GESTOR, GERENTE, OPERATIVO (docs/decisiones.md, ADR-001:
-- "los cuatro roles del negocio"). No se había notado porque hasta ahora
-- solo existía la fila de PROPIETARIO.
--
-- Insertar con el rol viejo (ej. ENCARGADO) rompe el login: Hibernate no
-- puede mapear ese texto a RolPersona. Insertar con el rol nuevo (ej.
-- GESTOR) violaba este constraint. Corrijo el constraint para que coincida
-- con el código.
--
-- Las políticas RLS que usan es_gestor() (en base a 'ENCARGADO') quedan
-- huérfanas pero sin efecto real: el backend se conecta como `postgres`,
-- que tiene rolbypassrls = true, así que RLS no se aplica a la app.

set search_path to public;

alter table persona drop constraint persona_rol_check;
alter table persona add constraint persona_rol_check
  check (rol = any (array['PROPIETARIO', 'GESTOR', 'GERENTE', 'OPERATIVO']));

insert into _migraciones_aplicadas (version)
values ('20260910190000_corregir_roles_persona')
on conflict (version) do nothing;

-- Comprobación
select conname, pg_get_constraintdef(oid) from pg_constraint where conname = 'persona_rol_check';

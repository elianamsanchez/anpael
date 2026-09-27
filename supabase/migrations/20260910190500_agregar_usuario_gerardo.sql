-- Alta de Gerardo, perfil de gestión (GESTOR). Requiere que ya haya corrido
-- 20260910190000_corregir_roles_persona.sql (agrega GESTOR al constraint).
--
-- Esta migración NO carga password_hash: igual que con el PROPIETARIO
-- (docs/decisiones.md, ADR-001 · A1), la contraseña inicial se setea a
-- mano contra la base real, para no dejar un hash -ni siquiera bcrypt-
-- comprometido con el historial de git. Después del alta, hay que
-- actualizar password_hash con BCrypt costo 10 (el mismo que usa
-- BCryptPasswordEncoder en backend/.../shared/config/SecurityConfig.java)
-- para que el login funcione.

set search_path to public;

insert into persona (nombre, rol, usuario)
values ('Gerardo', 'GESTOR', 'gerardo')
on conflict (usuario) do nothing;

insert into _migraciones_aplicadas (version)
values ('20260910190500_agregar_usuario_gerardo')
on conflict (version) do nothing;

-- Comprobación (tiene_pass da false hasta que se setee la contraseña a mano)
select id_persona, nombre, rol, usuario, (password_hash is not null) as tiene_pass
  from persona where usuario = 'gerardo';

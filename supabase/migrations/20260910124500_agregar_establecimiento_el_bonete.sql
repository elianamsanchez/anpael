-- Agrega el establecimiento El Bonete (CUIG W589) al catálogo.

set search_path to public;

insert into establecimiento (cuig, nombre, es_propio)
values ('W589', 'El Bonete', false)
on conflict (cuig) do nothing;

insert into _migraciones_aplicadas (version)
values ('20260910124500_agregar_establecimiento_el_bonete')
on conflict (version) do nothing;

-- Comprobación: el establecimiento existe.
select id_establecimiento, cuig, nombre, es_propio, activo
  from establecimiento
 where cuig = 'W589';
-- esperado: 1 fila

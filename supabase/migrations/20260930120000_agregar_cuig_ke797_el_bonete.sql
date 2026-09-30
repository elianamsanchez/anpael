-- Agrega un segundo CUIG de El Bonete: KE797 (el primero es W589,
-- migración 20260910124500).
--
-- En el modelo cada fila de establecimiento tiene un solo CUIG, así que un
-- CUIG más del mismo campo es otra fila con el mismo nombre -igual que
-- Santa Ana con PC269 y Al154-. En los combos se distinguen por el CUIG:
-- "El Bonete (W589)" y "El Bonete (KE797)". Queda como tercero (no propio)
-- y activo, igual que W589.

set search_path to public;

insert into establecimiento (cuig, nombre, es_propio)
values ('KE797', 'El Bonete', false)
on conflict (cuig) do nothing;

insert into _migraciones_aplicadas (version)
values ('20260930120000_agregar_cuig_ke797_el_bonete')
on conflict (version) do nothing;

-- Comprobación: El Bonete queda con sus dos CUIG.
select id_establecimiento, cuig, nombre, es_propio, activo
  from establecimiento
 where nombre = 'El Bonete'
 order by cuig;
-- esperado: 2 filas (KE797 y W589), las dos activas y no propias

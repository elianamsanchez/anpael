-- Agrega el establecimiento Scioli (CUIG AR298) al catálogo.

set search_path to public;

insert into establecimiento (cuig, nombre, es_propio)
values ('AR298', 'Scioli', false)
on conflict (cuig) do nothing;

insert into _migraciones_aplicadas (version)
values ('20260910123500_agregar_establecimiento_scioli')
on conflict (version) do nothing;

-- Comprobación: el establecimiento existe.
select id_establecimiento, cuig, nombre, es_propio, activo
  from establecimiento
 where cuig = 'AR298';
-- esperado: 1 fila

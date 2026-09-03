-- Migración: "Descarte" siempre último en el combo de rodeos
-- ANPAEL — 2026-09-03
--
-- Pedido del usuario en el chat: Descarte admite cualquier categoría (no
-- tiene fila en rodeo_categoria), así que aparece en el combo filtrado de
-- cualquier categoría que se elija — y ahí siempre tiene que quedar último,
-- no en el medio del orden 10-180 de los demás rodeos.
--
-- Se le pone un orden más alto que cualquier rodeo activo (990). No se usa
-- el rango 900-950 porque ese es el de los rodeos dados de baja -Descarte
-- sigue activo, esto es un orden real, no un "no importa".

set search_path to public;

UPDATE rodeo SET orden = 990 WHERE id_establecimiento = 10 AND nombre = 'Descarte';

-- Comprobación: Descarte queda con el orden más alto entre los activos.
SELECT nombre, orden FROM rodeo WHERE id_establecimiento = 10 AND activo = true ORDER BY orden;

insert into _migraciones_aplicadas (version)
values ('20260903210000_descarte_ultimo_en_orden')
on conflict (version) do nothing;

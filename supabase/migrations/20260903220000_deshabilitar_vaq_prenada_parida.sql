-- Migración: deshabilitar las categorías Vaquillona Preñada / Vaquillona Parida
-- ANPAEL — 2026-09-03
--
-- Pedido del usuario en el chat: esas dos categorías ya no se usan -pasaron
-- a ser rodeos de la categoría "Vaquillona 24 meses" (categorias_rodeos_v3
-- ya había migrado los animales que tenían, quedan 0 hoy). Se agrega
-- "activo" a categoria, mismo patrón que "rodeo.activo": no se borra la
-- fila (conserva el historial de animal_categoria), pero deja de listarse
-- en el combo de asignar categoría.

set search_path to public;

ALTER TABLE categoria ADD COLUMN IF NOT EXISTS activo boolean NOT NULL DEFAULT true;

UPDATE categoria SET activo = false WHERE codigo IN ('VAQ_PRENADA', 'VAQ_PARIDA');

insert into _migraciones_aplicadas (version)
values ('20260903220000_deshabilitar_vaq_prenada_parida')
on conflict (version) do nothing;

-- Comprobación: las dos quedan inactivas, el resto activo.
select codigo, nombre, activo from categoria order by orden;

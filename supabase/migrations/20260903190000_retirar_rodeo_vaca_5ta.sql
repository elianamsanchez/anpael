-- Migración: retirar el rodeo "Vaca 5ta"
-- ANPAEL — 2026-09-03
--
-- Antes de aplicar (según el flujo ya establecido):
--   1) supabase db dump   (backup obligatorio)
--   2) Revisar a mano cada bloque marcado DESTRUCTIVO abajo
--   3) supabase db push
--
-- categorias_rodeos_v3 dejó "Vaca 5ta" activo a propósito ("decisión de
-- campo, no modelada") porque tenía 22 animales sin reasignar. Pedido del
-- usuario en el chat: esos 22 (todos categoría Vaca +4 hoy) van a "Rodeo
-- General 1", que ya admite esa categoría (rodeo_categoria, migración
-- anterior). El rodeo se da de baja (activo=false), mismo patrón que
-- Novillito/Torito/CUT/Ternera/Ternero: no se borra la fila, para no perder
-- el historial de animal_rodeo.

BEGIN;

-- ============================================================
-- DESTRUCTIVO: mover los 22 animales de "Vaca 5ta" -> "Rodeo General 1"
-- ============================================================
WITH cerrados AS (
  UPDATE animal_rodeo ar
  SET fecha_hasta = CURRENT_DATE
  FROM rodeo r
  WHERE ar.id_rodeo = r.id_rodeo
    AND r.id_establecimiento = 10
    AND r.nombre = 'Vaca 5ta'
    AND ar.fecha_hasta IS NULL
  RETURNING ar.id_animal
)
INSERT INTO animal_rodeo (id_animal, id_rodeo, fecha_desde)
SELECT id_animal,
       (SELECT id_rodeo FROM rodeo WHERE id_establecimiento = 10 AND nombre = 'Rodeo General 1'),
       CURRENT_DATE
FROM cerrados;

UPDATE rodeo SET activo = false
WHERE id_establecimiento = 10 AND nombre = 'Vaca 5ta';

COMMIT;

-- ============================================================
-- Verificación sugerida después de aplicar
-- ============================================================
-- SELECT activo FROM rodeo WHERE nombre = 'Vaca 5ta';                                    -- false
-- SELECT count(*) FROM animal_rodeo ar JOIN rodeo r ON r.id_rodeo = ar.id_rodeo
--  WHERE r.nombre = 'Vaca 5ta' AND ar.fecha_hasta IS NULL;                                -- 0
-- SELECT count(*) FROM animal_rodeo ar JOIN rodeo r ON r.id_rodeo = ar.id_rodeo
--  WHERE r.nombre = 'Rodeo General 1' AND ar.fecha_hasta IS NULL AND ar.fecha_desde = CURRENT_DATE; -- 22

-- Migración: ajustar reglas categoría-rodeo + split Ternera/Ternero
-- ANPAEL — 2026-09-03
--
-- Antes de aplicar (según el flujo ya establecido):
--   1) supabase db dump   (backup obligatorio)
--   2) Revisar a mano cada bloque marcado DESTRUCTIVO abajo
--   3) supabase db push
--
-- Pedido del usuario en el chat (después de categorias_rodeos_v3): completar
-- las reglas de rodeo_categoria que faltaban y separar "Ternera"/"Ternero"
-- en variantes "destetada"/"en Feedlot".
--
-- Decisiones tomadas al traducir el pedido:
--   - Descarte queda SIN restricción a propósito (como ya estaba). El pedido
--     lo lista en las 13 categorías mencionadas, que es la forma de decir
--     "cualquiera puede ir ahí" -agregar 13 filas hubiera dejado a MEJ (que
--     no se mencionó) sin poder usarlo, justo lo contrario de la intención.
--   - Tropa de Venta SÍ pasa a tener restricción (hoy no tenía ninguna): el
--     pedido la lista solo para Ternero/Torito/Novillito/Novillo, nunca para
--     Toro ni para ninguna categoría de hembra. Si no era la intención, se
--     revierte borrando esas filas de rodeo_categoria (ver verificación al
--     final para encontrarlas).
--   - Vaca +4 (VACA5) y CUT ya tenían Rodeo General 1/2 desde
--     categorias_rodeos_v3: no se tocan.
--   - MEJ no se mencionó: sigue con la regla que ya tenía (Novillitos, MEJ y
--     toritos).
--   - "Todas las terneras/terneros de hoy están destetados" (confirmado):
--     se migran TODOS a "Ternera destetada" / "Terneros destetados"; los
--     rodeos "en Feedlot" quedan creados pero vacíos.
--
-- Qué hace este script:
--   1. Crea los rodeos: "Ternera destetada", "Ternera en Feedlot",
--      "Terneros destetados", "Terneros en Feedlot"
--   2. Migra todos los animales de "Ternera" -> "Ternera destetada" y de
--      "Ternero" -> "Terneros destetados"; da de baja los rodeos viejos
--   3. Agrega a rodeo_categoria las reglas que faltaban (detalle arriba)

BEGIN;

-- ============================================================
-- 1. Rodeos nuevos: split de Ternera / Ternero
-- ============================================================
INSERT INTO rodeo (id_establecimiento, nombre, descripcion, activo)
SELECT 10, 'Ternera destetada', 'Terneras hembra ya destetadas.', true
WHERE NOT EXISTS (SELECT 1 FROM rodeo WHERE id_establecimiento = 10 AND nombre = 'Ternera destetada');

INSERT INTO rodeo (id_establecimiento, nombre, descripcion, activo)
SELECT 10, 'Ternera en Feedlot', 'Terneras hembra en feedlot.', true
WHERE NOT EXISTS (SELECT 1 FROM rodeo WHERE id_establecimiento = 10 AND nombre = 'Ternera en Feedlot');

INSERT INTO rodeo (id_establecimiento, nombre, descripcion, activo)
SELECT 10, 'Terneros destetados', 'Terneros macho ya destetados.', true
WHERE NOT EXISTS (SELECT 1 FROM rodeo WHERE id_establecimiento = 10 AND nombre = 'Terneros destetados');

INSERT INTO rodeo (id_establecimiento, nombre, descripcion, activo)
SELECT 10, 'Terneros en Feedlot', 'Terneros macho en feedlot.', true
WHERE NOT EXISTS (SELECT 1 FROM rodeo WHERE id_establecimiento = 10 AND nombre = 'Terneros en Feedlot');

-- ============================================================
-- 2. DESTRUCTIVO: migrar todos los animales de "Ternera" -> "Ternera
--    destetada" y de "Ternero" -> "Terneros destetados". Da de baja los
--    rodeos viejos (mismo patrón que Novillito/Torito en categorias_rodeos_v3).
-- ============================================================
WITH cerrados AS (
  UPDATE animal_rodeo ar
  SET fecha_hasta = CURRENT_DATE
  FROM rodeo r
  WHERE ar.id_rodeo = r.id_rodeo
    AND r.id_establecimiento = 10
    AND r.nombre = 'Ternera'
    AND ar.fecha_hasta IS NULL
  RETURNING ar.id_animal
)
INSERT INTO animal_rodeo (id_animal, id_rodeo, fecha_desde)
SELECT id_animal,
       (SELECT id_rodeo FROM rodeo WHERE id_establecimiento = 10 AND nombre = 'Ternera destetada'),
       CURRENT_DATE
FROM cerrados;

WITH cerrados AS (
  UPDATE animal_rodeo ar
  SET fecha_hasta = CURRENT_DATE
  FROM rodeo r
  WHERE ar.id_rodeo = r.id_rodeo
    AND r.id_establecimiento = 10
    AND r.nombre = 'Ternero'
    AND ar.fecha_hasta IS NULL
  RETURNING ar.id_animal
)
INSERT INTO animal_rodeo (id_animal, id_rodeo, fecha_desde)
SELECT id_animal,
       (SELECT id_rodeo FROM rodeo WHERE id_establecimiento = 10 AND nombre = 'Terneros destetados'),
       CURRENT_DATE
FROM cerrados;

UPDATE rodeo SET activo = false
WHERE id_establecimiento = 10 AND nombre IN ('Ternera', 'Ternero');

-- ============================================================
-- 3. Reglas nuevas en rodeo_categoria
-- ============================================================

-- Ternera -> Ternera destetada, Ternera en Feedlot
INSERT INTO rodeo_categoria (id_rodeo, id_categoria)
SELECT r.id_rodeo, c.id_categoria
FROM rodeo r CROSS JOIN categoria c
WHERE r.id_establecimiento = 10 AND r.nombre IN ('Ternera destetada', 'Ternera en Feedlot')
  AND c.codigo = 'TERNERA'
ON CONFLICT (id_rodeo, id_categoria) DO NOTHING;

-- Ternero -> Terneros destetados, Terneros en Feedlot, Tropa de Venta
INSERT INTO rodeo_categoria (id_rodeo, id_categoria)
SELECT r.id_rodeo, c.id_categoria
FROM rodeo r CROSS JOIN categoria c
WHERE r.id_establecimiento = 10 AND r.nombre IN ('Terneros destetados', 'Terneros en Feedlot', 'Tropa de Venta')
  AND c.codigo = 'TERNERO'
ON CONFLICT (id_rodeo, id_categoria) DO NOTHING;

-- Vaquillona 12M -> Vaquillona 12M
INSERT INTO rodeo_categoria (id_rodeo, id_categoria)
SELECT r.id_rodeo, c.id_categoria
FROM rodeo r CROSS JOIN categoria c
WHERE r.id_establecimiento = 10 AND r.nombre = 'Vaquillona 12M' AND c.codigo = 'VAQ12M'
ON CONFLICT (id_rodeo, id_categoria) DO NOTHING;

-- Vaquillona 24M -> Vaquillona Preñada, Vaquillona Parida (Vaquillona a Servicio ya existe)
INSERT INTO rodeo_categoria (id_rodeo, id_categoria)
SELECT r.id_rodeo, c.id_categoria
FROM rodeo r CROSS JOIN categoria c
WHERE r.id_establecimiento = 10 AND r.nombre IN ('Vaquillona Preñada', 'Vaquillona Parida')
  AND c.codigo = 'VAQ24M'
ON CONFLICT (id_rodeo, id_categoria) DO NOTHING;

-- Vaca 2da -> Vaca 2da
INSERT INTO rodeo_categoria (id_rodeo, id_categoria)
SELECT r.id_rodeo, c.id_categoria
FROM rodeo r CROSS JOIN categoria c
WHERE r.id_establecimiento = 10 AND r.nombre = 'Vaca 2da' AND c.codigo = 'VACA2'
ON CONFLICT (id_rodeo, id_categoria) DO NOTHING;

-- Vaca 3era -> Vaca 3era (Rodeo General 1/2 ya la admitía)
INSERT INTO rodeo_categoria (id_rodeo, id_categoria)
SELECT r.id_rodeo, c.id_categoria
FROM rodeo r CROSS JOIN categoria c
WHERE r.id_establecimiento = 10 AND r.nombre = 'Vaca 3era' AND c.codigo = 'VACA3'
ON CONFLICT (id_rodeo, id_categoria) DO NOTHING;

-- Vaca 4ta -> Vaca 4ta (Rodeo General 1/2 ya la admitía)
INSERT INTO rodeo_categoria (id_rodeo, id_categoria)
SELECT r.id_rodeo, c.id_categoria
FROM rodeo r CROSS JOIN categoria c
WHERE r.id_establecimiento = 10 AND r.nombre = 'Vaca 4ta' AND c.codigo = 'VACA4'
ON CONFLICT (id_rodeo, id_categoria) DO NOTHING;

-- Novillo -> Novillo, Tropa de Venta
INSERT INTO rodeo_categoria (id_rodeo, id_categoria)
SELECT r.id_rodeo, c.id_categoria
FROM rodeo r CROSS JOIN categoria c
WHERE r.id_establecimiento = 10 AND r.nombre IN ('Novillo', 'Tropa de Venta') AND c.codigo = 'NOVILLO'
ON CONFLICT (id_rodeo, id_categoria) DO NOTHING;

-- Torito -> Tropa de Venta (Novillitos, MEJ y toritos ya la admitía)
INSERT INTO rodeo_categoria (id_rodeo, id_categoria)
SELECT r.id_rodeo, c.id_categoria
FROM rodeo r CROSS JOIN categoria c
WHERE r.id_establecimiento = 10 AND r.nombre = 'Tropa de Venta' AND c.codigo = 'TORITO'
ON CONFLICT (id_rodeo, id_categoria) DO NOTHING;

-- Novillito -> Tropa de Venta (Novillitos, MEJ y toritos ya la admitía)
INSERT INTO rodeo_categoria (id_rodeo, id_categoria)
SELECT r.id_rodeo, c.id_categoria
FROM rodeo r CROSS JOIN categoria c
WHERE r.id_establecimiento = 10 AND r.nombre = 'Tropa de Venta' AND c.codigo = 'NOVILLITO'
ON CONFLICT (id_rodeo, id_categoria) DO NOTHING;

-- Toro -> Toro (sin Tropa de Venta)
INSERT INTO rodeo_categoria (id_rodeo, id_categoria)
SELECT r.id_rodeo, c.id_categoria
FROM rodeo r CROSS JOIN categoria c
WHERE r.id_establecimiento = 10 AND r.nombre = 'Toro' AND c.codigo = 'TORO'
ON CONFLICT (id_rodeo, id_categoria) DO NOTHING;

COMMIT;

-- ============================================================
-- Verificación sugerida después de aplicar
-- ============================================================
-- SELECT c.nombre AS categoria, string_agg(r.nombre, ', ' ORDER BY r.nombre) AS rodeos_admitidos
-- FROM categoria c
-- LEFT JOIN rodeo_categoria rc ON rc.id_categoria = c.id_categoria
-- LEFT JOIN rodeo r ON r.id_rodeo = rc.id_rodeo
-- GROUP BY c.nombre ORDER BY c.nombre;
--
-- SELECT r.nombre, count(*) FROM animal_rodeo ar JOIN rodeo r ON r.id_rodeo = ar.id_rodeo
-- WHERE ar.fecha_hasta IS NULL AND r.nombre IN ('Ternera destetada','Ternera en Feedlot','Terneros destetados','Terneros en Feedlot')
-- GROUP BY r.nombre;

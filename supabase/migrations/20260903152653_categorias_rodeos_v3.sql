-- Migración: catálogo de categorías y rodeos v3
-- ANPAEL — 2026-09-03
--
-- Antes de aplicar (según el flujo ya establecido):
--   1) supabase db dump   (backup obligatorio)
--   2) Revisar a mano cada bloque marcado DESTRUCTIVO abajo
--   3) supabase db push
--1
-- Qué hace este script:
--   1. Agrega la categoría MEJ (Macho Entero Joven)
--   2. Renombra la categoría VACA5 -> "Vaca +4"
--   3. Crea los rodeos: "Novillitos, MEJ y toritos", "Descarte", "Tropa de Venta"
--   4. Renombra el rodeo "Vaquillona 24M" -> "Vaquillona a Servicio" (ver nota, es una asunción)
--   5. Crea la tabla rodeo_categoria (reglas categoría admitida por rodeo) y la puebla
--   6. Migra los animales de VAQ_PRENADA / VAQ_PARIDA a la categoría VAQ24M
--   7. Fusiona los animales de Novillito y Torito al nuevo rodeo "Novillitos, MEJ y toritos"
--      y da de baja (activo=false) los rodeos individuales Novillito y Torito
--   8. Corrige el único caso fuera de regla verificado hoy: 1 animal "Vaquillona Preñada"
--      que estaba en Rodeo General 1 (caravana A256, id_animal 1266)
--   9. Da de baja (activo=false) el rodeo "CUT" (0 animales)
--
-- Qué NO hace este script, a propósito (ver el final del archivo):
--   - No reasigna los 22 animales de "Vaca 5ta" a Rodeo general 1 o 2 (decisión de campo)
--   - No toca los 160 animales sin categoría vigente en Rodeo General 1/2
--   - No resuelve la duda de los 103 animales VACA4/VACA5 (stg.mig_pendiente)
--   - No migra el dato real de "a servicio" (fechas de primer entore) a la tabla `servicio`

BEGIN;

-- ============================================================
-- 1. Categoría nueva: MEJ (Macho Entero Joven)
-- ============================================================
INSERT INTO categoria (codigo, nombre, sexo, orden)
SELECT 'MEJ', 'Macho Entero Joven', 'M', 25
WHERE NOT EXISTS (SELECT 1 FROM categoria WHERE codigo = 'MEJ');
-- orden=25 la ubica entre Novillito(20) y Novillo(30); es un valor sugerido, ajustable.

-- ============================================================
-- 2. Renombrar Vaca 5ta -> Vaca +4 (confirmado: es la misma franja)
-- ============================================================
UPDATE categoria SET nombre = 'Vaca +4'
WHERE codigo = 'VACA5' AND nombre <> 'Vaca +4';
-- El codigo interno "VACA5" se deja sin tocar a propósito, por si hay código de aplicación
-- que lo referencia. Si confirmás que no hay ninguna referencia, se puede renombrar aparte.

-- ============================================================
-- 3. Rodeos nuevos
-- ============================================================
INSERT INTO rodeo (id_establecimiento, nombre, descripcion, activo)
SELECT 10, 'Novillitos, MEJ y toritos',
       'Rodeo multi-categoría: agrupa Novillito, MEJ y Torito.', true
WHERE NOT EXISTS (
  SELECT 1 FROM rodeo WHERE id_establecimiento = 10 AND nombre = 'Novillitos, MEJ y toritos'
);

INSERT INTO rodeo (id_establecimiento, nombre, descripcion, activo)
SELECT 10, 'Descarte',
       'Vacas vacías, vaca/toro descarte, jodidos y CUT sin ternero. Sin lista cerrada de categorías (el criterio es el motivo, no la categoría); convive con la marca administrativa animal_descarte.',
       true
WHERE NOT EXISTS (
  SELECT 1 FROM rodeo WHERE id_establecimiento = 10 AND nombre = 'Descarte'
);

INSERT INTO rodeo (id_establecimiento, nombre, descripcion, activo)
SELECT 10, 'Tropa de Venta', 'Sin restricción de categoría.', true
WHERE NOT EXISTS (
  SELECT 1 FROM rodeo WHERE id_establecimiento = 10 AND nombre = 'Tropa de Venta'
);

-- ============================================================
-- 4. "Vaquillona a Servicio"
-- ============================================================
-- ASUNCIÓN A CONFIRMAR: en vez de crear un rodeo nuevo vacío, se reutiliza y renombra el
-- rodeo "Vaquillona 24M" (hoy tiene los 141 animales VAQ24M que no están en "Vaquillona
-- Preñada" ni en "Vaquillona Parida" — por eliminación, ese es el estado "a servicio").
-- Si "a servicio" debe ser más estricto (solo animales dentro de una campaña de servicio
-- activa en la tabla `servicio`), esto hay que revisarlo cuando se migre el dato pendiente
-- en stg.mig_pendiente (fechas de primer entore, falta definir campaña y tipo).
UPDATE rodeo
SET nombre = 'Vaquillona a Servicio',
    descripcion = 'VAQ24M no incluida en Vaquillona Preñada ni Vaquillona Parida. Redefinir cuando se migre el dato real de servicio (stg.mig_pendiente).'
WHERE id_establecimiento = 10 AND nombre = 'Vaquillona 24M';

-- ============================================================
-- 5. Tabla de reglas categoría-rodeo
-- ============================================================
CREATE TABLE IF NOT EXISTS rodeo_categoria (
    id_rodeo_categoria SERIAL PRIMARY KEY,
    id_rodeo     INT NOT NULL REFERENCES rodeo(id_rodeo),
    id_categoria INT NOT NULL REFERENCES categoria(id_categoria),
    UNIQUE (id_rodeo, id_categoria)
);
COMMENT ON TABLE rodeo_categoria IS
  'Categorías admitidas por rodeo. Un id_rodeo sin ninguna fila acá = sin restricción de categoría (ej. Descarte, Tropa de Venta).';

-- Rodeo general 1 y 2: mismo criterio para ambos — Vaca 3ª, Vaca 4ª, Vaca +4 (ex Vaca 5ta), CUT
INSERT INTO rodeo_categoria (id_rodeo, id_categoria)
SELECT r.id_rodeo, c.id_categoria
FROM rodeo r
CROSS JOIN categoria c
WHERE r.id_establecimiento = 10
  AND r.nombre IN ('Rodeo General 1', 'Rodeo General 2')
  AND c.codigo IN ('VACA3', 'VACA4', 'VACA5', 'CUT')
ON CONFLICT (id_rodeo, id_categoria) DO NOTHING;

-- Novillitos, MEJ y toritos: Novillito, MEJ, Torito
INSERT INTO rodeo_categoria (id_rodeo, id_categoria)
SELECT r.id_rodeo, c.id_categoria
FROM rodeo r
CROSS JOIN categoria c
WHERE r.id_establecimiento = 10
  AND r.nombre = 'Novillitos, MEJ y toritos'
  AND c.codigo IN ('NOVILLITO', 'MEJ', 'TORITO')
ON CONFLICT (id_rodeo, id_categoria) DO NOTHING;

-- Vaquillona a Servicio: se restringe a VAQ24M (a diferencia de Descarte/Tropa de Venta,
-- que quedan sin filas = sin restricción, por decisión explícita)
INSERT INTO rodeo_categoria (id_rodeo, id_categoria)
SELECT r.id_rodeo, c.id_categoria
FROM rodeo r
CROSS JOIN categoria c
WHERE r.id_establecimiento = 10
  AND r.nombre = 'Vaquillona a Servicio'
  AND c.codigo = 'VAQ24M'
ON CONFLICT (id_rodeo, id_categoria) DO NOTHING;

-- Descarte y Tropa de Venta: sin filas a propósito (sin restricción de categoría)

-- ============================================================
-- 6. DESTRUCTIVO: migrar VAQ_PRENADA (127 animales) y VAQ_PARIDA (0) -> categoría VAQ24M
-- ============================================================
-- El rodeo de estos animales NO se toca acá: la gran mayoría ya está en el rodeo correcto
-- ("Vaquillona Preñada" / "Vaquillona Parida"); el único caso fuera de regla se corrige en el paso 8.
WITH cerrados AS (
  UPDATE animal_categoria ac
  SET fecha_hasta = CURRENT_DATE
  FROM categoria c
  WHERE ac.id_categoria = c.id_categoria
    AND c.codigo IN ('VAQ_PRENADA', 'VAQ_PARIDA')
    AND ac.fecha_hasta IS NULL
  RETURNING ac.id_animal
)
INSERT INTO animal_categoria (id_animal, id_categoria, fecha_desde)
SELECT id_animal, (SELECT id_categoria FROM categoria WHERE codigo = 'VAQ24M'), CURRENT_DATE
FROM cerrados;

-- ============================================================
-- 7. DESTRUCTIVO: fusionar Novillito (182) y Torito (30) al rodeo "Novillitos, MEJ y toritos"
-- ============================================================
WITH cerrados AS (
  UPDATE animal_rodeo ar
  SET fecha_hasta = CURRENT_DATE
  FROM rodeo r
  WHERE ar.id_rodeo = r.id_rodeo
    AND r.id_establecimiento = 10
    AND r.nombre IN ('Novillito', 'Torito')
    AND ar.fecha_hasta IS NULL
  RETURNING ar.id_animal
)
INSERT INTO animal_rodeo (id_animal, id_rodeo, fecha_desde)
SELECT id_animal,
       (SELECT id_rodeo FROM rodeo WHERE id_establecimiento = 10 AND nombre = 'Novillitos, MEJ y toritos'),
       CURRENT_DATE
FROM cerrados;

UPDATE rodeo SET activo = false
WHERE id_establecimiento = 10 AND nombre IN ('Novillito', 'Torito');

-- ============================================================
-- 8. DESTRUCTIVO: corregir el caso puntual fuera de regla
-- ============================================================
-- Animal id_animal=1266 (caravana A256), categoría Vaquillona Preñada, verificado en vivo
-- el 2026-09-03 en "Rodeo General 1" — no corresponde, debe estar en "Vaquillona Preñada".
-- id_animal_rodeo=81 es el registro puntual verificado; si este script se corre en otra
-- base o en otro momento, conviene re-verificar antes de aplicar este bloque.
UPDATE animal_rodeo
SET fecha_hasta = CURRENT_DATE
WHERE id_animal_rodeo = 81 AND fecha_hasta IS NULL;

INSERT INTO animal_rodeo (id_animal, id_rodeo, fecha_desde)
SELECT 1266,
       (SELECT id_rodeo FROM rodeo WHERE id_establecimiento = 10 AND nombre = 'Vaquillona Preñada'),
       CURRENT_DATE
WHERE EXISTS (
  SELECT 1 FROM animal_rodeo WHERE id_animal_rodeo = 81 AND fecha_hasta = CURRENT_DATE
);

-- ============================================================
-- 9. Dar de baja el rodeo CUT (0 animales hoy, no requiere reasignación)
-- ============================================================
UPDATE rodeo SET activo = false
WHERE id_establecimiento = 10 AND nombre = 'CUT';

COMMIT;

-- ============================================================
-- Consulta de referencia (NO se ejecuta acá): animales de "Vaca 5ta" pendientes de
-- reasignar manualmente a Rodeo general 1 o 2, según criterio de campo (potrero/manejo).
-- ============================================================
-- SELECT ar.id_animal, i.caravana
-- FROM animal_rodeo ar
-- JOIN rodeo r ON r.id_rodeo = ar.id_rodeo
-- LEFT JOIN v_ident_principal i ON i.id_animal = ar.id_animal
-- WHERE r.id_establecimiento = 10 AND r.nombre = 'Vaca 5ta' AND ar.fecha_hasta IS NULL;

-- ============================================================
-- Verificación sugerida después de aplicar (correr y comparar contra lo esperado)
-- ============================================================
-- SELECT rodeo, categoria, cabezas, pct_del_rodeo FROM v_rodeo_composicion ORDER BY rodeo, categoria;
-- SELECT * FROM rodeo WHERE id_establecimiento = 10 ORDER BY id_rodeo;
-- SELECT * FROM categoria ORDER BY orden;
-- SELECT * FROM rodeo_categoria;

-- ============================================================
-- Pendiente, deliberadamente fuera de este script
-- ============================================================
-- - Reasignar los 22 animales de "Vaca 5ta" a Rodeo general 1 o 2 (decisión de campo, no
--   modelada). El rodeo "Vaca 5ta" queda activo hasta que se resuelva, para no perder la
--   asignación de esos animales.
-- - Investigar los 160 animales sin categoría vigente que están en Rodeo General 1/2.
-- - Cerrar la duda de stg.mig_pendiente sobre los 103 animales VACA4/VACA5 inferidos por
--   año de primer servicio, antes de confiar en esa categoría para reportes.
-- - Migrar el dato real de "a servicio" (fechas de primer entore, columnas AE-AH del Excel
--   original) a la tabla `servicio`, una vez que definas campaña y tipo.

-- Migración: orden de categorías y rodeos para los combos
-- ANPAEL — 2026-09-03
--
-- Antes de aplicar (según el flujo ya establecido):
--   1) supabase db dump   (backup obligatorio)
--   2) Revisar a mano el orden asignado abajo
--   3) supabase db push
--
-- Pedido del usuario en el chat: agregar un orden numérico a categoria (ya
-- existía la columna, solo faltaba actualizar los valores) y a rodeo
-- (columna nueva). El orden sale de la lista categoria->rodeos que pasó en
-- el chat: cada "Categoria" numerada por el orden en que aparece, y cada
-- rodeo numerado por la primera vez que aparece en esa misma lista (Descarte
-- aparece en todas, así que le tocó el lugar de su primera aparición, bajo
-- "Ternera").
--
-- No mencionó VAQ_PRENADA ni VAQ_PARIDA (categorías dadas de baja en
-- categorias_rodeos_v3: sus animales ya se migraron a VAQ24M) ni los rodeos
-- inactivos (Ternera, Ternero, Torito, Novillito, CUT, Vaca 5ta, todos dados
-- de baja en migraciones anteriores). Como ninguno de los dos aparece nunca
-- en un combo (categoria: no se asigna una categoría dada de baja; rodeo:
-- los combos solo traen activo=true), les puse un número alto al final que
-- no importa en la práctica.
--
-- Esta migración por sí sola NO reordena los combos del rodeo: hoy
-- RodeoRepository ordena por nombre, no por esta columna nueva. Hace falta
-- un cambio de código en el backend (Rodeo.java + RodeoRepository) para que
-- la use. Ese cambio ya está escrito, pendiente de aplicar junto con esta
-- migración.

BEGIN;

-- ============================================================
-- 1. Categoria: actualizar los valores de orden (la columna ya existía)
-- ============================================================
UPDATE categoria SET orden = 10  WHERE codigo = 'TERNERA';
UPDATE categoria SET orden = 20  WHERE codigo = 'VAQ12M';
UPDATE categoria SET orden = 30  WHERE codigo = 'VAQ24M';
UPDATE categoria SET orden = 40  WHERE codigo = 'VACA2';
UPDATE categoria SET orden = 50  WHERE codigo = 'VACA3';
UPDATE categoria SET orden = 60  WHERE codigo = 'VACA4';
UPDATE categoria SET orden = 70  WHERE codigo = 'VACA5';
UPDATE categoria SET orden = 80  WHERE codigo = 'CUT';
UPDATE categoria SET orden = 90  WHERE codigo = 'TERNERO';
UPDATE categoria SET orden = 100 WHERE codigo = 'TORITO';
UPDATE categoria SET orden = 110 WHERE codigo = 'NOVILLITO';
UPDATE categoria SET orden = 120 WHERE codigo = 'MEJ';
UPDATE categoria SET orden = 130 WHERE codigo = 'NOVILLO';
UPDATE categoria SET orden = 140 WHERE codigo = 'TORO';
-- Dadas de baja (categorias_rodeos_v3): al final, no aparecen en combos.
UPDATE categoria SET orden = 150 WHERE codigo = 'VAQ_PRENADA';
UPDATE categoria SET orden = 160 WHERE codigo = 'VAQ_PARIDA';

-- ============================================================
-- 2. Rodeo: columna nueva + valores de orden
-- ============================================================
ALTER TABLE rodeo ADD COLUMN IF NOT EXISTS orden integer;

UPDATE rodeo SET orden = 10  WHERE id_establecimiento = 10 AND nombre = 'Ternera destetada';
UPDATE rodeo SET orden = 20  WHERE id_establecimiento = 10 AND nombre = 'Ternera en Feedlot';
UPDATE rodeo SET orden = 30  WHERE id_establecimiento = 10 AND nombre = 'Descarte';
UPDATE rodeo SET orden = 40  WHERE id_establecimiento = 10 AND nombre = 'Vaquillona 12M';
UPDATE rodeo SET orden = 50  WHERE id_establecimiento = 10 AND nombre = 'Vaquillona a Servicio';
UPDATE rodeo SET orden = 60  WHERE id_establecimiento = 10 AND nombre = 'Vaquillona Preñada';
UPDATE rodeo SET orden = 70  WHERE id_establecimiento = 10 AND nombre = 'Vaquillona Parida';
UPDATE rodeo SET orden = 80  WHERE id_establecimiento = 10 AND nombre = 'Vaca 2da';
UPDATE rodeo SET orden = 90  WHERE id_establecimiento = 10 AND nombre = 'Vaca 3era';
UPDATE rodeo SET orden = 100 WHERE id_establecimiento = 10 AND nombre = 'Rodeo General 1';
UPDATE rodeo SET orden = 110 WHERE id_establecimiento = 10 AND nombre = 'Rodeo General 2';
UPDATE rodeo SET orden = 120 WHERE id_establecimiento = 10 AND nombre = 'Vaca 4ta';
UPDATE rodeo SET orden = 130 WHERE id_establecimiento = 10 AND nombre = 'Terneros destetados';
UPDATE rodeo SET orden = 140 WHERE id_establecimiento = 10 AND nombre = 'Terneros en Feedlot';
UPDATE rodeo SET orden = 150 WHERE id_establecimiento = 10 AND nombre = 'Tropa de Venta';
UPDATE rodeo SET orden = 160 WHERE id_establecimiento = 10 AND nombre = 'Novillitos, MEJ y toritos';
UPDATE rodeo SET orden = 170 WHERE id_establecimiento = 10 AND nombre = 'Novillo';
UPDATE rodeo SET orden = 180 WHERE id_establecimiento = 10 AND nombre = 'Toro';
-- Dados de baja (migraciones anteriores): al final, no aparecen en combos
-- (RodeoRepository solo trae activo=true).
UPDATE rodeo SET orden = 900 WHERE id_establecimiento = 10 AND nombre = 'Ternero';
UPDATE rodeo SET orden = 910 WHERE id_establecimiento = 10 AND nombre = 'Novillito';
UPDATE rodeo SET orden = 920 WHERE id_establecimiento = 10 AND nombre = 'Torito';
UPDATE rodeo SET orden = 930 WHERE id_establecimiento = 10 AND nombre = 'Ternera';
UPDATE rodeo SET orden = 940 WHERE id_establecimiento = 10 AND nombre = 'Vaca 5ta';
UPDATE rodeo SET orden = 950 WHERE id_establecimiento = 10 AND nombre = 'CUT';

ALTER TABLE rodeo ALTER COLUMN orden SET NOT NULL;

COMMIT;

-- ============================================================
-- Verificación sugerida después de aplicar
-- ============================================================
-- SELECT nombre, orden FROM categoria ORDER BY orden;
-- SELECT nombre, orden, activo FROM rodeo WHERE id_establecimiento = 10 ORDER BY orden;
-- SELECT count(*) FROM rodeo WHERE orden IS NULL;   -- 0

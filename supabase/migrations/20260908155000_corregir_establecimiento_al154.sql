-- Corrige en bloque los animales que en el Excel original tenían CUIG
-- Al154 (o Al-154) y quedaron unificados a PC269 por mig_17_unificar_cuig.sql
-- ("es el mismo campo, otra sociedad"). La unificación en sí es correcta
-- -es el mismo campo físico-, pero para trámites puntuales (ej. SENASA)
-- hace falta conservar cuál era el CUIG real al momento del hecho, no el
-- vigente hoy.
--
-- Reconstruido desde las tablas de staging de la migración (stg.*), que
-- todavía tienen el dato crudo del Excel por fila -no desde una lista a
-- mano-. Dos formas de origen:
--   - 4 planillas con CUIG explícito por fila: Vac 5ta y 4ta 18-19,
--     Vaca3ra nro20, Vacas 4ta 2026, Vaq 2da 21.
--   - 3 planillas de toros donde el CUIG viene pegado al numero de RP/
--     caravana visual (ej. "AL154-J710").
--
-- Verificado antes de escribir: las caravanas candidatas matchean 1 a 1
-- contra una identificación VISUAL vigente, y todas estaban en PC269 -sin
-- huérfanos, sin casos raros. Corrige TODAS las identificaciones vigentes
-- del animal (no solo la VISUAL): los toros suelen tener FUEGO y VISUAL a
-- la vez, migradas con el mismo establecimiento en las dos filas.
--
-- De paso, dos de esas cuatro planillas (Vaq 2da 21 y Vacas 4ta 2026 nro20
-- ser22) estaban anotadas en stg.map_hoja como "cuig_establecimiento
-- puesto en PC269 por Claude: es el unico establecimiento propio, REVISAR
-- si alguna de estas jornadas se hizo en otro campo" -confirmado=false-.
-- Este archivo es esa revisión: sí, tenían el dato real, y era Al154.

set search_path to public;

with candidatos as (
    select distinct trim(c_c) as caravana
      from stg.stg_vac_5ta_4ta_18_19
     where c_b ilike 'al154' or c_b ilike 'al-154'
    union
    select distinct trim(c_b) as caravana
      from stg.stg_vaca3ra_nro20
     where c_a ilike 'al154' or c_a ilike 'al-154'
    union
    select distinct trim(c_b) as caravana
      from stg.stg_vacas_4ta_2026
     where c_a ilike 'al154' or c_a ilike 'al-154'
    union
    select distinct trim(c_b) as caravana
      from stg.stg_vaq_2da_21
     where c_a ilike 'al154' or c_a ilike 'al-154'
    union
    select distinct trim(split_part(c_b, '-', 2)) as caravana
      from stg.stg_toros_2026
     where c_b ilike 'al154-%'
    union
    select distinct trim(regexp_replace(c_c, '^al-?154\s*-\s*', '', 'i')) as caravana
      from stg.stg_toros_26_3_26
     where c_c ilike 'al154%' or c_c ilike 'al-154%'
    union
    select distinct trim(regexp_replace(c_c, '^al-?154\s*-\s*', '', 'i')) as caravana
      from stg.stg_toros_a_vaquillonas_2026
     where c_c ilike 'al154%' or c_c ilike 'al-154%'
),
animales as (
    select distinct i.id_animal
      from candidatos c
      join identificacion i
        on lower(i.caravana) = lower(c.caravana)
       and i.id_tipo_ident = (select id_tipo_ident from tipo_identificacion where codigo = 'VISUAL')
       and i.fecha_baja is null
)
update identificacion i
   set id_establecimiento = (select id_establecimiento from establecimiento where cuig = 'Al154')
  from animales a
 where i.id_animal = a.id_animal
   and i.fecha_baja is null
   and i.id_establecimiento = (select id_establecimiento from establecimiento where cuig = 'PC269');

insert into _migraciones_aplicadas (version)
values ('20260908155000_corregir_establecimiento_al154')
on conflict (version) do nothing;

-- Comprobación: cuántos animales y cuántas identificaciones vigentes
-- quedaron en Al154. Se espera animales_en_al154 = 442 la primera vez que
-- corre; si corre de nuevo no debería sumar nada más (el UPDATE solo toca
-- filas que hoy están en PC269).
select
    count(distinct id_animal) as animales_en_al154,
    count(*) as identificaciones_en_al154
  from identificacion
 where id_establecimiento = (select id_establecimiento from establecimiento where cuig = 'Al154')
   and fecha_baja is null;

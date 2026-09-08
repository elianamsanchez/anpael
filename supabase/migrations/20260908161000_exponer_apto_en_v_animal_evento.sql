-- Expone revision_toro.apto como columna propia de v_animal_evento -hoy
-- solo estaba mezclado adentro del texto de `detalle` ("Revision apto ·
-- CC 4.00 · dentadura BLL"), igual que condicion_corporal y dentadura ya
-- lo estaban por separado. Sirve para resaltarlo con una etiqueta de color
-- en el historial en vez de tener que leer el texto entero.
--
-- CREATE OR REPLACE VIEW solo permite agregar columnas al final.

set search_path to public;

create or replace view v_animal_evento as
SELECT ev.id_evento,
    ev.id_animal,
    t.fecha,
    t.tipo_trabajo,
    t.observaciones AS jornada,
    est.cuig,
    ev.origen_dato,
    NULLIF(concat_ws(' · '::text,
        CASE
            WHEN dg.id_evento IS NOT NULL THEN (('Tacto '::text || dg.resultado) || COALESCE((' ('::text || dg.tamano) || ')'::text, ''::text)) || COALESCE((' '::text || dg.edad_gestacional_dias) || ' dias'::text, ''::text)
            ELSE NULL::text
        END,
        CASE
            WHEN rt.id_evento IS NOT NULL THEN ('Revision '::text ||
            CASE
                WHEN rt.apto THEN 'apto'::text
                ELSE 'no apto'::text
            END) || COALESCE((' ('::text || rt.circ_escrotal_cm) || ' cm)'::text, ''::text)
            ELSE NULL::text
        END,
        CASE
            WHEN sa.id_evento IS NOT NULL THEN ('Sanidad '::text || sa.producto) || COALESCE((' ('::text || sa.dosis) || ')'::text, ''::text)
            ELSE NULL::text
        END,
        CASE
            WHEN mc.condicion_corporal IS NOT NULL THEN 'CC '::text || mc.condicion_corporal
            ELSE NULL::text
        END,
        CASE
            WHEN mc.dentadura IS NOT NULL THEN 'dentadura '::text || mc.dentadura
            ELSE NULL::text
        END,
        CASE
            WHEN mc.alzada_cm IS NOT NULL THEN ('alzada '::text || mc.alzada_cm) || ' cm'::text
            ELSE NULL::text
        END,
        CASE
            WHEN er.id_evento IS NOT NULL THEN (er.tipo || COALESCE(' tubo '::text || er.nro_tubo, ''::text)) || COALESCE(' partida '::text || er.partida_semen, ''::text)
            ELSE NULL::text
        END,
        CASE
            WHEN pe.id_evento IS NOT NULL THEN (('Pesada '::text || pe.peso_kg) || ' kg'::text) || COALESCE((' ('::text || pe.tipo_pesada) || ')'::text, ''::text)
            ELSE NULL::text
        END,
        CASE
            WHEN t.tipo_trabajo = 'IDENTIFICACION'::text THEN 'Identificacion'::text
            ELSE NULL::text
        END), ''::text) AS detalle,
        CASE
            WHEN dg.id_evento IS NOT NULL THEN 'TACTO'::text
            WHEN rt.id_evento IS NOT NULL THEN 'REVISION_TOROS'::text
            WHEN sa.id_evento IS NOT NULL THEN 'SANIDAD'::text
            WHEN er.id_evento IS NOT NULL THEN 'REPRODUCCION'::text
            WHEN mc.id_evento IS NOT NULL THEN 'CORPORAL'::text
            WHEN pe.id_evento IS NOT NULL THEN 'PESAJE'::text
            ELSE 'OTRO'::text
        END AS clase,
    dg.resultado AS tacto_resultado,
    mc.condicion_corporal,
    mc.dentadura,
    ev.comentario,
    rt.apto
   FROM evento ev
     JOIN trabajo t ON t.id_trabajo = ev.id_trabajo
     LEFT JOIN establecimiento est ON est.id_establecimiento = t.id_establecimiento
     LEFT JOIN diagnostico_gestacion dg ON dg.id_evento = ev.id_evento
     LEFT JOIN medicion_corporal mc ON mc.id_evento = ev.id_evento
     LEFT JOIN evento_reproductivo er ON er.id_evento = ev.id_evento
     LEFT JOIN pesaje pe ON pe.id_evento = ev.id_evento
     LEFT JOIN revision_toro rt ON rt.id_evento = ev.id_evento
     LEFT JOIN sanidad sa ON sa.id_evento = ev.id_evento;

insert into _migraciones_aplicadas (version)
values ('20260908161000_exponer_apto_en_v_animal_evento')
on conflict (version) do nothing;

-- Comprobación: la columna existe y trae los 56 "apto" de las revisiones migradas.
select count(*) as filas_con_apto from v_animal_evento where apto is not null;
-- esperado: 56

-- v0.2b (carga de resultados): v_animal_evento -"la historia de un animal"
-- (docs/modelo-datos.md)- es de antes de que existieran revision_toro y
-- sanidad como trabajos de la app. Sin este cambio, el historial de un
-- animal muestra en blanco justo esos dos tipos de trabajo, que son dos de
-- los cuatro que carga la pantalla /planillas/cargar.
--
-- Regla del repo: un archivo que ya se corrio no se edita nunca. Se agrega
-- este, no se toca la definicion original de v_animal_evento.
--
-- CREATE OR REPLACE VIEW no permite cambiar el nombre, orden o tipo de las
-- columnas existentes -por eso la lista de columnas de salida es identica
-- a la original, solo cambia como se arman "detalle" y "clase" por dentro.

set search_path to public;

create or replace view v_animal_evento as
select
    ev.id_evento,
    ev.id_animal,
    t.fecha,
    t.tipo_trabajo,
    t.observaciones as jornada,
    est.cuig,
    ev.origen_dato,
    nullif(
        concat_ws(
            ' · ',
            case when dg.id_evento is not null then
                'Tacto ' || dg.resultado
                || coalesce(' (' || dg.tamano || ')', '')
                || coalesce(' ' || dg.edad_gestacional_dias || ' dias', '')
            else null end,
            case when rt.id_evento is not null then
                'Revision ' || (case when rt.apto then 'apto' else 'no apto' end)
                || coalesce(' (' || rt.circ_escrotal_cm || ' cm)', '')
            else null end,
            case when sa.id_evento is not null then
                'Sanidad ' || sa.producto
                || coalesce(' (' || sa.dosis || ')', '')
            else null end,
            case when mc.condicion_corporal is not null then 'CC ' || mc.condicion_corporal else null end,
            case when mc.dentadura is not null then 'dentadura ' || mc.dentadura else null end,
            case when mc.alzada_cm is not null then 'alzada ' || mc.alzada_cm || ' cm' else null end,
            case when er.id_evento is not null then
                er.tipo || coalesce(' tubo ' || er.nro_tubo, '') || coalesce(' partida ' || er.partida_semen, '')
            else null end,
            case when pe.id_evento is not null then
                'Pesada ' || pe.peso_kg || ' kg' || coalesce(' (' || pe.tipo_pesada || ')', '')
            else null end,
            case when t.tipo_trabajo = 'IDENTIFICACION' then 'Identificacion' else null end
        ),
        ''
    ) as detalle,
    case
        when dg.id_evento is not null then 'TACTO'
        when rt.id_evento is not null then 'REVISION_TOROS'
        when sa.id_evento is not null then 'SANIDAD'
        when er.id_evento is not null then 'REPRODUCCION'
        when mc.id_evento is not null then 'CORPORAL'
        when pe.id_evento is not null then 'PESAJE'
        else 'OTRO'
    end as clase,
    dg.resultado as tacto_resultado,
    mc.condicion_corporal,
    mc.dentadura,
    ev.comentario
from evento ev
    join trabajo t on t.id_trabajo = ev.id_trabajo
    left join establecimiento est on est.id_establecimiento = t.id_establecimiento
    left join diagnostico_gestacion dg on dg.id_evento = ev.id_evento
    left join medicion_corporal mc on mc.id_evento = ev.id_evento
    left join evento_reproductivo er on er.id_evento = ev.id_evento
    left join pesaje pe on pe.id_evento = ev.id_evento
    left join revision_toro rt on rt.id_evento = ev.id_evento
    left join sanidad sa on sa.id_evento = ev.id_evento;

-- Comprobación: la vista sigue existiendo y REVISION_TOROS/SANIDAD ya
-- traen texto en "detalle" en vez de quedar vacíos.
select tipo_trabajo, clase, detalle
  from v_animal_evento
 where tipo_trabajo in ('REVISION_TOROS', 'SANIDAD')
 limit 5;

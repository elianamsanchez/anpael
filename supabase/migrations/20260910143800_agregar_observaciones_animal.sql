-- Notas de texto libre sobre el animal, distintas de animal_validacion.observacion
-- (esa es específica de la revisión del saneamiento, esta es de uso general).
--
-- CREATE OR REPLACE VIEW solo permite agregar columnas al final.

set search_path to public;

alter table animal add column if not exists observaciones text;

create or replace view v_animal_lista
with (security_invoker = true)
as
select
    a.id_animal,
    vi.caravana,
    vi.tipo_ident,
    a.sexo,
    r.nombre as raza,
    c.codigo as categoria_codigo,
    c.nombre as categoria,
    a.fecha_nacimiento,
    a.fecha_nac_es_estimada,
    vi.fecha_alta as fecha_ident,
    vi.fecha_alta_es_estimada as fecha_ident_es_estimada,
    e.cuig,
    a.activo,
    b.id_baja is not null as tiene_baja,
    coalesce(v.estado, 'SIN_REVISAR') as validacion,
    v.observacion as validacion_obs,
    v.revisado_en,
    p.nombre as revisado_por,
    (select count(*) from evento ev where ev.id_animal = a.id_animal) as eventos,
    a.fecha_nacimiento is null as sin_fecha_nac,
    a.fecha_nac_es_estimada or vi.fecha_alta_es_estimada as con_fecha_estimada,
    c.id_categoria is null as sin_categoria,
    rd.nombre as rodeo,
    ar.fecha_desde as en_rodeo_desde,
    ar.id_rodeo,
    c.id_categoria,
    pl.nombre as pelaje,
    e.nombre as establecimiento,
    a.anio_nacimiento,
    a.anio_ingreso,
    a.anio_primer_servicio,
    ar.fecha_desde_es_estimada as en_rodeo_desde_es_estimada,
    a.peso_nacer_kg,
    a.id_padre,
    padre.caravana as padre_caravana,
    a.padre_nombre,
    (
        select string_agg(i.caravana, ' · ' order by
            case ti.codigo
                when 'VISUAL' then 1
                when 'FUEGO' then 2
                when 'ADICIONAL' then 3
                when 'RFID' then 4
                when 'SENASA' then 5
                else 6
            end, i.id_identificacion)
          from identificacion i
          join tipo_identificacion ti on ti.id_tipo_ident = i.id_tipo_ident
         where i.id_animal = a.id_animal and i.fecha_baja is null
    ) as identificaciones,
    ac.fecha_desde as categoria_desde,
    ac.fecha_desde_es_estimada as categoria_desde_es_estimada,
    a.observaciones
from animal a
    left join v_ident_principal vi on vi.id_animal = a.id_animal
    left join raza r on r.id_raza = a.id_raza
    left join pelaje pl on pl.id_pelaje = a.id_pelaje
    left join establecimiento e on e.id_establecimiento = vi.id_establecimiento
    left join animal_categoria ac on ac.id_animal = a.id_animal and ac.fecha_hasta is null
    left join categoria c on c.id_categoria = ac.id_categoria
    left join animal_rodeo ar on ar.id_animal = a.id_animal and ar.fecha_hasta is null
    left join rodeo rd on rd.id_rodeo = ar.id_rodeo
    left join baja b on b.id_animal = a.id_animal
    left join animal_validacion v on v.id_animal = a.id_animal
    left join persona p on p.id_persona = v.id_persona
    left join v_ident_principal padre on padre.id_animal = a.id_padre;

insert into _migraciones_aplicadas (version)
values ('20260910143800_agregar_observaciones_animal')
on conflict (version) do nothing;

-- Comprobación: la columna existe y la vista sigue devolviendo una fila por animal.
select column_name, data_type from information_schema.columns
 where table_name = 'animal' and column_name = 'observaciones';
select
    (select count(*) from v_animal_lista) as filas_vista,
    (select count(*) from animal) as animales;

-- Pantalla de animales: agregar año de nacimiento, año de 1er ingreso,
-- color (pelaje) y el nombre del establecimiento junto al CUIG.
--
-- anio_nacimiento y anio_ingreso son columnas nuevas, independientes de
-- fecha_nacimiento / fecha_ingreso: para buena parte del padrón migrado
-- solo se conoce el año, no el día ni el mes exacto. Se backfillean con el
-- año de la fecha completa cuando esta existe, pero quedan editables por
-- separado -no hay que tener la fecha completa para cargar el año.
--
-- CREATE OR REPLACE VIEW solo permite agregar columnas al final.

set search_path to public;

alter table animal add column if not exists anio_nacimiento integer
    check (anio_nacimiento between 1900 and 2100);
alter table animal add column if not exists anio_ingreso integer
    check (anio_ingreso between 1900 and 2100);

update animal set anio_nacimiento = extract(year from fecha_nacimiento)
 where fecha_nacimiento is not null and anio_nacimiento is null;

update animal set anio_ingreso = extract(year from fecha_ingreso)
 where fecha_ingreso is not null and anio_ingreso is null;

create or replace view v_animal_lista as
select
    a.id_animal,
    i.caravana,
    ti.codigo as tipo_ident,
    a.sexo,
    r.nombre as raza,
    c.codigo as categoria_codigo,
    c.nombre as categoria,
    a.fecha_nacimiento,
    a.fecha_nac_es_estimada,
    i.fecha_alta as fecha_ident,
    i.fecha_alta_es_estimada as fecha_ident_es_estimada,
    e.cuig,
    a.activo,
    b.id_baja is not null as tiene_baja,
    coalesce(v.estado, 'SIN_REVISAR') as validacion,
    v.observacion as validacion_obs,
    v.revisado_en,
    p.nombre as revisado_por,
    (select count(*) from evento ev where ev.id_animal = a.id_animal) as eventos,
    a.fecha_nacimiento is null as sin_fecha_nac,
    a.fecha_nac_es_estimada or i.fecha_alta_es_estimada as con_fecha_estimada,
    c.id_categoria is null as sin_categoria,
    rd.nombre as rodeo,
    ar.fecha_desde as en_rodeo_desde,
    ar.id_rodeo,
    c.id_categoria,
    pl.nombre as pelaje,
    e.nombre as establecimiento,
    a.anio_nacimiento,
    a.anio_ingreso
from animal a
    left join identificacion i on i.id_animal = a.id_animal and i.fecha_baja is null
    left join tipo_identificacion ti on ti.id_tipo_ident = i.id_tipo_ident
    left join raza r on r.id_raza = a.id_raza
    left join pelaje pl on pl.id_pelaje = a.id_pelaje
    left join establecimiento e on e.id_establecimiento = i.id_establecimiento
    left join animal_categoria ac on ac.id_animal = a.id_animal and ac.fecha_hasta is null
    left join categoria c on c.id_categoria = ac.id_categoria
    left join animal_rodeo ar on ar.id_animal = a.id_animal and ar.fecha_hasta is null
    left join rodeo rd on rd.id_rodeo = ar.id_rodeo
    left join baja b on b.id_animal = a.id_animal
    left join animal_validacion v on v.id_animal = a.id_animal
    left join persona p on p.id_persona = v.id_persona;

insert into _migraciones_aplicadas (version)
values ('20260903100000_agregar_anio_nacimiento_ingreso_pelaje_establecimiento')
on conflict (version) do nothing;

-- Comprobación: las columnas nuevas aparecen, con el backfill corrido.
select id_animal, pelaje, establecimiento, anio_nacimiento, anio_ingreso
  from v_animal_lista
 where anio_nacimiento is not null or anio_ingreso is not null
 limit 5;

-- Expone peso_nacer_kg y padre (vía id_padre) en v_animal_lista. Los dos ya
-- existían en `animal` -peso_nacer_kg corregible desde hace rato, id_padre
-- cargable solo al alta- pero ninguno se mostraba en la ficha.
--
-- padre_caravana sale de v_ident_principal, no de un join directo contra
-- identificacion: mismo motivo de siempre, no duplicar filas si el padre
-- tiene más de una identificación vigente.
--
-- CREATE OR REPLACE VIEW solo permite agregar columnas al final.

set search_path to public;

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
    padre.caravana as padre_caravana
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
values ('20260908185500_agregar_peso_nacer_padre_v_animal_lista')
on conflict (version) do nothing;

-- Comprobación: sigue una fila por animal, y aparecen datos de padre donde corresponde.
select
    (select count(*) from v_animal_lista) as filas_vista,
    (select count(*) from animal) as animales,
    (select count(*) from v_animal_lista where id_padre is not null) as con_padre_cargado,
    (select count(*) from v_animal_lista where peso_nacer_kg is not null) as con_peso_nacer;

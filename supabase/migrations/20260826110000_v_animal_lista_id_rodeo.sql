-- v0.2a (saneamiento): filtro por rodeo en el padron. v_animal_lista ya
-- trae el NOMBRE del rodeo (columna "rodeo"), pero para filtrar por un
-- rodeo puntual desde un combo hace falta el id, no el nombre -filtrar por
-- texto es fragil si algun dia dos rodeos terminan con nombres parecidos.
--
-- El join a animal_rodeo ya existe en la vista (ar), asi que agregar
-- id_rodeo es gratis: no hace falta ningun join nuevo.
--
-- CREATE OR REPLACE VIEW no permite insertar una columna en el medio ni
-- cambiar las que ya existen, solo agregar al final. Por eso id_rodeo va
-- despues de en_rodeo_desde y no al lado de "rodeo", que seria mas prolijo
-- pero rompe cualquier consulta que ya use `select *`.

set search_path to public;

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
    ar.id_rodeo
from animal a
    left join identificacion i on i.id_animal = a.id_animal and i.fecha_baja is null
    left join tipo_identificacion ti on ti.id_tipo_ident = i.id_tipo_ident
    left join raza r on r.id_raza = a.id_raza
    left join establecimiento e on e.id_establecimiento = i.id_establecimiento
    left join animal_categoria ac on ac.id_animal = a.id_animal and ac.fecha_hasta is null
    left join categoria c on c.id_categoria = ac.id_categoria
    left join animal_rodeo ar on ar.id_animal = a.id_animal and ar.fecha_hasta is null
    left join rodeo rd on rd.id_rodeo = ar.id_rodeo
    left join baja b on b.id_animal = a.id_animal
    left join animal_validacion v on v.id_animal = a.id_animal
    left join persona p on p.id_persona = v.id_persona;

-- Comprobación: id_rodeo aparece y coincide con el nombre.
select id_animal, rodeo, id_rodeo from v_animal_lista where id_rodeo is not null limit 5;

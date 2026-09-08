-- Corrige v_animal_lista: duplicaba animales con más de una identificación
-- vigente (1.782 filas para 1.732 animales, el mismo número que
-- docs/modelo-datos.md ya documentaba como resuelto: "los 64 toros
-- aparecían dos y tres veces... hasta que esta vista lo resolvió").
--
-- La reescritura de 20260903100000_agregar_anio_nacimiento_ingreso_pelaje_
-- establecimiento.sql volvió a unir contra `identificacion` directo
-- (i.fecha_baja is null) en lugar de `v_ident_principal`, reintroduciendo
-- el bug: un animal con FUEGO y VISUAL vigentes a la vez (normal en los
-- toros, mig_18_toros.sql) sale dos veces en cualquier listado o
-- búsqueda. Se detectó porque dos toros reasignados de categoría
-- aparecían duplicados al filtrar por categoría en /animales.
--
-- CREATE OR REPLACE VIEW solo permite agregar columnas al final; acá no
-- se agrega ninguna, así que alcanza con reescribir el FROM/JOIN.

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
    a.anio_ingreso
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
    left join persona p on p.id_persona = v.id_persona;

insert into _migraciones_aplicadas (version)
values ('20260907140000_corregir_v_animal_lista_duplicados_identificacion')
on conflict (version) do nothing;

-- Comprobación: una fila por animal, sin excepciones -antes daba 1.782.
select
    (select count(*) from v_animal_lista) as filas_vista,
    (select count(*) from animal) as animales;
-- esperado: los dos números iguales (1.732 = 1.732)

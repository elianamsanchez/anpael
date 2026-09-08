-- Marca si fecha_desde de animal_rodeo es real o un artefacto de la
-- migración (la fecha que se cargó al sanear, no el día real en que el
-- animal entró a ese rodeo) -mismo patrón que fecha_es_estimada en `baja`
-- para REGULARIZACION, fecha_nac_es_estimada en `animal`, fecha_alta_es_
-- estimada en `identificacion`.
--
-- Por default false: no hay forma de inferirla para las filas ya cargadas,
-- así que asumir que no son estimadas es lo que menos sorprende -mover a
-- rodeo() a partir de ahora la recibe explícita.
--
-- CREATE OR REPLACE VIEW solo permite agregar columnas al final.

set search_path to public;

alter table animal_rodeo add column if not exists fecha_desde_es_estimada boolean not null default false;

-- Un parametro nuevo con DEFAULT no reemplaza la funcion vieja: Postgres la
-- trata como una firma distinta y quedan las dos, ambiguas para una llamada
-- de 3 argumentos. Se saca la vieja a proposito.
drop function if exists mover_a_rodeo(integer, integer, date);

create or replace function mover_a_rodeo(
    p_animal integer,
    p_rodeo integer,
    p_fecha date default current_date,
    p_fecha_es_estimada boolean default false
) returns text
language plpgsql
set search_path to 'public'
as $function$
declare
    v_actual   integer;
    v_desde    date;
    v_nombre   text;
    v_anterior text;
begin
    select nombre into v_nombre from rodeo where id_rodeo = p_rodeo and activo;
    if v_nombre is null then
        return 'ERROR: el rodeo ' || p_rodeo || ' no existe o esta inactivo.';
    end if;

    select ar.id_rodeo, ar.fecha_desde into v_actual, v_desde
      from animal_rodeo ar
     where ar.id_animal = p_animal and ar.fecha_hasta is null;

    if v_actual = p_rodeo then
        return 'Sin cambios: el animal ya estaba en ' || v_nombre || '.';
    end if;

    if v_actual is not null then
        if p_fecha <= v_desde then
            return 'ERROR: la fecha ' || p_fecha || ' no es posterior a la de ingreso '
                   'al rodeo actual (' || v_desde || '). No se cambio nada.';
        end if;
        select r.nombre into v_anterior from rodeo r where r.id_rodeo = v_actual;
        update animal_rodeo set fecha_hasta = p_fecha
         where id_animal = p_animal and fecha_hasta is null;
    end if;

    insert into animal_rodeo (id_animal, id_rodeo, fecha_desde, fecha_desde_es_estimada)
    values (p_animal, p_rodeo, p_fecha, p_fecha_es_estimada);

    return coalesce('Movido de ' || v_anterior || ' a ', 'Asignado a ') || v_nombre ||
           ' el ' || p_fecha || '.';
end;
$function$;

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
    ar.fecha_desde_es_estimada as en_rodeo_desde_es_estimada
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
values ('20260908101000_agregar_fecha_estimada_animal_rodeo')
on conflict (version) do nothing;

-- Comprobación: la columna existe, y mover_a_rodeo() tiene una sola firma
-- (4 argumentos) -sin la vieja de 3 dando ambigüedad.
select column_name, data_type, is_nullable, column_default
  from information_schema.columns
 where table_name = 'animal_rodeo' and column_name = 'fecha_desde_es_estimada';
-- esperado: 1 fila · boolean · NO · false

select count(*) as firmas_mover_a_rodeo
  from pg_proc where proname = 'mover_a_rodeo';
-- esperado: 1

-- Año de primer servicio: pensado para toros -cuándo entraron a servicio-,
-- mismo patrón que anio_nacimiento/anio_ingreso (20260903100000): un entero
-- suelto porque de la mayoría no se conoce la fecha exacta, solo el año. No
-- se restringe a sexo='M' a nivel de base -no hace falta un CHECK para algo
-- que el campo, en la práctica, solo carga en toros.
--
-- CREATE OR REPLACE VIEW solo permite agregar columnas al final.

set search_path to public;

alter table animal add column if not exists anio_primer_servicio integer
    check (anio_primer_servicio between 1900 and 2100);

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
    a.anio_primer_servicio
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
values ('20260908100000_agregar_anio_primer_servicio')
on conflict (version) do nothing;

-- Comprobación: la columna existe, con el tipo esperado.
select column_name, data_type, is_nullable
  from information_schema.columns
 where table_name = 'animal' and column_name = 'anio_primer_servicio';
-- esperado: 1 fila · integer · YES

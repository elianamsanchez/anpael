-- v0.2a (saneamiento, docs/etapas.md): un quinto tipo de baja -REGULARIZACION-,
-- sus tres causas, y la columna que dice si la fecha de la baja es estimada.
--
-- POR QUE UN TIPO Y NO UNA CAUSA MAS
-- ---------------------------------------------------------------------
-- La migración 20260825120000 había resuelto esto agregando una causa
-- 'regularizacion_inicial' DENTRO de FALTANTE. Este archivo no la edita
-- -un archivo que ya corrió no se toca, ver supabase/migrations/README.md-
-- pero la deja de usar: la regla que se va a usar en todos los indicadores
-- del primer año es esta, y tiene que ser estable:
--
--     where cb.tipo_baja <> 'REGULARIZACION'
--
-- Si la regularización fuera una causa dentro de FALTANTE, ese filtro
-- tendría que comparar contra el TEXTO de la descripción. El día que
-- alguien le cambie una tilde o agregue una causa parecida, el filtro deja
-- de funcionar EN SILENCIO y la mortandad del primer año queda inflada sin
-- que nadie se entere. Filtrar por tipo no se rompe.
--
-- LA REGLA DE USO  ·  esto es lo que hay que respetar
-- ---------------------------------------------------------------------
-- REGULARIZACION es SOLO para "no está, y no sabemos ni cuándo ni por qué".
--
-- Si se sabe que el animal se vendió en marzo de 2025, eso NO es
-- regularización: es una VENTA cargada tarde, con la fecha real. Usar
-- REGULARIZACION ahí sería tirar información que después no se recupera.
--
-- LA COLUMNA fecha_es_estimada
-- ---------------------------------------------------------------------
-- En estas bajas, 'fecha' es el día en que se hizo el saneamiento, no el
-- día en que el animal salió del campo. Son cosas distintas y hasta ahora
-- el modelo no las distinguía. La columna lo deja explícito, igual que
-- animal.fecha_nac_es_estimada.
--
-- Importa más de lo que parece: sin ese dato, dentro de dos años alguien
-- va a calcular "días entre el último evento y la baja" y le va a dar
-- cualquier cosa, sin forma de saber que esas fechas no eran reales.
--
-- ES ADITIVO salvo por el paso A2 (retira la causa provisional de la
-- migración anterior). Se puede correr más de una vez.

set search_path to public;


-- =====================================================================
-- A1  EL TIPO NUEVO
-- =====================================================================
do $tipo$
declare
    v_con text;
begin
    -- El CHECK del modelo no tiene nombre puesto a mano, así que se busca
    -- por su definición en lugar de adivinar cómo lo llamó PostgreSQL.
    select conname into v_con
      from pg_constraint
     where conrelid = 'public.causa_baja'::regclass
       and contype = 'c'
       and pg_get_constraintdef(oid) like '%tipo_baja%';

    if v_con is not null then
        execute format('alter table causa_baja drop constraint %I', v_con);
        raise notice 'A1: restricción % reemplazada.', v_con;
    end if;

    alter table causa_baja
      add constraint causa_baja_tipo_baja_check
      check (tipo_baja in ('VENTA','MUERTE','TRASLADO','FALTANTE','REGULARIZACION'));

    raise notice 'A1: tipos de baja permitidos: VENTA, MUERTE, TRASLADO, FALTANTE, REGULARIZACION.';
end $tipo$;


-- =====================================================================
-- A2  RETIRAR LA CAUSA PROVISIONAL DE 20260825120000
-- =====================================================================
-- 'regularizacion_inicial' bajo FALTANTE queda reemplazada por el tipo de
-- arriba. Se borra solo si nadie la usó todavía -si ya se cargó alguna
-- baja con ella, se corta acá en lugar de dejar una fila húerfana o un
-- id_causa_baja roto: hay que decidir a mano qué hacer con esas bajas.
do $retiro$
declare
    v_id integer;
    v_en_uso integer;
begin
    select id_causa_baja into v_id
      from causa_baja
     where tipo_baja = 'FALTANTE' and descripcion = 'regularizacion_inicial';

    if v_id is null then
        raise notice 'A2: no había causa provisional que retirar.';
        return;
    end if;

    select count(*) into v_en_uso from baja where id_causa_baja = v_id;

    if v_en_uso > 0 then
        raise exception 'A2: hay % baja(s) usando la causa provisional (id_causa_baja=%). '
            'Recategorizarlas a REGULARIZACION antes de correr esta migración.', v_en_uso, v_id;
    end if;

    delete from causa_baja where id_causa_baja = v_id;
    raise notice 'A2: causa provisional (id_causa_baja=%) retirada, sin bajas que la usaran.', v_id;
end $retiro$;


-- =====================================================================
-- A3  LAS TRES CAUSAS
-- =====================================================================
insert into causa_baja (tipo_baja, descripcion) values
  ('REGULARIZACION', 'No esta en el campo, salida sin registrar'),
  ('REGULARIZACION', 'Error de carga: la fila del Excel no era un animal real'),
  ('REGULARIZACION', 'Duplicado no detectado en la migracion')
on conflict (tipo_baja, descripcion) do nothing;


-- =====================================================================
-- A4  LA COLUMNA fecha_es_estimada
-- =====================================================================
alter table baja
  add column if not exists fecha_es_estimada boolean not null default false;

comment on column baja.fecha_es_estimada is
  'true = la fecha de la baja NO es el día real en que el animal salió, sino '
  'el día en que se registró que ya no estaba. Es lo normal en las bajas de '
  'tipo REGULARIZACION. Cualquier cálculo de días que use baja.fecha tiene '
  'que excluir o marcar estas filas.';


-- =====================================================================
-- A5  LOS CONTROLES
-- =====================================================================

-- 1) El resumen que hay que mirar al cerrar el saneamiento.
create or replace view public.v_baja_resumen as
select cb.tipo_baja,
       cb.descripcion                                  as causa,
       count(*)                                        as animales,
       min(b.fecha)                                    as primera,
       max(b.fecha)                                    as ultima,
       count(*) filter (where b.fecha_es_estimada)     as con_fecha_estimada,
       round(100.0 * count(*) / (select count(*) from animal), 1) as pct_del_padron
  from baja b
  join causa_baja cb using (id_causa_baja)
 group by cb.tipo_baja, cb.descripcion;

alter view public.v_baja_resumen set (security_invoker = true);

comment on view public.v_baja_resumen is
  'Bajas por tipo y causa. Si REGULARIZACION supera el 10-15% del padrón, '
  'ese número hay que mostrarlo antes de que alguien lea los indicadores del '
  'primer año: significa que el Excel estaba bastante desactualizado.';


-- 2) El riesgo de este archivo: que el tipo sobreviva al saneamiento y se
--    use como cajón de sastre. Esta vista lo hace visible sin que nadie
--    tenga que acordarse de una fecha de cierre: toma la primera
--    regularización como arranque y marca las que llegan más de 90 días
--    después. Si el saneamiento dura más, cambiar el 90 acá.
create or replace view public.v_qa_regularizacion_tardia as
with arranque as (
    select min(b.fecha) as desde
      from baja b join causa_baja cb using (id_causa_baja)
     where cb.tipo_baja = 'REGULARIZACION'
)
select b.id_baja, b.id_animal, i.caravana, b.fecha,
       cb.descripcion                        as causa,
       (b.fecha - a.desde)                   as dias_despues_del_arranque,
       'Baja de regularizacion cargada mucho despues del saneamiento. '
       'Revisar si no corresponde a una VENTA o MUERTE real.'::text as detalle
  from baja b
  join causa_baja cb using (id_causa_baja)
  cross join arranque a
  left join v_ident_principal i on i.id_animal = b.id_animal
 where cb.tipo_baja = 'REGULARIZACION'
   and b.fecha > a.desde + 90;

alter view public.v_qa_regularizacion_tardia set (security_invoker = true);


-- 3) Una regularización con fecha marcada como real es casi seguro un
--    olvido: si se supiera la fecha real, no sería una regularización.
create or replace view public.v_qa_regularizacion_sin_marca as
select b.id_baja, b.id_animal, i.caravana, b.fecha, cb.descripcion as causa,
       'Baja de regularizacion con fecha_es_estimada = false. Si la fecha real '
       'se conoce, la baja no deberia ser REGULARIZACION sino VENTA o MUERTE '
       'con esa fecha.'::text as detalle
  from baja b
  join causa_baja cb using (id_causa_baja)
  left join v_ident_principal i on i.id_animal = b.id_animal
 where cb.tipo_baja = 'REGULARIZACION'
   and not b.fecha_es_estimada;

alter view public.v_qa_regularizacion_sin_marca set (security_invoker = true);

grant select on public.v_baja_resumen, public.v_qa_regularizacion_tardia,
                public.v_qa_regularizacion_sin_marca to authenticated;
revoke all  on public.v_baja_resumen, public.v_qa_regularizacion_tardia,
                public.v_qa_regularizacion_sin_marca from anon;


-- =====================================================================
-- CÓMO SE DA UNA BAJA DE REGULARIZACIÓN  ·  ejemplo, no se ejecuta
-- =====================================================================
--   insert into baja (id_animal, id_causa_baja, fecha, fecha_es_estimada, observaciones)
--   select i.id_animal,
--          (select id_causa_baja from causa_baja
--            where tipo_baja = 'REGULARIZACION'
--              and descripcion = 'No esta en el campo, salida sin registrar'),
--          current_date,
--          true,                         -- <- la fecha NO es la real
--          'Saneamiento inicial: no aparece en el recuento de campo.'
--     from identificacion i
--    where i.id_tipo_ident = 1
--      and i.caravana in ('H901','H902');   -- <- las caravanas que correspondan
--
-- OJO: baja.id_animal es unique. Un animal no se puede dar de baja dos
-- veces, y está bien que sea así.


-- =====================================================================
-- COMPROBACIÓN
-- =====================================================================
-- 1) el catálogo completo, por tipo -no debe quedar FALTANTE/regularizacion_inicial-
select tipo_baja, descripcion from causa_baja order by tipo_baja, descripcion;

-- 2) la columna nueva
select column_name, data_type, column_default, is_nullable
  from information_schema.columns
 where table_name = 'baja' and column_name = 'fecha_es_estimada';

-- 3) el resumen. Hoy vacío si todavía no hay ninguna baja cargada.
select * from v_baja_resumen order by tipo_baja, animales desc;

-- 4) los dos controles nuevos: 0 filas
select count(*) as regularizaciones_tardias  from v_qa_regularizacion_tardia;
select count(*) as regularizaciones_sin_marca from v_qa_regularizacion_sin_marca;

-- 5) la consulta de mortandad real, sin arrastre del saneamiento
select count(*) filter (where cb.tipo_baja = 'MUERTE')                as muertes_reales,
       count(*) filter (where cb.tipo_baja = 'VENTA')                 as ventas,
       count(*) filter (where cb.tipo_baja = 'REGULARIZACION')        as arrastre_del_excel,
       round(100.0 * count(*) filter (where cb.tipo_baja = 'MUERTE')
             / nullif((select count(*) from animal), 0), 2)           as pct_mortandad
  from baja b join causa_baja cb using (id_causa_baja);


-- =====================================================================
-- CÓMO DESHACERLO
-- =====================================================================
-- Solo funciona si todavía no se cargó ninguna baja de regularización.
--
--   drop view if exists v_qa_regularizacion_sin_marca;
--   drop view if exists v_qa_regularizacion_tardia;
--   drop view if exists v_baja_resumen;
--   delete from causa_baja where tipo_baja = 'REGULARIZACION';
--   alter table baja drop column if exists fecha_es_estimada;
--   alter table causa_baja drop constraint causa_baja_tipo_baja_check;
--   alter table causa_baja add constraint causa_baja_tipo_baja_check
--     check (tipo_baja in ('VENTA','MUERTE','TRASLADO','FALTANTE'));
--   -- y, si hace falta, volver a insertar la causa provisional que A2 retiró:
--   insert into causa_baja (tipo_baja, descripcion)
--     values ('FALTANTE', 'regularizacion_inicial');

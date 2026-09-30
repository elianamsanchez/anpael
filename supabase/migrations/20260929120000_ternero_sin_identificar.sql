-- Terneros nacidos que todavía no tienen caravana: el stock los cuenta desde
-- el nacimiento hasta el trabajo de identificación, POR CICLO PRODUCTIVO.
--
-- Qué agrega:
--   1. ciclo_productivo: catálogo editable de ciclos (servicio -> destete).
--      Hay dos líneas que corren en paralelo: VACA (código '2025-26') y VAQ
--      (vaquillonas, código 'VAQ2025-26'). Ver docs/ciclo_vaca_anio1_a_anio3.png
--      y docs/ciclo_vaquillona_desde_servicio.png.
--   2. ternero_sin_identificar_mov: movimientos append-only (NACIMIENTO,
--      IDENTIFICACION, MUERTE, BAJA_OTRA, ANULACION). No se crea animal: solo
--      cantidades por ciclo y sexo. Los candidatos a torito NO pasan por acá:
--      se dan de alta como animal (categoría TORITO + identificación ADICIONAL).
--   3. Vistas de saldo y de alerta, y una línea "sin identificar" en
--      v_stock_unificado y v_rodeo_stock.
--
-- Por qué el ciclo guarda también la ventana de parición: los ciclos
-- completos de una misma línea se superponen (el destete de vacas de
-- marzo/abril del año 3 cae después del servicio del ciclo siguiente, que
-- arranca en octubre del año 2). Lo que NO se superpone dentro de una línea
-- es [paricion_desde, fecha_fin]: desde que empiezan a nacer hasta que se
-- identifican. Ese rango es el que se usa para sugerir el ciclo por fecha y
-- para definir el ciclo "vigente" de una identificación.
--
-- Claves integer identity, como todo el resto de la base (ADR-002: el UUID
-- queda para lo que se cree offline, esto no lo es).

set search_path to public;

-- Para "sin superposición dentro de la misma línea" en un solo EXCLUDE.
create extension if not exists btree_gist with schema extensions;


-- =====================================================================
-- 1 · ciclo_productivo
-- =====================================================================

create table ciclo_productivo (
    id_ciclo_productivo integer generated always as identity primary key,
    codigo              text not null,
    linea               text not null,
    fecha_inicio        date not null,
    paricion_desde      date not null,
    paricion_hasta      date not null,
    fecha_fin           date not null,
    observaciones       text,
    constraint ciclo_productivo_codigo_key unique (codigo),
    constraint ciclo_productivo_linea_check check (linea in ('VACA', 'VAQ')),
    constraint ciclo_productivo_fechas_check check (
        fecha_inicio <= paricion_desde
        and paricion_desde <= paricion_hasta
        and paricion_hasta <= fecha_fin),
    constraint ciclo_productivo_sin_solape exclude using gist (
        linea with =,
        daterange(paricion_desde, fecha_fin, '[]') with &&)
);

comment on table ciclo_productivo is
  'Ciclos productivos, editables. fecha_inicio = inicio del servicio, '
  'fecha_fin = fin del destete/identificación. [paricion_desde, fecha_fin] no '
  'se superpone dentro de una línea: es el rango que usa ciclo_productivo_sugerido().';
comment on column ciclo_productivo.linea is
  'VACA (código 2025-26) o VAQ (vaquillonas, código VAQ2025-26): corren en paralelo.';

insert into ciclo_productivo (codigo, linea, fecha_inicio, paricion_desde, paricion_hasta, fecha_fin) values
    ('2025-26',    'VACA', '2025-10-01', '2026-07-15', '2026-09-30', '2027-04-30'),
    ('2026-27',    'VACA', '2026-10-01', '2027-07-15', '2027-09-30', '2028-04-30'),
    ('VAQ2025-26', 'VAQ',  '2025-07-01', '2026-04-01', '2026-07-31', '2026-12-31'),
    ('VAQ2026-27', 'VAQ',  '2026-07-01', '2027-04-01', '2027-07-31', '2027-12-31')
on conflict (codigo) do nothing;

-- El ciclo al que pertenece una fecha dentro de una línea: a lo sumo uno,
-- por el EXCLUDE de arriba. Sirve tanto para sugerir el ciclo de un
-- nacimiento como para el ciclo "vigente" de una identificación. null = la
-- fecha no cae en ningún ciclo cargado: el usuario elige a mano.
create or replace function ciclo_productivo_sugerido(p_linea text, p_fecha date)
returns integer
language sql
stable
set search_path to public
as $$
    select id_ciclo_productivo
      from ciclo_productivo
     where linea = p_linea
       and p_fecha between paricion_desde and fecha_fin;
$$;


-- =====================================================================
-- 2 · ternero_sin_identificar_mov
-- =====================================================================

create table ternero_sin_identificar_mov (
    id_mov               integer generated always as identity primary key,
    id_establecimiento   integer not null references establecimiento (id_establecimiento),
    id_ciclo_productivo  integer not null references ciclo_productivo (id_ciclo_productivo),
    ciclo_manual         boolean not null default false,
    fecha_evento         date not null,
    fecha_es_estimada    boolean not null default false,
    fecha_registro       timestamptz not null default now(),
    sexo                 text not null,
    cantidad             integer not null,
    tipo                 text not null,
    id_mov_anulado       integer references ternero_sin_identificar_mov (id_mov),
    id_trabajo           integer references trabajo (id_trabajo),
    excede_saldo         boolean not null default false,
    observaciones        text,
    id_persona_registro  integer references persona (id_persona) default persona_actual(),
    constraint ternero_mov_sexo_check check (sexo in ('M', 'H')),
    constraint ternero_mov_cantidad_check check (cantidad > 0),
    constraint ternero_mov_tipo_check check (
        tipo in ('NACIMIENTO', 'IDENTIFICACION', 'MUERTE', 'BAJA_OTRA', 'ANULACION')),
    -- una anulación apunta a un movimiento, y cada movimiento se anula una sola vez
    constraint ternero_mov_anulacion_check check ((tipo = 'ANULACION') = (id_mov_anulado is not null)),
    constraint ternero_mov_id_mov_anulado_key unique (id_mov_anulado),
    constraint ternero_mov_identificacion_trabajo_check check (tipo <> 'IDENTIFICACION' or id_trabajo is not null),
    constraint ternero_mov_excede_check check (not excede_saldo or tipo = 'IDENTIFICACION')
);

create index ternero_mov_ciclo_sexo_idx on ternero_sin_identificar_mov (id_ciclo_productivo, sexo);
create index ternero_mov_trabajo_idx on ternero_sin_identificar_mov (id_trabajo);

comment on table ternero_sin_identificar_mov is
  'Terneros sin caravana, en cantidades por ciclo y sexo. Solo se agregan filas: '
  'una corrección es una ANULACION del movimiento equivocado más el movimiento correcto.';
comment on column ternero_sin_identificar_mov.ciclo_manual is
  'true = el usuario cambió el ciclo que sugería ciclo_productivo_sugerido().';
comment on column ternero_sin_identificar_mov.excede_saldo is
  'Solo IDENTIFICACION: se identificaron más terneros que el saldo del ciclo. Lo calcula el trigger.';

-- Cada movimiento con su efecto sobre el saldo (delta) y si fue anulado.
-- Una ANULACION resta exactamente lo que sumaba el original.
create view v_ternero_sin_identificar_mov
with (security_invoker = true)
as
select
    m.id_mov,
    m.id_establecimiento,
    m.id_ciclo_productivo,
    c.codigo as ciclo,
    c.linea,
    m.ciclo_manual,
    m.fecha_evento,
    m.fecha_es_estimada,
    m.fecha_registro,
    m.sexo,
    m.cantidad,
    m.tipo,
    m.id_mov_anulado,
    m.id_trabajo,
    m.excede_saldo,
    m.observaciones,
    m.id_persona_registro,
    p.nombre as registrado_por,
    exists (select 1 from ternero_sin_identificar_mov a where a.id_mov_anulado = m.id_mov) as anulado,
    case m.tipo
        when 'NACIMIENTO' then m.cantidad
        when 'ANULACION' then case o.tipo when 'NACIMIENTO' then -m.cantidad else m.cantidad end
        else -m.cantidad
    end as delta
from ternero_sin_identificar_mov m
    join ciclo_productivo c on c.id_ciclo_productivo = m.id_ciclo_productivo
    left join ternero_sin_identificar_mov o on o.id_mov = m.id_mov_anulado
    left join persona p on p.id_persona = m.id_persona_registro;

-- Validación al insertar. Toma un lock por (ciclo, sexo) para que dos cargas
-- simultáneas no pasen las dos el control de saldo.
--   - ANULACION: mismo ciclo, sexo y cantidad que el original; no se anula una anulación.
--   - Si el movimiento deja el saldo del ciclo en negativo:
--       IDENTIFICACION -> se permite, con excede_saldo = true (los terneros existen:
--                         faltaron nacimientos por cargar o son de otro ciclo)
--       el resto       -> error.
create or replace function ternero_mov_validar()
returns trigger
language plpgsql
set search_path to public
as $$
declare
    v_orig   ternero_sin_identificar_mov%rowtype;
    v_delta  integer;
    v_saldo  bigint;
    v_ciclo  text;
begin
    perform pg_advisory_xact_lock(
        hashtext('ternero_sin_identificar_mov'),
        new.id_ciclo_productivo * 2 + case new.sexo when 'H' then 1 else 0 end);

    if new.tipo = 'ANULACION' then
        select * into v_orig from ternero_sin_identificar_mov where id_mov = new.id_mov_anulado;
        if not found then
            raise exception 'No existe el movimiento % que se quiere anular.', new.id_mov_anulado;
        end if;
        if v_orig.tipo = 'ANULACION' then
            raise exception 'El movimiento % ya es una anulación: no se anula, se carga de nuevo el movimiento correcto.',
                v_orig.id_mov;
        end if;
        if v_orig.id_ciclo_productivo <> new.id_ciclo_productivo
           or v_orig.sexo <> new.sexo
           or v_orig.cantidad <> new.cantidad then
            raise exception 'La anulación del movimiento % tiene que tener su mismo ciclo, sexo y cantidad.',
                v_orig.id_mov;
        end if;
        v_delta := case v_orig.tipo when 'NACIMIENTO' then -new.cantidad else new.cantidad end;
    elsif new.tipo = 'NACIMIENTO' then
        v_delta := new.cantidad;
    else
        v_delta := -new.cantidad;
    end if;

    new.excede_saldo := false;
    if v_delta < 0 then
        select coalesce(sum(delta), 0) into v_saldo
          from v_ternero_sin_identificar_mov
         where id_ciclo_productivo = new.id_ciclo_productivo and sexo = new.sexo;

        if v_saldo + v_delta < 0 then
            if new.tipo = 'IDENTIFICACION' then
                new.excede_saldo := true;
            else
                select codigo into v_ciclo from ciclo_productivo where id_ciclo_productivo = new.id_ciclo_productivo;
                raise exception 'En el ciclo % quedan % % sin identificar: no se pueden descontar %.',
                    v_ciclo, v_saldo, case new.sexo when 'M' then 'machos' else 'hembras' end, new.cantidad;
            end if;
        end if;
    end if;

    return new;
end;
$$;

create or replace function ternero_mov_inmutable()
returns trigger
language plpgsql
as $$
begin
    raise exception 'ternero_sin_identificar_mov no se edita ni se borra: para corregir el movimiento %, cargá una ANULACION.',
        old.id_mov;
end;
$$;

-- Mismo trigger de autoría que baja y evento (ADR-001: desde el backend
-- auth.uid() es null y el autor lo pone Java).
create trigger trg_forzar_autoria_ternero_mov
    before insert on ternero_sin_identificar_mov
    for each row execute function forzar_autoria();

create trigger trg_ternero_mov_validar
    before insert on ternero_sin_identificar_mov
    for each row execute function ternero_mov_validar();

create trigger trg_ternero_mov_inmutable
    before update or delete on ternero_sin_identificar_mov
    for each row execute function ternero_mov_inmutable();


-- =====================================================================
-- 3 · Vistas de saldo y alertas
-- =====================================================================

-- Una fila por ciclo y sexo (aunque no tenga movimientos), más el total por
-- sexo y el total general (nivel = 'TOTAL', ciclo en null).
-- Los movimientos anulados y las anulaciones no suman en las columnas de
-- detalle; saldo = nacidos - identificados - muertes - otras_bajas.
create view v_ternero_sin_identificar_saldo
with (security_invoker = true)
as
select
    case when grouping(c.id_ciclo_productivo) = 1 then 'TOTAL' else 'CICLO' end as nivel,
    c.id_ciclo_productivo,
    c.codigo as ciclo,
    c.linea,
    c.paricion_desde,
    c.fecha_fin,
    s.sexo,
    coalesce(sum(m.cantidad) filter (where m.tipo = 'NACIMIENTO' and not m.anulado), 0) as nacidos,
    coalesce(sum(m.cantidad) filter (where m.tipo = 'IDENTIFICACION' and not m.anulado), 0) as identificados,
    coalesce(sum(m.cantidad) filter (where m.tipo = 'MUERTE' and not m.anulado), 0) as muertes,
    coalesce(sum(m.cantidad) filter (where m.tipo = 'BAJA_OTRA' and not m.anulado), 0) as otras_bajas,
    coalesce(sum(m.delta), 0) as saldo,
    case when grouping(c.id_ciclo_productivo) = 0 then c.fecha_fin < current_date end as ciclo_cerrado
from ciclo_productivo c
    cross join (values ('M'), ('H')) as s (sexo)
    left join v_ternero_sin_identificar_mov m
           on m.id_ciclo_productivo = c.id_ciclo_productivo and m.sexo = s.sexo
group by grouping sets (
    (c.id_ciclo_productivo, c.codigo, c.linea, c.paricion_desde, c.fecha_fin, s.sexo),
    (s.sexo),
    ());

-- Ciclos ya terminados que quedaron con terneros sin identificar (saldo > 0)
-- o identificados de más (saldo < 0). No es un control v_qa_* porque un saldo
-- pendiente al cierre no es un error: tiene que quedar a la vista.
create view v_alerta_ternero_ciclo_cerrado
with (security_invoker = true)
as
select id_ciclo_productivo, ciclo, linea, fecha_fin, sexo, saldo
  from v_ternero_sin_identificar_saldo
 where nivel = 'CICLO' and ciclo_cerrado and saldo <> 0;

-- Movimientos cuya fecha cae fuera del ciclo al que se cargaron: un ciclo mal
-- elegido a mano, o fechas del ciclo editadas después de cargar.
create view v_alerta_ternero_fuera_de_ciclo
with (security_invoker = true)
as
select m.id_mov, m.tipo, m.fecha_evento, m.sexo, m.cantidad, m.ciclo, m.ciclo_manual,
       c.fecha_inicio, c.fecha_fin
  from v_ternero_sin_identificar_mov m
  join ciclo_productivo c on c.id_ciclo_productivo = m.id_ciclo_productivo
 where m.tipo <> 'ANULACION'
   and not m.anulado
   and m.fecha_evento not between c.fecha_inicio and c.fecha_fin;


-- =====================================================================
-- 4 · Integración con las vistas de stock
-- =====================================================================
-- CREATE OR REPLACE VIEW exige las mismas columnas, con el mismo tipo y en el
-- mismo orden. Las dos partes originales quedan igual; solo se agrega una
-- UNION con los terneros sin identificar, una fila por ciclo y sexo con saldo
-- distinto de cero (si es negativo, se ve negativo).

create or replace view v_stock_unificado
with (security_invoker = true)
as
select 'CATEGORIA'::text as tipo,
       c.orden,
       c.nombre as grupo,
       count(ac.id_animal) as cabezas
  from categoria c
  left join animal_categoria ac on ac.id_categoria = c.id_categoria and ac.fecha_hasta is null
 group by c.orden, c.nombre
union all
select 'RODEO'::text as tipo,
       1000 + r.id_rodeo as orden,
       r.nombre as grupo,
       count(ar.id_animal) as cabezas
  from rodeo r
  left join animal_rodeo ar on ar.id_rodeo = r.id_rodeo and ar.fecha_hasta is null
 group by r.id_rodeo, r.nombre
union all
select 'SIN_IDENTIFICAR'::text as tipo,
       2000 + s.id_ciclo_productivo * 2 + case s.sexo when 'H' then 1 else 0 end as orden,
       'Sin identificar · ' || s.ciclo || ' · ' || case s.sexo when 'M' then 'machos' else 'hembras' end as grupo,
       s.saldo as cabezas
  from v_ternero_sin_identificar_saldo s
 where s.nivel = 'CICLO' and s.saldo <> 0;

create or replace view v_rodeo_stock
with (security_invoker = true)
as
select coalesce(rodeo, '(sin rodeo asignado)'::text) as rodeo,
       count(*) as cabezas,
       count(*) filter (where sexo = 'H'::text) as hembras,
       count(*) filter (where sexo = 'M'::text) as machos,
       count(distinct categoria_codigo) as categorias_distintas
  from v_rodeo_actual
 group by (coalesce(rodeo, '(sin rodeo asignado)'::text))
union all
select '(sin identificar · ' || s.ciclo || ')' as rodeo,
       sum(s.saldo)::bigint as cabezas,
       coalesce(sum(s.saldo) filter (where s.sexo = 'H'), 0)::bigint as hembras,
       coalesce(sum(s.saldo) filter (where s.sexo = 'M'), 0)::bigint as machos,
       0::bigint as categorias_distintas
  from v_ternero_sin_identificar_saldo s
 where s.nivel = 'CICLO'
 group by s.id_ciclo_productivo, s.ciclo
having bool_or(s.saldo <> 0);


-- =====================================================================
-- 5 · Permisos (GRANT + RLS)
-- =====================================================================
-- Las tablas nuevas en public reciben GRANT completo a anon/authenticated por
-- el default ACL de Supabase: se recorta a lo que corresponde.

revoke all on ciclo_productivo, ternero_sin_identificar_mov from anon, authenticated;
grant select, insert, update on ciclo_productivo to authenticated;
grant select, insert on ternero_sin_identificar_mov to authenticated;

revoke all on v_ternero_sin_identificar_mov, v_ternero_sin_identificar_saldo,
              v_alerta_ternero_ciclo_cerrado, v_alerta_ternero_fuera_de_ciclo from anon;
grant select on v_ternero_sin_identificar_mov, v_ternero_sin_identificar_saldo,
                v_alerta_ternero_ciclo_cerrado, v_alerta_ternero_fuera_de_ciclo to authenticated;

alter table ciclo_productivo enable row level security;
create policy ciclo_productivo_select_auth on ciclo_productivo
    for select to authenticated using (true);
create policy ciclo_productivo_insert_gestor on ciclo_productivo
    for insert to authenticated with check (es_gestor());
create policy ciclo_productivo_update_gestor on ciclo_productivo
    for update to authenticated using (es_gestor()) with check (es_gestor());

-- Sin políticas de UPDATE/DELETE: la tabla es de solo agregar (además del trigger).
alter table ternero_sin_identificar_mov enable row level security;
create policy ternero_mov_select_auth on ternero_sin_identificar_mov
    for select to authenticated using (true);
create policy ternero_mov_insert_auth on ternero_sin_identificar_mov
    for insert to authenticated with check (true);


insert into _migraciones_aplicadas (version)
values ('20260929120000_ternero_sin_identificar')
on conflict (version) do nothing;


-- =====================================================================
-- Comprobación
-- =====================================================================

select codigo, linea, fecha_inicio, paricion_desde, paricion_hasta, fecha_fin
  from ciclo_productivo order by linea, fecha_inicio;
-- esperado: 4 filas (2025-26, 2026-27, VAQ2025-26, VAQ2026-27)

select
    (select codigo from ciclo_productivo where id_ciclo_productivo = ciclo_productivo_sugerido('VACA', '2026-08-15')) as vaca_ago_2026,
    (select codigo from ciclo_productivo where id_ciclo_productivo = ciclo_productivo_sugerido('VACA', '2027-03-20')) as vaca_mar_2027,
    (select codigo from ciclo_productivo where id_ciclo_productivo = ciclo_productivo_sugerido('VAQ',  '2026-05-10')) as vaq_may_2026,
    (select codigo from ciclo_productivo where id_ciclo_productivo = ciclo_productivo_sugerido('VAQ',  '2027-01-15')) as vaq_ene_2027;
-- esperado: 2025-26 · 2025-26 · VAQ2025-26 · null

select count(*) as filas_saldo from v_ternero_sin_identificar_saldo;
-- esperado: 11 (4 ciclos x 2 sexos + 2 totales por sexo + 1 total general)

select count(*) filter (where tipo = 'SIN_IDENTIFICAR') as filas_sin_identificar from v_stock_unificado;
-- esperado: 0 (todavía no hay movimientos)

select n.nspname || '.' || c.relname as sin_permiso
  from pg_class c join pg_namespace n on n.oid = c.relnamespace
 where n.nspname = 'public'
   and c.relname in ('ciclo_productivo', 'ternero_sin_identificar_mov', 'v_ternero_sin_identificar_mov',
                     'v_ternero_sin_identificar_saldo', 'v_alerta_ternero_ciclo_cerrado',
                     'v_alerta_ternero_fuera_de_ciclo', 'v_stock_unificado', 'v_rodeo_stock')
   and not has_table_privilege('authenticated', c.oid, 'SELECT');
-- esperado: 0 filas

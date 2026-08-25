-- v0.2a (saneamiento), ver docs/etapas.md y docs/decisiones.md ADR-003.
--
-- Antes de dar de baja los animales que ya no estan en el campo (perdidos
-- de vista durante la migracion, sin registro de venta/muerte/traslado real)
-- hace falta una causa que los distinga de una muerte de verdad. Sin esto,
-- esas bajas se mezclan con la mortandad real e inflan el KPI del primer
-- año.
--
-- tipo_baja = FALTANTE porque no es venta, muerte confirmada ni traslado:
-- es "no sabemos donde esta, dejo de figurar como stock vigente".

set search_path to public;

insert into causa_baja (tipo_baja, descripcion)
values ('FALTANTE', 'regularizacion_inicial');

-- Comprobación: la causa existe, una sola vez.
select id_causa_baja, tipo_baja, descripcion
  from causa_baja
 where descripcion = 'regularizacion_inicial';
-- esperado: 1 fila

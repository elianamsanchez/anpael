# Migraciones de la base

## Por qué los `.sql` viven en el repositorio

Hoy la base se toca desde el editor SQL de Supabase. Eso funciona para una
persona sola, pero tiene un problema: **no queda registro de qué se corrió ni
en qué orden**. Si mañana hay que levantar la base de cero —un entorno de
prueba, una recuperación, otro campo— la única forma de reconstruirla es que
alguien se acuerde.

Con los archivos acá, la reconstrucción es correr una carpeta en orden.

---

## Los archivos de la migración inicial

La migración desde Excel son **20 archivos** que se corren en orden y dan 0
errores desde una base vacía. Están en el paquete `migracion_santa_ana.zip`,
con su guía `00_EMPEZAR_ACA.md`.

| archivo | qué hace |
|---|---|
| `modelo_ganadero_santa_ana_supabase.sql` | crea las 25 tablas, las políticas RLS y las vistas |
| `mig_01_staging.sql` | copia textual de las hojas Excel a `stg_*` |
| `mig_02_mapeos.sql` | tablas `map_*`: cómo se traduce cada valor del Excel |
| `mig_03_transformacion.sql` | animales e identificaciones |
| `mig_04_control.sql` | controles de la primera etapa |
| `mig_05_segunda_etapa.sql` | el resto de las hojas |
| `mig_06_eventos.sql` | trabajos y eventos |
| `mig_07_autoria_por_usuario.sql` | quién cargó cada cosa |
| `mig_08_seguridad_vistas.sql` | `security_invoker` en las vistas |
| `mig_09*.sql` | catálogo de dentadura |
| `mig_10*.sql` | categorías, incluida CUT |
| `mig_11_descarte.sql` | descartes |
| `mig_12_validacion.sql` | tabla `animal_validacion` |
| `mig_13_ordenar_esquemas.sql` | devuelve las `stg_*` al esquema `stg` |
| `mig_14_destrabar.sql` | `causa_baja`, `potrero`, `animal_categoria` |
| `mig_15_rodeos.sql` | rodeos de verdad + `mover_a_rodeo()` + `v_ident_principal` |
| `mig_16_rodeo_gral.sql` | carga Rodeo Gral 1 y 2 |
| `mig_17_unificar_cuig.sql` | une Al154 con PC269: es el mismo campo, otra sociedad |
| `mig_18_toros.sql` | los 64 toros, identificados por marca a fuego |
| `mig_19_pendientes.sql` | deja registrado lo que no se pudo resolver |
| `mig_20_permisos.sql` | los `GRANT`. **Sin esto la aplicación no lee nada** |

---

## Cómo pasarlos a este repositorio

El formato de Supabase CLI es `<timestamp>_<nombre>.sql`, y se corren en
orden alfabético. La migración inicial se copia acá con nombres que respeten
el orden en que hay que ejecutarla:

```
supabase/migrations/
  20260101000000_modelo_base.sql
  20260101000100_mig_01_staging.sql
  20260101000200_mig_02_mapeos.sql
  ...
  20260101002000_mig_20_permisos.sql
```

La fecha es de conveniencia: reconstruye el orden, no la historia real. Lo
importante es que **el orden no se puede alterar**: `mig_03` necesita los
mapeos de `mig_02`, `mig_16` necesita los rodeos de `mig_15`.

De acá en adelante, cada cambio nuevo es un archivo nuevo con la fecha real:

```
20260315120000_agregar_causa_regularizacion_inicial.sql
20260318093000_crear_tablas_planillas.sql
```

---

## Tres reglas

**1 · Un archivo que ya se corrió no se edita nunca.** Si algo salió mal, se
arregla con un archivo nuevo. Editar uno viejo hace que las bases queden
distintas según cuándo se levantaron, y esa diferencia es invisible hasta que
rompe algo.

**2 · Todo archivo empieza declarando dónde escribe.**

```sql
set search_path to public;
```

Esto no es adorno. Durante la migración, pegar un archivo por partes en el
editor de Supabase hizo que solo el primer pedazo llevara el `search_path`: 20
tablas terminaron en el esquema equivocado, y una vista de control se creó en
`stg` en lugar de `public`. Pasó tres veces.

**3 · Todo archivo termina con su propia comprobación**, en SQL, que diga si
funcionó. No "no dio error" — un `select` que muestre el resultado esperado.
Los 20 archivos de la migración están hechos así.

---

## Antes de correr algo en la base de verdad

```sql
-- ¿queda algún control de calidad en rojo?
select * from v_qa_seguridad_completa;   -- 0 filas
select * from v_qa_ident_duplicada;      -- 0 filas
select * from v_qa_sin_categoria;
```

Y después de cualquier cambio de permisos, la comprobación que importa:

```sql
select n.nspname || '.' || c.relname
  from pg_class c join pg_namespace n on n.oid = c.relnamespace
 where n.nspname = 'public' and c.relkind in ('r','v')
   and not has_table_privilege('authenticated', c.oid, 'SELECT');
```

Tiene que dar 0 filas. Si devuelve algo, esa vista o tabla va a fallar con
`permission denied` la primera vez que la aplicación la toque.

---

## Copias de seguridad

Supabase hace copias automáticas, pero **la retención depende del plan y en
el gratuito es corta**. Antes de cualquier archivo que borre, mueva o
reasigne datos, conviene bajar un respaldo propio:

```bash
pg_dump "$ANPAEL_DB_URL_DIRECTA" -Fc -f respaldo_$(date +%F).dump
```

Con la conexión **directa** (puerto 5432), no con el pooler.

# El modelo de datos

La base **ya existe y está poblada**. Este documento es el mapa para
escribir las entidades JPA sin adivinar. Con `ddl-auto: validate`, cualquier
diferencia entre una entidad y su tabla hace que la aplicación no arranque:
la tabla real manda, siempre.

> La fuente de verdad es la base, no este archivo. Ante la duda:
> ```sql
> select column_name, data_type, is_nullable
>   from information_schema.columns
>  where table_name = 'animal' order by ordinal_position;
> ```

---

## Lo que hay hoy

| | cantidad |
|---|---|
| animales | 1.732 |
| identificaciones | 1.782 |
| eventos | 3.164 |
| animales asignados a un rodeo | 269 |
| revisiones de toro | 56 |
| caravanas duplicadas | 0 |
| problemas de QA abiertos | 0 |

---

## Las 25 tablas del modelo

### Padrón

| tabla | qué guarda |
|---|---|
| `animal` | una fila por animal. La identidad, no el estado |
| `identificacion` | los números del animal, uno por fila |
| `tipo_identificacion` | VISUAL, RFID, SENASA, FUEGO, ADICIONAL |
| `establecimiento` | los campos. Santa Ana y su CUIG |
| `cabana` | origen de los animales comprados |
| `raza`, `pelaje` | catálogos |
| `persona` | quién carga y quién trabaja |

**Ojo con `identificacion.caravana`.** La columna se llama `caravana` pero
la tabla guarda todos los tipos de identificación, incluidos los que no son
caravanas: `FUEGO` es la marca a fuego y `ADICIONAL` es el número interno
(RP). Es texto, nunca número: si fuera número se pierden los ceros a la
izquierda y `0075` pasa a ser `75`.

Un animal puede tener varias identificaciones vigentes a la vez. Para
"la" identificación de un animal hay una vista: **`v_ident_principal`**, que
elige una sola con un orden de preferencia (VISUAL → RFID → SENASA → FUEGO).
**Usarla siempre** al listar animales. Hacer el `join` directo contra
`identificacion` duplica filas: los 64 toros aparecían dos y tres veces
—1.782 en lugar de 1.732— hasta que esta vista lo resolvió.

### Estado en el tiempo

| tabla | qué guarda |
|---|---|
| `animal_categoria` | qué categoría tiene, con `fecha_desde` / `fecha_hasta` |
| `animal_rodeo` | en qué rodeo está, con `fecha_desde` / `fecha_hasta` |
| `categoria` | vaca, vaquillona, ternero, toro, CUT, … con un `orden` |
| `rodeo` | los rodeos. **Un rodeo no es una categoría** |
| `potrero` | los potreros. **Vacío todavía** |

Las dos tablas de estado usan el mismo patrón: la fila vigente es la que
tiene `fecha_hasta is null`. Eso permite preguntar tanto *qué es hoy* como
*qué era en marzo* sin duplicar tablas.

Para mover animales de rodeo **no hay que hacer `INSERT` a mano**: existe la
función `mover_a_rodeo()`, que cierra la fila anterior y abre la nueva en un
solo paso. Hacerlo a mano deja animales en dos rodeos al mismo tiempo; hay
índices únicos parciales que lo impiden, así que el `INSERT` directo falla.

Un rodeo puede tener animales de una sola categoría o de varias, y los
rodeos cambian con el tiempo. El modelo no asume lo contrario.

### Trabajos y eventos

| tabla | qué guarda |
|---|---|
| `trabajo` | la jornada: qué se hizo, cuándo, en qué establecimiento |
| `evento` | un animal dentro de un trabajo |
| `pesaje` | kilos |
| `medicion_corporal` | condición corporal, circunferencia escrotal |
| `diagnostico_gestacion` | tacto: resultado y tamaño de preñez |
| `evento_reproductivo`, `servicio`, `servicio_toro`, `parto` | reproducción |
| `revision_toro` | revisión de toros |
| `sanidad` | vacunaciones y tratamientos |

`trabajo.fecha` es **cuándo pasó en el campo**. Cuándo se cargó al sistema es
otra cosa y vive en las columnas de auditoría. No son lo mismo y no hay que
mezclarlas: un tacto de marzo cargado en agosto sigue siendo de marzo.

Cada tabla de medición tiene sus propias restricciones (`CHECK` de rango en
condición corporal, lista cerrada de dentaduras, coherencia entre resultado
de tacto y tamaño de preñez). **Son las que impidieron que entraran datos
malos durante la migración.** Al escribir desde Java, esas restricciones
siguen actuando: una violación llega como excepción de base, no como un
error de validación prolijo. Hay que validar también en el backend para dar
un mensaje entendible, sin sacar el `CHECK`.

### Bajas

| tabla | qué guarda |
|---|---|
| `baja` | cuándo salió el animal del campo y por qué |
| `causa_baja` | catálogo de causas (11 cargadas) |

Un animal dado de baja **no se borra**. Sigue en `animal` y sus eventos
siguen ahí; lo que cambia es que deja de estar vigente.

Falta agregar la causa `regularizacion_inicial`, para los animales que se den
de baja durante el saneamiento porque ya no están en el campo. Sin ella, esas
bajas se mezclan con las muertes reales e inflan el KPI de mortandad del
primer año. Es un `INSERT`, va en la v0.2a.

### Andamiaje de la migración

| tabla | qué guarda |
|---|---|
| `animal_validacion` | qué animales revisó una persona. **La escribe la app HTML** |
| `animal_descarte`, `motivo_descarte` | descartes |
| `mig_pendiente` | lo que la migración no pudo resolver sola |
| `map_*`, `stg_*` | mapeos y copias textuales del Excel |

`animal_validacion` **no se toca desde el backend** hasta que termine la
revisión con `santa_ana_v02.html`. Las `stg_*` viven en el esquema `stg` y no
se exponen.

---

## Vistas útiles

| vista | para qué |
|---|---|
| `v_ident_principal` | una identificación por animal. **Usar siempre** |
| `v_animal_lista` | el padrón listo para mostrar |
| `v_animal_evento` | la historia de un animal |
| `v_animal_vigente` | los que están hoy en el campo |
| `v_stock_unificado` | stock por categoría |
| `v_rodeo_composicion` | qué hay en cada rodeo |
| `v_rodeo_actual`, `v_rodeo_movimientos`, `v_rodeo_stock` | rodeos |
| `v_pendiente`, `v_pendiente_resumen` | qué falta sanear |
| `v_validacion_avance` | cuánto se revisó |
| `v_qa_*` | controles de calidad. Tienen que dar 0 filas |

Las vistas están creadas con `security_invoker`, es decir que corren con los
permisos de quien consulta, no de quien las creó. Por eso hace falta el
`GRANT` sobre la vista **y** sobre las tablas de abajo.

---

## Dos candados distintos

Esto costó una tarde entera de diagnóstico, así que queda escrito:

| | pregunta que responde |
|---|---|
| **GRANT** | ¿este rol puede *tocar* esta tabla? |
| **RLS** | ¿qué *filas* de esa tabla puede ver? |

Son independientes. Todo el trabajo de seguridad del modelo —112 políticas—
es el segundo candado. El primero se abrió recién en `mig_20_permisos.sql`.
Un `GRANT` sobre una tabla con RLS activa **no muestra ni una fila de más**.

Cuando aparezca `permission denied for view v_...`, es el candado 1.
Cuando la consulta funcione pero devuelva 0 filas, es el candado 2.

---

## Cómo se traduce a JPA

- **Claves.** Todas las tablas usan `integer generated always as identity`
  → `@GeneratedValue(strategy = IDENTITY)`. Las tablas nuevas del circuito
  de planillas van con UUID (ver ADR-002).
- **Vistas.** Se mapean como `@Entity @Immutable` con `@Table(name = "v_...")`,
  o se leen con proyecciones de consulta nativa. Nunca se escriben.
- **Auditoría.** `AuditableEntity` pone quién y cuándo. Ojo: la base tiene un
  *trigger* `forzar_autoria()` que hoy depende de `auth.uid()`; según cómo se
  cierre ADR-001, esa lógica hay que rehacerla en Java.
- **Fechas.** `LocalDate` para las de campo (`trabajo.fecha`), `OffsetDateTime`
  para las de auditoría.
- **Enteros.** `Integer`, no `int`: `null` es un dato válido y significa
  "no se sabe", que no es lo mismo que cero.

---

## Lo que todavía falta sanear

Esto es trabajo de la Etapa 1, no defectos de la migración:

- 381 animales sin categoría asignada
- los potreros: la tabla está vacía
- revisiones 2024 y 2025 de los toros, que llegaron sin fecha
- tres formas de dentadura sin normalizar: `Cuarto diente`, `-1/4D`, `GD`
- confirmar la lectura de 5ta contra 4ta en la hoja `Vac 5ta y 4ta 18 y 19`
- definir si `Al155` es el mismo campo que `Al154` / `PC269` o es otro

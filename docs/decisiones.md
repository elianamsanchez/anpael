# Decisiones de arquitectura (ADR livianos)

Una entrada por decisión. Las que dicen **ABIERTA** hay que resolverlas antes
de escribir el código que dependa de ellas.

Formato: qué se decidió · por qué · qué se rompe si se cambia después.

---

## ADR-001 · Quién manda en la autorización: Spring Security o RLS · **RESUELTA (2026-08-21) — Opción A**

> Decidido: Spring Security es el guardián. Condiciones abajo, no negociables.

**El choque.** El documento de stack define `Spring Security + JWT (jjwt)`.
La base de datos, en cambio, ya tiene construida y probada una capa de
seguridad completa a nivel de fila:

- 112 políticas RLS
- las funciones `rol_actual()`, `es_gestor()`, `es_propietario()`
- un *trigger* `forzar_autoria()` que impide que un usuario cargue un dato
  a nombre de otro
- todas apoyadas en `auth.uid()`, que es **el usuario de Supabase Auth**

Un backend Spring se conecta a PostgreSQL con **un solo usuario de base**.
Para PostgreSQL, todos los pedidos vienen de ese usuario. Entonces:

- `auth.uid()` devuelve `null`
- ninguna política RLS de las que exigen usuario autenticado deja pasar nada,
  **o**, si el usuario de base es privilegiado, RLS se saltea por completo
- el *trigger* de autoría deja de funcionar: hay que setear el autor en Java

Es decir: **las dos capas no se suman, compiten.** No es un problema de
configuración, es una decisión de diseño que hay que tomar.

### Opción A · El backend es el guardián *(la del documento)*

Spring Security decide todo. La conexión a la base usa un rol con permiso
para saltear RLS. Las políticas quedan como red de seguridad para lo que
toque la base **por fuera** del backend: el editor SQL, un script, la app HTML
de revisión que ya existe.

- ✅ Coherente con el documento y con el perfil del desarrollador
- ✅ Una sola fuente de verdad para los permisos, en Java, testeable con JUnit
- ✅ No ata el proyecto a Supabase: mudar de proveedor no cambia la autorización
- ❌ Las 112 políticas dejan de proteger a la aplicación
- ❌ Un bug de autorización en Java expone datos sin segunda barrera
- ❌ Hay que reimplementar en Java el `forzar_autoria()` que hoy es un trigger

### Opción B · Supabase Auth es el guardián

El frontend se autentica contra Supabase (como ya lo hace la app HTML). El
backend valida ese JWT y lo propaga a PostgreSQL en cada transacción, de modo
que RLS actúe por usuario.

- ✅ Aprovecha las 112 políticas ya escritas y probadas
- ✅ Defensa en profundidad real: aunque el backend falle, la base filtra
- ✅ El trigger de autoría sigue funcionando solo
- ❌ Ata el proyecto a Supabase Auth
- ❌ Propagar el JWT a cada transacción JDBC es trabajo fino y poco documentado
- ❌ Contradice el documento de stack

### Decisión

**Opción A**, con dos condiciones que la hacen defendible:

1. **No desactivar RLS.** Queda como barrera para todo lo que no pase por el
   backend, que hoy es bastante: el editor SQL, la app HTML, los scripts.
2. **Reimplementar la autoría en Java** en la v0.1, no "después". Es lo único
   que se pierde de forma silenciosa, y es justo lo que sirve para auditar.

El motivo de fondo: el desarrollador es sólido en Java y la autorización es la
capa que más va a cambiar cuando aparezcan las aprobaciones del rol Gerente.
Que viva en el lenguaje que se domina vale más que el segundo candado.

### Consecuencia todavía sin cerrar: credenciales · **RESUELTA (2026-08-24) — Opción A1**

Hoy `persona` tiene `id_auth_user` (uuid, nullable) apuntando a Supabase Auth,
pero **no tiene columna de contraseña propia**. La única `persona` cargada
(PROPIETARIO) se autentica hoy vía Supabase Auth. Si Spring Security pasa a
ser el guardián, hay que decidir cómo se valida el login — era una
sub-decisión de la ADR-001 que había quedado abierta y bloqueaba escribir el
`AuthController`:

- **A1 · Password propia en Java.** Agregar `persona.password_hash` y
  autenticar 100% en Spring (BCrypt, ya está el bean). Corta el lazo con
  Supabase Auth para login. Requiere migración (nueva columna) y setear una
  contraseña inicial para el usuario PROPIETARIO existente.
- **A2 · Delegar la verificación a Supabase Auth, pero emitir el JWT propio.**
  El backend llama a la API de Supabase Auth con usuario/contraseña, y si es
  válido, emite su propio JWT firmado con `rol` de `persona`. No hay que
  migrar nada ni tocar `id_auth_user`, pero el login depende de un servicio
  externo y de la red.

**Decisión: A1.** El motivo es portabilidad. A2 ata el login a la API de
Supabase Auth: si algún día se migra la base a un Postgres fuera de Supabase,
ese login deja de funcionar y hay que rehacerlo igual. A1 solo depende de
tener una base Postgres (cualquiera) con la tabla `persona` y el bean de
BCrypt que ya existe en `SecurityConfig`. Es además la opción coherente con
el motivo de fondo de la ADR-001: una sola fuente de verdad en Java, sin
atar el proyecto a un proveedor.

Queda pendiente, aparte de esto: las 112 políticas RLS usan `auth.uid()`, una
función propia de Supabase Auth. Eso no depende de A1 ni de A2 — es un costo
de migrar la base fuera de Supabase en cualquier escenario, y queda como
problema menor porque RLS es red de seguridad secundaria, no la barrera
principal (ver Opción A arriba).

**Qué hace falta para implementarlo** (no incluido en este ADR, queda para
cuando se escriba el módulo Seguridad):

1. ✅ Migración: `supabase/migrations/20260824100000_agregar_login_persona.sql`.
   `persona` no tenía ningún campo de login (solo `id_persona`,
   `id_auth_user`, `nombre`, `rol`), así que además del `password_hash` se
   agrega `usuario` (nullable, único), separado de `nombre`. Le saca el
   `SELECT` a `authenticated`/`anon` sobre `password_hash` puntualmente.
   **Falta correrla** contra la base real.
2. Setear a mano una contraseña inicial para el `PROPIETARIO` existente.
3. ✅ `AuthController` (`POST /api/auth/login`) y filtro JWT en
   `com.anpael.seguridad` / `com.anpael.shared.security`. Todavía no
   probado contra la base real: falta correr el paso 1 y el paso 2.

---

## ADR-002 · Identificadores: UUID vs enteros · **ABIERTA, pero con salida barata**

**El choque.** El documento pide UUID v4 generados en el cliente, para
habilitar el alta offline de la Fase 2. La base ya cargada usa
`integer generated always as identity` en **todas** las tablas, con 1.732
animales, 3.164 eventos y todas sus claves foráneas ya escritas.

Migrar las claves de una base poblada es de las operaciones más caras y
riesgosas que existen. Y el motivo del documento —el alta offline— solo aplica
a lo que se **crea** en el campo sin señal, no al padrón histórico.

### Recomendación: híbrido

| | clave |
|---|---|
| tablas que ya existen (`animal`, `evento`, `trabajo`, …) | siguen con enteros |
| tablas nuevas del circuito de planillas (`sesion_trabajo`, `linea_planilla`) | **UUID** |
| si algún día hay que crear animales offline | agregar `animal.uuid_externo`, sin tocar la PK |

Cumple el propósito del documento a costo casi cero. Lo que **no** hay que
hacer es empezar a mezclar sin criterio: la regla es *lo nuevo que se cree
fuera de línea lleva UUID; lo demás no*.

---

## ADR-003 · Los nombres del documento no son los de la base · **RESUELTA**

El documento describe un modelo de datos en sus secciones 5 y 9 que **ya está
implementado, con otros nombres**. Como `ddl-auto: validate` obliga a que las
entidades JPA coincidan con las tablas reales, mandan las tablas.

| documento | tabla real | ¿cumple la intención? |
|---|---|---|
| `animal.categoria_id` + `historial_categoria` | `animal_categoria` con `fecha_desde` / `fecha_hasta` | Sí, y mejor: una sola tabla responde "qué es hoy" y "qué era en marzo" |
| `animal.rodeo_id` + `movimiento_rodeo` | `animal_rodeo` con `fecha_desde` / `fecha_hasta` + función `mover_a_rodeo()` | Sí |
| `rodeo.potrero_actual_id` | **no existe todavía** | Falta. `potrero` está vacío |
| `fecha_evento` / `fecha_registro` | `trabajo.fecha` (cuándo ocurrió) + auditoría (cuándo se cargó) | Sí |
| bajas con `fecha_baja` / `motivo_baja` en el animal | tabla `baja` + catálogo `causa_baja` | Sí, y permite estadística por causa |
| `motivo_baja = regularizacion_inicial` | **falta cargarlo** en `causa_baja` | Ver la nota de abajo |
| `SesionTrabajo` / `LineaPlanilla` | **no existen** | Es la tabla nueva de la v0.2b |
| payload de eventos en JSONB | tablas específicas (`diagnostico_gestacion`, `medicion_corporal`, …) | Difiere. Ver abajo |

**Sobre el JSONB.** El documento propone un `payload` JSONB validado en el
backend para no tener seis tablas. La base tomó el camino contrario y ya tiene
las seis tablas, con sus restricciones (`CHECK` de rango en condición corporal,
lista cerrada de dentaduras, coherencia entre resultado y tamaño de preñez).
Esas restricciones son las que impidieron que entraran datos malos durante la
migración, y en JSONB no existirían. **Se mantiene el modelo de la base.** El
JSONB queda disponible para tipos de evento nuevos que todavía no tienen forma
definida.

**Falta agregar** `regularizacion_inicial` al catálogo `causa_baja`: es la que
evita inflar los KPI de mortandad del primer año cuando se den de baja los
animales que ya no están en el campo. Es un `INSERT`, va en la v0.2a.

---

## ADR-004 · La app HTML de revisión convive, no compite · RESUELTA

Ya existe `santa_ana_v02.html`: un archivo, sin compilar, que lee la base por
la API REST de Supabase y sirve para revisar los 1.732 animales migrados.

**No se reemplaza con la v0.1.** Es una herramienta de saneamiento con vida
corta, ya funciona, y rehacerla en Vue no agrega nada. Cuando el módulo de
trazabilidad tenga la pantalla de animales, deja de usarse sola.

Lo que sí importa: escribe en `animal_validacion`, así que esa tabla **no se
toca** hasta que la revisión termine.

---

## ADR-005 · Java 21 + Spring Boot 3.3.5 · RESUELTA

Versión del parent fijada en el `pom.xml`. Se sube cambiando un solo número.
No se fijan versiones de las dependencias que el parent ya administra
(postgresql, lombok, testcontainers, jackson): fijarlas a mano garantiza que
tarde o temprano se desincronicen del resto.

---

## ADR-006 · Sin CSRF, token en memoria · RESUELTA

La API es *stateless* y autentica por header `Authorization`. No hay cookies
de sesión, así que CSRF no aplica y está desactivado. **Si alguna vez se pasa
a cookies, hay que volver a encenderlo.**

El token vive en memoria en el frontend, nunca en `localStorage`. El costo es
tener que volver a entrar al recargar la página; el beneficio es que el token
no queda disponible para cualquiera que use esa computadora.

---

## ADR-007 · El pooler de Supabase necesita `prepareThreshold=0` · RESUELTA

El *transaction pooler* (puerto 6543) no soporta *prepared statements* con
nombre, y el driver JDBC de PostgreSQL los usa por defecto. Sin ese parámetro
en la URL aparecen errores **intermitentes** del tipo
`prepared statement "S_1" already exists`, que son de los más difíciles de
diagnosticar porque no fallan siempre.

Ya está puesto en `.env.example`.

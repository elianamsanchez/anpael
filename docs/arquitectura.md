# 🏗️ Documentación de Arquitectura: ANPAEL · Gestión ganadera Santa Ana

Este documento describe la arquitectura global, las decisiones de diseño y el
flujo de datos del sistema. Al ser un proyecto desarrollado en solitario, se
prioriza la **simplicidad**, la **mantenibilidad** y el **bajo acoplamiento**.

Es el mapa de conjunto. Los dos documentos que lo complementan son
`decisiones.md` (el *por qué* de cada decisión grande) y `modelo-datos.md`
(el detalle tabla por tabla). Ante una contradicción, manda la base de datos:
está poblada y en uso.

---

## 1. 🌍 Vista General del Sistema

El software es un **Monolito Modular** en el backend + **Single Page
Application** en el frontend, contra una base PostgreSQL que **ya existía y
está poblada** (1.732 animales, 1.782 identificaciones, 3.164 eventos
migrados desde las planillas Excel).

```text
[ Navegador / Celular (PWA) ]  <--- (HTTPS / JSON + JWT) ---> [ Backend Spring Boot ]
         Vue 3 + PrimeVue                                              |
                                                            (JDBC · pooler 6543)
                                                                       |
                                                      [ PostgreSQL en Supabase ]
                                                       25 tablas · vistas · 112 RLS
```

*   **Frontend:** Vue 3 + TypeScript + Vite + PrimeVue, empaquetado como PWA
    (`vite-plugin-pwa`, `registerType: 'prompt'`). La PWA está elegida
    defensivamente: hoy no habilita nada offline, pero la Etapa 2 la necesita y
    así no hay que reescribir el empaquetado.
*   **Backend:** Java 21 + Spring Boot 3.3.5 (`anpael-backend 0.1.0-SNAPSHOT`).
    Spring Web + Data JPA + Security + Validation, `jjwt` para los tokens,
    Thymeleaf + openhtmltopdf para las planillas en PDF, springdoc para Swagger.
*   **Base de datos:** PostgreSQL alojada en Supabase. El esquema **no** lo
    maneja Hibernate: lo manejan los `.sql` de `supabase/migrations/`.

**Dos detalles de conexión que no son opcionales:**

| | |
|---|---|
| puerto **6543** (*transaction pooler*) | el que usa la aplicación |
| puerto **5432** (*direct connection*) | migraciones y `pg_dump`; en el plan gratuito puede no estar disponible por IPv4 |
| `?prepareThreshold=0` en la URL | el pooler no soporta *prepared statements* con nombre (ADR-007) |
| `ddl-auto: validate` | si una entidad JPA no coincide con la tabla real, la aplicación **no arranca**. Es a propósito |

`GET /api/health` es el chequeo de punta a punta: devuelve `entorno`,
`usuarioBase`, `base`, el conteo de `animales` y `base_de_datos: ok`. Mirar
siempre **`entorno`** antes de escribir algo: el Supabase local tiene un dump
de producción, así que el conteo de animales ya no distingue una base de la
otra.

---

## 2. 📁 Estructura del Proyecto (Monorepo)

```text
├── .github/workflows/     ci.yml — compila y testea backend y frontend en cada push
├── docs/                  arquitectura.md (este) · decisiones.md · modelo-datos.md
│                          etapas.md · captura-planillas.md
├── scripts/               levantar_local.sh · levantar_produccion.sh
│                          bajar_ambiente.sh · usuario_prueba_local.sh
├── supabase/
│   └── migrations/        los .sql que le dan forma a la base, + su README
├── backend/               Spring Boot · Java 21 · monolito modular
│   ├── .env.local.example        plantilla contra el Supabase local en Docker
│   ├── .env.production.example   plantilla contra la base real
│   └── src/main/java/com/anpael/
│       ├── AnpaelApplication.java
│       ├── shared/              lo que puede usar cualquier módulo
│       │   ├── api/             HealthController
│       │   ├── audit/           AuditableEntity (creado_por / modificado_por)
│       │   ├── config/          Security, Cors, Jpa, OpenApi
│       │   ├── exception/       GlobalExceptionHandler + excepciones de negocio
│       │   ├── security/        JwtService, JwtAuthenticationFilter, ContextoAutenticacion
│       │   └── util/
│       ├── seguridad/           login, persona, roles
│       ├── trazabilidad/        padrón: animal, identificación, categoría, rodeo, baja
│       ├── planillas/           trabajos, eventos, PDF y carga de resultados
│       ├── sanidad/             (vacío todavía)
│       ├── reproduccion/        (vacío todavía)
│       ├── nutricion/           (vacío todavía)
│       └── reportes/            (vacío todavía)
└── frontend/
    └── src/
        ├── api/            client.ts (axios + interceptores) · animales · auth · health
        │                   planillas · trabajos
        ├── assets/tokens/  colores · tipografía · espaciado · bordes · movimiento
        ├── components/     base/ · datos/ · formularios/ · avisos/ · icons/
        ├── router/         rutas privadas por default
        ├── stores/         auth.ts (Pinia)
        ├── types/
        └── views/          seguridad/ · trazabilidad/ + Dashboard · Estado
```

### Las dos reglas de la estructura

**1 · Un módulo no importa clases de otro módulo.** Si necesita datos ajenos,
los pide por un servicio público o por una vista de la base. `shared/` es la
excepción: lo puede usar cualquiera, y por eso no tiene lógica de negocio
adentro.

**2 · Cada módulo tiene las mismas cuatro capas**, siempre con estos nombres:

```text
modulo/
├── api/              controllers + dto/   (transporte HTTP, nada de reglas)
├── service/          la lógica de negocio
├── domain/           entidades JPA y enums
└── infrastructure/   repositorios Spring Data
```

Las carpetas de `frontend/src/views/` espejan los módulos del backend a
propósito: al tocar una funcionalidad se editan carpetas con el mismo nombre
de los dos lados.

### Estado de los módulos

| módulo | estado |
|---|---|
| `shared` | ✅ salud, auditoría, seguridad HTTP, manejo de errores |
| `seguridad` | ✅ `POST /api/auth/login`, `Persona`, `RolPersona`, filtro JWT |
| `trazabilidad` | ✅ padrón, alta, corrección, baja, categoría, rodeo, validación, catálogos |
| `planillas` | ✅ PDF de planillas + carga y edición de resultados (tacto, pesada, revisión de toros, sanidad) |
| `sanidad`, `reproduccion`, `nutricion`, `reportes` | ⏳ paquetes creados, vacíos |

### La API de hoy

| grupo | endpoints |
|---|---|
| salud | `GET /api/health` · `GET /actuator/health` |
| seguridad | `POST /api/auth/login` |
| padrón | `GET/POST /api/animales` · `GET /api/animales/{id}` · `/historial` · `/identificaciones` · `PATCH /api/animales/{id}` · `POST .../categoria`, `/rodeo`, `/establecimiento`, `/validacion`, `/baja` |
| catálogos | `/api/categorias` · `/api/rodeos` (+ `/{id}/animales`) · `/api/razas` · `/api/pelajes` · `/api/cabanas` · `/api/establecimientos` · `/api/causas-baja` |
| planillas | `GET /api/planillas` (PDF) |
| resultados | `POST /api/trabajos/{tacto,pesada,revision-toros,sanidad}` · `PATCH /api/eventos/{id}/{tacto,pesada,revision-toros,sanidad}` |

La documentación se genera sola desde los controllers, en
`http://localhost:8080/swagger-ui.html`.

---

## 3. 🗄️ Modelo de Datos (Esquema Conceptual)

25 tablas. El detalle está en `modelo-datos.md`; acá van las piezas que hay
que entender para no equivocarse.

### Entidades principales

*   **`animal`** — una fila por animal. Guarda **la identidad, no el estado**.
*   **`identificacion`** — los números del animal, uno por fila. Un animal puede
    tener varias vigentes a la vez (`VISUAL`, `RFID`, `SENASA`, `FUEGO`,
    `ADICIONAL`).
*   **`animal_categoria` / `animal_rodeo`** — el estado en el tiempo, con
    `fecha_desde` / `fecha_hasta`. La fila vigente es la de `fecha_hasta is null`.
*   **`trabajo`** — la jornada: qué se hizo, cuándo, en qué establecimiento.
*   **`evento`** — un animal dentro de un trabajo. De ahí cuelgan las tablas de
    medición: `pesaje`, `medicion_corporal`, `diagnostico_gestacion`,
    `revision_toro`, `sanidad`, `parto`, `servicio`…
*   **`baja`** — cuándo salió el animal del campo y por qué. Un animal dado de
    baja **no se borra**: deja de estar vigente.
*   **`persona`** — quién carga y quién trabaja. Desde
    `20260824100000_agregar_login_persona.sql` tiene `usuario` y `password_hash`.

```text
  +------------------+                  +----------------------+
  |     PERSONA      |                  |  TIPO_IDENTIFICACION |
  +------------------+                  +----------------------+
  | id_persona (PK)  |                  | VISUAL/RFID/SENASA…  |
  | usuario (unico)  |                  +----------------------+
  | password_hash    |                             | 1
  | rol              |                             | N
  | id_auth_user     |                  +----------------------+
  +------------------+                  |   IDENTIFICACION     |
                                        +----------------------+
                                        | id (PK)              |
                                        | id_animal (FK)       |
                                        | caravana  (TEXTO)    |
                                        +----------------------+
                                                   | N
                                                   | 1
  +-------------------+  N        1  +-------------------+  1        N  +------------------+
  | ANIMAL_CATEGORIA  |--------------|      ANIMAL       |--------------|      EVENTO      |
  +-------------------+              +-------------------+              +------------------+
  | id_animal (FK)    |              | id_animal (PK)    |              | id_evento (PK)   |
  | id_categoria (FK) |              | sexo, raza,       |              | id_animal  (FK)  |
  | fecha_desde       |              | pelaje, cabaña,   |              | id_trabajo (FK)  |
  | fecha_hasta       |              | establecimiento,  |              +------------------+
  +-------------------+              | nacimiento,       |                       | 1
                                     | ingreso, padre,   |                       | 1
  +-------------------+  N        1  | observaciones     |         +-------------------------+
  |   ANIMAL_RODEO    |--------------+-------------------+         | PESAJE                  |
  +-------------------+                 |  1        1  |           | MEDICION_CORPORAL       |
  | id_animal (FK)    |                 |              |           | DIAGNOSTICO_GESTACION   |
  | id_rodeo (FK)     |                 | N            | N         | REVISION_TORO           |
  | fecha_desde       |          +-------------+  +-----------+    | SANIDAD                 |
  | fecha_hasta       |          |    BAJA     |  |  ANIMAL_  |    +-------------------------+
  +-------------------+          +-------------+  | VALIDACION|
                                 | causa_baja  |  +-----------+         +----------------+
                                 +-------------+                        |    TRABAJO     |
                                                                        +----------------+
                                                                        | id_trabajo (PK)|
                                                                        | fecha  ← campo |
                                                                        | tipo           |
                                                                        +----------------+
```

### Cuatro trampas del modelo, escritas para no repetirlas

1.  **`identificacion.caravana` es texto, nunca número.** Si fuera número se
    pierden los ceros a la izquierda y `0075` pasa a ser `75`. Y la tabla guarda
    todos los tipos de identificación, no solo caravanas: `FUEGO` es la marca a
    fuego, `ADICIONAL` el número interno (RP).
2.  **Al listar animales se usa `v_ident_principal`**, la vista que elige una
    sola identificación por animal (VISUAL → RFID → SENASA → FUEGO). El `join`
    directo contra `identificacion` duplica filas: los 64 toros aparecían dos y
    tres veces —1.782 en lugar de 1.732— hasta que esta vista lo resolvió.
3.  **Para mover un animal de rodeo se llama a `mover_a_rodeo()`**, no se hace
    `INSERT` a mano: la función cierra la fila anterior y abre la nueva en un
    paso. Hay índices únicos parciales que hacen fallar el `INSERT` directo.
4.  **`trabajo.fecha` es cuándo pasó en el campo**; cuándo se cargó al sistema
    vive en las columnas de auditoría. Un tacto de marzo cargado en agosto sigue
    siendo de marzo, y mezclarlas hace mentir a los reportes.

### Vistas

Se mapean como `@Entity @Immutable` con `@Table(name = "v_...")`, o se leen
con proyecciones nativas. **Nunca se escriben.** Las principales:
`v_animal_lista` (el padrón listo para mostrar), `v_animal_evento` (la
historia de un animal), `v_animal_vigente`, `v_stock_unificado`,
`v_rodeo_composicion`, `v_qa_*` (controles de calidad, tienen que dar 0 filas).

Están creadas con `security_invoker`: corren con los permisos de quien
consulta, así que hace falta el `GRANT` sobre la vista **y** sobre las tablas
de abajo.

### Convenciones JPA

| | |
|---|---|
| claves | `integer generated always as identity` → `@GeneratedValue(IDENTITY)`. Las tablas nuevas del circuito de planillas van con UUID (ADR-002) |
| fechas de campo | `LocalDate` (`trabajo.fecha`) |
| fechas de auditoría | `OffsetDateTime` |
| enteros | `Integer`, no `int`: `null` significa "no se sabe", que no es cero |

---

## 4. 🔐 Estrategia de Autenticación y Seguridad

**Spring Security es el guardián** (ADR-001, Opción A). La decisión de fondo:
la base ya traía una capa de seguridad completa —112 políticas RLS, las
funciones `rol_actual()` / `es_gestor()` / `es_propietario()`, el trigger
`forzar_autoria()`— toda apoyada en `auth.uid()` de Supabase Auth. Pero un
backend Spring se conecta con **un solo usuario de base**: para PostgreSQL
todos los pedidos vienen de ese usuario, `auth.uid()` es `null` y las dos
capas no se suman, **compiten**.

Se eligió que la autorización viva en Java, con dos condiciones no
negociables:

1.  **RLS no se desactiva.** Queda como red de seguridad para todo lo que toque
    la base por fuera del backend: el editor SQL de Supabase, los scripts.
2.  **La autoría se reimplementa en Java.** Es lo único que se perdía en
    silencio al dejar de funcionar el trigger, y es justo lo que sirve para
    auditar.

### Cómo funciona el login

1.  `POST /api/auth/login` con usuario y contraseña. `AuthService` compara
    contra `persona.password_hash` con **BCrypt** (costo por defecto, 10:
    subirlo encarece el login sin beneficio real para tres o cuatro usuarios).
2.  `JwtService` emite un JWT propio, firmado **HMAC-SHA** con una clave
    simétrica que vive solo en `ANPAEL_JWT_SECRETO`. Claims: `sub` = id de
    persona, `nombre`, `rol`. Vida: `ANPAEL_JWT_MINUTOS`, por defecto **480
    minutos** (8 horas, una jornada).
3.  El backend **nunca** llama a la API de Supabase Auth para autenticar
    (ADR-001 · A1). El motivo es portabilidad: A1 solo necesita un PostgreSQL
    cualquiera con la tabla `persona` y el bean de BCrypt.
4.  `JwtAuthenticationFilter` valida el token en cada pedido y deja el id de
    persona en `Authentication.details`, de donde lo lee
    `ContextoAutenticacion.idPersonaActual()` para los FK numéricos como
    `baja.id_persona_registro`. El nombre legible lo toma
    `JpaConfig.auditorActual()` para `creado_por` / `modificado_por`.

### Reglas de la capa HTTP

| regla | por qué |
|---|---|
| **todo cerrado por default** (`anyRequest().authenticated()`) | si se arranca con todo abierto y "después" se cierra, siempre queda algo abierto. Al revés, cada endpoint nuevo obliga a decidir quién lo usa |
| público solo: `/api/health`, `/actuator/health`, `/api/auth/login`, Swagger, `OPTIONS /**` | Swagger es documentación: los endpoints que lista siguen pidiendo JWT |
| **sin CSRF**, sesión `STATELESS` | no hay cookies de sesión, así que CSRF no aplica. **Si algún día se pasa a cookies, hay que volver a encenderlo** (ADR-006) |
| `@EnableMethodSecurity` | habilita `@PreAuthorize("hasRole('GERENTE')")` en los servicios, para cuando lleguen las aprobaciones |
| 401 y 403 con cuerpo JSON propio | los tira el filtro, antes de cualquier controller: `GlobalExceptionHandler` no llega ahí, y sin esto Spring devuelve un 403 vacío o redirige a un form de login que no existe |
| CORS por variable de entorno | `ANPAEL_CORS_ORIGENES`. En desarrollo no interviene: el proxy de Vite hace que backend y frontend sean el mismo origen para el navegador |

**Los cuatro roles del negocio:** `PROPIETARIO`, `GESTOR`, `GERENTE`,
`OPERATIVO`. La estructura está definida desde el día 1 aunque las
validaciones lleguen después: agregar un modelo de permisos sobre datos ya
cargados es caro.

### En el frontend

El token vive **en memoria**, en el store de Pinia, nunca en `localStorage`
(ADR-006). El costo es volver a entrar al recargar la página; el beneficio es
que el token no queda disponible para cualquiera que use esa computadora ni
para scripts de terceros. `api/client.ts` lo agrega con un interceptor de
salida, y **las rutas son privadas por default**: hay que marcarlas
`meta: { publico: true }` a propósito para dejarlas afuera del login.

El interceptor de entrada distingue **"el servidor no contesta"** (estado `0`)
de **"el servidor dijo que no"**: el primero es un problema de conexión, el
segundo una respuesta legítima. Confundirlos hace perder mucho tiempo al
depurar.

### Los secretos

Ningún archivo del repositorio tiene una clave adentro, y así tiene que
quedar. Todo entra por variables de entorno: `ANPAEL_DB_URL`,
`ANPAEL_DB_USER`, `ANPAEL_DB_PASSWORD`, `ANPAEL_JWT_SECRETO`,
`ANPAEL_ENTORNO`, `ANPAEL_CORS_ORIGENES`. `.env`, `.env.local` y
`.env.production` están en `.gitignore`; se versionan solo las plantillas
`*.example`, y cada entorno tiene su propio `ANPAEL_JWT_SECRETO`.

La clave `sb_secret_` / *service role* de Supabase **no se usa acá** y no
tiene que estar en ninguna máquina de desarrollo: saltea toda la seguridad de
la base. Y si alguna vez se sube un secreto por error, hay que **rotarlo**:
borrarlo con un commit nuevo no sirve, queda en el historial.

---

## 5. 🚀 Flujo de Despliegue (CI/CD)

### Integración continua — automatizada

`.github/workflows/ci.yml` corre en cada push y PR a `main` y `develop`, en
dos jobs paralelos. **No necesita ninguna clave**: los tests de integración
levantan su propio PostgreSQL con Testcontainers y no se conectan a Supabase.

| job | qué hace |
|---|---|
| **Backend · Java 21** | JDK 21 temurin + caché de Maven → `mvn --batch-mode verify` (compila + tests unitarios + integración) → guarda `surefire-reports/` como artefacto, **también cuando falla**: ahí es cuando sirve |
| **Frontend · Node 20** | `npm ci` (con fallback a `npm install` hasta que exista el lock) → `npm run build`, que corre `vue-tsc` antes de compilar, así que un error de tipos rompe el build |

### Despliegue — todavía manual

No hay hosting ni pipeline de deploy: hoy la aplicación se corre desde la
máquina del desarrollador, contra la base local o la real. Los scripts hacen
ese camino repetible:

```bash
bash scripts/levantar_local.sh       # contra el Supabase local en Docker
bash scripts/levantar_produccion.sh  # contra la base real
bash scripts/bajar_ambiente.sh       # baja backend y frontend; no toca Supabase
```

`levantar_produccion.sh` es deliberadamente incómodo, y eso es la feature:

1.  exige `backend/.env.production` completo, sin defaults inventados;
2.  pide escribir la palabra `produccion` para confirmar;
3.  después de levantar consulta `/api/health` y **aborta si `entorno` no es el
    esperado** — mejor cortar ahí que dejar escribir a ciegas en la base de
    verdad.

### Migraciones de base — manuales y con reglas

Se corren a mano desde el editor SQL de Supabase; los `.sql` viven en
`supabase/migrations/` para que la base se pueda reconstruir corriendo una
carpeta en orden. Las reglas, del README de esa carpeta:

1.  **Un archivo que ya se corrió no se edita nunca.** Si algo salió mal, se
    arregla con un archivo nuevo. Editar uno viejo hace que las bases queden
    distintas según cuándo se levantaron, y esa diferencia es invisible hasta
    que rompe algo.
2.  **Todo archivo empieza con `set search_path to public;`.** No es adorno:
    pegar un archivo por partes en el editor hizo que 20 tablas terminaran en
    el esquema equivocado. Pasó tres veces.
3.  **Todo archivo termina con su propia comprobación en SQL** que muestre el
    resultado esperado — no basta con "no dio error".
4.  **Y se anota en `_migraciones_aplicadas`**, que es la respuesta a "¿qué
    migraciones ya corrieron acá?".

Antes de tocar la base real: que `v_qa_seguridad_completa` y
`v_qa_ident_duplicada` den 0 filas, y respaldo propio con `pg_dump` por la
conexión **directa** (5432) si el archivo borra, mueve o reasigna datos.

---

## 6. 🧪 Estrategia de Pruebas

Se priorizan los **tests de integración** sobre los unitarios:
`spring-boot-testcontainers` + `testcontainers/postgresql` levantan un
PostgreSQL de verdad en Docker por corrida. `HealthControllerIT` es el que
existe hoy. El motivo es directo: prueba una sola persona el sistema entero, y
los tests de integración son el segundo par de ojos. Docker hace falta solo
para correrlos.

---

## 7. 🗺️ Por dónde va el proyecto

El criterio de corte de cada versión es **qué puede hacer una persona en el
campo que antes no podía**, no cuántas pantallas hay (detalle en `etapas.md`).

| | estado |
|---|---|
| Base de datos migrada y verificada | ✅ |
| v0.1 · Seguridad y acceso (login, JWT, roles, autoría en Java) | ✅ desbloqueada al cerrar ADR-001 |
| v0.2a · Saneamiento (padrón, categorías, rodeos, bajas) | 🔄 en curso — faltan 381 animales sin categoría y los potreros |
| v0.2b · Generador de planillas PDF + carga de resultados | ✅ el circuito imprimir → trabajar → cargar |
| Etapa 2 · Carga en el celular sin señal (PWA + sincronización) | ⏳ acá recién tienen sentido los UUID de ADR-002 |
| Etapa 3 · Indicadores: preñez por rodeo y por toro, destete, ADPV, mortandad | ⏳ |

La Etapa 3 **no se puede adelantar**: un indicador calculado sobre datos sin
sanear es peor que no tener indicador, porque se le cree.

---

## 📌 Historial de Decisiones Arquitectónicas (ADR)

El detalle completo, con las opciones descartadas y sus consecuencias, está en
**`docs/decisiones.md`**. Acá va el índice.

| ADR | decisión | estado |
|---|---|---|
| **001** | Spring Security es el guardián de la autorización, no RLS. Sub-decisión A1: contraseña propia en `persona.password_hash`, sin depender de Supabase Auth | ✅ resuelta 2026-08-21 / 2026-08-24 |
| **002** | Identificadores híbridos: las tablas pobladas siguen con enteros, las nuevas del circuito de planillas van con UUID | 🟡 abierta, con salida barata |
| **003** | Manda el nombre de la tabla real, no el del documento de diseño. Y se mantienen las seis tablas específicas de medición en lugar de un `payload` JSONB | ✅ resuelta |
| **004** | `santa_ana_v02.html` se retira: la revisión se hace desde `AnimalDetalleView` con `POST /api/animales/{id}/validacion` | ✅ resuelta, retirada 2026-09-07 |
| **005** | Java 21 + Spring Boot 3.3.5, con las versiones administradas por el parent del `pom.xml` | ✅ resuelta |
| **006** | Sin CSRF (API stateless, sin cookies) y token en memoria, nunca en `localStorage` | ✅ resuelta |
| **007** | `prepareThreshold=0` en la URL del pooler de Supabase | ✅ resuelta |

### La que más conviene recordar

**[ADR-003] Se mantienen las tablas específicas de medición sobre un `payload`
JSONB.**

*   **Contexto:** el documento de diseño original proponía un JSONB validado en
    el backend para evitar seis tablas de evento. La base tomó el camino
    contrario y ya tiene las seis, con sus restricciones: `CHECK` de rango en
    condición corporal, lista cerrada de dentaduras, coherencia entre resultado
    de tacto y tamaño de preñez.
*   **Decisión:** se mantiene el modelo de la base. El JSONB queda disponible
    para tipos de evento nuevos que todavía no tienen forma definida.
*   **Consecuencias:** esas restricciones son las que impidieron que entraran
    datos malos durante la migración, y en JSONB no existirían. Al escribir
    desde Java siguen actuando, pero una violación llega como excepción de base,
    no como un error de validación prolijo — **hay que validar también en el
    backend para dar un mensaje entendible, sin sacar el `CHECK`**.

---

## 🔍 Apéndice: dos candados distintos

Esto costó una tarde entera de diagnóstico, así que queda escrito acá también:

| | pregunta que responde |
|---|---|
| **GRANT** | ¿este rol puede *tocar* esta tabla? |
| **RLS** | ¿qué *filas* de esa tabla puede ver? |

Son independientes. Un `GRANT` sobre una tabla con RLS activa no muestra ni
una fila de más. Cuando aparezca `permission denied for view v_...` es el
candado 1 (`mig_20_permisos.sql`). Cuando la consulta funcione pero devuelva 0
filas, es el candado 2.

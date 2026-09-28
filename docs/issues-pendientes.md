# Issues pendientes para GitHub

Lista de trabajo armada a partir de `etapas.md`, `decisiones.md`,
`modelo-datos.md`, `captura-planillas.md` y una revisión del código actual
(controllers, template del PDF, tests, CI). Cada bloque de abajo es un issue:
copiar el título y el cuerpo tal cual a GitHub, o usar el bloque `gh` al
final para cargarlos todos de una vez si en algún momento se instala y
autentica el CLI (`gh auth login`).

Fecha de este relevamiento: 2026-09-28. Los números de saneamiento (381
animales sin categoría, 1.463 sin rodeo, etc.) son los que registraba
`etapas.md` cuando se escribió — conviene verificarlos contra la base antes
de cargar esos issues, por si ya se avanzó.

---

## ✅ Ya resuelto (no va como issue, solo contexto)

- Base migrada y verificada (25 tablas, 112 RLS, 1.732 animales)
- v0.1 Seguridad: login, JWT, roles (ADR-001 cerrada)
- Padrón: alta, ficha, corrección, baja con causa, asignar categoría/rodeo
  **de a uno**, validación
- v0.2b: PDF de tacto/pesada/revisión de toros/sanidad + carga y edición de
  resultados
- CI en GitHub Actions (build + test backend y frontend)

---

## Saneamiento (v0.2a)

### 1 · Asignar categoría a los animales sin categoría
**Labels:** `saneamiento`

381 animales sin categoría asignada según `docs/etapas.md`. Verificar el
número actual contra `v_qa_sin_categoria` (tiene que dar 0 filas cuando esté
terminado) y completar la asignación desde la ficha del animal.

### 2 · Asignar rodeo a los animales sin rodeo
**Labels:** `saneamiento`

1.463 de 1.732 animales sin rodeo asignado según `docs/etapas.md`. Verificar
el número actual y completar.

### 3 · Dar de baja los animales que ya no están en el campo
**Labels:** `saneamiento`

La causa `regularizacion_inicial` ya está cargada en el catálogo
(`causa_baja`, migración `20260825120000`). Falta identificar cuántos
animales corresponden y darlos de baja con esa causa, para no inflar el KPI
de mortandad del primer año.

### 4 · Normalizar las formas de dentadura sin normalizar
**Labels:** `saneamiento`, `datos`

`docs/modelo-datos.md` lista tres formas sin normalizar: `Cuarto diente`,
`-1/4D`, `GD`. Definir el criterio de normalización y corregir.

### 5 · Confirmar la lectura de 5ta vs 4ta dentadura
**Labels:** `saneamiento`

En la hoja `Vac 5ta y 4ta 18 y 19` del Excel migrado, confirmar si la
lectura quedó bien asignada.

### 6 · Definir si `Al155` es el mismo campo que `Al154`/`PC269` o es otro
**Labels:** `saneamiento`

`Al154` ya se unificó con `PC269` (commit `75c28de`, misma sociedad). Falta
resolver si `Al155` corresponde al mismo caso o es un establecimiento
distinto.

### 7 · Fechar las revisiones de toro de 2024 y 2025 sin fecha
**Labels:** `saneamiento`

Llegaron sin fecha desde el Excel migrado.

---

## Padrón — funcionalidad faltante

### 8 · Asignar categoría/rodeo por lote
**Labels:** `feature`, `trazabilidad`

Hoy la asignación de categoría y rodeo existe solo de a uno, desde la ficha
del animal (`AnimalDetalleView`). `docs/etapas.md` pide poder marcar varios
animales y asignarles el mismo rodeo/categoría de una vez ("de a uno son
horas"). Falta selección múltiple en `AnimalesView` y el endpoint de lote en
el backend.

### 9 · Cargar los potreros
**Labels:** `feature`, `trazabilidad`

La tabla `potrero` está vacía y no hay controller, servicio ni vista para
gestionarla. `rodeo.potrero_actual_id` tampoco existe todavía (ADR-003).

---

## Planillas (v0.2b) — cerrar lo que quedó pendiente

### 10 · Generar la planilla de destete
**Labels:** `feature`, `planillas`

`PlanillaService` deja destete afuera a propósito: caravana de madre +
caravana de cría + sexo + peso en la misma fila, una forma distinta a las
otras cuatro (que listan un animal por fila). Falta diseñarla e
implementarla.

### 11 · Agregar QR de sesión al PDF impreso
**Labels:** `feature`, `planillas`

Decidido en `docs/captura-planillas.md`: un QR en el encabezado con el
identificador de sesión de trabajo (rodeo, tipo de trabajo, fecha, página),
para que la foto se auto-identifique en la futura importación. El template
actual (`planilla.html`) no lo tiene.

### 12 · Casillas para tildar en vez de espacios para escribir
**Labels:** `feature`, `planillas`

Según `docs/captura-planillas.md`: tacto `P`/`V` y `G`/`M`/`CH`, condición
corporal casilleros del 1 al 5, apto sí/no con dos casillas. Hoy
`planilla.html` es una tabla de celdas de texto libre, sin casilleros.

---

## Importación por foto (v0.3 — `docs/captura-planillas.md`)

### 13 · Crear las tablas `sesion_trabajo` y `linea_planilla`
**Labels:** `feature`, `base-de-datos`

Son las primeras tablas del proyecto con UUID (ADR-002). No existen
todavía. Sin ellas no hay circuito de importación por foto ni forma de
auditar de dónde salió cada número cargado.

### 14 · Backend: leer el QR y transcribir la planilla con nivel de confianza
**Labels:** `feature`

Depende de **#13**. La lectura vive en el backend (no en un chat manual),
llamando a una API de visión.

### 15 · Pantalla de confirmación de lo dudoso antes de escribir en la base
**Labels:** `feature`

Depende de **#14**. Nada se escribe sin que una persona confirme lo dudoso;
mostrar solo las celdas que no validaron, no la planilla entera.

---

## Seguridad

### 16 · Aplicar `@PreAuthorize` por rol en los servicios
**Labels:** `seguridad`

`@EnableMethodSecurity` está habilitado en `SecurityConfig`, pero no se usa
en ningún service todavía (confirmado: cero usos de `@PreAuthorize` /
`hasRole` en el código). Hoy cualquier usuario autenticado, sin importar el
rol, puede llamar cualquier endpoint. Definir qué acciones requieren
`GERENTE`/`PROPIETARIO` y aplicarlo.

### 17 · Setear la contraseña de Gerardo contra la base real
**Labels:** `seguridad`

La migración de alta (`20260910190500_agregar_usuario_gerardo.sql`) lo deja
sin `password_hash` a propósito, mismo patrón que el `PROPIETARIO`. Falta
generar un hash BCrypt costo 10 y cargarlo a mano contra producción para que
pueda loguearse.

---

## Calidad

### 18 · Tests de integración para trazabilidad, seguridad y planillas
**Labels:** `tests`

Hoy el único test es `HealthControllerIT`. Ningún módulo con lógica de
negocio (alta/baja/corrección de animal, login, generación de PDF, carga de
resultados) tiene test.

### 19 · Simplificar la instalación de dependencias del frontend en CI
**Labels:** `ci`

`ci.yml` corre `npm ci --no-audit --no-fund || npm install --no-audit
--no-fund` como fallback "para la primera corrida, antes de que el lock
esté commiteado". `frontend/package-lock.json` ya está en el repo: se puede
sacar el fallback y agregar `cache: npm` /
`cache-dependency-path: frontend/package-lock.json`, tal como pide el
comentario del propio workflow.

---

## ADR abierta

### 20 · Cerrar ADR-002 al crear las tablas de planillas
**Labels:** `adr`

Aplicar formalmente el criterio híbrido acordado (enteros en lo existente,
UUID en `sesion_trabajo`/`linea_planilla`, ver **#13**) y agregar
`animal.uuid_externo` si en algún momento hace falta alta offline de
animales.

---

## Fuera de esta lista, a propósito

**Etapa 2** (carga offline en el celular) y **Etapa 3** (indicadores de
preñez, destete, ADPV, mortandad) no están desglosadas en issues todavía.
`docs/etapas.md` es explícito: la Etapa 2 depende de cerrar el saneamiento,
y un indicador calculado sobre datos sin sanear "es peor que no tener
indicador, porque se le cree" — no se pueden adelantar.

---

## Para cargarlos con `gh` (si se instala y autentica el CLI)

```bash
gh issue create --title "Asignar categoría a los animales sin categoría" \
  --label "saneamiento" \
  --body "381 animales sin categoría asignada según docs/etapas.md. Verificar el número actual contra v_qa_sin_categoria (tiene que dar 0 filas) y completar la asignación desde la ficha del animal."

# ...repetir un gh issue create por cada bloque de arriba, con su título,
# sus labels y su cuerpo.
```

Antes de correrlo hace falta `gh auth login` y que existan los labels usados
(`saneamiento`, `feature`, `trazabilidad`, `planillas`, `base-de-datos`,
`seguridad`, `tests`, `ci`, `adr`, `datos`) — `gh label create <nombre>` si
no existen.

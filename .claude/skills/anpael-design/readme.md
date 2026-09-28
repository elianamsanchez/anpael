# ANPAEL · Sistema de diseño

Sistema de diseño de **Agropecuaria Anpael**, sobre el software de gestión ganadera del
establecimiento **Santa Ana**. Un backend Java (Spring Boot 3.3.5) y un frontend móvil
(Vue 3 + TypeScript + Vite + PrimeVue, PWA) para llevar el ganado en el campo: padrón de
animales, trazabilidad de eventos, planillas de trabajo imprimibles y carga de resultados.

La base ya está poblada y migrada desde planillas Excel: **1.732 animales, 1.782
identificaciones y 3.164 eventos**. El producto no está reemplazando un sistema anterior:
está reemplazando el Excel.

## Fuentes de este sistema de diseño

- **Codebase montada:** `anpael/` (monorepo: `backend/`, `frontend/`, `supabase/migrations/`, `docs/`).
  - `frontend/src/App.vue` — la paleta original del código. Se reescribió en la v3 (**"Campo abierto"**); del código quedan `--ok`, `--bad` y la estructura de grises.
  - `frontend/src/views/**/*.vue` — siete vistas con CSS propio (`<style scoped>`). De ahí salen todos los valores de espaciado, radio, tipografía y estados.
  - `frontend/src/main.ts` — PrimeVue con preset Aura, sin modo oscuro, locale es-AR.
  - `docs/decisiones.md`, `docs/etapas.md`, `docs/modelo-datos.md`, `README.md` — el tono de voz del producto.
- **Logotipo entregado por el usuario:** `assets/logo-horizontal.png` (recortado al contenido, 558×180) y el original `assets/logo-horizontal-marron.png` (806×410, con margen transparente).
- **Foto de referencia de paleta** entregada por el usuario (campo al atardecer). Sus tonos cálidos —trigo, oliva, durazno— se descartaron en la v3: la paleta pasó a verdes, gris frío y ámbar en dosis mínimas. Queda como referencia histórica en `uploads/`sto menos seco).
- **No se entregó** Figma, mazos de diapositivas ni tipografías.

## Los productos

Hay uno solo, con dos usos:

| | |
|---|---|
| **ANPAEL Campo** (PWA) | La aplicación. Se usa en una oficina y en el celular a pleno sol, a veces con guantes. Un solo modo, legible. Kit en `ui_kits/anpael-campo/`. |
| **Planillas impresas** | El entregable que más se usa: un PDF con las caravanas de un rodeo y las columnas del trabajo. Se imprime, se anota a mano en la manga, y después se cargan los resultados. El papel es parte del producto, no un fallback. |

Roles del sistema: Peón, Gestor, Gerente, Propietario.

---

# Fundamentos de contenido

**Idioma: castellano rioplatense, con voseo.** No es una decisión de tono, es cómo habla el
campo argentino. "Dejá en blanco lo que no quieras cambiar." "Elegí el rodeo y el trabajo."
"¿Ya trabajaste con la planilla impresa?" Nunca "deje", "elija", "usted".

**Segunda persona para el usuario, nunca primera persona del sistema.** El sistema no dice
"estamos guardando"; dice "Guardando…". No se presenta ni se disculpa.

**Vocabulario del oficio, sin traducir.** Caravana, rodeo, tacto, pesada, revisión de toros,
sanidad, destete, cabaña, potrero, manga, CUIG, saneamiento, baja, regularización. No se
explican en la interfaz: quien usa el sistema los conoce. Se explican en los `docs/`.

**Se dice la verdad sobre lo que falta.** El producto está a medio hacer y lo admite:
"sin categoría", "sin rodeo", "Sin eventos registrados todavía", "esta pantalla todavía no
lo resuelve", "a determinar". El dato faltante es un estado de primera clase, no un error.

**Los errores explican qué hacer, no qué pasó.**
> No responde
> ¿Está levantado el backend? `mvn spring-boot:run`
> ¿Contesta directo? `curl http://localhost:8080/api/health`
> Si contesta directo pero acá no, el proxy de `vite.config.ts` está mal apuntado.

**Advertencias donde importan, con el porqué.**
> Regularización: usar solo si no se sabe cuándo ni por qué salió el animal. Si se conoce
> la fecha real, cargar la causa real (venta, muerte, traslado) con esa fecha.

**Mayúsculas: sólo la primera letra.** "Nuevo animal", "Dar de baja", "Volver a consultar".
Las versalitas se reservan para los tipos de trabajo, que vienen así de la base:
`TACTO`, `PESADA`, `REVISION_TOROS`, `SANIDAD`, `DESTETE`.

**Botones: verbo en infinitivo o imperativo corto.** Entrar, Asignar, Generar PDF, Guardar
cambios, Registrar baja, Dar de alta, Volver a consultar. Estado en gerundio con puntos
suspensivos: "Entrando…", "Guardando…", "Generando…", "Consultando…".

**Nada de emoji.** Ni uno, en ninguna pantalla. Los `docs/` usan ✅ y ⏳ en tablas de estado
del proyecto; eso es documentación interna, no producto.

**Números en es-AR:** punto de miles, coma decimal, fechas dd/mm/aaaa. `1.732 animales`,
`412,5 kg`, `14/03/2026`.

**El vibe.** Un sistema hecho por alguien que trabaja en el campo, para gente que trabaja en
el campo. Sobrio, directo, sin entusiasmo de producto. Nada celebra. Nada convence de nada.
La pantalla más importante del proyecto es una que "no tiene valor de negocio": la de estado.

---

# Fundamentos visuales

## Color

La paleta se llama **"Campo abierto"**. Nació en `frontend/src/App.vue` y se reescribió con el
usuario: **salieron el naranja tierra (#B5651D / #964D00), el amarillo warn (#8A6100) y, en esta
versión, también el marrón cuero, el oliva y el trigo**. El campo se representa ahora en verde y
aire: monte, pasto, cielo, piedra, y ámbar en dosis mínimas. El fondo de la app es **plano
#F5F7F5**, sin degradé. Del código sobreviven `--ok`, `--bad` y los grises, reafinados a
neutros fríos para que convivan con el verde.

**Base** (`tokens/colores.css`):

| token | valor | de dónde | para qué |
|---|---|---|---|
| `--monte` | #3E6B4A | verde profundo | **acción** primaria, marca, franjas |
| `--pasto` | #5E8F44 | verde vivo | acento, acciones de creación |
| `--cielo` | #3A6E8F | azul de apoyo | enlaces, información, foco |
| `--piedra` | #7C8781 | gris frío verdoso | bordes marcados, dato faltante |
| `--ambar` | #C68A16 | cálido único | avisos y gráficos, en dosis mínimas |
| `--tinta` | #2A312B | nuevo | color del texto (antes era marrón) |
| `--n50` | #F5F7F5 | elegido por el usuario | fondo de app, plano |
| `--n200` `--n500` | #D7DDD8 #6E766F | código, reafinados | borde y texto secundario |
| `--ok` `--bad` | #3F7A44 #9A3324 | código | estados |

Más `--monte-hondo` #2F5238 para portadas, franjas e impresos.

- **La acción es verde monte.** Primario #2F5238 (`--monte-700`), que pasa contraste con texto blanco. Acento de creación: **pasto-700** #47702F — el pasto base #5E8F44 es el color de paleta, pero no llega al contraste con texto blanco, así que el relleno usa un paso más oscuro.
- **Dos verdes con trabajos distintos:** monte para la acción de siempre (guardar, entrar, confirmar); pasto para crear algo nuevo. Nunca los dos llenos en la misma pantalla.
- **El dato faltante** ("sin categoría", "sin rodeo") ya no es amarillo: va en piedra-700 #49524D. Es un dato que falta, no una alarma.
- **El aviso de atención** usa ámbar: fondo #FAEDD3, borde #EBD8A6, texto #1E231F.
- **El ámbar es el único cálido y va en manchas chicas:** avisos y gráficos. Nunca una superficie grande, nunca un fondo de pantalla.
- **Las superficies de apoyo son grises verdosos, no cálidos:** campos #F1F4F1, hundidos #EFF3EF, franjas #E9EEE9.
- **El cielo es el único frío saturado:** enlaces, texto de información y el anillo de foco. Nunca relleno de botón.
- Cada estado es un **trío** fondo/borde/texto, nunca un color suelto.

## Tipografía

**Sustitución declarada.** El código no define webfonts: usa la pila del sistema
(`-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial`). Este sistema de
diseño propone tres familias de Google Fonts, servidas por CDN desde `tokens/fuentes.css`:

| rol | familia | para qué |
|---|---|---|
| `--font-display` | **Instrument Serif** | Marca, portadas, material impreso. Nunca dentro de la app. |
| `--font-ui` | **Karla** | Toda la interfaz. Humanista, cerrada, legible a 12px. |
| `--font-mono` | **IBM Plex Mono** | Caravanas, kilos, fechas, CUIG. Toda cifra que se compara. |

**Si Agropecuaria Anpael tiene tipografías propias, hay que reemplazarlas acá.**

La escala es la real del producto: 11, 12, 12.5, 13, 13.5, 14, 15, 16, 20. No hay títulos
grandes en la app; el 40 y el 64 son sólo para marca e impresos.

## Espaciado y layout

Paso de 2px. **No hay grilla de 8**: el código usa 6, 9, 10, 14 y 18, y se respeta tal cual.

Cada vista es **una sola columna centrada** con `margin: 6vh auto` y 16px de padding lateral.
Cuatro anchos: 380 (login), 620 (lectura), 720 (formulario largo), 980 (tabla). No hay menú
lateral ni layout de dos columnas — el `App.vue` real dice que el menú entra recién en la v0.1.
Nada está fijo al viewport: ni cabecera pegajosa, ni barra inferior, ni botón flotante.

Objetivo táctil mínimo 44px (`--tap-min`) en cualquier control que se toque en la manga.

## Superficies, bordes y sombras

El fondo de la app es **plano #F5F7F5** (`--surface-app`, elegido por el usuario). No hay
degradé: el token `--fondo-degrade` quedó como alias plano del mismo valor, por compatibilidad.

Sobre ese gris, las superficies son: **blanco** (las tarjetas), **#F1F4F1** (los campos de
formulario dentro de una tarjeta), **#EFF3EF** (lo hundido: `<code>`, cápsulas), **#E9EEE9**
(las franjas de sección) y **monte hondo** #2F5238 para portadas e impresos.

**Regla de campos:** un control que vive *dentro* de una tarjeta va en #F1F4F1 (se hunde); uno
que vive *sobre el fondo de la app* — el buscador, los selects de la barra de filtros — va en
**blanco** (`<Campo sobreFondo>`, `<Buscador>`), que es lo que lo despega del gris.

**El producto no usa sombra.** Ninguna pantalla, en ningún estado. Una tarjeta es blanco +
borde 1px #D7DDD8 + radio 10px, y eso la separa del fondo gris. Hay dos tokens de sombra
(`--sombra-flotante`, `--sombra-elevada`) reservados para superficies que floten de verdad —
un menú, una hoja móvil — y nada más. Sombra en una tarjeta es un error.

Dos pesos de borde, los dos en gris frío para que la tarjeta blanca se despegue del fondo:
**1px #D7DDD8** (`--n200`) para lo que delimita (tarjetas, inputs, botón sobrio) y
**1px #E8ECE8** (`--n100`) — el filete — para separar filas de una tabla o de una ficha.

Radios: 4 (`<code>`), 6 (input embebido en un formulario desplegable), 8 (botones, inputs,
avisos), 10 (tarjetas), 50% (el punto de la marca). Nada más.

**Sin degradés, sin transparencia, sin blur, sin texturas, sin patrones repetidos.** No hay
una sola capa translúcida en el producto. Si hace falta atenuar algo, se baja la opacidad del
elemento entero (.4 / .5 en deshabilitados), no se pone un velo encima.

## Imágenes

El repositorio no tiene ninguna: `frontend/public/` está vacío. No hay fotos, ilustraciones ni
fondos. Si se agregan, que sean **fotos de campo verde** — pasto, monte, animales, cielo
abierto — sin blanco y negro y sin grano artificial. A sangre completa
cuando sean protagonistas; nunca de fondo detrás de texto. No usar degradés de protección:
si el texto no se lee sobre la foto, va afuera de la foto.

## Interacción

- **Hover:** oscurece. #2F5238 → #26432E (`--action-primary-hover`). Nunca aclara, nunca cambia de matiz, nunca escala.
- **Presionado:** oscurece un paso más, #1E3527 (`--action-primary-press`). No hay `scale` ni hundimiento.
- **Foco:** anillo cielo de 2px con 1px de separación (`outline: var(--foco-anillo); outline-offset: var(--foco-offset)`, que resuelve a `2px solid #3A6E8F`). No es una sombra difusa.
- **Deshabilitado:** opacidad .5 en botones llenos, .4 en botones sobrios, y `cursor: not-allowed`. El color no cambia y el botón nunca se oculta.
- **Enlaces:** #2A5570 (`--text-link`), semibold, sin subrayado; subrayado al hover.

## Animación

Casi nula, a propósito: la app se usa con una mano, en el campo, a veces con señal mala.
Nada rebota, nada se desliza, nada aparece con retardo. Sólo transiciones de color y opacidad.
Tres duraciones — 80ms (respuesta táctil), 140ms (hover), 220ms (algo que aparece) — con
`cubic-bezier(.2,0,.2,1)`. Todo a 0ms con `prefers-reduced-motion`.

**El feedback es texto, no movimiento.** Un botón que guarda cambia su etiqueta a "Guardando…"
y aparece un aviso verde debajo del formulario. No hay spinners, no hay skeletons, no hay
toasts flotantes: cuando algo carga, dice "Consultando…" en gris.

---

# Iconografía

**No hay iconos.** Ni uno solo en las siete vistas escritas del producto.

- El proyecto instala **PrimeIcons 7** (`primeicons/primeicons.css`, importado en `main.ts`) porque viene con PrimeVue, pero **ninguna vista lo usa todavía**. Si hacen falta iconos, ese es el set que ya está pago: `<i class="pi pi-search"></i>`, disponible por CDN en `https://unpkg.com/primeicons@7.0.0/primeicons.css`. Trazo lineal, 14px de base, hereda `color`. No mezclar con otro set.
- Lo que hoy hace de icono son **caracteres Unicode sueltos**, siempre dentro de una etiqueta de texto: `‹` y `›` en navegación y paginado, `+` en "+ Nuevo animal", `·` como separador en las bajadas, `—` para "sin dato", `…` en placeholders y estados de carga.
- **El punto de la marca** — un círculo de 12px color tierra — es el único elemento gráfico del producto. No es un logo.
- **No hay emoji** en el producto.
- **No hay SVG** en el repositorio.

Regla para quien diseñe algo nuevo: **antes de agregar un icono, probá con la palabra.**
Este producto dice "Corregir", no dibuja un lápiz.

# Marca

**Logotipo:** `assets/logo-horizontal.png` — versión horizontal, monograma circular a la
izquierda y "AGROPECUARIA / ANPAEL" a la derecha, en marrón con sombra suave. El marrón vive
sólo en el logotipo: no es un color de la paleta. Recortado al
contenido (558×180); el original con margen transparente queda en
`assets/logo-horizontal-marron.png` (806×410).

- **Va sobre fondo blanco o sobre el gris #F5F7F5.** Nunca sobre monte hondo, nunca sobre foto, nunca invertido: la sombra del PNG lo delata.
- **Altura mínima 34px**, que es a la que se usa en la cabecera de la app (`<Marca logo />`).
- **Cuando no cabe** — favicon, cabecera angosta, pantalla de detalle — se usa el punto de 12px color pasto-700 + `ANPAEL` en Karla bold 16px. Sobre monte hondo el punto pasa a pasto-300.
- En material impreso y portadas: el logotipo, o `ANPAEL` en Instrument Serif sobre monte hondo.

Falta la versión monocromática y la vertical; si existen, agregarlas a `assets/`.

---

# Índice

**Raíz**
- `styles.css` — punto de entrada; sólo `@import`. Es el único archivo que enlaza un consumidor.
- `thumbnail.html` — mosaico del sistema de diseño.
- `readme.md` — este archivo.
- `SKILL.md` — envoltorio para usar esta carpeta como Agent Skill.

**`tokens/`** — `fuentes.css` (@import de Google Fonts), `colores.css`, `tipografia.css`, `espaciado.css`, `bordes-sombras.css`, `movimiento.css`.

**`components/`** — 12 primitivas, cada una con `.jsx`, `.d.ts` y `.prompt.md`.

| grupo | componentes |
|---|---|
| `base/` | `Boton`, `Tarjeta`, `Marca`, `Etiqueta` |
| `formularios/` | `Campo`, `Check`, `Buscador` |
| `datos/` | `Tabla`, `ListaDatos`, `Paginado`, `ItemHistorial` |
| `avisos/` | `Aviso` |

El inventario sale del código: son los patrones que las siete vistas `.vue` repiten. **No se
agregaron primitivas que el producto no tiene** — no hay Modal, ni Tabs, ni Toast, ni Avatar,
ni Tooltip, ni Dropdown de menú, porque el producto no los usa.

*Agregados intencionales:* ninguno. `Etiqueta` y `ListaDatos` no existen como componentes en
el código Vue, pero sí como patrones CSS repetidos (`.falta`/`.tipo-historial` y el bloque
`<dl>` que se repite en tres vistas); se los factorizó, no se los inventó.

**`ui_kits/anpael-campo/`** — recreación click-through de las siete pantallas. Ver su `README.md`.

**`assets/`** — `logo-horizontal.png` (recortado, para usar) y `logo-horizontal-marron.png` (original).

**`guidelines/`** — 19 fichas de fundamentos (colores, tipografía, espaciado, marca) que
alimentan la pestaña Design System.

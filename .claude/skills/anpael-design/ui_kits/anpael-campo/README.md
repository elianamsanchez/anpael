# UI kit · ANPAEL Campo

Recreación click-through del frontend real (`anpael/frontend`, Vue 3 + PrimeVue Aura, PWA).
Todo lo visual sale del código de las vistas `.vue`; los datos son falsos pero tienen la
forma de las respuestas de la API (`src/api/animales.ts`, `trabajos.ts`, `planillas.ts`).

## Recorrido

`index.html` arranca en el **login**. Entrá con cualquier usuario y contraseña.

1. **Login** — `Login.jsx` · `views/seguridad/LoginView.vue`
2. **Estado del sistema** — `Estado.jsx` · `views/EstadoView.vue`. La pantalla de arranque; desde acá se va al padrón y a planillas.
3. **Padrón** — `Padron.jsx` · `views/trazabilidad/AnimalesView.vue`. Filtros vivos (buscador, "sin categoría", "sin rodeo") y paginado.
4. **Alta de animal** — `Nuevo.jsx` · `views/trazabilidad/AnimalNuevoView.vue`. Los campos de origen aparecen y desaparecen según NACIDO / COMPRADO / RECIBIDO.
5. **Detalle de animal** — `Animal.jsx` · `views/trazabilidad/AnimalDetalleView.vue`. Asignar rodeo funciona y deja un aviso verde.
6. **Planillas** — `Planillas.jsx` · `views/trazabilidad/PlanillasView.vue`. Genera una vista previa de la planilla en vez de abrir un PDF.
7. **Cargar resultados** — `Cargar.jsx` · `views/trazabilidad/CargarResultadosView.vue`. La grilla cambia de control según el trabajo elegido.

## Qué se dejó afuera a propósito

- **Menú lateral**: el `App.vue` real dice que entra recién en la v0.1. No existe todavía; no se inventó.
- **Asignación por lote** (marcar 40 animales y asignarles un rodeo): está en `docs/etapas.md` como pendiente, no hay diseño.
- **Componentes PrimeVue**: el producto los instala (`primevue@4.2`, preset Aura) pero ninguna vista escrita los usa todavía; todas las pantallas son HTML propio. El kit copia eso.
- **Modo oscuro**: descartado en `main.ts` ("un solo modo, legible").

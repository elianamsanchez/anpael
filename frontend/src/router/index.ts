import { createRouter, createWebHistory } from 'vue-router'

/**
 * Rutas.
 *
 * La carpeta views/ espeja los modulos del backend a proposito: al tocar una
 * funcionalidad se editan carpetas con el mismo nombre de los dos lados.
 *
 * Las vistas se cargan con import dinamico para que el bundle inicial no
 * crezca con pantallas que casi no se usan.
 */
const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      name: 'inicio',
      component: () => import('@/views/EstadoView.vue'),
      meta: { publico: true }
    }
    // v0.1:  /login            -> views/seguridad/LoginView.vue
    // v0.2a: /animales         -> views/trazabilidad/AnimalesView.vue
    //        /animales/:id     -> views/trazabilidad/AnimalDetalleView.vue
    // v0.2b: /planillas        -> views/trazabilidad/PlanillasView.vue
  ]
})

/**
 * Guardia de navegacion. Hoy no bloquea nada porque no hay login, pero queda
 * escrito para que agregar una ruta privada sea marcarla y nada mas.
 */
router.beforeEach((to) => {
  if (to.meta.publico) return true
  // v0.1: aca va la verificacion del store de auth
  return true
})

export default router

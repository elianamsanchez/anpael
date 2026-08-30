import { createRouter, createWebHistory } from 'vue-router'
import { useAuth } from '@/stores/auth'

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
      component: () => import('@/views/DashboardView.vue')
    },
    {
      path: '/estado',
      name: 'estado',
      component: () => import('@/views/EstadoView.vue')
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/seguridad/LoginView.vue'),
      meta: { publico: true }
    },
    {
      path: '/animales',
      name: 'animales',
      component: () => import('@/views/trazabilidad/AnimalesView.vue')
    },
    {
      path: '/animales/nuevo',
      name: 'animal-nuevo',
      component: () => import('@/views/trazabilidad/AnimalNuevoView.vue')
    },
    {
      path: '/animales/:id',
      name: 'animal-detalle',
      component: () => import('@/views/trazabilidad/AnimalDetalleView.vue')
    },
    {
      path: '/planillas',
      name: 'planillas',
      component: () => import('@/views/trazabilidad/PlanillasView.vue')
    },
    {
      path: '/planillas/cargar',
      name: 'planillas-cargar',
      component: () => import('@/views/trazabilidad/CargarResultadosView.vue')
    }
  ]
})

/**
 * Guardia de navegacion. Una ruta es privada por default: hay que marcarla
 * `meta: { publico: true }` a proposito para dejarla afuera del login.
 */
router.beforeEach((to) => {
  if (to.meta.publico) return true
  const auth = useAuth()
  if (!auth.autenticado) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }
  return true
})

export default router

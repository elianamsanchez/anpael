<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth, type Rol } from '@/stores/auth'
import { buscarAnimales } from '@/api/animales'
import Marca from '@/components/base/Marca.vue'
import Tarjeta from '@/components/base/Tarjeta.vue'
import Aviso from '@/components/avisos/Aviso.vue'

const ETIQUETA_ROL: Record<Rol, string> = {
  PROPIETARIO: 'Propietario',
  GERENTE: 'Gerente',
  GESTOR: 'Gestor',
  OPERATIVO: 'Operativo'
}

/**
 * Panel principal (v0.3, mockup): primera versión de una pantalla de
 * inicio con valor de negocio, para que propietario y gestión vean algo
 * más que el estado técnico al entrar. Fechas y gráficos son de ejemplo
 * todavía -no hay calendario de trabajos ni agregados de validación en
 * el backend-; las dos alertas de categoría/rodeo sí son reales.
 */
const router = useRouter()
const auth = useAuth()

function salir() {
  auth.salir()
  router.replace({ name: 'login' })
}

const rolEtiqueta = computed(() => auth.usuario ? ETIQUETA_ROL[auth.usuario.rol] : '')

const sinCategoria = ref<number | null>(null)
const sinRodeo = ref<number | null>(null)

onMounted(async () => {
  try {
    const [porCategoria, porRodeo] = await Promise.all([
      buscarAnimales({ sinCategoria: true, page: 0, size: 1 }),
      buscarAnimales({ sinRodeo: true, page: 0, size: 1 })
    ])
    sinCategoria.value = porCategoria.totalElements
    sinRodeo.value = porRodeo.totalElements
  } catch {
    // si falla, esas dos alertas simplemente no aparecen
  }
})

const fechasImportantes = [
  { fecha: '15/09/2026', detalle: 'Vacunación antiaftosa — Rodeo General 1 y 2' },
  { fecha: '20/09/2026', detalle: 'Revisión de toros programada' },
  { fecha: '05/10/2026', detalle: 'Inicio de servicio' },
  { fecha: '15/12/2026', detalle: 'Destete' }
]

const categorias = [
  { nombre: 'Ternero', cantidad: 420 },
  { nombre: 'Vaquillona 12M', cantidad: 310 },
  { nombre: 'Novillo', cantidad: 280 },
  { nombre: 'Vaca 3ra a 5ta', cantidad: 260 },
  { nombre: 'Toro', cantidad: 45 }
]
const maxCategoria = Math.max(...categorias.map(c => c.cantidad))

const validaciones = [
  { estado: 'Sin revisar', cantidad: 1180, clase: 'sin-revisar' },
  { estado: 'Corregir', cantidad: 340, clase: 'corregir' },
  { estado: 'Dudoso', cantidad: 150, clase: 'dudoso' },
  { estado: 'Ok', cantidad: 112, clase: 'ok' }
]
const maxValidacion = Math.max(...validaciones.map(v => v.cantidad))
</script>

<template>
  <main class="pantalla">
    <Marca bajada="Santa Ana · panel principal">
      <RouterLink class="link-nav" to="/animales">Padrón</RouterLink>
      <RouterLink class="link-nav" to="/planillas">Planillas</RouterLink>
      <RouterLink class="link-nav" to="/estado">Estado</RouterLink>
      <div class="quien" v-if="auth.usuario">
        <span class="quien-nombre">{{ auth.usuario.nombre }}</span>
        <small class="quien-rol">{{ rolEtiqueta }}</small>
      </div>
      <button class="link-nav link-nav--boton" @click="salir">Salir</button>
    </Marca>

    <div class="grilla">
      <Tarjeta titulo="Fechas importantes">
        <ul class="lista-fechas">
          <li v-for="f in fechasImportantes" :key="f.fecha">
            <span class="fecha">{{ f.fecha }}</span>
            <span class="detalle">{{ f.detalle }}</span>
          </li>
        </ul>
      </Tarjeta>

      <Tarjeta titulo="Alertas">
        <div class="lista-alertas">
          <Aviso v-if="sinCategoria" tono="atencion">
            {{ sinCategoria.toLocaleString('es-AR') }} animales sin categoría asignada.
            <RouterLink to="/animales">Ver en el padrón ›</RouterLink>
          </Aviso>
          <Aviso v-if="sinRodeo" tono="atencion">
            {{ sinRodeo.toLocaleString('es-AR') }} animales sin rodeo asignado.
            <RouterLink to="/animales">Ver en el padrón ›</RouterLink>
          </Aviso>
          <Aviso tono="atencion">6 animales con validación dudosa en el último saneamiento.</Aviso>
          <Aviso tono="info">1 baja registrada con fecha estimada.</Aviso>
        </div>
      </Tarjeta>

      <Tarjeta titulo="Animales por categoría">
        <div class="grafico">
          <div class="grafico-fila" v-for="c in categorias" :key="c.nombre">
            <span class="grafico-etiqueta">{{ c.nombre }}</span>
            <div class="grafico-barra-fondo">
              <div class="grafico-barra grafico-barra--info" :style="{ width: (c.cantidad / maxCategoria * 100) + '%' }"></div>
            </div>
            <span class="grafico-valor">{{ c.cantidad.toLocaleString('es-AR') }}</span>
          </div>
        </div>
      </Tarjeta>

      <Tarjeta titulo="Validación del saneamiento">
        <div class="grafico">
          <div class="grafico-fila" v-for="v in validaciones" :key="v.estado">
            <span class="grafico-etiqueta">{{ v.estado }}</span>
            <div class="grafico-barra-fondo">
              <div class="grafico-barra" :class="`grafico-barra--${v.clase}`" :style="{ width: (v.cantidad / maxValidacion * 100) + '%' }"></div>
            </div>
            <span class="grafico-valor">{{ v.cantidad.toLocaleString('es-AR') }}</span>
          </div>
        </div>
      </Tarjeta>
    </div>

    <p class="nota-mockup">
      Vista preliminar: las fechas y los gráficos son de ejemplo hasta conectar el calendario de
      trabajos y los agregados de validación. Las alertas de categoría y rodeo ya son reales.
    </p>
  </main>
</template>

<style scoped>
.pantalla { max-width: var(--ancho-tabla); margin: 6vh auto 4vh; padding: 0 16px; }
header.marca { margin-bottom: 18px; }
.link-nav {
  background: none; border: 1px solid var(--border-default); color: var(--text-body);
  border-radius: var(--radio-md); padding: 6px 10px; font-size: var(--fs-13); font-weight: var(--fw-semibold);
  cursor: pointer; text-decoration: none; font-family: inherit;
}
.link-nav--boton { font: inherit; }
.quien { display: flex; flex-direction: column; line-height: 1.25; }
.quien-nombre { font-size: var(--fs-13); color: var(--text-body); }
.quien-rol { font-size: var(--fs-11); color: var(--text-muted); }

.grilla {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(340px, 1fr));
  gap: 20px;
}

.lista-fechas { list-style: none; margin: 0; padding: 0; }
.lista-fechas li {
  display: flex; gap: 12px; align-items: baseline; padding: 8px 0;
  border-bottom: var(--borde-filete);
}
.lista-fechas li:last-child { border-bottom: none; }
.lista-fechas .fecha {
  font-family: var(--font-mono); font-size: var(--fs-125); color: var(--text-muted); white-space: nowrap;
}
.lista-fechas .detalle { font-size: var(--fs-135); }

.lista-alertas { display: flex; flex-direction: column; gap: 10px; }
.lista-alertas :deep(a) { color: inherit; font-weight: var(--fw-semibold); text-decoration: underline; margin-left: 4px; }

.grafico { display: flex; flex-direction: column; gap: 10px; }
.grafico-fila { display: grid; grid-template-columns: 130px 1fr 44px; align-items: center; gap: 10px; }
.grafico-etiqueta { font-size: var(--fs-13); color: var(--text-muted); }
.grafico-barra-fondo { background: var(--surface-sunken); border-radius: var(--radio-xs); height: 10px; overflow: hidden; }
.grafico-barra { height: 100%; border-radius: var(--radio-xs); }
.grafico-barra--info { background: var(--cielo-500); }
.grafico-barra--sin-revisar { background: var(--piedra-500); }
.grafico-barra--corregir { background: var(--bad); }
.grafico-barra--dudoso { background: var(--ambar-500); }
.grafico-barra--ok { background: var(--ok); }
.grafico-valor {
  font-family: var(--font-mono); font-variant-numeric: tabular-nums; font-size: var(--fs-13);
  text-align: right; color: var(--text-muted);
}

.nota-mockup { margin: 24px 0 0; font-size: var(--fs-125); color: var(--text-muted); }
</style>

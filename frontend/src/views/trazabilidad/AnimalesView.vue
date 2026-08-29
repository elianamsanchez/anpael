<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { buscarAnimales, listarRodeos, listarCategorias, type Animal, type Rodeo, type Categoria } from '@/api/animales'
import type { ErrorApi } from '@/api/client'
import Marca from '@/components/base/Marca.vue'
import Tarjeta from '@/components/base/Tarjeta.vue'
import Buscador from '@/components/formularios/Buscador.vue'
import Check from '@/components/formularios/Check.vue'
import Campo from '@/components/formularios/Campo.vue'
import Etiqueta from '@/components/base/Etiqueta.vue'
import Tabla from '@/components/datos/Tabla.vue'
import Paginado from '@/components/datos/Paginado.vue'

/**
 * v0.2a · saneamiento (docs/etapas.md): buscar un animal por caravana y ver
 * quien todavia no tiene categoria o rodeo asignado. Asignar y dar de baja
 * son pantallas propias, todavia no escritas.
 */
const caravana = ref('')
const sinCategoria = ref(false)
const sinRodeo = ref(false)
const idRodeoElegido = ref<number | null>(null)
const idCategoriaElegida = ref<number | null>(null)
const pagina = ref(0)
const tamanioPagina = 30

const rodeos = ref<Rodeo[]>([])
const categorias = ref<Categoria[]>([])
const cargando = ref(true)
const animales = ref<Animal[]>([])
const totalElementos = ref(0)
const totalPaginas = ref(0)
const error = ref<ErrorApi | null>(null)

async function buscar() {
  cargando.value = true
  error.value = null
  try {
    const resultado = await buscarAnimales({
      caravana: caravana.value || undefined,
      sinCategoria: sinCategoria.value || undefined,
      sinRodeo: sinRodeo.value || undefined,
      idRodeo: idRodeoElegido.value ?? undefined,
      idCategoria: idCategoriaElegida.value ?? undefined,
      page: pagina.value,
      size: tamanioPagina
    })
    animales.value = resultado.content
    totalElementos.value = resultado.totalElements
    totalPaginas.value = resultado.totalPages
  } catch (e) {
    error.value = e as ErrorApi
    animales.value = []
  } finally {
    cargando.value = false
  }
}

// "sin rodeo/categoria" y "un rodeo/categoria puntual" se pisan entre si: elegir uno limpia el otro.
watch(idRodeoElegido, (valor) => { if (valor !== null) sinRodeo.value = false })
watch(sinRodeo, (valor) => { if (valor) idRodeoElegido.value = null })
watch(idCategoriaElegida, (valor) => { if (valor !== null) sinCategoria.value = false })
watch(sinCategoria, (valor) => { if (valor) idCategoriaElegida.value = null })

let debounce: ReturnType<typeof setTimeout>
watch(caravana, () => {
  clearTimeout(debounce)
  debounce = setTimeout(() => { pagina.value = 0; buscar() }, 350)
})
watch([sinCategoria, sinRodeo, idRodeoElegido, idCategoriaElegida], () => { pagina.value = 0; buscar() })
watch(pagina, buscar)

onMounted(() => {
  buscar()
  listarRodeos().then(r => { rodeos.value = r })
  listarCategorias().then(c => { categorias.value = c })
})

const columnas = [
  { clave: 'caravana', titulo: 'Caravana' },
  { clave: 'sexo', titulo: 'Sexo' },
  { clave: 'raza', titulo: 'Raza' },
  { clave: 'categoria', titulo: 'Categoría' },
  { clave: 'rodeo', titulo: 'Rodeo' },
  { clave: 'validacion', titulo: 'Validación' }
]

const opcionesRodeo = computed(() => [
  { valor: null, etiqueta: 'Todos los rodeos' },
  ...rodeos.value.map(r => ({ valor: r.idRodeo, etiqueta: r.nombre }))
])
const opcionesCategoria = computed(() => [
  { valor: null, etiqueta: 'Todas las categorías' },
  ...categorias.value.map(c => ({ valor: c.idCategoria, etiqueta: c.nombre }))
])
</script>

<template>
  <main class="pantalla">
    <RouterLink to="/" class="volver">‹ Inicio</RouterLink>

    <Marca bajada="Santa Ana · saneamiento del padrón" class="marca-animales">
      <RouterLink to="/animales/nuevo" class="link-nuevo">+ Nuevo animal</RouterLink>
    </Marca>

    <section class="filtros">
      <Buscador v-model:valor="caravana" placeholder="Buscar por caravana…" />
      <Check etiqueta="Sin categoría" v-model:marcado="sinCategoria" />
      <Check etiqueta="Sin rodeo" v-model:marcado="sinRodeo" />
      <Campo
        class="campo-filtro"
        sobre-fondo
        :opciones="opcionesRodeo"
        :valor="idRodeoElegido"
        @update:valor="idRodeoElegido = $event === '' ? null : Number($event)"
      />
      <Campo
        class="campo-filtro"
        sobre-fondo
        :opciones="opcionesCategoria"
        :valor="idCategoriaElegida"
        @update:valor="idCategoriaElegida = $event === '' ? null : Number($event)"
      />
      <span class="total" v-if="!cargando">{{ totalElementos.toLocaleString('es-AR') }} animales</span>
    </section>

    <Tarjeta denso>
      <p v-if="cargando" class="atenuado">Consultando…</p>

      <template v-else-if="error">
        <h2 class="etiqueta-mal">No responde</h2>
        <p><b>{{ error.mensaje }}</b></p>
      </template>

      <template v-else-if="animales.length === 0">
        <p class="atenuado">No hay animales que coincidan con la búsqueda.</p>
      </template>

      <Tabla v-else :columnas="columnas" :filas="animales">
        <template #celda-caravana="{ fila }">
          <RouterLink class="link-caravana" :to="`/animales/${fila.idAnimal}`">{{ fila.caravana ?? '(sin identificación)' }}</RouterLink>
        </template>
        <template #celda-raza="{ fila }">{{ fila.raza ?? '—' }}</template>
        <template #celda-categoria="{ fila }">
          <Etiqueta v-if="fila.sinCategoria" tono="falta">sin categoría</Etiqueta>
          <span v-else>{{ fila.categoria }}</span>
        </template>
        <template #celda-rodeo="{ fila }">
          <Etiqueta v-if="!fila.rodeo" tono="falta">sin rodeo</Etiqueta>
          <span v-else>{{ fila.rodeo }}</span>
        </template>
      </Tabla>

      <Paginado :pagina="pagina" :total-paginas="totalPaginas" @cambio="pagina = $event" />
    </Tarjeta>
  </main>
</template>

<style scoped>
.pantalla { max-width: var(--ancho-tabla); margin: 6vh auto; padding: 0 16px; }
.volver { display: inline-block; margin-bottom: 14px; color: var(--text-muted); font-size: var(--fs-13); text-decoration: none; }
.volver:hover { text-decoration: underline; }
header.marca-animales { margin-bottom: 18px; }
.link-nuevo {
  margin-left: auto; background: var(--action-primary); color: #fff; text-decoration: none;
  border-radius: var(--radio-md); padding: 8px 14px; font-size: var(--fs-13); font-weight: var(--fw-semibold);
}
.link-nuevo:hover { background: var(--action-primary-hover); }

.filtros { display: flex; align-items: center; gap: 16px; margin-bottom: 12px; flex-wrap: wrap; }
label.campo-filtro { flex: 0 0 auto; min-width: 0; }
.total { margin-left: auto; font-size: var(--fs-13); color: var(--text-muted); }

.atenuado { color: var(--text-muted); }
.etiqueta-mal { color: var(--bad); }
.link-caravana { color: var(--text-link); font-weight: var(--fw-semibold); text-decoration: none; }
.link-caravana:hover { text-decoration: underline; }
</style>

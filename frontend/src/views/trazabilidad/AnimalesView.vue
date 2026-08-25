<script setup lang="ts">
import { ref, watch, onMounted } from 'vue'
import { buscarAnimales, type Animal } from '@/api/animales'
import type { ErrorApi } from '@/api/client'

/**
 * v0.2a · saneamiento (docs/etapas.md): buscar un animal por caravana y ver
 * quien todavia no tiene categoria o rodeo asignado. Asignar y dar de baja
 * son pantallas propias, todavia no escritas.
 */
const caravana = ref('')
const sinCategoria = ref(false)
const sinRodeo = ref(false)
const pagina = ref(0)
const tamanioPagina = 30

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

let debounce: ReturnType<typeof setTimeout>
watch(caravana, () => {
  clearTimeout(debounce)
  debounce = setTimeout(() => { pagina.value = 0; buscar() }, 350)
})
watch([sinCategoria, sinRodeo], () => { pagina.value = 0; buscar() })
watch(pagina, buscar)

onMounted(buscar)
</script>

<template>
  <main class="pantalla">
    <header class="marca">
      <span class="punto"></span>
      <div>
        ANPAEL
        <small>Santa Ana · saneamiento del padrón</small>
      </div>
    </header>

    <section class="filtros">
      <input v-model="caravana" type="search" placeholder="Buscar por caravana…" class="buscador" />
      <label class="check">
        <input v-model="sinCategoria" type="checkbox" /> Sin categoría
      </label>
      <label class="check">
        <input v-model="sinRodeo" type="checkbox" /> Sin rodeo
      </label>
      <span class="total" v-if="!cargando">{{ totalElementos.toLocaleString('es-AR') }} animales</span>
    </section>

    <section class="tarjeta">
      <p v-if="cargando" class="atenuado">Consultando…</p>

      <template v-else-if="error">
        <h2 class="mal">No responde</h2>
        <p><b>{{ error.mensaje }}</b></p>
      </template>

      <template v-else-if="animales.length === 0">
        <p class="atenuado">No hay animales que coincidan con la búsqueda.</p>
      </template>

      <table v-else class="tabla">
        <thead>
          <tr>
            <th>Caravana</th>
            <th>Sexo</th>
            <th>Raza</th>
            <th>Categoría</th>
            <th>Rodeo</th>
            <th>Validación</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="a in animales" :key="a.idAnimal">
            <td>
              <RouterLink :to="`/animales/${a.idAnimal}`">{{ a.caravana ?? '(sin identificación)' }}</RouterLink>
            </td>
            <td>{{ a.sexo }}</td>
            <td>{{ a.raza ?? '—' }}</td>
            <td><span v-if="a.sinCategoria" class="falta">sin categoría</span><span v-else>{{ a.categoria }}</span></td>
            <td><span v-if="!a.rodeo" class="falta">sin rodeo</span><span v-else>{{ a.rodeo }}</span></td>
            <td>{{ a.validacion }}</td>
          </tr>
        </tbody>
      </table>

      <nav class="paginado" v-if="totalPaginas > 1">
        <button class="boton-chico" :disabled="pagina === 0" @click="pagina--">‹ Anterior</button>
        <span class="atenuado">página {{ pagina + 1 }} de {{ totalPaginas }}</span>
        <button class="boton-chico" :disabled="pagina >= totalPaginas - 1" @click="pagina++">Siguiente ›</button>
      </nav>
    </section>
  </main>
</template>

<style scoped>
.pantalla { max-width: 980px; margin: 6vh auto; padding: 0 16px; }
.marca { display: flex; gap: 10px; align-items: center; font-weight: 700; margin-bottom: 18px; }
.marca small { display: block; font-weight: 400; font-size: 12px; color: var(--n500); }
.punto { width: 12px; height: 12px; border-radius: 50%; background: var(--tierra); }

.filtros { display: flex; align-items: center; gap: 16px; margin-bottom: 12px; flex-wrap: wrap; }
.buscador {
  font: inherit; padding: 9px 12px; border-radius: 8px; border: 1px solid var(--n200);
  background: #fff; min-width: 240px;
}
.check { display: flex; align-items: center; gap: 6px; font-size: 13.5px; color: var(--n500); cursor: pointer; }
.total { margin-left: auto; font-size: 13px; color: var(--n500); }

.tarjeta { background: #fff; border: 1px solid var(--n200); border-radius: 10px; padding: 16px 20px; }
.atenuado { color: var(--n500); }
.mal { color: var(--bad); }

.tabla { width: 100%; border-collapse: collapse; font-size: 14px; }
.tabla th { text-align: left; font-size: 12px; color: var(--n500); font-weight: 600; padding: 8px 10px; border-bottom: 1px solid var(--n200); }
.tabla td { padding: 8px 10px; border-bottom: 1px solid #EBE5DC; }
.tabla a { color: var(--tierra-txt); font-weight: 600; text-decoration: none; }
.tabla a:hover { text-decoration: underline; }
.falta { color: var(--warn); font-size: 12.5px; }

.paginado { display: flex; align-items: center; justify-content: center; gap: 16px; margin-top: 16px; }
.boton-chico {
  background: none; border: 1px solid var(--n200); color: var(--cuero);
  border-radius: 8px; padding: 6px 12px; font-size: 13px; font-weight: 600; cursor: pointer;
}
.boton-chico:disabled { opacity: .4; cursor: not-allowed; }
</style>

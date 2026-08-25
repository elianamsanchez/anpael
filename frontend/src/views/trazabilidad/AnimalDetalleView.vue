<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import {
  getAnimal, listarCategorias, listarRodeos, asignarCategoria, asignarRodeo,
  type Animal, type Categoria, type Rodeo
} from '@/api/animales'
import type { ErrorApi } from '@/api/client'

const route = useRoute()
const idAnimal = Number(route.params.id)

const cargando = ref(true)
const animal = ref<Animal | null>(null)
const error = ref<ErrorApi | null>(null)

const categorias = ref<Categoria[]>([])
const rodeos = ref<Rodeo[]>([])

const idCategoriaElegida = ref<number | null>(null)
const guardandoCategoria = ref(false)
const mensajeCategoria = ref<string | null>(null)
const errorCategoria = ref<ErrorApi | null>(null)

const idRodeoElegido = ref<number | null>(null)
const guardandoRodeo = ref(false)
const mensajeRodeo = ref<string | null>(null)
const errorRodeo = ref<ErrorApi | null>(null)

async function cargar() {
  cargando.value = true
  error.value = null
  try {
    const [animalCargado, categoriasCargadas, rodeosCargados] = await Promise.all([
      getAnimal(idAnimal),
      listarCategorias(),
      listarRodeos()
    ])
    animal.value = animalCargado
    categorias.value = categoriasCargadas
    rodeos.value = rodeosCargados
  } catch (e) {
    error.value = e as ErrorApi
    animal.value = null
  } finally {
    cargando.value = false
  }
}

async function guardarCategoria() {
  if (!idCategoriaElegida.value) return
  guardandoCategoria.value = true
  mensajeCategoria.value = null
  errorCategoria.value = null
  try {
    const resultado = await asignarCategoria(idAnimal, idCategoriaElegida.value)
    animal.value = resultado.animal
    mensajeCategoria.value = resultado.mensaje
  } catch (e) {
    errorCategoria.value = e as ErrorApi
  } finally {
    guardandoCategoria.value = false
  }
}

async function guardarRodeo() {
  if (!idRodeoElegido.value) return
  guardandoRodeo.value = true
  mensajeRodeo.value = null
  errorRodeo.value = null
  try {
    const resultado = await asignarRodeo(idAnimal, idRodeoElegido.value)
    animal.value = resultado.animal
    mensajeRodeo.value = resultado.mensaje
  } catch (e) {
    errorRodeo.value = e as ErrorApi
  } finally {
    guardandoRodeo.value = false
  }
}

onMounted(cargar)
</script>

<template>
  <main class="pantalla">
    <RouterLink to="/animales" class="volver">‹ Volver al padrón</RouterLink>

    <p v-if="cargando" class="atenuado">Consultando…</p>

    <template v-else-if="error">
      <section class="tarjeta">
        <h2 class="mal">No responde</h2>
        <p><b>{{ error.mensaje }}</b></p>
      </section>
    </template>

    <template v-else-if="animal">
      <header class="marca">
        <span class="punto"></span>
        <div>
          {{ animal.caravana ?? `Animal #${animal.idAnimal}` }}
          <small>{{ animal.tipoIdent }} · {{ animal.sexo === 'M' ? 'macho' : 'hembra' }}</small>
        </div>
      </header>

      <section class="tarjeta">
        <dl>
          <div><dt>Raza</dt><dd>{{ animal.raza ?? '—' }}</dd></div>
          <div>
            <dt>Categoría</dt>
            <dd><span v-if="animal.sinCategoria" class="falta">sin asignar</span><span v-else>{{ animal.categoria }}</span></dd>
          </div>
          <div>
            <dt>Rodeo</dt>
            <dd>
              <span v-if="!animal.rodeo" class="falta">sin asignar</span>
              <span v-else>{{ animal.rodeo }} <span class="atenuado">(desde {{ animal.enRodeoDesde }})</span></span>
            </dd>
          </div>

          <div class="asignar">
            <form class="form-asignar" @submit.prevent="guardarCategoria">
              <select v-model.number="idCategoriaElegida">
                <option :value="null" disabled>Asignar categoría…</option>
                <option v-for="c in categorias" :key="c.idCategoria" :value="c.idCategoria">{{ c.nombre }}</option>
              </select>
              <button class="boton-chico" type="submit" :disabled="!idCategoriaElegida || guardandoCategoria">
                {{ guardandoCategoria ? 'Guardando…' : 'Asignar' }}
              </button>
            </form>
            <p v-if="mensajeCategoria" class="aviso-ok">{{ mensajeCategoria }}</p>
            <p v-if="errorCategoria" class="aviso-error">{{ errorCategoria.mensaje }}</p>
          </div>

          <div class="asignar">
            <form class="form-asignar" @submit.prevent="guardarRodeo">
              <select v-model.number="idRodeoElegido">
                <option :value="null" disabled>Asignar rodeo…</option>
                <option v-for="r in rodeos" :key="r.idRodeo" :value="r.idRodeo">{{ r.nombre }}</option>
              </select>
              <button class="boton-chico" type="submit" :disabled="!idRodeoElegido || guardandoRodeo">
                {{ guardandoRodeo ? 'Guardando…' : 'Asignar' }}
              </button>
            </form>
            <p v-if="mensajeRodeo" class="aviso-ok">{{ mensajeRodeo }}</p>
            <p v-if="errorRodeo" class="aviso-error">{{ errorRodeo.mensaje }}</p>
          </div>
          <div><dt>Fecha de nacimiento</dt>
            <dd>
              {{ animal.fechaNacimiento ?? 'sin registrar' }}
              <span v-if="animal.fechaNacEsEstimada" class="atenuado">(estimada)</span>
            </dd>
          </div>
          <div><dt>Identificación desde</dt><dd>{{ animal.fechaIdent ?? '—' }}</dd></div>
          <div><dt>Establecimiento (CUIG)</dt><dd>{{ animal.cuig ?? '—' }}</dd></div>
          <div><dt>Estado</dt>
            <dd>
              <span :class="animal.activo ? 'bien' : 'mal'">{{ animal.activo ? 'activo' : 'inactivo' }}</span>
              <span v-if="animal.tieneBaja" class="atenuado"> · tiene registro de baja</span>
            </dd>
          </div>
          <div><dt>Eventos registrados</dt><dd>{{ animal.eventos }}</dd></div>
          <div><dt>Validación del saneamiento</dt>
            <dd>
              {{ animal.validacion }}
              <span v-if="animal.revisadoPor" class="atenuado"> · por {{ animal.revisadoPor }}</span>
            </dd>
          </div>
          <div v-if="animal.validacionObs"><dt>Observaciones</dt><dd>{{ animal.validacionObs }}</dd></div>
        </dl>
      </section>
    </template>
  </main>
</template>

<style scoped>
.pantalla { max-width: 620px; margin: 6vh auto; padding: 0 16px; }
.volver { display: inline-block; margin-bottom: 14px; color: var(--n500); font-size: 13px; text-decoration: none; }
.volver:hover { text-decoration: underline; }
.marca { display: flex; gap: 10px; align-items: center; font-weight: 700; margin-bottom: 18px; }
.marca small { display: block; font-weight: 400; font-size: 12px; color: var(--n500); }
.punto { width: 12px; height: 12px; border-radius: 50%; background: var(--tierra); }
.tarjeta { background: #fff; border: 1px solid var(--n200); border-radius: 10px; padding: 20px; }
.atenuado { color: var(--n500); }
.mal { color: var(--bad); }
.bien { color: var(--ok); }
.falta { color: var(--warn); font-size: 12.5px; }
dl { margin: 0; }
dl > div { display: flex; justify-content: space-between; gap: 16px; padding: 8px 0; border-bottom: 1px solid #EBE5DC; }
dt { color: var(--n500); font-size: 13px; flex-shrink: 0; }
dd { margin: 0; font-weight: 600; text-align: right; }

.asignar { display: block; padding: 10px 0; }
.form-asignar { display: flex; gap: 8px; }
.form-asignar select {
  flex: 1; font: inherit; font-size: 13.5px; padding: 8px 10px; border-radius: 8px;
  border: 1px solid var(--n200); background: var(--n50); color: var(--cuero);
}
.boton-chico {
  background: none; border: 1px solid var(--n200); color: var(--cuero);
  border-radius: 8px; padding: 6px 12px; font-size: 13px; font-weight: 600; cursor: pointer;
}
.boton-chico:disabled { opacity: .4; cursor: not-allowed; }
.aviso-ok {
  background: #EAF3EA; border: 1px solid #BFDDBF; color: var(--ok);
  border-radius: 8px; padding: 8px 10px; font-size: 13px; margin: 8px 0 0;
}
.aviso-error {
  background: #FBEAE6; border: 1px solid #E8B3A6; color: var(--bad);
  border-radius: 8px; padding: 8px 10px; font-size: 13px; margin: 8px 0 0;
}
</style>

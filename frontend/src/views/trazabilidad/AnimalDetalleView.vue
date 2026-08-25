<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import {
  getAnimal, listarCategorias, listarRodeos, asignarCategoria, asignarRodeo,
  listarCausasBaja, darDeBaja, listarRazas, listarPelajes, corregirAnimal, historialAnimal,
  type Animal, type Categoria, type Rodeo, type CausaBaja, type Raza, type Pelaje, type AnimalEvento
} from '@/api/animales'
import {
  corregirTacto, corregirPesada, corregirRevisionToros, corregirSanidad
} from '@/api/trabajos'
import type { ErrorApi } from '@/api/client'

const TIPOS_EDITABLES = ['TACTO', 'PESADA', 'REVISION_TOROS', 'SANIDAD']

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

const causasBaja = ref<CausaBaja[]>([])
const idCausaBajaElegida = ref<number | null>(null)
const destinoBaja = ref('')
const observacionesBaja = ref('')
const guardandoBaja = ref(false)
const mensajeBaja = ref<string | null>(null)
const errorBaja = ref<ErrorApi | null>(null)

const razas = ref<Raza[]>([])
const pelajes = ref<Pelaje[]>([])
const idRazaElegida = ref<number | null>(null)
const idPelajeElegido = ref<number | null>(null)
const fechaNacimientoCorregida = ref('')
const fechaEsEstimada = ref(false)
const pesoNacerCorregido = ref('')
const guardandoCorreccion = ref(false)
const mensajeCorreccion = ref<string | null>(null)
const errorCorreccion = ref<ErrorApi | null>(null)

const historial = ref<AnimalEvento[]>([])

interface EdicionEvento {
  abierto: boolean
  guardando: boolean
  mensaje: string | null
  error: ErrorApi | null
  resultado: string
  tamano: string
  observaciones: string
  kilos: string
  circunferenciaEscrotal: string
  condicionCorporal: string
  apto: string
  producto: string
  dosis: string
}
const edicion = ref<Record<number, EdicionEvento>>({})

function estadoEdicion(idEvento: number): EdicionEvento {
  if (!edicion.value[idEvento]) {
    edicion.value[idEvento] = {
      abierto: false, guardando: false, mensaje: null, error: null,
      resultado: '', tamano: '', observaciones: '',
      kilos: '', circunferenciaEscrotal: '', condicionCorporal: '', apto: '',
      producto: '', dosis: ''
    }
  }
  return edicion.value[idEvento]
}

function alternarEdicion(idEvento: number) {
  estadoEdicion(idEvento).abierto = !estadoEdicion(idEvento).abierto
}

async function guardarCorreccionEvento(ev: AnimalEvento) {
  const e = estadoEdicion(ev.idEvento)
  e.guardando = true
  e.mensaje = null
  e.error = null
  try {
    let resultado
    if (ev.tipoTrabajo === 'TACTO') {
      resultado = await corregirTacto(ev.idEvento, {
        resultado: e.resultado || undefined,
        tamano: e.tamano || undefined,
        observaciones: e.observaciones || undefined
      })
    } else if (ev.tipoTrabajo === 'PESADA') {
      resultado = await corregirPesada(ev.idEvento, { kilos: e.kilos ? Number(e.kilos) : undefined })
    } else if (ev.tipoTrabajo === 'REVISION_TOROS') {
      resultado = await corregirRevisionToros(ev.idEvento, {
        circunferenciaEscrotal: e.circunferenciaEscrotal ? Number(e.circunferenciaEscrotal) : undefined,
        condicionCorporal: e.condicionCorporal ? Number(e.condicionCorporal) : undefined,
        apto: e.apto ? e.apto === 'si' : undefined
      })
    } else if (ev.tipoTrabajo === 'SANIDAD') {
      resultado = await corregirSanidad(ev.idEvento, {
        producto: e.producto || undefined,
        dosis: e.dosis ? Number(e.dosis) : undefined
      })
    } else {
      return
    }
    const idx = historial.value.findIndex(h => h.idEvento === ev.idEvento)
    if (idx !== -1) historial.value[idx] = resultado.evento
    e.mensaje = resultado.mensaje
  } catch (err) {
    e.error = err as ErrorApi
  } finally {
    e.guardando = false
  }
}

async function cargar() {
  cargando.value = true
  error.value = null
  try {
    const [animalCargado, categoriasCargadas, rodeosCargados, causasCargadas, razasCargadas, pelajesCargados,
      historialCargado] = await Promise.all([
      getAnimal(idAnimal),
      listarCategorias(),
      listarRodeos(),
      listarCausasBaja(),
      listarRazas(),
      listarPelajes(),
      historialAnimal(idAnimal)
    ])
    animal.value = animalCargado
    categorias.value = categoriasCargadas
    rodeos.value = rodeosCargados
    causasBaja.value = causasCargadas
    razas.value = razasCargadas
    pelajes.value = pelajesCargados
    historial.value = historialCargado
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

async function guardarBaja() {
  if (!idCausaBajaElegida.value) return
  guardandoBaja.value = true
  mensajeBaja.value = null
  errorBaja.value = null
  try {
    const resultado = await darDeBaja(idAnimal, {
      idCausaBaja: idCausaBajaElegida.value,
      destino: destinoBaja.value || undefined,
      observaciones: observacionesBaja.value || undefined
    })
    animal.value = resultado.animal
    mensajeBaja.value = resultado.mensaje
  } catch (e) {
    errorBaja.value = e as ErrorApi
  } finally {
    guardandoBaja.value = false
  }
}

async function guardarCorreccion() {
  const cambios = {
    idRaza: idRazaElegida.value ?? undefined,
    idPelaje: idPelajeElegido.value ?? undefined,
    fechaNacimiento: fechaNacimientoCorregida.value || undefined,
    fechaNacEsEstimada: fechaNacimientoCorregida.value ? fechaEsEstimada.value : undefined,
    pesoNacerKg: pesoNacerCorregido.value ? Number(pesoNacerCorregido.value) : undefined
  }
  if (Object.values(cambios).every(v => v === undefined)) return

  guardandoCorreccion.value = true
  mensajeCorreccion.value = null
  errorCorreccion.value = null
  try {
    animal.value = await corregirAnimal(idAnimal, cambios)
    mensajeCorreccion.value = 'Datos actualizados.'
    idRazaElegida.value = null
    idPelajeElegido.value = null
    fechaNacimientoCorregida.value = ''
    fechaEsEstimada.value = false
    pesoNacerCorregido.value = ''
  } catch (e) {
    errorCorreccion.value = e as ErrorApi
  } finally {
    guardandoCorreccion.value = false
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

      <section class="tarjeta historial">
        <h3>Historial de trabajos</h3>
        <p v-if="historial.length === 0" class="atenuado">Sin eventos registrados todavía.</p>
        <ul v-else class="lista-historial">
          <li v-for="ev in historial" :key="ev.idEvento">
            <div class="fila-historial">
              <span class="fecha-historial">{{ ev.fecha }}</span>
              <span class="tipo-historial">{{ ev.tipoTrabajo }}</span>
            </div>
            <p v-if="ev.detalle" class="detalle-historial">{{ ev.detalle }}</p>
            <p v-if="ev.comentario" class="detalle-historial atenuado">"{{ ev.comentario }}"</p>

            <button v-if="TIPOS_EDITABLES.includes(ev.tipoTrabajo)" class="link-corregir"
                    type="button" @click="alternarEdicion(ev.idEvento)">
              {{ estadoEdicion(ev.idEvento).abierto ? 'Cancelar' : 'Corregir' }}
            </button>

            <form v-if="estadoEdicion(ev.idEvento).abierto" class="form-correccion-evento"
                  @submit.prevent="guardarCorreccionEvento(ev)">
              <p class="atenuado chico">Dejá en blanco lo que no quieras cambiar.</p>

              <template v-if="ev.tipoTrabajo === 'TACTO'">
                <select v-model="estadoEdicion(ev.idEvento).resultado">
                  <option value="">Resultado (sin cambios)</option>
                  <option value="PRENADA">Preñada</option>
                  <option value="VACIA">Vacía</option>
                  <option value="DUDOSA">Dudosa</option>
                </select>
                <select v-model="estadoEdicion(ev.idEvento).tamano">
                  <option value="">Tamaño (sin cambios)</option>
                  <option value="CHICA">Chica</option>
                  <option value="MEDIANA">Mediana</option>
                  <option value="GRANDE">Grande</option>
                </select>
                <input v-model="estadoEdicion(ev.idEvento).observaciones" type="text" placeholder="Observaciones" />
              </template>

              <template v-else-if="ev.tipoTrabajo === 'PESADA'">
                <input v-model="estadoEdicion(ev.idEvento).kilos" type="number" min="15" max="1400" step="0.1" placeholder="Kilos" />
              </template>

              <template v-else-if="ev.tipoTrabajo === 'REVISION_TOROS'">
                <input v-model="estadoEdicion(ev.idEvento).circunferenciaEscrotal" type="number" min="24" max="50" step="0.1" placeholder="Circunf. escrotal" />
                <input v-model="estadoEdicion(ev.idEvento).condicionCorporal" type="number" min="1" max="5" step="0.5" placeholder="Cond. corporal" />
                <select v-model="estadoEdicion(ev.idEvento).apto">
                  <option value="">Apto (sin cambios)</option>
                  <option value="si">Sí</option>
                  <option value="no">No</option>
                </select>
              </template>

              <template v-else-if="ev.tipoTrabajo === 'SANIDAD'">
                <input v-model="estadoEdicion(ev.idEvento).producto" type="text" placeholder="Producto" />
                <input v-model="estadoEdicion(ev.idEvento).dosis" type="number" min="0" step="0.01" placeholder="Dosis" />
              </template>

              <button class="boton-chico" type="submit" :disabled="estadoEdicion(ev.idEvento).guardando">
                {{ estadoEdicion(ev.idEvento).guardando ? 'Guardando…' : 'Guardar corrección' }}
              </button>
              <p v-if="estadoEdicion(ev.idEvento).mensaje" class="aviso-ok">{{ estadoEdicion(ev.idEvento).mensaje }}</p>
              <p v-if="estadoEdicion(ev.idEvento).error" class="aviso-error">{{ estadoEdicion(ev.idEvento).error!.mensaje }}</p>
            </form>
          </li>
        </ul>
      </section>

      <section class="tarjeta correccion">
        <h3>Corregir / completar datos</h3>
        <p class="atenuado chico">Dejá en blanco lo que no quieras cambiar.</p>

        <form class="form-correccion" @submit.prevent="guardarCorreccion">
          <label class="campo-chico">
            <span>Raza</span>
            <select v-model.number="idRazaElegida">
              <option :value="null">(sin cambios)</option>
              <option v-for="r in razas" :key="r.idRaza" :value="r.idRaza">{{ r.nombre }}</option>
            </select>
          </label>
          <label class="campo-chico">
            <span>Pelaje</span>
            <select v-model.number="idPelajeElegido">
              <option :value="null">(sin cambios)</option>
              <option v-for="p in pelajes" :key="p.idPelaje" :value="p.idPelaje">{{ p.nombre }}</option>
            </select>
          </label>
          <label class="campo-chico">
            <span>Fecha de nacimiento</span>
            <input v-model="fechaNacimientoCorregida" type="date" />
          </label>
          <label class="check" v-if="fechaNacimientoCorregida">
            <input v-model="fechaEsEstimada" type="checkbox" /> Es estimada
          </label>
          <label class="campo-chico">
            <span>Peso al nacer (kg)</span>
            <input v-model="pesoNacerCorregido" type="number" min="10" max="70" step="0.1" placeholder="10 a 70" />
          </label>
          <button class="boton-chico" type="submit" :disabled="guardandoCorreccion">
            {{ guardandoCorreccion ? 'Guardando…' : 'Guardar cambios' }}
          </button>
        </form>
        <p v-if="mensajeCorreccion" class="aviso-ok">{{ mensajeCorreccion }}</p>
        <p v-if="errorCorreccion" class="aviso-error">{{ errorCorreccion.mensaje }} <span v-if="errorCorreccion.detalle">— {{ errorCorreccion.detalle }}</span></p>
      </section>

      <section class="tarjeta baja">
        <h3>Dar de baja</h3>

        <p v-if="animal.tieneBaja" class="atenuado">
          Este animal ya tiene una baja registrada. No se puede cargar otra.
        </p>

        <form v-else class="form-baja" @submit.prevent="guardarBaja">
          <select v-model.number="idCausaBajaElegida">
            <option :value="null" disabled>Causa…</option>
            <option v-for="c in causasBaja" :key="c.idCausaBaja" :value="c.idCausaBaja">
              {{ c.tipoBaja }} · {{ c.descripcion }}
            </option>
          </select>
          <input v-model="destinoBaja" type="text" placeholder="Destino (opcional)" />
          <textarea v-model="observacionesBaja" placeholder="Observaciones (opcional)" rows="2"></textarea>
          <button class="boton-chico" type="submit" :disabled="!idCausaBajaElegida || guardandoBaja">
            {{ guardandoBaja ? 'Guardando…' : 'Registrar baja' }}
          </button>
        </form>
        <p v-if="mensajeBaja" class="aviso-ok">{{ mensajeBaja }}</p>
        <p v-if="errorBaja" class="aviso-error">{{ errorBaja.mensaje }}</p>
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

.historial { margin-top: 16px; }
.historial h3 { margin: 0 0 12px; font-size: 15px; }
.lista-historial { list-style: none; margin: 0; padding: 0; }
.lista-historial li { padding: 10px 0; border-bottom: 1px solid #EBE5DC; }
.lista-historial li:last-child { border-bottom: none; }
.fila-historial { display: flex; justify-content: space-between; align-items: baseline; gap: 10px; }
.fecha-historial { font-size: 12.5px; color: var(--n500); white-space: nowrap; }
.tipo-historial { font-size: 11px; font-weight: 700; letter-spacing: .02em; color: var(--tierra-txt); text-transform: uppercase; }
.detalle-historial { margin: 4px 0 0; font-size: 13.5px; }
.link-corregir {
  background: none; border: none; color: var(--tierra-txt); font-size: 12px; font-weight: 600;
  cursor: pointer; padding: 6px 0 0; text-decoration: underline;
}
.form-correccion-evento { display: flex; flex-direction: column; gap: 8px; margin-top: 8px; }
.form-correccion-evento select, .form-correccion-evento input {
  font: inherit; font-size: 13px; padding: 6px 8px; border-radius: 6px;
  border: 1px solid var(--n200); background: var(--n50); color: var(--cuero);
}
.form-correccion-evento .boton-chico { align-self: flex-start; }

.correccion { margin-top: 16px; }
.correccion h3 { margin: 0 0 4px; font-size: 15px; }
.chico { font-size: 12.5px; margin: 0 0 12px; }
.form-correccion { display: flex; flex-direction: column; gap: 10px; }
.campo-chico { display: flex; flex-direction: column; gap: 4px; font-size: 13px; color: var(--n500); }
.campo-chico select, .campo-chico input {
  font: inherit; font-size: 13.5px; padding: 8px 10px; border-radius: 8px;
  border: 1px solid var(--n200); background: var(--n50); color: var(--cuero);
}
.form-correccion .check { display: flex; align-items: center; gap: 6px; font-size: 13px; color: var(--n500); }
.form-correccion .boton-chico { align-self: flex-start; }

.baja { margin-top: 16px; }
.baja h3 { margin: 0 0 12px; font-size: 15px; }
.form-baja { display: flex; flex-direction: column; gap: 8px; }
.form-baja select, .form-baja input, .form-baja textarea {
  font: inherit; font-size: 13.5px; padding: 8px 10px; border-radius: 8px;
  border: 1px solid var(--n200); background: var(--n50); color: var(--cuero); resize: vertical;
}
.form-baja .boton-chico { align-self: flex-start; }
</style>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
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
import Marca from '@/components/base/Marca.vue'
import Tarjeta from '@/components/base/Tarjeta.vue'
import Boton from '@/components/base/Boton.vue'
import Etiqueta from '@/components/base/Etiqueta.vue'
import Campo from '@/components/formularios/Campo.vue'
import Check from '@/components/formularios/Check.vue'
import Aviso from '@/components/avisos/Aviso.vue'
import ItemHistorial from '@/components/datos/ItemHistorial.vue'

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
const fechaBaja = ref('')
const fechaEsEstimadaBaja = ref(false)
const destinoBaja = ref('')
const observacionesBaja = ref('')
const guardandoBaja = ref(false)
const mensajeBaja = ref<string | null>(null)
const errorBaja = ref<ErrorApi | null>(null)

const causaBajaElegida = computed(() => causasBaja.value.find(c => c.idCausaBaja === idCausaBajaElegida.value))
const esRegularizacion = computed(() => causaBajaElegida.value?.tipoBaja === 'REGULARIZACION')

const causasBajaOrdenadas = computed(() =>
  [...causasBaja.value].sort((a, b) =>
    a.tipoBaja.localeCompare(b.tipoBaja) || a.descripcion.localeCompare(b.descripcion)
  )
)

// REGULARIZACION es "no sabemos ni cuando ni por que" (docs/modelo-datos.md):
// la fecha que se carga es la del saneamiento, no la real, así que por
// default es estimada. Para las demas causas se sabe la fecha real.
watch(idCausaBajaElegida, () => { fechaEsEstimadaBaja.value = esRegularizacion.value })

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
      fecha: fechaBaja.value || undefined,
      fechaEsEstimada: fechaEsEstimadaBaja.value,
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
    <nav class="migas">
      <RouterLink to="/" class="volver">‹ Inicio</RouterLink>
      <span class="atenuado">·</span>
      <RouterLink to="/animales" class="volver">Volver al padrón</RouterLink>
    </nav>

    <p v-if="cargando" class="atenuado">Consultando…</p>

    <template v-else-if="error">
      <Tarjeta>
        <h2 class="etiqueta-mal">No responde</h2>
        <p><b>{{ error.mensaje }}</b></p>
      </Tarjeta>
    </template>

    <template v-else-if="animal">
      <Marca
        class="marca-animal"
        :titulo="animal.caravana ?? `Animal #${animal.idAnimal}`"
        :bajada="`${animal.tipoIdent} · ${animal.sexo === 'M' ? 'macho' : 'hembra'}`"
      />

      <Tarjeta>
        <dl class="lista-info">
          <div><dt>Raza</dt><dd>{{ animal.raza ?? '—' }}</dd></div>
          <div>
            <dt>Categoría</dt>
            <dd><Etiqueta v-if="animal.sinCategoria" tono="falta">sin asignar</Etiqueta><span v-else>{{ animal.categoria }}</span></dd>
          </div>
          <div>
            <dt>Rodeo</dt>
            <dd>
              <Etiqueta v-if="!animal.rodeo" tono="falta">sin asignar</Etiqueta>
              <span v-else>{{ animal.rodeo }} <span class="atenuado">(desde {{ animal.enRodeoDesde }})</span></span>
            </dd>
          </div>

          <div class="asignar">
            <form class="form-asignar" @submit.prevent="guardarCategoria">
              <Campo
                class="campo-asignar"
                :opciones="[{ valor: null, etiqueta: 'Asignar categoría…' }, ...categorias.map(c => ({ valor: c.idCategoria, etiqueta: c.nombre }))]"
                :valor="idCategoriaElegida"
                @update:valor="idCategoriaElegida = $event === '' ? null : Number($event)"
              />
              <Boton variante="sobrio" tamano="sm" tipo="submit" :deshabilitado="!idCategoriaElegida || guardandoCategoria">
                {{ guardandoCategoria ? 'Guardando…' : 'Asignar' }}
              </Boton>
            </form>
            <Aviso v-if="mensajeCategoria" tono="ok" class="aviso-fila">{{ mensajeCategoria }}</Aviso>
            <Aviso v-if="errorCategoria" tono="error" class="aviso-fila">{{ errorCategoria.mensaje }}</Aviso>
          </div>

          <div class="asignar">
            <form class="form-asignar" @submit.prevent="guardarRodeo">
              <Campo
                class="campo-asignar"
                :opciones="[{ valor: null, etiqueta: 'Asignar rodeo…' }, ...rodeos.map(r => ({ valor: r.idRodeo, etiqueta: r.nombre }))]"
                :valor="idRodeoElegido"
                @update:valor="idRodeoElegido = $event === '' ? null : Number($event)"
              />
              <Boton variante="sobrio" tamano="sm" tipo="submit" :deshabilitado="!idRodeoElegido || guardandoRodeo">
                {{ guardandoRodeo ? 'Guardando…' : 'Asignar' }}
              </Boton>
            </form>
            <Aviso v-if="mensajeRodeo" tono="ok" class="aviso-fila">{{ mensajeRodeo }}</Aviso>
            <Aviso v-if="errorRodeo" tono="error" class="aviso-fila">{{ errorRodeo.mensaje }}</Aviso>
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
              <Etiqueta :tono="animal.activo ? 'ok' : 'mal'">{{ animal.activo ? 'activo' : 'inactivo' }}</Etiqueta>
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
      </Tarjeta>

      <Tarjeta titulo="Historial de trabajos" class="tarjeta-espaciada">
        <p v-if="historial.length === 0" class="atenuado">Sin eventos registrados todavía.</p>
        <ul v-else class="lista-historial">
          <ItemHistorial
            v-for="(ev, i) in historial"
            :key="ev.idEvento"
            :fecha="ev.fecha"
            :tipo="ev.tipoTrabajo"
            :detalle="ev.detalle"
            :comentario="ev.comentario"
            :ultimo="i === historial.length - 1"
          >
            <Boton
              v-if="TIPOS_EDITABLES.includes(ev.tipoTrabajo)"
              variante="texto" tamano="sm" tipo="button" class="link-corregir"
              @click="alternarEdicion(ev.idEvento)"
            >
              {{ estadoEdicion(ev.idEvento).abierto ? 'Cancelar' : 'Corregir' }}
            </Boton>

            <form v-if="estadoEdicion(ev.idEvento).abierto" class="form-correccion-evento"
                  @submit.prevent="guardarCorreccionEvento(ev)">
              <p class="atenuado chico">Dejá en blanco lo que no quieras cambiar.</p>

              <template v-if="ev.tipoTrabajo === 'TACTO'">
                <select class="select-chico" v-model="estadoEdicion(ev.idEvento).resultado">
                  <option value="">Resultado (sin cambios)</option>
                  <option value="PRENADA">Preñada</option>
                  <option value="VACIA">Vacía</option>
                  <option value="DUDOSA">Dudosa</option>
                </select>
                <select class="select-chico" v-model="estadoEdicion(ev.idEvento).tamano">
                  <option value="">Tamaño (sin cambios)</option>
                  <option value="CHICA">Chica</option>
                  <option value="MEDIANA">Mediana</option>
                  <option value="GRANDE">Grande</option>
                </select>
                <input class="select-chico" v-model="estadoEdicion(ev.idEvento).observaciones" type="text" placeholder="Observaciones" />
              </template>

              <template v-else-if="ev.tipoTrabajo === 'PESADA'">
                <input class="select-chico" v-model="estadoEdicion(ev.idEvento).kilos" type="number" min="15" max="1400" step="0.1" placeholder="Kilos" />
              </template>

              <template v-else-if="ev.tipoTrabajo === 'REVISION_TOROS'">
                <input class="select-chico" v-model="estadoEdicion(ev.idEvento).circunferenciaEscrotal" type="number" min="24" max="50" step="0.1" placeholder="Circunf. escrotal" />
                <input class="select-chico" v-model="estadoEdicion(ev.idEvento).condicionCorporal" type="number" min="1" max="5" step="0.5" placeholder="Cond. corporal" />
                <select class="select-chico" v-model="estadoEdicion(ev.idEvento).apto">
                  <option value="">Apto (sin cambios)</option>
                  <option value="si">Sí</option>
                  <option value="no">No</option>
                </select>
              </template>

              <template v-else-if="ev.tipoTrabajo === 'SANIDAD'">
                <input class="select-chico" v-model="estadoEdicion(ev.idEvento).producto" type="text" placeholder="Producto" />
                <input class="select-chico" v-model="estadoEdicion(ev.idEvento).dosis" type="number" min="0" step="0.01" placeholder="Dosis" />
              </template>

              <Boton variante="sobrio" tamano="sm" class="boton-fila" tipo="submit" :deshabilitado="estadoEdicion(ev.idEvento).guardando">
                {{ estadoEdicion(ev.idEvento).guardando ? 'Guardando…' : 'Guardar corrección' }}
              </Boton>
              <Aviso v-if="estadoEdicion(ev.idEvento).mensaje" tono="ok" class="aviso-fila">{{ estadoEdicion(ev.idEvento).mensaje }}</Aviso>
              <Aviso v-if="estadoEdicion(ev.idEvento).error" tono="error" class="aviso-fila">{{ estadoEdicion(ev.idEvento).error!.mensaje }}</Aviso>
            </form>
          </ItemHistorial>
        </ul>
      </Tarjeta>

      <Tarjeta titulo="Corregir / completar datos" nota="Dejá en blanco lo que no quieras cambiar." class="tarjeta-espaciada">
        <form class="form-correccion" @submit.prevent="guardarCorreccion">
          <Campo
            etiqueta="Raza"
            :opciones="[{ valor: null, etiqueta: '(sin cambios)' }, ...razas.map(r => ({ valor: r.idRaza, etiqueta: r.nombre }))]"
            :valor="idRazaElegida"
            @update:valor="idRazaElegida = $event === '' ? null : Number($event)"
          />
          <Campo
            etiqueta="Pelaje"
            :opciones="[{ valor: null, etiqueta: '(sin cambios)' }, ...pelajes.map(p => ({ valor: p.idPelaje, etiqueta: p.nombre }))]"
            :valor="idPelajeElegido"
            @update:valor="idPelajeElegido = $event === '' ? null : Number($event)"
          />
          <Campo etiqueta="Fecha de nacimiento" tipo="date" v-model:valor="fechaNacimientoCorregida" />
          <Check v-if="fechaNacimientoCorregida" etiqueta="Es estimada" v-model:marcado="fechaEsEstimada" />
          <Campo etiqueta="Peso al nacer (kg)" tipo="number" min="10" max="70" step="0.1" placeholder="10 a 70" v-model:valor="pesoNacerCorregido" />
          <Boton variante="sobrio" tamano="sm" class="boton-fila" tipo="submit" :deshabilitado="guardandoCorreccion">
            {{ guardandoCorreccion ? 'Guardando…' : 'Guardar cambios' }}
          </Boton>
        </form>
        <Aviso v-if="mensajeCorreccion" tono="ok" class="aviso-fila">{{ mensajeCorreccion }}</Aviso>
        <Aviso v-if="errorCorreccion" tono="error" class="aviso-fila">{{ errorCorreccion.mensaje }} <span v-if="errorCorreccion.detalle">— {{ errorCorreccion.detalle }}</span></Aviso>
      </Tarjeta>

      <Tarjeta titulo="Dar de baja" class="tarjeta-espaciada">
        <p v-if="animal.tieneBaja" class="atenuado">
          Este animal ya tiene una baja registrada. No se puede cargar otra.
        </p>

        <form v-else class="form-baja" @submit.prevent="guardarBaja">
          <Campo
            :opciones="[{ valor: null, etiqueta: 'Causa…' }, ...causasBajaOrdenadas.map(c => ({ valor: c.idCausaBaja, etiqueta: `${c.tipoBaja} · ${c.descripcion}` }))]"
            :valor="idCausaBajaElegida"
            @update:valor="idCausaBajaElegida = $event === '' ? null : Number($event)"
          />
          <p v-if="esRegularizacion" class="atenuado chico">
            Regularización: usar solo si no se sabe cuándo ni por qué salió el animal.
            Si se conoce la fecha real, cargar la causa real (venta, muerte, traslado) con esa fecha.
          </p>
          <Campo etiqueta="Fecha de baja" tipo="date" v-model:valor="fechaBaja" />
          <p v-if="!fechaBaja" class="atenuado chico">Si la dejás en blanco, se registra como hoy.</p>
          <Check
            etiqueta="La fecha es estimada"
            v-model:marcado="fechaEsEstimadaBaja"
          />
          <Campo placeholder="Destino (opcional)" v-model:valor="destinoBaja" />
          <Campo tipo="textarea" :filas="2" placeholder="Observaciones (opcional)" v-model:valor="observacionesBaja" />
          <Boton variante="sobrio" tamano="sm" class="boton-fila" tipo="submit" :deshabilitado="!idCausaBajaElegida || guardandoBaja">
            {{ guardandoBaja ? 'Guardando…' : 'Registrar baja' }}
          </Boton>
        </form>
        <Aviso v-if="mensajeBaja" tono="ok" class="aviso-fila">{{ mensajeBaja }}</Aviso>
        <Aviso v-if="errorBaja" tono="error" class="aviso-fila">{{ errorBaja.mensaje }}</Aviso>
      </Tarjeta>
    </template>
  </main>
</template>

<style scoped>
.pantalla { max-width: var(--ancho-lectura); margin: 6vh auto; padding: 0 16px; }
.migas { display: flex; align-items: center; gap: 8px; margin-bottom: 14px; }
.volver { color: var(--text-muted); font-size: var(--fs-13); text-decoration: none; }
.volver:hover { text-decoration: underline; }
header.marca-animal { margin-bottom: 18px; }
.atenuado { color: var(--text-muted); }
.etiqueta-mal { color: var(--bad); }
section.tarjeta-espaciada { margin-top: 16px; }

.lista-info { margin: 0; }
.lista-info > div { display: flex; justify-content: space-between; gap: 16px; padding: 8px 0; border-bottom: var(--borde-filete); }
.lista-info dt { color: var(--text-muted); font-size: var(--fs-13); flex-shrink: 0; }
.lista-info dd { margin: 0; font-weight: var(--fw-semibold); text-align: right; }

.asignar { display: block; padding: 10px 0; }
.form-asignar { display: flex; gap: 8px; align-items: flex-end; }
label.campo-asignar { flex: 1; min-width: 0; }
p.aviso-fila { margin: 8px 0 0; }

.lista-historial { list-style: none; margin: 0; padding: 0; }
button.link-corregir { padding-top: 6px; }
.form-correccion-evento { display: flex; flex-direction: column; gap: 8px; margin-top: 8px; }
.select-chico {
  font: inherit; font-family: var(--font-ui); font-size: var(--fs-13); padding: 6px 8px; border-radius: var(--radio-sm);
  border: var(--borde-fino); background: var(--surface-field); color: var(--text-body);
}
button.boton-fila { align-self: flex-start; }

.chico { font-size: var(--fs-125); margin: 0 0 12px; }
.form-correccion { display: flex; flex-direction: column; gap: 10px; }
.form-baja { display: flex; flex-direction: column; gap: 8px; }
</style>

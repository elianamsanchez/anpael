<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import {
  getAnimal, listarCategorias, listarRodeos, asignarCategoria, asignarRodeo,
  listarCausasBaja, darDeBaja, listarRazas, listarPelajes, corregirAnimal, historialAnimal,
  marcarValidacion, listarEstablecimientos, asignarEstablecimiento, identificacionesAnimal,
  type Animal, type Categoria, type Rodeo, type CausaBaja, type Raza, type Pelaje, type AnimalEvento,
  type MarcarValidacionParams, type Establecimiento, type Identificacion
} from '@/api/animales'
import {
  corregirTacto, corregirPesada, corregirRevisionToros, corregirSanidad,
  cargarTacto, cargarPesada, cargarRevisionToros, cargarSanidad
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
const TIPOS_TRABAJO = [
  { valor: 'TACTO', etiqueta: 'Tacto' },
  { valor: 'PESADA', etiqueta: 'Pesada' },
  { valor: 'REVISION_TOROS', etiqueta: 'Revisión de toros' },
  { valor: 'SANIDAD', etiqueta: 'Sanidad' }
]
// Catálogo de dentadura (CHECK de medicion_corporal, docs/modelo-datos.md).
const OPCIONES_DENTADURA = ['2D', '3D', '4D', '6D', 'BLL', '3/4D', 'MD+', 'MD', 'MD-', '1/4D', '-1/4D', 'SD/CUT']

const route = useRoute()
const idAnimal = Number(route.params.id)

const cargando = ref(true)
const animal = ref<Animal | null>(null)
const error = ref<ErrorApi | null>(null)

const categorias = ref<Categoria[]>([])
const rodeos = ref<Rodeo[]>([])

const idCategoriaElegida = ref<number | null>(null)
const fechaEsEstimadaCategoria = ref(false)
const guardandoCategoria = ref(false)
const mensajeCategoria = ref<string | null>(null)
const errorCategoria = ref<ErrorApi | null>(null)

const idRodeoElegido = ref<number | null>(null)
const fechaEsEstimadaRodeo = ref(false)
const guardandoRodeo = ref(false)
const mensajeRodeo = ref<string | null>(null)
const errorRodeo = ref<ErrorApi | null>(null)

const establecimientos = ref<Establecimiento[]>([])
const idEstablecimientoElegido = ref<number | null>(null)
const guardandoEstablecimiento = ref(false)
const mensajeEstablecimiento = ref<string | null>(null)
const errorEstablecimiento = ref<ErrorApi | null>(null)

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
const anioNacimientoCorregido = ref('')
const anioIngresoCorregido = ref('')
const anioPrimerServicioCorregido = ref('')
const pesoNacerCorregido = ref('')
const padreNombreCorregido = ref('')
const observacionesCorregido = ref('')

// La fecha completa manda: si se carga, el año se completa solo (backend
// AnimalCorreccionService), así que el campo manual no aplica.
watch(fechaNacimientoCorregida, (valor) => { if (valor) anioNacimientoCorregido.value = '' })
const guardandoCorreccion = ref(false)
const mensajeCorreccion = ref<string | null>(null)
const errorCorreccion = ref<ErrorApi | null>(null)

const ESTADOS_VALIDACION: MarcarValidacionParams['estado'][] = ['VALIDADO', 'CORREGIR', 'DUDOSO']

const estadoValidacionElegido = ref<MarcarValidacionParams['estado'] | null>(null)
const observacionValidacion = ref('')
const guardandoValidacion = ref(false)
const mensajeValidacion = ref<string | null>(null)
const errorValidacion = ref<ErrorApi | null>(null)

const historial = ref<AnimalEvento[]>([])
const identificaciones = ref<Identificacion[]>([])

const ETIQUETA_TIPO_TRABAJO: Record<string, string> = {
  TACTO: 'Tacto', PESADA: 'Pesada', REVISION_TOROS: 'Revisión de toros',
  SANIDAD: 'Sanidad', IDENTIFICACION: 'Identificación'
}
const ORDEN_TIPOS_FILTRO = ['TACTO', 'REVISION_TOROS', 'PESADA', 'SANIDAD', 'IDENTIFICACION']

const filtroTipoHistorial = ref<string | null>(null)

// Los chips solo muestran tipos que realmente aparecen en el historial de
// este animal -no tiene sentido ofrecer "Sanidad" si nunca tuvo una.
const tiposEnHistorial = computed(() => {
  const presentes = new Set(historial.value.map(ev => ev.tipoTrabajo))
  const ordenados = ORDEN_TIPOS_FILTRO.filter(t => presentes.has(t))
  const otros = [...presentes].filter(t => !ORDEN_TIPOS_FILTRO.includes(t))
  return [...ordenados, ...otros]
})

const historialFiltrado = computed(() =>
  filtroTipoHistorial.value
    ? historial.value.filter(ev => ev.tipoTrabajo === filtroTipoHistorial.value)
    : historial.value
)

// El historial ya viene ordenado por fecha descendente (findByIdAnimalOrderByFechaDesc):
// agrupar por año contiguo alcanza, no hace falta reordenar.
const historialAgrupado = computed(() => {
  const grupos: { anio: string; items: AnimalEvento[] }[] = []
  for (const ev of historialFiltrado.value) {
    const anio = ev.fecha.slice(0, 4)
    const actual = grupos[grupos.length - 1]
    if (actual?.anio === anio) {
      actual.items.push(ev)
    } else {
      grupos.push({ anio, items: [ev] })
    }
  }
  return grupos
})

interface NuevoTrabajo {
  tipo: string
  fecha: string
  resultado: string
  tamano: string
  observaciones: string
  kilos: string
  circunferenciaEscrotal: string
  condicionCorporal: string
  dentadura: string
  apto: string
  producto: string
  dosis: string
}
function trabajoVacio(): NuevoTrabajo {
  return {
    tipo: '', fecha: '', resultado: '', tamano: '', observaciones: '',
    kilos: '', circunferenciaEscrotal: '', condicionCorporal: '', dentadura: '', apto: '',
    producto: '', dosis: ''
  }
}
const nuevoTrabajo = ref<NuevoTrabajo>(trabajoVacio())
const guardandoTrabajo = ref(false)
const mensajeTrabajo = ref<string | null>(null)
const errorTrabajo = ref<ErrorApi | null>(null)

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
  dentadura: string
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
      kilos: '', circunferenciaEscrotal: '', condicionCorporal: '', dentadura: '', apto: '',
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
        dentadura: e.dentadura || undefined,
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

async function guardarTrabajoNuevo() {
  if (!animal.value?.idRodeo || !nuevoTrabajo.value.tipo) return
  const idRodeo = animal.value.idRodeo
  const t = nuevoTrabajo.value
  const fecha = t.fecha || undefined

  guardandoTrabajo.value = true
  mensajeTrabajo.value = null
  errorTrabajo.value = null
  try {
    let resultado
    if (t.tipo === 'TACTO') {
      resultado = await cargarTacto(idRodeo, [{
        idAnimal, resultado: t.resultado, tamano: t.tamano || undefined, observaciones: t.observaciones || undefined
      }], fecha)
    } else if (t.tipo === 'PESADA') {
      resultado = await cargarPesada(idRodeo, [{ idAnimal, kilos: Number(t.kilos) }], fecha)
    } else if (t.tipo === 'REVISION_TOROS') {
      resultado = await cargarRevisionToros(idRodeo, [{
        idAnimal,
        circunferenciaEscrotal: t.circunferenciaEscrotal ? Number(t.circunferenciaEscrotal) : undefined,
        condicionCorporal: t.condicionCorporal ? Number(t.condicionCorporal) : undefined,
        dentadura: t.dentadura || undefined,
        apto: t.apto === 'si'
      }], fecha)
    } else if (t.tipo === 'SANIDAD') {
      resultado = await cargarSanidad(idRodeo, [{
        idAnimal, producto: t.producto, dosis: t.dosis ? Number(t.dosis) : undefined
      }], fecha)
    } else {
      return
    }
    mensajeTrabajo.value = resultado.mensaje
    historial.value = await historialAnimal(idAnimal)
    nuevoTrabajo.value = trabajoVacio()
  } catch (e) {
    errorTrabajo.value = e as ErrorApi
  } finally {
    guardandoTrabajo.value = false
  }
}

async function cargar() {
  cargando.value = true
  error.value = null
  try {
    const [animalCargado, categoriasCargadas, rodeosCargados, causasCargadas, razasCargadas, pelajesCargados,
      historialCargado, establecimientosCargados, identificacionesCargadas] = await Promise.all([
      getAnimal(idAnimal),
      listarCategorias(),
      listarRodeos(),
      listarCausasBaja(),
      listarRazas(),
      listarPelajes(),
      historialAnimal(idAnimal),
      listarEstablecimientos(true),
      identificacionesAnimal(idAnimal)
    ])
    animal.value = animalCargado
    categorias.value = categoriasCargadas
    rodeos.value = rodeosCargados
    causasBaja.value = causasCargadas
    razas.value = razasCargadas
    pelajes.value = pelajesCargados
    historial.value = historialCargado
    establecimientos.value = establecimientosCargados
    identificaciones.value = identificacionesCargadas
    if (ESTADOS_VALIDACION.includes(animalCargado.validacion as MarcarValidacionParams['estado'])) {
      estadoValidacionElegido.value = animalCargado.validacion as MarcarValidacionParams['estado']
    }
    observacionValidacion.value = animalCargado.validacionObs ?? ''
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
    const resultado = await asignarCategoria(idAnimal, idCategoriaElegida.value, fechaEsEstimadaCategoria.value)
    animal.value = resultado.animal
    mensajeCategoria.value = resultado.mensaje
    fechaEsEstimadaCategoria.value = false
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
    const resultado = await asignarRodeo(idAnimal, idRodeoElegido.value, fechaEsEstimadaRodeo.value)
    animal.value = resultado.animal
    mensajeRodeo.value = resultado.mensaje
    fechaEsEstimadaRodeo.value = false
  } catch (e) {
    errorRodeo.value = e as ErrorApi
  } finally {
    guardandoRodeo.value = false
  }
}

async function guardarEstablecimiento() {
  if (!idEstablecimientoElegido.value) return
  guardandoEstablecimiento.value = true
  mensajeEstablecimiento.value = null
  errorEstablecimiento.value = null
  try {
    const resultado = await asignarEstablecimiento(idAnimal, idEstablecimientoElegido.value)
    animal.value = resultado.animal
    mensajeEstablecimiento.value = resultado.mensaje
  } catch (e) {
    errorEstablecimiento.value = e as ErrorApi
  } finally {
    guardandoEstablecimiento.value = false
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

async function guardarValidacion() {
  if (!estadoValidacionElegido.value) return
  guardandoValidacion.value = true
  mensajeValidacion.value = null
  errorValidacion.value = null
  try {
    const resultado = await marcarValidacion(idAnimal, {
      estado: estadoValidacionElegido.value,
      observacion: observacionValidacion.value || undefined
    })
    animal.value = resultado.animal
    mensajeValidacion.value = resultado.mensaje
  } catch (e) {
    errorValidacion.value = e as ErrorApi
  } finally {
    guardandoValidacion.value = false
  }
}

async function guardarCorreccion() {
  const cambios = {
    idRaza: idRazaElegida.value ?? undefined,
    idPelaje: idPelajeElegido.value ?? undefined,
    fechaNacimiento: fechaNacimientoCorregida.value || undefined,
    fechaNacEsEstimada: fechaNacimientoCorregida.value ? fechaEsEstimada.value : undefined,
    anioNacimiento: anioNacimientoCorregido.value ? Number(anioNacimientoCorregido.value) : undefined,
    anioIngreso: anioIngresoCorregido.value ? Number(anioIngresoCorregido.value) : undefined,
    anioPrimerServicio: anioPrimerServicioCorregido.value ? Number(anioPrimerServicioCorregido.value) : undefined,
    pesoNacerKg: pesoNacerCorregido.value ? Number(pesoNacerCorregido.value) : undefined,
    padreNombre: padreNombreCorregido.value || undefined,
    observaciones: observacionesCorregido.value || undefined
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
    anioNacimientoCorregido.value = ''
    anioIngresoCorregido.value = ''
    anioPrimerServicioCorregido.value = ''
    pesoNacerCorregido.value = ''
    padreNombreCorregido.value = ''
    observacionesCorregido.value = ''
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
          <div v-if="identificaciones.length">
            <dt>Identificación</dt>
            <dd>
              <div v-for="ident in identificaciones" :key="ident.tipoIdent">
                {{ ident.tipoIdent }}: {{ ident.caravana }}
              </div>
            </dd>
          </div>
          <div><dt>Raza</dt><dd>{{ animal.raza ?? '—' }}</dd></div>
          <div><dt>Color</dt><dd>{{ animal.pelaje ?? '—' }}</dd></div>
          <div>
            <dt>Categoría</dt>
            <dd>
              <Etiqueta v-if="animal.sinCategoria" tono="falta">sin asignar</Etiqueta>
              <span v-else>
                {{ animal.categoria }}
                <span v-if="animal.categoriaDesde" class="atenuado">
                  (desde {{ animal.categoriaDesde }}<template v-if="animal.categoriaDesdeEsEstimada">, estimada</template>)
                </span>
              </span>
            </dd>
          </div>
          <div>
            <dt>Rodeo</dt>
            <dd>
              <Etiqueta v-if="!animal.rodeo" tono="falta">sin asignar</Etiqueta>
              <span v-else>
                {{ animal.rodeo }}
                <span class="atenuado">
                  (desde {{ animal.enRodeoDesde }}<template v-if="animal.enRodeoDesdeEsEstimada">, fecha de la migración</template>)
                </span>
              </span>
            </dd>
          </div>
          <div><dt>Fecha de nacimiento</dt>
            <dd>
              {{ animal.fechaNacimiento ?? 'sin registrar' }}
              <span v-if="animal.fechaNacEsEstimada" class="atenuado">(estimada)</span>
            </dd>
          </div>
          <div><dt>Año de nacimiento</dt><dd>{{ animal.anioNacimiento ?? '—' }}</dd></div>
          <div v-if="animal.pesoNacerKg"><dt>Peso al nacer</dt><dd>{{ animal.pesoNacerKg }} kg</dd></div>
          <div v-if="animal.sexo === 'M' && (animal.padreCaravana || animal.padreNombre)">
            <dt>Padre</dt>
            <dd>
              <RouterLink v-if="animal.padreCaravana" :to="`/animales/${animal.idPadre}`">{{ animal.padreCaravana }}</RouterLink>
              <span v-else>{{ animal.padreNombre }}</span>
            </dd>
          </div>
          <div><dt>Identificación desde</dt><dd>{{ animal.fechaIdent ?? '—' }}</dd></div>
          <div><dt>Año de ingreso</dt><dd>{{ animal.anioIngreso ?? '—' }}</dd></div>
          <div v-if="animal.sexo === 'M'"><dt>Año de primer servicio</dt><dd>{{ animal.anioPrimerServicio ?? '—' }}</dd></div>
          <div><dt>Establecimiento</dt>
            <dd>
              <Etiqueta v-if="!animal.cuig" tono="falta">sin asignar</Etiqueta>
              <span v-else>{{ animal.establecimiento }} <span class="atenuado">({{ animal.cuig }})</span></span>
            </dd>
          </div>
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
          <div v-if="animal.observaciones"><dt>Notas</dt><dd>{{ animal.observaciones }}</dd></div>
        </dl>
      </Tarjeta>

      <Tarjeta titulo="Agregar trabajo" class="tarjeta-espaciada">
        <p v-if="!animal.idRodeo" class="atenuado chico">
          Este animal no tiene rodeo asignado -asignale uno primero en "Categoría, rodeo y establecimiento" para poder cargarle un trabajo.
        </p>

        <form v-else class="form-trabajo" @submit.prevent="guardarTrabajoNuevo">
          <Campo
            etiqueta="Tipo de trabajo"
            :opciones="[{ valor: null, etiqueta: 'Elegir…' }, ...TIPOS_TRABAJO.map(t => ({ valor: t.valor, etiqueta: t.etiqueta }))]"
            :valor="nuevoTrabajo.tipo"
            @update:valor="nuevoTrabajo.tipo = $event"
          />
          <Campo etiqueta="Fecha" tipo="date" placeholder="Si se deja en blanco, hoy" v-model:valor="nuevoTrabajo.fecha" />

          <template v-if="nuevoTrabajo.tipo === 'TACTO'">
            <Campo
              etiqueta="Resultado"
              :opciones="[{ valor: '', etiqueta: 'Elegir…' }, { valor: 'PRENADA', etiqueta: 'Preñada' }, { valor: 'VACIA', etiqueta: 'Vacía' }, { valor: 'DUDOSA', etiqueta: 'Dudosa' }]"
              v-model:valor="nuevoTrabajo.resultado"
            />
            <Campo
              v-if="nuevoTrabajo.resultado === 'PRENADA'"
              etiqueta="Tamaño"
              :opciones="[{ valor: '', etiqueta: 'Elegir…' }, { valor: 'CHICA', etiqueta: 'Chica' }, { valor: 'MEDIANA', etiqueta: 'Mediana' }, { valor: 'GRANDE', etiqueta: 'Grande' }]"
              v-model:valor="nuevoTrabajo.tamano"
            />
            <Campo etiqueta="Observaciones" tipo="textarea" :filas="2" v-model:valor="nuevoTrabajo.observaciones" />
          </template>

          <template v-else-if="nuevoTrabajo.tipo === 'PESADA'">
            <Campo etiqueta="Kilos" tipo="number" min="15" max="1400" step="0.1" v-model:valor="nuevoTrabajo.kilos" />
          </template>

          <template v-else-if="nuevoTrabajo.tipo === 'REVISION_TOROS'">
            <Campo etiqueta="Circunferencia escrotal (cm)" tipo="number" min="24" max="50" step="0.1" v-model:valor="nuevoTrabajo.circunferenciaEscrotal" />
            <Campo etiqueta="Condición corporal" tipo="number" min="1" max="5" step="0.5" v-model:valor="nuevoTrabajo.condicionCorporal" />
            <Campo
              etiqueta="Dentadura"
              :opciones="[{ valor: '', etiqueta: 'Elegir…' }, ...OPCIONES_DENTADURA.map(d => ({ valor: d, etiqueta: d }))]"
              v-model:valor="nuevoTrabajo.dentadura"
            />
            <Campo
              etiqueta="Apto"
              :opciones="[{ valor: '', etiqueta: 'Elegir…' }, { valor: 'si', etiqueta: 'Sí' }, { valor: 'no', etiqueta: 'No' }]"
              v-model:valor="nuevoTrabajo.apto"
            />
          </template>

          <template v-else-if="nuevoTrabajo.tipo === 'SANIDAD'">
            <Campo etiqueta="Producto" v-model:valor="nuevoTrabajo.producto" />
            <Campo etiqueta="Dosis" tipo="number" min="0" step="0.01" v-model:valor="nuevoTrabajo.dosis" />
          </template>

          <Boton
            v-if="nuevoTrabajo.tipo"
            variante="sobrio" tamano="sm" class="boton-fila" tipo="submit"
            :deshabilitado="guardandoTrabajo"
          >
            {{ guardandoTrabajo ? 'Guardando…' : 'Agregar trabajo' }}
          </Boton>
        </form>
        <Aviso v-if="mensajeTrabajo" tono="ok" class="aviso-fila">{{ mensajeTrabajo }}</Aviso>
        <Aviso v-if="errorTrabajo" tono="error" class="aviso-fila">{{ errorTrabajo.mensaje }} <span v-if="errorTrabajo.detalle">— {{ errorTrabajo.detalle }}</span></Aviso>
      </Tarjeta>

      <Tarjeta titulo="Historial de trabajos" class="tarjeta-espaciada">
        <p v-if="historial.length === 0" class="atenuado">Sin eventos registrados todavía.</p>

        <template v-else>
          <div v-if="tiposEnHistorial.length > 1" class="filtros-historial">
            <button
              type="button" class="chip" :class="{ 'chip--activo': !filtroTipoHistorial }"
              @click="filtroTipoHistorial = null"
            >Todos</button>
            <button
              v-for="t in tiposEnHistorial" :key="t" type="button" class="chip"
              :class="{ 'chip--activo': filtroTipoHistorial === t }"
              @click="filtroTipoHistorial = t"
            >{{ ETIQUETA_TIPO_TRABAJO[t] ?? t }}</button>
          </div>

          <p v-if="historialFiltrado.length === 0" class="atenuado">No hay eventos de este tipo.</p>

          <ul v-else class="lista-historial">
          <template v-for="grupo in historialAgrupado" :key="grupo.anio">
            <li class="anio-historial">{{ grupo.anio }}</li>
            <ItemHistorial
              v-for="ev in grupo.items"
              :key="ev.idEvento"
              :fecha="ev.fecha"
              :tipo="ev.tipoTrabajo"
              :detalle="ev.detalle"
              :comentario="ev.comentario"
              :origen-dato="ev.origenDato"
              :apto="ev.apto"
              :ultimo="ev.idEvento === historialFiltrado[historialFiltrado.length - 1]?.idEvento"
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
                <select class="select-chico" v-model="estadoEdicion(ev.idEvento).dentadura">
                  <option value="">Dentadura (sin cambios)</option>
                  <option v-for="d in OPCIONES_DENTADURA" :key="d" :value="d">{{ d }}</option>
                </select>
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
          </template>
          </ul>
        </template>
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
          <Campo
            etiqueta="Año de nacimiento"
            tipo="number" min="1900" max="2100"
            :placeholder="fechaNacimientoCorregida ? 'Se completa solo con la fecha' : 'Si no se sabe la fecha exacta'"
            :deshabilitado="!!fechaNacimientoCorregida"
            v-model:valor="anioNacimientoCorregido"
          />
          <Campo etiqueta="Año de ingreso" tipo="number" min="1900" max="2100" v-model:valor="anioIngresoCorregido" />
          <Campo
            v-if="animal.sexo === 'M'"
            etiqueta="Año de primer servicio" tipo="number" min="1900" max="2100"
            v-model:valor="anioPrimerServicioCorregido"
          />
          <Campo etiqueta="Peso al nacer (kg)" tipo="number" min="10" max="70" step="0.1" placeholder="10 a 70" v-model:valor="pesoNacerCorregido" />
          <Campo
            v-if="animal.sexo === 'M'"
            etiqueta="Padre" placeholder="Nombre, si no está registrado como animal"
            v-model:valor="padreNombreCorregido"
          />
          <Campo etiqueta="Notas" tipo="textarea" :filas="2" v-model:valor="observacionesCorregido" />
          <Boton variante="sobrio" tamano="sm" class="boton-fila" tipo="submit" :deshabilitado="guardandoCorreccion">
            {{ guardandoCorreccion ? 'Guardando…' : 'Guardar cambios' }}
          </Boton>
        </form>
        <Aviso v-if="mensajeCorreccion" tono="ok" class="aviso-fila">{{ mensajeCorreccion }}</Aviso>
        <Aviso v-if="errorCorreccion" tono="error" class="aviso-fila">{{ errorCorreccion.mensaje }} <span v-if="errorCorreccion.detalle">— {{ errorCorreccion.detalle }}</span></Aviso>
      </Tarjeta>

      <Tarjeta titulo="Categoría, rodeo y establecimiento" class="tarjeta-espaciada">
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
          <Check etiqueta="La fecha es estimada" v-model:marcado="fechaEsEstimadaCategoria" />
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
          <Check etiqueta="La fecha es la de la migración" v-model:marcado="fechaEsEstimadaRodeo" />
          <Aviso v-if="mensajeRodeo" tono="ok" class="aviso-fila">{{ mensajeRodeo }}</Aviso>
          <Aviso v-if="errorRodeo" tono="error" class="aviso-fila">{{ errorRodeo.mensaje }}</Aviso>
        </div>

        <div class="asignar">
          <form class="form-asignar" @submit.prevent="guardarEstablecimiento">
            <Campo
              class="campo-asignar"
              :opciones="[
                { valor: null, etiqueta: animal.cuig ? 'Corregir establecimiento…' : 'Asignar establecimiento…' },
                ...establecimientos.map(e => ({
                  valor: e.idEstablecimiento,
                  etiqueta: `${e.nombre} (${e.cuig})${e.activo ? '' : ' · inactivo'}`
                }))
              ]"
              :valor="idEstablecimientoElegido"
              @update:valor="idEstablecimientoElegido = $event === '' ? null : Number($event)"
            />
            <Boton variante="sobrio" tamano="sm" tipo="submit" :deshabilitado="!idEstablecimientoElegido || guardandoEstablecimiento">
              {{ guardandoEstablecimiento ? 'Guardando…' : (animal.cuig ? 'Corregir' : 'Asignar') }}
            </Boton>
          </form>
          <Aviso v-if="mensajeEstablecimiento" tono="ok" class="aviso-fila">{{ mensajeEstablecimiento }}</Aviso>
          <Aviso v-if="errorEstablecimiento" tono="error" class="aviso-fila">{{ errorEstablecimiento.mensaje }}</Aviso>
        </div>
      </Tarjeta>

      <Tarjeta titulo="Revisión de saneamiento" class="tarjeta-espaciada">
        <p class="atenuado chico">
          Estado actual:
          <Etiqueta :tono="animal.validacion === 'VALIDADO' ? 'ok' : animal.validacion === 'CORREGIR' ? 'mal' : animal.validacion === 'DUDOSO' ? 'atenuado' : 'falta'">
            {{ animal.validacion === 'SIN_REVISAR' ? 'sin revisar' : animal.validacion.toLowerCase() }}
          </Etiqueta>
          <span v-if="animal.revisadoPor"> · por {{ animal.revisadoPor }}</span>
        </p>

        <form class="form-validacion" @submit.prevent="guardarValidacion">
          <Campo
            :opciones="[
              { valor: null, etiqueta: 'Marcar como…' },
              { valor: 'VALIDADO', etiqueta: 'Validado' },
              { valor: 'CORREGIR', etiqueta: 'A corregir' },
              { valor: 'DUDOSO', etiqueta: 'Dudoso' }
            ]"
            :valor="estadoValidacionElegido"
            @update:valor="estadoValidacionElegido = $event === '' ? null : ($event as MarcarValidacionParams['estado'])"
          />
          <Campo tipo="textarea" :filas="2" placeholder="Observaciones (opcional)" v-model:valor="observacionValidacion" />
          <Boton variante="sobrio" tamano="sm" class="boton-fila" tipo="submit" :deshabilitado="!estadoValidacionElegido || guardandoValidacion">
            {{ guardandoValidacion ? 'Guardando…' : 'Guardar revisión' }}
          </Boton>
        </form>
        <Aviso v-if="mensajeValidacion" tono="ok" class="aviso-fila">{{ mensajeValidacion }}</Aviso>
        <Aviso v-if="errorValidacion" tono="error" class="aviso-fila">{{ errorValidacion.mensaje }}</Aviso>
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
.anio-historial {
  list-style: none; font-size: var(--fs-11); font-weight: var(--fw-bold); color: var(--text-muted);
  letter-spacing: var(--ls-caps); text-transform: uppercase; margin: 14px 0 4px 42px;
}
.anio-historial:first-child { margin-top: 0; }
.filtros-historial { display: flex; gap: 6px; flex-wrap: wrap; margin-bottom: 14px; }
button.chip {
  font: inherit; font-family: var(--font-ui); font-size: var(--fs-13); font-weight: var(--fw-semibold);
  padding: 5px 12px; border-radius: var(--radio-pill); border: var(--borde-fino);
  background: var(--surface-card); color: var(--text-muted); cursor: pointer;
}
button.chip--activo { background: var(--cielo-100); border-color: var(--cielo-300); color: var(--cielo-700); }
button.link-corregir { padding-top: 6px; }
.form-correccion-evento { display: flex; flex-direction: column; gap: 8px; margin-top: 8px; }
.select-chico {
  font: inherit; font-family: var(--font-ui); font-size: var(--fs-13); padding: 6px 8px; border-radius: var(--radio-sm);
  border: var(--borde-fino); background: var(--surface-field); color: var(--text-body);
}
button.boton-fila { align-self: flex-start; }

.chico { font-size: var(--fs-125); margin: 0 0 12px; }
.form-correccion { display: flex; flex-direction: column; gap: 10px; }
.form-trabajo { display: flex; flex-direction: column; gap: 10px; }
.form-baja { display: flex; flex-direction: column; gap: 8px; }
.form-validacion { display: flex; flex-direction: column; gap: 8px; margin-top: 8px; }
</style>

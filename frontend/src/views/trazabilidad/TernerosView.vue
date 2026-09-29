<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import {
  LINEAS, ETIQUETA_TIPO, fechaAR, hoyISO, sexoPlural,
  listarCiclos, cicloSugerido, saldoTerneros, movimientosTerneros, alertasTerneros,
  registrarNacimiento, registrarBajaTerneros, anularMovimiento, reasignarMovimiento, crearCandidatoTorito,
  type CicloProductivo, type Linea, type Sexo, type SaldoTerneros, type MovimientoTerneros, type AlertasTerneros
} from '@/api/terneros'
import { buscarAnimales } from '@/api/animales'
import type { ErrorApi } from '@/api/client'
import Marca from '@/components/base/Marca.vue'
import Tarjeta from '@/components/base/Tarjeta.vue'
import Campo from '@/components/formularios/Campo.vue'
import Check from '@/components/formularios/Check.vue'
import Boton from '@/components/base/Boton.vue'
import Aviso from '@/components/avisos/Aviso.vue'
import Etiqueta from '@/components/base/Etiqueta.vue'

/**
 * Terneros nacidos sin caravana (migración 20260929120000): se cuentan por
 * ciclo productivo y sexo desde que nacen hasta el trabajo de
 * identificación. Los candidatos a torito no van en la cantidad: se dan de
 * alta como animal, con su caravana especial.
 *
 * El ciclo lo sugiere la fecha dentro de la línea (vacas o vaquillonas); se
 * puede cambiar a mano y queda registrado que se cambió. Nada se edita ni se
 * borra: un error se corrige anulando el movimiento o pasándolo a otro ciclo.
 */
const ciclos = ref<CicloProductivo[]>([])
const saldo = ref<SaldoTerneros[]>([])
const alertas = ref<AlertasTerneros | null>(null)
const movimientos = ref<MovimientoTerneros[]>([])
const idCicloMovimientos = ref<number | null>(null)
const error = ref<ErrorApi | null>(null)

async function consultar() {
  try {
    const [c, s, a] = await Promise.all([listarCiclos(), saldoTerneros(), alertasTerneros()])
    ciclos.value = c
    saldo.value = s
    alertas.value = a
    await consultarMovimientos()
  } catch (e) {
    error.value = e as ErrorApi
  }
}

async function consultarMovimientos() {
  movimientos.value = await movimientosTerneros(idCicloMovimientos.value ?? undefined)
}
watch(idCicloMovimientos, () => consultarMovimientos().catch(e => { error.value = e as ErrorApi }))

onMounted(consultar)

const filasCiclo = computed(() => saldo.value.filter(s => s.nivel === 'CICLO'))
const filasTotal = computed(() => saldo.value.filter(s => s.nivel === 'TOTAL'))
const numero = (n: number) => n.toLocaleString('es-AR')
const opcionesCiclo = (linea?: Linea) => ciclos.value
  .filter(c => !linea || c.linea === linea)
  .map(c => ({ valor: c.idCicloProductivo, etiqueta: c.codigo }))

// --------------------------------------------------------- cargar movimiento

const tipo = ref<'NACIMIENTO' | 'MUERTE' | 'BAJA_OTRA'>('NACIMIENTO')
const linea = ref<Linea>('VACA')
const fecha = ref(hoyISO())
const fechaEsEstimada = ref(false)
const sexo = ref<Sexo | null>(null)
const cantidad = ref('')
const idCiclo = ref<number | null>(null)
const sugerido = ref<CicloProductivo | null>(null)
const observaciones = ref('')
const guardando = ref(false)
const mensaje = ref<string | null>(null)

async function sugerir() {
  sugerido.value = null
  if (!fecha.value) return
  try {
    sugerido.value = await cicloSugerido(linea.value, fecha.value)
  } catch {
    // sin sugerencia: se elige a mano
  }
  idCiclo.value = sugerido.value?.idCicloProductivo ?? null
}
watch([linea, fecha], sugerir, { immediate: true })

const cicloManual = computed(() => idCiclo.value !== null && idCiclo.value !== sugerido.value?.idCicloProductivo)

async function registrar() {
  if (!sexo.value || !cantidad.value || !idCiclo.value) return
  guardando.value = true
  mensaje.value = null
  error.value = null
  const pedido = {
    fecha: fecha.value, fechaEsEstimada: fechaEsEstimada.value, sexo: sexo.value,
    cantidad: Number(cantidad.value), linea: linea.value, idCicloProductivo: idCiclo.value,
    observaciones: observaciones.value || undefined
  }
  try {
    const mov = tipo.value === 'NACIMIENTO'
      ? await registrarNacimiento(pedido)
      : await registrarBajaTerneros({ ...pedido, tipo: tipo.value })
    mensaje.value = `${ETIQUETA_TIPO[mov.tipo]} registrado: ${numero(mov.cantidad)} `
      + `${sexoPlural(mov.sexo).toLowerCase()} en el ciclo ${mov.ciclo}.`
    cantidad.value = ''
    observaciones.value = ''
    await consultar()
  } catch (e) {
    error.value = e as ErrorApi
  } finally {
    guardando.value = false
  }
}

// ------------------------------------------------------------- correcciones

const corrigiendo = ref<{ idMov: number; accion: 'anular' | 'reasignar'; idCiclo: number | null; motivo: string } | null>(null)

function puedeAnular(m: MovimientoTerneros) {
  return !m.anulado && m.tipo !== 'ANULACION' && m.tipo !== 'IDENTIFICACION'
}
function puedeReasignar(m: MovimientoTerneros) {
  return !m.anulado && m.tipo !== 'ANULACION'
}

async function confirmarCorreccion() {
  const c = corrigiendo.value
  if (!c) return
  error.value = null
  mensaje.value = null
  try {
    if (c.accion === 'anular') {
      await anularMovimiento(c.idMov, c.motivo || undefined)
      mensaje.value = `Movimiento ${c.idMov} anulado.`
    } else {
      if (!c.idCiclo) return
      const nuevo = await reasignarMovimiento(c.idMov, c.idCiclo, c.motivo || undefined)
      mensaje.value = `Movimiento ${c.idMov} pasado al ciclo ${nuevo.ciclo}.`
    }
    corrigiendo.value = null
    await consultar()
  } catch (e) {
    error.value = e as ErrorApi
  }
}

// ------------------------------------------------------ candidato a torito

const torito = ref({ caravana: '', fechaNacimiento: hoyISO(), estimada: false, peso: '', madre: '', padre: '' })
const guardandoTorito = ref(false)
const mensajeTorito = ref<string | null>(null)
const errorTorito = ref<ErrorApi | null>(null)

async function idPorCaravana(caravana: string) {
  const pagina = await buscarAnimales({ caravana, size: 10 })
  const exacto = pagina.content.find(a => a.caravana?.toLowerCase() === caravana.trim().toLowerCase())
  if (!exacto) throw { estado: 0, mensaje: `No hay un animal con la caravana ${caravana}.` } as ErrorApi
  return exacto.idAnimal
}

async function darDeAltaTorito() {
  const t = torito.value
  if (!t.caravana || !t.fechaNacimiento) return
  guardandoTorito.value = true
  mensajeTorito.value = null
  errorTorito.value = null
  try {
    const r = await crearCandidatoTorito({
      caravanaAdicional: t.caravana,
      fechaNacimiento: t.fechaNacimiento,
      fechaNacEsEstimada: t.estimada,
      pesoNacerKg: t.peso ? Number(t.peso) : undefined,
      idMadre: t.madre ? await idPorCaravana(t.madre) : undefined,
      padreNombre: t.padre || undefined
    })
    mensajeTorito.value = r.mensaje
    torito.value = { caravana: '', fechaNacimiento: hoyISO(), estimada: false, peso: '', madre: '', padre: '' }
  } catch (e) {
    errorTorito.value = e as ErrorApi
  } finally {
    guardandoTorito.value = false
  }
}
</script>

<template>
  <main class="pantalla">
    <RouterLink to="/" class="volver">‹ Inicio</RouterLink>

    <Marca bajada="Santa Ana · terneros sin identificar" class="marca-terneros">
      <RouterLink class="link-nav" to="/planillas/identificacion">Cargar identificación</RouterLink>
      <RouterLink class="link-nav" to="/terneros/ciclos">Ciclos</RouterLink>
    </Marca>

    <div v-if="alertas && (alertas.ciclosCerrados.length || alertas.fueraDeCiclo.length)" class="avisos">
      <Aviso v-for="a in alertas.ciclosCerrados" :key="`c${a.idCicloProductivo}${a.sexo}`" tono="atencion">
        <template v-if="a.saldo > 0">
          El ciclo {{ a.ciclo }} terminó el {{ fechaAR(a.fechaFin) }} con {{ numero(a.saldo) }}
          {{ sexoPlural(a.sexo).toLowerCase() }} sin identificar.
        </template>
        <template v-else>
          El ciclo {{ a.ciclo }} terminó con {{ numero(-a.saldo) }} {{ sexoPlural(a.sexo).toLowerCase() }}
          identificados de más: faltan nacimientos por cargar, o hay identificaciones en el ciclo equivocado.
        </template>
      </Aviso>
      <Aviso v-if="alertas.fueraDeCiclo.length" tono="atencion">
        {{ alertas.fueraDeCiclo.length }} movimientos tienen una fecha fuera de las fechas de su ciclo.
        Revisalos abajo: puede que haya que pasarlos a otro ciclo.
      </Aviso>
    </div>

    <Aviso v-if="error" tono="error" :detalle="error.detalle" class="aviso-fila">{{ error.mensaje }}</Aviso>
    <Aviso v-if="mensaje" tono="ok" class="aviso-fila">{{ mensaje }}</Aviso>

    <!-- ============================================ pendientes por ciclo -->
    <Tarjeta titulo="Pendientes por ciclo" nota="Terneros nacidos que todavía no tienen caravana." denso class="bloque">
      <div class="tabla-scroll">
        <table class="tabla">
          <thead>
            <tr>
              <th>Ciclo</th><th>Sexo</th>
              <th class="num">Nacidos</th><th class="num">Identificados</th>
              <th class="num">Muertes</th><th class="num">Otras bajas</th><th class="num">Pendientes</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="s in filasCiclo" :key="`${s.idCicloProductivo}${s.sexo}`" :class="{ 'fila-vacia': !s.nacidos && !s.saldo }">
              <td class="ciclo">
                {{ s.ciclo }}
                <Etiqueta v-if="s.cicloCerrado" tono="atenuado"> · terminado</Etiqueta>
              </td>
              <td>{{ sexoPlural(s.sexo) }}</td>
              <td class="num">{{ numero(s.nacidos) }}</td>
              <td class="num">{{ numero(s.identificados) }}</td>
              <td class="num">{{ numero(s.muertes) }}</td>
              <td class="num">{{ numero(s.otrasBajas) }}</td>
              <td class="num fuerte">
                <Etiqueta v-if="s.saldo < 0" tono="mal">{{ numero(s.saldo) }}</Etiqueta>
                <template v-else>{{ numero(s.saldo) }}</template>
              </td>
            </tr>
          </tbody>
          <tfoot>
            <tr v-for="t in filasTotal" :key="`t${t.sexo ?? ''}`" :class="{ 'total-general': !t.sexo }">
              <td>{{ t.sexo ? 'Total' : 'Total general' }}</td>
              <td>{{ t.sexo ? sexoPlural(t.sexo) : '' }}</td>
              <td class="num">{{ numero(t.nacidos) }}</td>
              <td class="num">{{ numero(t.identificados) }}</td>
              <td class="num">{{ numero(t.muertes) }}</td>
              <td class="num">{{ numero(t.otrasBajas) }}</td>
              <td class="num fuerte">{{ numero(t.saldo) }}</td>
            </tr>
          </tfoot>
        </table>
      </div>
      <p v-if="filasCiclo.some(s => s.saldo < 0)" class="nota">
        Un pendiente negativo quiere decir que se identificaron más terneros que los nacimientos cargados en ese ciclo.
      </p>
    </Tarjeta>

    <!-- ============================================== cargar movimiento -->
    <Tarjeta titulo="Cargar nacimientos o bajas" class="bloque">
      <form class="form" @submit.prevent="registrar">
        <div class="fila">
          <Campo
            etiqueta="Movimiento" v-model:valor="tipo"
            :opciones="[{ valor: 'NACIMIENTO', etiqueta: 'Nacimiento' }, { valor: 'MUERTE', etiqueta: 'Muerte' }, { valor: 'BAJA_OTRA', etiqueta: 'Otra baja' }]"
          />
          <Campo etiqueta="Madres" v-model:valor="linea" :opciones="LINEAS" />
        </div>
        <div class="fila">
          <Campo etiqueta="Fecha" tipo="date" requerido v-model:valor="fecha" />
          <Campo
            etiqueta="Sexo" requerido
            :opciones="[{ valor: null, etiqueta: 'Elegir…' }, { valor: 'M', etiqueta: 'Machos' }, { valor: 'H', etiqueta: 'Hembras' }]"
            :valor="sexo" @update:valor="sexo = ($event || null) as Sexo | null"
          />
          <Campo etiqueta="Cantidad" tipo="number" requerido min="1" max="2000" v-model:valor="cantidad" />
        </div>
        <Check etiqueta="La fecha es estimada" v-model:marcado="fechaEsEstimada" />

        <Campo
          etiqueta="Ciclo" requerido
          :opciones="[{ valor: null, etiqueta: 'Elegir ciclo…' }, ...opcionesCiclo(linea)]"
          :valor="idCiclo" @update:valor="idCiclo = $event === '' ? null : Number($event)"
        />
        <p class="nota">
          <template v-if="sugerido && !cicloManual">Sugerido por la fecha.</template>
          <template v-else-if="sugerido && cicloManual">
            Elegido a mano: por la fecha correspondía {{ sugerido.codigo }}. Queda registrado que se cambió.
          </template>
          <template v-else>La fecha no cae en ningún ciclo de {{ linea === 'VACA' ? 'vacas' : 'vaquillonas' }}: elegilo a mano.</template>
        </p>

        <Campo etiqueta="Observaciones" tipo="textarea" v-model:valor="observaciones" />

        <Boton tipo="submit" :deshabilitado="guardando || !sexo || !cantidad || !idCiclo">
          {{ guardando ? 'Guardando…' : 'Registrar' }}
        </Boton>
      </form>
    </Tarjeta>

    <!-- ===================================================== movimientos -->
    <Tarjeta titulo="Movimientos" denso class="bloque">
      <div class="filtro-movimientos">
        <Campo
          etiqueta="Ciclo"
          :opciones="[{ valor: null, etiqueta: 'Todos' }, ...opcionesCiclo()]"
          :valor="idCicloMovimientos" @update:valor="idCicloMovimientos = $event === '' ? null : Number($event)"
        />
      </div>
      <p v-if="movimientos.length === 0" class="nota">Sin movimientos cargados todavía.</p>
      <div v-else class="tabla-scroll">
        <table class="tabla">
          <thead>
            <tr><th>Fecha</th><th>Movimiento</th><th>Ciclo</th><th>Sexo</th><th class="num">Cantidad</th><th>Detalle</th><th></th></tr>
          </thead>
          <tbody>
            <template v-for="m in movimientos" :key="m.idMov">
              <tr :class="{ anulado: m.anulado }">
                <td class="mono">{{ fechaAR(m.fechaEvento) }}<span v-if="m.fechaEsEstimada" class="atenuado"> (est.)</span></td>
                <td>
                  {{ ETIQUETA_TIPO[m.tipo] }}
                  <span v-if="m.idMovAnulado" class="atenuado"> de {{ m.idMovAnulado }}</span>
                </td>
                <td>{{ m.ciclo }}<span v-if="m.cicloManual" class="atenuado"> · a mano</span></td>
                <td>{{ sexoPlural(m.sexo) }}</td>
                <td class="num mono">{{ m.delta > 0 ? '+' : '' }}{{ numero(m.delta) }}</td>
                <td class="detalle">
                  <Etiqueta v-if="m.anulado" tono="atenuado">anulado</Etiqueta>
                  <Etiqueta v-if="m.excedeSaldo" tono="mal">excede el pendiente</Etiqueta>
                  {{ m.observaciones }}
                  <span v-if="m.registradoPor" class="atenuado"> · {{ m.registradoPor }}</span>
                </td>
                <td class="acciones">
                  <Boton v-if="puedeAnular(m)" variante="texto" tamano="sm"
                    @click="corrigiendo = { idMov: m.idMov, accion: 'anular', idCiclo: null, motivo: '' }">Anular</Boton>
                  <Boton v-if="puedeReasignar(m)" variante="texto" tamano="sm"
                    @click="corrigiendo = { idMov: m.idMov, accion: 'reasignar', idCiclo: null, motivo: '' }">Otro ciclo</Boton>
                </td>
              </tr>
              <tr v-if="corrigiendo?.idMov === m.idMov" class="fila-correccion">
                <td colspan="7">
                  <form class="correccion" @submit.prevent="confirmarCorreccion">
                    <Campo
                      v-if="corrigiendo.accion === 'reasignar'" etiqueta="Pasar al ciclo" requerido
                      :opciones="[{ valor: null, etiqueta: 'Elegir ciclo…' }, ...opcionesCiclo().filter(o => o.valor !== m.idCicloProductivo)]"
                      :valor="corrigiendo.idCiclo" @update:valor="corrigiendo.idCiclo = $event === '' ? null : Number($event)"
                    />
                    <Campo etiqueta="Motivo" v-model:valor="corrigiendo.motivo" />
                    <Boton tipo="submit" tamano="sm"
                      :deshabilitado="corrigiendo.accion === 'reasignar' && !corrigiendo.idCiclo">
                      {{ corrigiendo.accion === 'anular' ? 'Anular movimiento' : 'Pasar de ciclo' }}
                    </Boton>
                    <Boton variante="sobrio" tamano="sm" @click="corrigiendo = null">Cancelar</Boton>
                  </form>
                  <p class="nota">
                    No se borra nada: se carga un movimiento contrario en el mismo ciclo
                    {{ corrigiendo.accion === 'reasignar' ? 'y el mismo movimiento de nuevo en el ciclo elegido' : '' }}.
                  </p>
                </td>
              </tr>
            </template>
          </tbody>
        </table>
      </div>
    </Tarjeta>

    <!-- ============================================== candidato a torito -->
    <Tarjeta titulo="Candidato a torito" nota="Se da de alta como animal desde que nace, con su caravana especial. No suma en los pendientes." class="bloque">
      <form class="form" @submit.prevent="darDeAltaTorito">
        <div class="fila">
          <Campo etiqueta="Caravana especial" requerido v-model:valor="torito.caravana" />
          <Campo etiqueta="Nacimiento" tipo="date" requerido v-model:valor="torito.fechaNacimiento" />
          <Campo etiqueta="Peso al nacer (kg)" tipo="number" min="10" max="70" step="0.5" v-model:valor="torito.peso" />
        </div>
        <Check etiqueta="La fecha es estimada" v-model:marcado="torito.estimada" />
        <div class="fila">
          <Campo etiqueta="Caravana de la madre" placeholder="Si se sabe" v-model:valor="torito.madre" />
          <Campo etiqueta="Padre" placeholder="Nombre o caravana, si se sabe" v-model:valor="torito.padre" />
        </div>
        <Aviso v-if="errorTorito" tono="error" :detalle="errorTorito.detalle">{{ errorTorito.mensaje }}</Aviso>
        <Aviso v-if="mensajeTorito" tono="ok">{{ mensajeTorito }}</Aviso>
        <Boton tipo="submit" :deshabilitado="guardandoTorito || !torito.caravana || !torito.fechaNacimiento">
          {{ guardandoTorito ? 'Guardando…' : 'Dar de alta' }}
        </Boton>
      </form>
    </Tarjeta>
  </main>
</template>

<style scoped>
.pantalla { max-width: var(--ancho-tabla); margin: 6vh auto; padding: 0 16px; }
.volver { display: inline-block; margin-bottom: 14px; color: var(--text-muted); font-size: var(--fs-13); text-decoration: none; }
.volver:hover { text-decoration: underline; }
header.marca-terneros { margin-bottom: 18px; }
.link-nav {
  border: 1px solid var(--border-default); color: var(--text-body); border-radius: var(--radio-md);
  padding: 6px 10px; font-size: var(--fs-13); font-weight: var(--fw-semibold); text-decoration: none;
}
.link-nav:hover { background: var(--surface-sunken); }

.avisos { display: flex; flex-direction: column; gap: 10px; margin-bottom: 14px; }
p.aviso-fila { margin: 0 0 14px; }
section.bloque { margin-bottom: 18px; }

.form { display: flex; flex-direction: column; gap: var(--gap-campo); }
.fila { display: flex; gap: 14px; flex-wrap: wrap; }
.nota { margin: 0; font-size: var(--fs-125); color: var(--text-muted); }
.atenuado { color: var(--text-muted); }
.mono { font-family: var(--font-mono); }

.tabla-scroll { overflow-x: auto; }
.tabla { width: 100%; border-collapse: collapse; font-size: var(--fs-135); margin-bottom: 10px; }
.tabla th { text-align: left; font-size: 11.5px; color: var(--text-muted); font-weight: var(--fw-semibold); padding: 6px 8px; border-bottom: var(--borde-fino); white-space: nowrap; }
.tabla td { padding: 6px 8px; border-bottom: var(--borde-filete); vertical-align: top; }
.tabla .num { text-align: right; font-family: var(--font-mono); font-variant-numeric: tabular-nums; }
.tabla .fuerte { font-weight: var(--fw-semibold); }
.tabla td.ciclo { font-weight: var(--fw-semibold); white-space: nowrap; }
.tabla tr.fila-vacia td { color: var(--text-muted); }
.tabla tfoot td { border-bottom: none; border-top: var(--borde-fino); color: var(--text-muted); }
.tabla tfoot tr.total-general td { color: var(--text-body); font-weight: var(--fw-semibold); }
.tabla tr.anulado td { color: var(--text-muted); }
.tabla td.detalle { font-size: var(--fs-13); }
.tabla td.acciones { white-space: nowrap; text-align: right; }
.tabla td.acciones .boton + .boton { margin-left: 12px; }
.tabla tr.fila-correccion td { background: var(--surface-sunken); }

.filtro-movimientos { max-width: 260px; margin-bottom: 10px; }
.correccion { display: flex; gap: 10px; align-items: flex-end; flex-wrap: wrap; margin-bottom: 6px; }
</style>

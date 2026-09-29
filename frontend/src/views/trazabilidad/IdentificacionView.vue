<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import {
  fechaAR, hoyISO, sexoPlural,
  listarCiclos, cicloSugerido, saldoTerneros, cargarIdentificacion,
  type CicloProductivo, type Linea, type Sexo, type SaldoTerneros
} from '@/api/terneros'
import { listarRodeos, listarCategorias, buscarAnimales, type Rodeo, type Animal } from '@/api/animales'
import type { ErrorApi } from '@/api/client'
import Marca from '@/components/base/Marca.vue'
import Tarjeta from '@/components/base/Tarjeta.vue'
import Campo from '@/components/formularios/Campo.vue'
import Check from '@/components/formularios/Check.vue'
import Boton from '@/components/base/Boton.vue'
import Aviso from '@/components/avisos/Aviso.vue'
import Etiqueta from '@/components/base/Etiqueta.vue'

/**
 * Transcripción de la planilla de identificación. Dos cosas en el mismo
 * trabajo:
 *   - terneros que se llevaban como cantidad: se cargan sus caravanas por
 *     ciclo y sexo. Cada caravana es un animal nuevo, y cada grupo descuenta
 *     de la cantidad pendiente de su ciclo. Por defecto el ciclo vigente de la
 *     línea a la fecha del trabajo; se puede cambiar.
 *   - candidatos a torito: ya son animales; se les agrega la caravana visual.
 * Todo entra junto o no entra nada.
 */
interface Grupo {
  clave: number
  idCiclo: number | null
  sexo: Sexo | null
  texto: string
}

const fecha = ref(hoyISO())
const idRodeo = ref<number | null>(null)
const observaciones = ref('')
const grupos = ref<Grupo[]>([])
const caravanasTorito = ref<Record<number, string>>({})
const confirmarExceso = ref(false)

const ciclos = ref<CicloProductivo[]>([])
const saldo = ref<SaldoTerneros[]>([])
const rodeos = ref<Rodeo[]>([])
const toritos = ref<Animal[]>([])

const guardando = ref(false)
const mensaje = ref<string | null>(null)
const error = ref<ErrorApi | null>(null)
let siguienteClave = 1

async function consultar() {
  try {
    const [c, s, r, categorias] = await Promise.all([listarCiclos(), saldoTerneros(), listarRodeos(), listarCategorias()])
    ciclos.value = c
    saldo.value = s
    rodeos.value = r
    const idTorito = categorias.find(k => k.codigo === 'TORITO')?.idCategoria
    if (idTorito) {
      const pagina = await buscarAnimales({ idCategoria: idTorito, size: 500 })
      // candidatos: toritos que todavía no tienen caravana visual
      toritos.value = pagina.content.filter(a => a.tipoIdent !== 'VISUAL' && !a.tieneBaja)
    }
  } catch (e) {
    error.value = e as ErrorApi
  }
}
onMounted(consultar)

async function agregarGrupo(linea: Linea) {
  let vigente: CicloProductivo | null = null
  try {
    vigente = await cicloSugerido(linea, fecha.value)
  } catch {
    // sin ciclo vigente: se elige a mano
  }
  grupos.value.push({ clave: siguienteClave++, idCiclo: vigente?.idCicloProductivo ?? null, sexo: null, texto: '' })
}

function caravanasDe(g: Grupo) {
  return g.texto.split(/[\s,;]+/).map(c => c.trim()).filter(Boolean)
}

function pendientes(g: Grupo) {
  return saldo.value.find(s => s.nivel === 'CICLO' && s.idCicloProductivo === g.idCiclo && s.sexo === g.sexo)?.saldo ?? 0
}

function exceso(g: Grupo) {
  if (!g.idCiclo || !g.sexo) return 0
  return Math.max(0, caravanasDe(g).length - pendientes(g))
}

const hayExceso = computed(() => grupos.value.some(g => exceso(g) > 0))
const toritosCargados = computed(() => Object.entries(caravanasTorito.value)
  .filter(([, c]) => c.trim())
  .map(([id, c]) => ({ idAnimal: Number(id), caravana: c.trim() })))
const gruposCompletos = computed(() => grupos.value.every(g => g.idCiclo && g.sexo && caravanasDe(g).length > 0))
const total = computed(() => grupos.value.reduce((n, g) => n + caravanasDe(g).length, 0) + toritosCargados.value.length)
const puedeGuardar = computed(() => !guardando.value && total.value > 0 && gruposCompletos.value
  && (!hayExceso.value || confirmarExceso.value))

const codigoCiclo = (id: number | null) => ciclos.value.find(c => c.idCicloProductivo === id)?.codigo ?? '—'

async function guardar() {
  if (!puedeGuardar.value) return
  guardando.value = true
  mensaje.value = null
  error.value = null
  try {
    const r = await cargarIdentificacion({
      fecha: fecha.value,
      idRodeo: idRodeo.value ?? undefined,
      grupos: grupos.value.map(g => ({ idCicloProductivo: g.idCiclo!, sexo: g.sexo!, caravanas: caravanasDe(g) })),
      toritos: toritosCargados.value,
      confirmarExcesoSaldo: confirmarExceso.value,
      observaciones: observaciones.value || undefined
    })
    mensaje.value = r.mensaje
    grupos.value = []
    caravanasTorito.value = {}
    confirmarExceso.value = false
    await consultar()
  } catch (e) {
    error.value = e as ErrorApi
  } finally {
    guardando.value = false
  }
}
</script>

<template>
  <main class="pantalla">
    <RouterLink to="/terneros" class="volver">‹ Terneros sin identificar</RouterLink>

    <Marca bajada="Santa Ana · trabajo de identificación" class="marca-ident" />

    <Aviso v-if="error" tono="error" :detalle="error.detalle" class="aviso-fila">{{ error.mensaje }}</Aviso>
    <Aviso v-if="mensaje" tono="ok" class="aviso-fila">{{ mensaje }}</Aviso>

    <form @submit.prevent="guardar">
      <Tarjeta class="bloque">
        <div class="fila">
          <Campo etiqueta="Fecha del trabajo" tipo="date" requerido v-model:valor="fecha" />
          <Campo
            etiqueta="Rodeo donde quedan"
            :opciones="[{ valor: null, etiqueta: 'Sin asignar' }, ...rodeos.map(r => ({ valor: r.idRodeo, etiqueta: r.nombre }))]"
            :valor="idRodeo" @update:valor="idRodeo = $event === '' ? null : Number($event)"
          />
        </div>
      </Tarjeta>

      <!-- ====================================== terneros de la cantidad -->
      <Tarjeta
        titulo="Terneros"
        nota="Las caravanas de cada ciclo y sexo, separadas por espacio, coma o renglón. Cada una es un animal nuevo y se descuenta de los pendientes de ese ciclo."
        class="bloque"
      >
        <div v-for="(g, i) in grupos" :key="g.clave" class="grupo">
          <div class="fila">
            <Campo
              etiqueta="Ciclo" requerido
              :opciones="[{ valor: null, etiqueta: 'Elegir ciclo…' }, ...ciclos.map(c => ({ valor: c.idCicloProductivo, etiqueta: c.codigo }))]"
              :valor="g.idCiclo" @update:valor="g.idCiclo = $event === '' ? null : Number($event)"
            />
            <Campo
              etiqueta="Sexo" requerido
              :opciones="[{ valor: null, etiqueta: 'Elegir…' }, { valor: 'M', etiqueta: 'Machos' }, { valor: 'H', etiqueta: 'Hembras' }]"
              :valor="g.sexo" @update:valor="g.sexo = ($event || null) as Sexo | null"
            />
          </div>
          <Campo etiqueta="Caravanas" tipo="textarea" :filas="3" class="caravanas" v-model:valor="g.texto" />
          <p class="nota">
            {{ caravanasDe(g).length }} caravanas
            <template v-if="g.idCiclo && g.sexo">
              · pendientes en {{ codigoCiclo(g.idCiclo) }}: {{ pendientes(g) }} {{ sexoPlural(g.sexo).toLowerCase() }}
              <Etiqueta v-if="exceso(g) > 0" tono="mal"> · {{ exceso(g) }} de más</Etiqueta>
            </template>
            · <Boton variante="texto" tamano="sm" @click="grupos.splice(i, 1)">Quitar</Boton>
          </p>
        </div>

        <div class="agregar">
          <Boton variante="sobrio" tamano="sm" @click="agregarGrupo('VACA')">+ Terneros de vacas</Boton>
          <Boton variante="sobrio" tamano="sm" @click="agregarGrupo('VAQ')">+ Terneros de vaquillonas</Boton>
        </div>
        <p class="nota">El ciclo arranca en el vigente a la fecha del trabajo. Si los terneros son de otro ciclo, cambialo.</p>
      </Tarjeta>

      <!-- ============================================ candidatos a torito -->
      <Tarjeta
        titulo="Candidatos a torito"
        nota="Ya están cargados con su caravana especial. Anotá la caravana visual de los que se identificaron; los que queden en blanco no se tocan."
        denso class="bloque"
      >
        <p v-if="toritos.length === 0" class="nota">No hay candidatos a torito sin caravana visual.</p>
        <table v-else class="tabla">
          <thead><tr><th>Caravana especial</th><th>Nacimiento</th><th>Caravana visual</th></tr></thead>
          <tbody>
            <tr v-for="t in toritos" :key="t.idAnimal">
              <td class="mono">{{ t.identificaciones ?? `#${t.idAnimal}` }}</td>
              <td class="mono">{{ fechaAR(t.fechaNacimiento) }}</td>
              <td><input v-model="caravanasTorito[t.idAnimal]" type="text" /></td>
            </tr>
          </tbody>
        </table>
      </Tarjeta>

      <Tarjeta class="bloque">
        <Campo etiqueta="Observaciones" tipo="textarea" v-model:valor="observaciones" />

        <template v-if="hayExceso">
          <Aviso tono="atencion" class="aviso-exceso">
            Hay grupos con más caravanas que terneros pendientes en su ciclo. Suele pasar cuando faltan
            nacimientos por cargar o cuando el ciclo elegido no es el de esos terneros. Si está bien, se carga
            igual y el ciclo queda con pendientes negativos a la vista.
          </Aviso>
          <Check etiqueta="Cargar igual" v-model:marcado="confirmarExceso" />
        </template>

        <Boton tipo="submit" :deshabilitado="!puedeGuardar" class="guardar">
          {{ guardando ? 'Guardando…' : `Guardar identificación (${total})` }}
        </Boton>
      </Tarjeta>
    </form>
  </main>
</template>

<style scoped>
.pantalla { max-width: var(--ancho-forma); margin: 6vh auto; padding: 0 16px; }
.volver { display: inline-block; margin-bottom: 14px; color: var(--text-muted); font-size: var(--fs-13); text-decoration: none; }
.volver:hover { text-decoration: underline; }
header.marca-ident { margin-bottom: 18px; }
p.aviso-fila { margin: 0 0 14px; }
section.bloque { margin-bottom: 18px; }

.fila { display: flex; gap: 14px; flex-wrap: wrap; }
.nota { margin: 6px 0 0; font-size: var(--fs-125); color: var(--text-muted); }
.mono { font-family: var(--font-mono); }

.grupo { padding-bottom: 14px; margin-bottom: 14px; border-bottom: var(--borde-filete); display: flex; flex-direction: column; gap: var(--gap-campo); }
label.caravanas :deep(textarea) { font-family: var(--font-mono); }
.agregar { display: flex; gap: 10px; flex-wrap: wrap; }

.tabla { width: 100%; border-collapse: collapse; font-size: var(--fs-135); }
.tabla th { text-align: left; font-size: 11.5px; color: var(--text-muted); font-weight: var(--fw-semibold); padding: 6px 8px; border-bottom: var(--borde-fino); }
.tabla td { padding: 4px 6px; border-bottom: var(--borde-filete); }
.tabla input {
  font: inherit; font-family: var(--font-mono); font-size: var(--fs-13); padding: 5px 6px; border-radius: var(--radio-sm);
  border: var(--borde-fino); background: var(--surface-field); color: var(--text-body); width: 100%; box-sizing: border-box;
}

p.aviso-exceso { margin: 14px 0 8px; }
.guardar { margin-top: 14px; }
</style>

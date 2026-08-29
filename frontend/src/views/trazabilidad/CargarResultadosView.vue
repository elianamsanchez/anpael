<script setup lang="ts">
import { ref, watch } from 'vue'
import { listarRodeos, type Rodeo, type Animal } from '@/api/animales'
import { TIPOS_TRABAJO_PLANILLA } from '@/api/planillas'
import {
  animalesDelRodeo, cargarTacto, cargarPesada, cargarRevisionToros, cargarSanidad
} from '@/api/trabajos'
import type { ErrorApi } from '@/api/client'
import Marca from '@/components/base/Marca.vue'
import Tarjeta from '@/components/base/Tarjeta.vue'
import Campo from '@/components/formularios/Campo.vue'
import Boton from '@/components/base/Boton.vue'
import Aviso from '@/components/avisos/Aviso.vue'

/**
 * v0.2b · cargar resultados (docs/etapas.md): "cargás los resultados sin
 * transcribir nada dos veces" -la lista de animales es la misma que la del
 * PDF, en el mismo orden. Solo entran los animales que HOY estan en el
 * rodeo: si en el campo aparecio uno de mas (los renglones en blanco del
 * PDF), esta pantalla todavia no lo resuelve.
 */
interface Fila {
  idAnimal: number
  caravana: string
  resultado: string
  tamano: string
  observaciones: string
  kilos: string
  circunferenciaEscrotal: string
  condicionCorporal: string
  apto: string // '', 'si', 'no'
  producto: string
  dosis: string
}

const rodeos = ref<Rodeo[]>([])
const idRodeoElegido = ref<number | null>(null)
const tipoTrabajoElegido = ref<string | null>(null)
const cargandoAnimales = ref(false)
const filas = ref<Fila[]>([])

const guardando = ref(false)
const mensaje = ref<string | null>(null)
const error = ref<ErrorApi | null>(null)

listarRodeos().then(r => { rodeos.value = r })

function filaVacia(a: Animal): Fila {
  return {
    idAnimal: a.idAnimal,
    caravana: a.caravana ?? `#${a.idAnimal}`,
    resultado: '', tamano: '', observaciones: '',
    kilos: '', circunferenciaEscrotal: '', condicionCorporal: '', apto: '',
    producto: '', dosis: ''
  }
}

async function cargarAnimales() {
  filas.value = []
  mensaje.value = null
  error.value = null
  if (!idRodeoElegido.value || !tipoTrabajoElegido.value) return
  cargandoAnimales.value = true
  try {
    const animales = await animalesDelRodeo(idRodeoElegido.value)
    filas.value = animales.map(filaVacia)
  } catch (e) {
    error.value = e as ErrorApi
  } finally {
    cargandoAnimales.value = false
  }
}

watch([idRodeoElegido, tipoTrabajoElegido], cargarAnimales)

async function guardar() {
  if (!idRodeoElegido.value || !tipoTrabajoElegido.value) return
  guardando.value = true
  mensaje.value = null
  error.value = null
  try {
    let resultado
    if (tipoTrabajoElegido.value === 'TACTO') {
      const resultados = filas.value
        .filter(f => f.resultado)
        .map(f => ({
          idAnimal: f.idAnimal, resultado: f.resultado,
          tamano: f.tamano || undefined, observaciones: f.observaciones || undefined
        }))
      resultado = await cargarTacto(idRodeoElegido.value, resultados)
    } else if (tipoTrabajoElegido.value === 'PESADA') {
      const resultados = filas.value
        .filter(f => f.kilos)
        .map(f => ({ idAnimal: f.idAnimal, kilos: Number(f.kilos) }))
      resultado = await cargarPesada(idRodeoElegido.value, resultados)
    } else if (tipoTrabajoElegido.value === 'REVISION_TOROS') {
      const resultados = filas.value
        .filter(f => f.apto)
        .map(f => ({
          idAnimal: f.idAnimal, apto: f.apto === 'si',
          circunferenciaEscrotal: f.circunferenciaEscrotal ? Number(f.circunferenciaEscrotal) : undefined,
          condicionCorporal: f.condicionCorporal ? Number(f.condicionCorporal) : undefined
        }))
      resultado = await cargarRevisionToros(idRodeoElegido.value, resultados)
    } else {
      const resultados = filas.value
        .filter(f => f.producto)
        .map(f => ({ idAnimal: f.idAnimal, producto: f.producto, dosis: f.dosis ? Number(f.dosis) : undefined }))
      resultado = await cargarSanidad(idRodeoElegido.value, resultados)
    }
    mensaje.value = resultado.mensaje
    await cargarAnimales()
  } catch (e) {
    error.value = e as ErrorApi
  } finally {
    guardando.value = false
  }
}
</script>

<template>
  <main class="pantalla">
    <RouterLink to="/" class="volver">‹ Inicio</RouterLink>

    <Marca bajada="Santa Ana · cargar resultados" class="marca-cargar" />

    <section class="filtros">
      <Campo
        etiqueta="Rodeo" sobre-fondo class="campo-filtro"
        :opciones="[{ valor: null, etiqueta: 'Elegir rodeo…' }, ...rodeos.map(r => ({ valor: r.idRodeo, etiqueta: r.nombre }))]"
        :valor="idRodeoElegido"
        @update:valor="idRodeoElegido = $event === '' ? null : Number($event)"
      />
      <Campo
        etiqueta="Trabajo" sobre-fondo class="campo-filtro"
        :opciones="[{ valor: null, etiqueta: 'Elegir trabajo…' }, ...TIPOS_TRABAJO_PLANILLA.map(t => ({ valor: t.valor, etiqueta: t.etiqueta }))]"
        v-model:valor="tipoTrabajoElegido"
      />
    </section>

    <Aviso v-if="error" tono="error" class="aviso-fila">{{ error.mensaje }}</Aviso>
    <Aviso v-if="mensaje" tono="ok" class="aviso-fila">{{ mensaje }}</Aviso>

    <Tarjeta v-if="cargandoAnimales">
      <p class="atenuado">Consultando…</p>
    </Tarjeta>

    <Tarjeta v-else-if="filas.length > 0" denso class="tarjeta-ancha">
      <form @submit.prevent="guardar">
        <table class="tabla">
          <thead>
            <tr>
              <th>Caravana</th>
              <template v-if="tipoTrabajoElegido === 'TACTO'">
                <th>Resultado</th><th>Tamaño</th><th>Observaciones</th>
              </template>
              <template v-else-if="tipoTrabajoElegido === 'PESADA'">
                <th>Kilos</th>
              </template>
              <template v-else-if="tipoTrabajoElegido === 'REVISION_TOROS'">
                <th>Circunf. escrotal</th><th>Cond. corporal</th><th>Apto</th>
              </template>
              <template v-else-if="tipoTrabajoElegido === 'SANIDAD'">
                <th>Producto</th><th>Dosis</th>
              </template>
            </tr>
          </thead>
          <tbody>
            <tr v-for="f in filas" :key="f.idAnimal">
              <td class="caravana">{{ f.caravana }}</td>

              <template v-if="tipoTrabajoElegido === 'TACTO'">
                <td>
                  <select v-model="f.resultado">
                    <option value="">—</option>
                    <option value="PRENADA">Preñada</option>
                    <option value="VACIA">Vacía</option>
                    <option value="DUDOSA">Dudosa</option>
                  </select>
                </td>
                <td>
                  <select v-model="f.tamano" :disabled="f.resultado !== 'PRENADA'">
                    <option value="">—</option>
                    <option value="CHICA">Chica</option>
                    <option value="MEDIANA">Mediana</option>
                    <option value="GRANDE">Grande</option>
                  </select>
                </td>
                <td><input v-model="f.observaciones" type="text" /></td>
              </template>

              <template v-else-if="tipoTrabajoElegido === 'PESADA'">
                <td><input v-model="f.kilos" type="number" min="15" max="1400" step="0.1" /></td>
              </template>

              <template v-else-if="tipoTrabajoElegido === 'REVISION_TOROS'">
                <td><input v-model="f.circunferenciaEscrotal" type="number" min="24" max="50" step="0.1" /></td>
                <td><input v-model="f.condicionCorporal" type="number" min="1" max="5" step="0.5" /></td>
                <td>
                  <select v-model="f.apto">
                    <option value="">—</option>
                    <option value="si">Sí</option>
                    <option value="no">No</option>
                  </select>
                </td>
              </template>

              <template v-else-if="tipoTrabajoElegido === 'SANIDAD'">
                <td><input v-model="f.producto" type="text" /></td>
                <td><input v-model="f.dosis" type="number" min="0" step="0.01" /></td>
              </template>
            </tr>
          </tbody>
        </table>

        <Boton tipo="submit" :deshabilitado="guardando">
          {{ guardando ? 'Guardando…' : 'Guardar resultados' }}
        </Boton>
      </form>
    </Tarjeta>

    <Tarjeta v-else-if="idRodeoElegido && tipoTrabajoElegido">
      <p class="atenuado">Este rodeo no tiene animales asignados todavía.</p>
    </Tarjeta>
  </main>
</template>

<style scoped>
.pantalla { max-width: var(--ancho-tabla); margin: 6vh auto; padding: 0 16px; }
.volver { display: inline-block; margin-bottom: 14px; color: var(--text-muted); font-size: var(--fs-13); text-decoration: none; }
.volver:hover { text-decoration: underline; }
header.marca-cargar { margin-bottom: 18px; }

.filtros { display: flex; gap: 16px; margin-bottom: 14px; }
label.campo-filtro { flex: 0 0 auto; min-width: 200px; }
p.aviso-fila { margin: 0 0 14px; }

section.tarjeta-ancha { padding: 16px; }
.atenuado { color: var(--text-muted); }

.tabla { width: 100%; border-collapse: collapse; font-size: var(--fs-135); margin-bottom: 14px; }
.tabla th { text-align: left; font-size: 11.5px; color: var(--text-muted); font-weight: var(--fw-semibold); padding: 6px 8px; border-bottom: var(--borde-fino); }
.tabla td { padding: 4px 6px; border-bottom: var(--borde-filete); }
.tabla td.caravana { font-weight: var(--fw-semibold); white-space: nowrap; font-family: var(--font-mono); }
.tabla input, .tabla select {
  font: inherit; font-family: var(--font-ui); font-size: var(--fs-13); padding: 5px 6px; border-radius: var(--radio-sm);
  border: var(--borde-fino); background: var(--surface-field); color: var(--text-body); width: 100%; box-sizing: border-box;
}
</style>

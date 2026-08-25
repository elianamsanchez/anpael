<script setup lang="ts">
import { ref, watch } from 'vue'
import { listarRodeos, type Rodeo, type Animal } from '@/api/animales'
import { TIPOS_TRABAJO_PLANILLA } from '@/api/planillas'
import {
  animalesDelRodeo, cargarTacto, cargarPesada, cargarRevisionToros, cargarSanidad
} from '@/api/trabajos'
import type { ErrorApi } from '@/api/client'

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
    <header class="marca">
      <span class="punto"></span>
      <div>
        ANPAEL
        <small>Santa Ana · cargar resultados</small>
      </div>
    </header>

    <section class="filtros">
      <label class="campo-chico">
        <span>Rodeo</span>
        <select v-model.number="idRodeoElegido">
          <option :value="null" disabled>Elegir rodeo…</option>
          <option v-for="r in rodeos" :key="r.idRodeo" :value="r.idRodeo">{{ r.nombre }}</option>
        </select>
      </label>
      <label class="campo-chico">
        <span>Trabajo</span>
        <select v-model="tipoTrabajoElegido">
          <option :value="null" disabled>Elegir trabajo…</option>
          <option v-for="t in TIPOS_TRABAJO_PLANILLA" :key="t.valor" :value="t.valor">{{ t.etiqueta }}</option>
        </select>
      </label>
    </section>

    <p v-if="error" class="aviso-error">{{ error.mensaje }}</p>
    <p v-if="mensaje" class="aviso-ok">{{ mensaje }}</p>

    <section v-if="cargandoAnimales" class="tarjeta">
      <p class="atenuado">Consultando…</p>
    </section>

    <section v-else-if="filas.length > 0" class="tarjeta ancha">
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

        <button class="boton" type="submit" :disabled="guardando">
          {{ guardando ? 'Guardando…' : 'Guardar resultados' }}
        </button>
      </form>
    </section>

    <section v-else-if="idRodeoElegido && tipoTrabajoElegido" class="tarjeta">
      <p class="atenuado">Este rodeo no tiene animales asignados todavía.</p>
    </section>
  </main>
</template>

<style scoped>
.pantalla { max-width: 980px; margin: 6vh auto; padding: 0 16px; }
.marca { display: flex; gap: 10px; align-items: center; font-weight: 700; margin-bottom: 18px; }
.marca small { display: block; font-weight: 400; font-size: 12px; color: var(--n500); }
.punto { width: 12px; height: 12px; border-radius: 50%; background: var(--tierra); }

.filtros { display: flex; gap: 16px; margin-bottom: 14px; }
.campo-chico { display: flex; flex-direction: column; gap: 4px; font-size: 13px; color: var(--n500); }
.campo-chico select {
  font: inherit; font-size: 13.5px; padding: 8px 10px; border-radius: 8px;
  border: 1px solid var(--n200); background: #fff; color: var(--cuero); min-width: 200px;
}

.tarjeta { background: #fff; border: 1px solid var(--n200); border-radius: 10px; padding: 16px 20px; }
.ancha { padding: 16px; }
.atenuado { color: var(--n500); }

.tabla { width: 100%; border-collapse: collapse; font-size: 13.5px; margin-bottom: 14px; }
.tabla th { text-align: left; font-size: 11.5px; color: var(--n500); font-weight: 600; padding: 6px 8px; border-bottom: 1px solid var(--n200); }
.tabla td { padding: 4px 6px; border-bottom: 1px solid #EBE5DC; }
.tabla td.caravana { font-weight: 600; white-space: nowrap; }
.tabla input, .tabla select {
  font: inherit; font-size: 13px; padding: 5px 6px; border-radius: 6px;
  border: 1px solid var(--n200); background: var(--n50); color: var(--cuero); width: 100%; box-sizing: border-box;
}

.boton {
  background: var(--tierra-txt); color: #fff; border: 0;
  border-radius: 8px; padding: 9px 16px; font-weight: 600; cursor: pointer;
}
.boton:disabled { opacity: .5; cursor: not-allowed; }
.aviso-ok {
  background: #EAF3EA; border: 1px solid #BFDDBF; color: var(--ok);
  border-radius: 8px; padding: 10px; font-size: 13px; margin: 0 0 14px;
}
.aviso-error {
  background: #FBEAE6; border: 1px solid #E8B3A6; color: var(--bad);
  border-radius: 8px; padding: 10px; font-size: 13px; margin: 0 0 14px;
}
</style>

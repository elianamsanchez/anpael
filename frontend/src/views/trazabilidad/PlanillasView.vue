<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { listarRodeos, type Rodeo } from '@/api/animales'
import { generarPlanilla, TIPOS_TRABAJO_PLANILLA } from '@/api/planillas'
import type { ErrorApi } from '@/api/client'

/**
 * v0.2b · generador de planillas (docs/etapas.md): un PDF imprimible con
 * las caravanas de un rodeo y las columnas del trabajo elegido. Se abre en
 * una pestaña nueva -el navegador ya sabe imprimir un PDF-, no se fuerza
 * la descarga.
 */
const rodeos = ref<Rodeo[]>([])
const idRodeoElegido = ref<number | null>(null)
const tipoTrabajoElegido = ref<string | null>(null)
const generando = ref(false)
const error = ref<ErrorApi | null>(null)

async function cargarRodeos() {
  try {
    rodeos.value = await listarRodeos()
  } catch (e) {
    error.value = e as ErrorApi
  }
}

async function generar() {
  if (!idRodeoElegido.value || !tipoTrabajoElegido.value) return
  generando.value = true
  error.value = null
  try {
    const pdf = await generarPlanilla(idRodeoElegido.value, tipoTrabajoElegido.value)
    const url = URL.createObjectURL(pdf)
    window.open(url, '_blank')
    // Se libera despues: si se revoca antes de que la pestaña nueva termine
    // de cargar el PDF, se queda en blanco.
    setTimeout(() => URL.revokeObjectURL(url), 30000)
  } catch (e) {
    error.value = e as ErrorApi
  } finally {
    generando.value = false
  }
}

onMounted(cargarRodeos)
</script>

<template>
  <main class="pantalla">
    <header class="marca">
      <span class="punto"></span>
      <div>
        ANPAEL
        <small>Santa Ana · planillas de trabajo</small>
      </div>
    </header>

    <section class="tarjeta">
      <p class="atenuado">
        Elegí el rodeo y el trabajo: se abre un PDF con las caravanas de ese rodeo, listo para imprimir.
      </p>

      <form class="form-planilla" @submit.prevent="generar">
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

        <button class="boton" type="submit" :disabled="!idRodeoElegido || !tipoTrabajoElegido || generando">
          {{ generando ? 'Generando…' : 'Generar PDF' }}
        </button>
      </form>

      <p v-if="error" class="aviso-error">{{ error.mensaje }}</p>
    </section>
  </main>
</template>

<style scoped>
.pantalla { max-width: 620px; margin: 8vh auto; padding: 0 16px; }
.marca { display: flex; gap: 10px; align-items: center; font-weight: 700; margin-bottom: 18px; }
.marca small { display: block; font-weight: 400; font-size: 12px; color: var(--n500); }
.punto { width: 12px; height: 12px; border-radius: 50%; background: var(--tierra); }
.tarjeta { background: #fff; border: 1px solid var(--n200); border-radius: 10px; padding: 20px; }
.atenuado { color: var(--n500); font-size: 13.5px; margin: 0 0 16px; }

.form-planilla { display: flex; flex-direction: column; gap: 14px; }
.campo-chico { display: flex; flex-direction: column; gap: 4px; font-size: 13px; color: var(--n500); }
.campo-chico select {
  font: inherit; font-size: 14px; padding: 9px 10px; border-radius: 8px;
  border: 1px solid var(--n200); background: var(--n50); color: var(--cuero);
}
.boton {
  background: var(--tierra-txt); color: #fff; border: 0;
  border-radius: 8px; padding: 10px 14px; font-weight: 600; cursor: pointer;
}
.boton:disabled { opacity: .5; cursor: not-allowed; }
.aviso-error {
  background: #FBEAE6; border: 1px solid #E8B3A6; color: var(--bad);
  border-radius: 8px; padding: 10px; font-size: 13px; margin: 14px 0 0;
}
</style>

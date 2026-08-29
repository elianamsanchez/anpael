<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { listarRodeos, type Rodeo } from '@/api/animales'
import { generarPlanilla, TIPOS_TRABAJO_PLANILLA } from '@/api/planillas'
import type { ErrorApi } from '@/api/client'
import Marca from '@/components/base/Marca.vue'
import Tarjeta from '@/components/base/Tarjeta.vue'
import Campo from '@/components/formularios/Campo.vue'
import Boton from '@/components/base/Boton.vue'
import Aviso from '@/components/avisos/Aviso.vue'

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

  // window.open() tiene que pasar ACA, sincronico, dentro del handler del
  // click: es lo unico que el navegador reconoce como "el usuario pidio
  // esto" y deja pasar sin bloquear. Si se llama despues del await de
  // abajo, para el navegador ya no hay gesto de usuario -es indistinguible
  // de un popup que se abre solo- y lo bloquea en silencio, sin avisar.
  const ventana = window.open('', '_blank')

  try {
    const pdf = await generarPlanilla(idRodeoElegido.value, tipoTrabajoElegido.value)
    const url = URL.createObjectURL(pdf)
    if (ventana) {
      ventana.location.href = url
    } else {
      error.value = { estado: 0, mensaje: 'El navegador bloqueó la pestaña nueva.',
        detalle: 'Permitila desde el ícono de la barra de direcciones y probá de nuevo.' }
    }
    setTimeout(() => URL.revokeObjectURL(url), 30000)
  } catch (e) {
    ventana?.close()
    error.value = e as ErrorApi
  } finally {
    generando.value = false
  }
}

onMounted(cargarRodeos)
</script>

<template>
  <main class="pantalla">
    <RouterLink to="/" class="volver">‹ Inicio</RouterLink>

    <Marca bajada="Santa Ana · planillas de trabajo" class="marca-planillas" />

    <Tarjeta>
      <p class="atenuado intro">
        Elegí el rodeo y el trabajo: se abre un PDF con las caravanas de ese rodeo, listo para imprimir.
      </p>

      <form class="form-planilla" @submit.prevent="generar">
        <Campo
          etiqueta="Rodeo"
          :opciones="[{ valor: null, etiqueta: 'Elegir rodeo…' }, ...rodeos.map(r => ({ valor: r.idRodeo, etiqueta: r.nombre }))]"
          :valor="idRodeoElegido"
          @update:valor="idRodeoElegido = $event === '' ? null : Number($event)"
        />

        <Campo
          etiqueta="Trabajo"
          :opciones="[{ valor: null, etiqueta: 'Elegir trabajo…' }, ...TIPOS_TRABAJO_PLANILLA.map(t => ({ valor: t.valor, etiqueta: t.etiqueta }))]"
          v-model:valor="tipoTrabajoElegido"
        />

        <Boton tipo="submit" :deshabilitado="!idRodeoElegido || !tipoTrabajoElegido || generando">
          {{ generando ? 'Generando…' : 'Generar PDF' }}
        </Boton>
      </form>

      <Aviso v-if="error" tono="error" class="aviso-fila">{{ error.mensaje }}</Aviso>

      <p class="pie">
        ¿Ya trabajaste con la planilla impresa? <RouterLink to="/planillas/cargar">Cargar resultados</RouterLink>
      </p>
    </Tarjeta>
  </main>
</template>

<style scoped>
.pantalla { max-width: var(--ancho-lectura); margin: 6vh auto; padding: 0 16px; }
.volver { display: inline-block; margin-bottom: 14px; color: var(--text-muted); font-size: var(--fs-13); text-decoration: none; }
.volver:hover { text-decoration: underline; }
header.marca-planillas { margin-bottom: 18px; }
.atenuado { color: var(--text-muted); }
.intro { font-size: var(--fs-135); margin: 0 0 16px; }

.form-planilla { display: flex; flex-direction: column; gap: var(--gap-campo); }
p.aviso-fila { margin: 14px 0 0; }
.pie { font-size: var(--fs-125); color: var(--text-muted); margin: 16px 0 0; }
.pie a { color: var(--text-link); font-weight: var(--fw-semibold); }
</style>

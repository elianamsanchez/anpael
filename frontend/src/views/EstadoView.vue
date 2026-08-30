<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { getHealth, type Health } from '@/api/health'
import type { ErrorApi } from '@/api/client'
import Marca from '@/components/base/Marca.vue'
import Tarjeta from '@/components/base/Tarjeta.vue'
import Boton from '@/components/base/Boton.vue'
import Aviso from '@/components/avisos/Aviso.vue'
import ListaDatos from '@/components/datos/ListaDatos.vue'

/**
 * PANTALLA DE ESTADO  ·  el paso 3 del arranque tecnico.
 *
 * No tiene valor de negocio: prueba que el frontend habla con el backend y
 * que el backend habla con la base. Segun el documento de stack, este es el
 * paso que mas frena a quien viene de backend, y resolverlo con una pantalla
 * tonta es mucho mas barato que descubrirlo depurando el login.
 *
 * Ya no es la pantalla de inicio (esa es DashboardView) -queda como una
 * pantalla mas, para el chequeo tecnico puntual.
 */
const cargando = ref(true)
const datos = ref<Health | null>(null)
const error = ref<ErrorApi | null>(null)

async function consultar() {
  cargando.value = true
  error.value = null
  try {
    datos.value = await getHealth()
  } catch (e) {
    error.value = e as ErrorApi
    datos.value = null
  } finally {
    cargando.value = false
  }
}

onMounted(consultar)

const items = computed(() => {
  if (!datos.value) return []
  const d = datos.value
  const filas: { rotulo: string; valor: string | number; numerico?: boolean }[] = [
    { rotulo: 'Aplicación', valor: d.aplicacion },
    { rotulo: 'Base de datos', valor: d.base_de_datos }
  ]
  if (d.base) filas.push({ rotulo: 'Base', valor: d.base })
  if (d.usuarioBase) filas.push({ rotulo: 'Usuario', valor: d.usuarioBase })
  if (d.animales !== undefined) filas.push({ rotulo: 'Animales', valor: d.animales.toLocaleString('es-AR'), numerico: true })
  return filas
})
</script>

<template>
  <main class="pantalla">
    <RouterLink to="/" class="volver">‹ Inicio</RouterLink>

    <Marca bajada="Santa Ana · estado del sistema" class="marca-estado" />

    <Tarjeta class="tarjeta-estado">
      <p v-if="cargando" class="atenuado">Consultando…</p>

      <template v-else-if="error">
        <h2 class="etiqueta-mal">No responde</h2>
        <p><b>{{ error.mensaje }}</b></p>
        <p v-if="error.detalle" class="atenuado">{{ error.detalle }}</p>
        <ol class="ayuda">
          <li>¿Está levantado el backend? <code>mvn spring-boot:run</code></li>
          <li>¿Contesta directo? <code>curl http://localhost:8080/api/health</code></li>
          <li>Si contesta directo pero acá no, el proxy de <code>vite.config.ts</code>
              está mal apuntado.</li>
        </ol>
      </template>

      <template v-else-if="datos">
        <h2 :class="datos.base_de_datos === 'ok' ? 'etiqueta-ok' : 'etiqueta-mal'">
          {{ datos.base_de_datos === 'ok' ? 'Todo conectado' : 'Backend sí, base no' }}
        </h2>
        <ListaDatos :items="items" />
        <Aviso v-if="datos.detalle" tono="atencion" class="aviso-detalle">{{ datos.detalle }}</Aviso>
      </template>

      <Boton class="boton-consultar" @click="consultar" :deshabilitado="cargando">Volver a consultar</Boton>
    </Tarjeta>
  </main>
</template>

<style scoped>
.pantalla { max-width: var(--ancho-lectura); margin: 6vh auto; padding: 0 16px; }
.volver { display: inline-block; margin-bottom: 14px; color: var(--text-muted); font-size: var(--fs-13); text-decoration: none; }
.volver:hover { text-decoration: underline; }
header.marca-estado { margin-bottom: 18px; }
section.tarjeta-estado { margin: 0; }
h2 { margin: 0 0 14px; font-size: var(--fs-20); }
.etiqueta-ok { color: var(--ok); }
.etiqueta-mal { color: var(--bad); }
.atenuado { color: var(--text-muted); }
p.aviso-detalle { margin-top: 12px; }
.ayuda { font-size: var(--fs-135); color: var(--text-muted); line-height: var(--lh-loose); }
.ayuda code { background: var(--surface-sunken); padding: 1px 5px; border-radius: var(--radio-xs); }
button.boton-consultar { margin-top: 16px; }
</style>

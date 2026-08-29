<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { getHealth, type Health } from '@/api/health'
import type { ErrorApi } from '@/api/client'
import { useAuth } from '@/stores/auth'
import Marca from '@/components/base/Marca.vue'
import Tarjeta from '@/components/base/Tarjeta.vue'
import Boton from '@/components/base/Boton.vue'
import Aviso from '@/components/avisos/Aviso.vue'
import ListaDatos from '@/components/datos/ListaDatos.vue'

/**
 * PANTALLA DE ESTADO  ·  el paso 3 del arranque tecnico.
 *
 * No tiene valor de negocio y es la pantalla mas importante del proyecto en
 * este momento: prueba que el frontend habla con el backend y que el backend
 * habla con la base. Segun el documento de stack, este es el paso que mas
 * frena a quien viene de backend, y resolverlo con una pantalla tonta es
 * mucho mas barato que descubrirlo depurando el login.
 *
 * Ahora es pantalla de admin (ruta privada): quien la ve ya inicio sesion.
 */
const router = useRouter()
const auth = useAuth()
const cargando = ref(true)
const datos = ref<Health | null>(null)
const error = ref<ErrorApi | null>(null)

function salir() {
  auth.salir()
  router.replace({ name: 'login' })
}

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
    <Marca bajada="Santa Ana · estado del sistema">
      <RouterLink class="link-salir" to="/animales">Padrón</RouterLink>
      <RouterLink class="link-salir" to="/planillas">Planillas</RouterLink>
      <span class="quien" v-if="auth.usuario">{{ auth.usuario.nombre }}</span>
      <button class="link-salir link-salir--boton" @click="salir">Salir</button>
    </Marca>

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
.link-salir {
  background: none; border: 1px solid var(--border-default); color: var(--text-body);
  border-radius: var(--radio-md); padding: 6px 10px; font-size: var(--fs-13); font-weight: var(--fw-semibold);
  cursor: pointer; text-decoration: none; font-family: inherit;
}
.link-salir--boton { font: inherit; }
.quien { font-weight: var(--fw-regular); font-size: var(--fs-13); color: var(--text-muted); }
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

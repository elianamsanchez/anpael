<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { getHealth, type Health } from '@/api/health'
import type { ErrorApi } from '@/api/client'
import { useAuth } from '@/stores/auth'

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
</script>

<template>
  <main class="pantalla">
    <header class="marca">
      <span class="punto"></span>
      <div>
        ANPAEL
        <small>Santa Ana · estado del sistema</small>
      </div>
      <span class="espaciador"></span>
      <RouterLink class="salir" to="/animales">Padrón</RouterLink>
      <RouterLink class="salir" to="/planillas">Planillas</RouterLink>
      <span class="quien" v-if="auth.usuario">{{ auth.usuario.nombre }}</span>
      <button class="salir" @click="salir">Salir</button>
    </header>

    <section class="tarjeta">
      <p v-if="cargando" class="atenuado">Consultando…</p>

      <template v-else-if="error">
        <h2 class="mal">No responde</h2>
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
        <h2 :class="datos.base_de_datos === 'ok' ? 'bien' : 'mal'">
          {{ datos.base_de_datos === 'ok' ? 'Todo conectado' : 'Backend sí, base no' }}
        </h2>
        <dl>
          <div><dt>Aplicación</dt><dd>{{ datos.aplicacion }}</dd></div>
          <div><dt>Base de datos</dt><dd>{{ datos.base_de_datos }}</dd></div>
          <div v-if="datos.base"><dt>Base</dt><dd>{{ datos.base }}</dd></div>
          <div v-if="datos.usuarioBase"><dt>Usuario</dt><dd>{{ datos.usuarioBase }}</dd></div>
          <div v-if="datos.animales !== undefined">
            <dt>Animales</dt><dd class="numero">{{ datos.animales.toLocaleString('es-AR') }}</dd>
          </div>
        </dl>
        <p v-if="datos.detalle" class="aviso">{{ datos.detalle }}</p>
      </template>

      <button class="boton" @click="consultar" :disabled="cargando">Volver a consultar</button>
    </section>
  </main>
</template>

<style scoped>
.pantalla { max-width: 620px; margin: 8vh auto; padding: 0 16px; }
.marca { display: flex; gap: 10px; align-items: center; font-weight: 700; margin-bottom: 18px; }
.marca small { display: block; font-weight: 400; font-size: 12px; color: var(--n500); }
.punto { width: 12px; height: 12px; border-radius: 50%; background: var(--tierra); }
.espaciador { flex: 1; }
.quien { font-weight: 400; font-size: 13px; color: var(--n500); }
.salir {
  background: none; border: 1px solid var(--n200); color: var(--cuero);
  border-radius: 8px; padding: 6px 10px; font-size: 13px; font-weight: 600; cursor: pointer;
  text-decoration: none;
}
.tarjeta { background: #fff; border: 1px solid var(--n200); border-radius: 10px; padding: 20px; }
h2 { margin: 0 0 14px; font-size: 20px; }
.bien { color: var(--ok); }
.mal { color: var(--bad); }
dl { margin: 0; }
dl > div { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #EBE5DC; }
dt { color: var(--n500); font-size: 13px; }
dd { margin: 0; font-weight: 600; }
.numero { font-variant-numeric: tabular-nums; }
.atenuado { color: var(--n500); }
.aviso { background: #FBF1DC; border: 1px solid #E8D3A6; color: #6E4E00;
         border-radius: 8px; padding: 10px; font-size: 13px; }
.ayuda { font-size: 13.5px; color: var(--n500); line-height: 1.7; }
.ayuda code { background: var(--arena); padding: 1px 5px; border-radius: 4px; }
.boton { margin-top: 16px; background: var(--tierra-txt); color: #fff; border: 0;
         border-radius: 8px; padding: 9px 14px; font-weight: 600; cursor: pointer; }
.boton:disabled { opacity: .5; cursor: not-allowed; }
</style>

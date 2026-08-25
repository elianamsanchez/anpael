<script setup lang="ts">
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { login } from '@/api/auth'
import { useAuth } from '@/stores/auth'
import type { ErrorApi } from '@/api/client'

const router = useRouter()
const route = useRoute()
const auth = useAuth()

const usuario = ref('')
const password = ref('')
const cargando = ref(false)
const error = ref<ErrorApi | null>(null)

async function entrar() {
  cargando.value = true
  error.value = null
  try {
    const respuesta = await login(usuario.value, password.value)
    auth.entrar({ nombre: respuesta.nombre, rol: respuesta.rol }, respuesta.token)
    const destino = typeof route.query.redirect === 'string' ? route.query.redirect : '/'
    router.replace(destino)
  } catch (e) {
    error.value = e as ErrorApi
  } finally {
    cargando.value = false
  }
}
</script>

<template>
  <main class="pantalla">
    <header class="marca">
      <span class="punto"></span>
      <div>
        ANPAEL
        <small>Santa Ana · iniciar sesión</small>
      </div>
    </header>

    <section class="tarjeta">
      <form @submit.prevent="entrar">
        <label class="campo">
          <span>Usuario</span>
          <input v-model="usuario" type="text" autocomplete="username" autofocus required />
        </label>

        <label class="campo">
          <span>Contraseña</span>
          <input v-model="password" type="password" autocomplete="current-password" required />
        </label>

        <p v-if="error" class="aviso-error">{{ error.mensaje }}</p>

        <button class="boton" type="submit" :disabled="cargando">
          {{ cargando ? 'Entrando…' : 'Entrar' }}
        </button>
      </form>
    </section>
  </main>
</template>

<style scoped>
.pantalla { max-width: 380px; margin: 12vh auto; padding: 0 16px; }
.marca { display: flex; gap: 10px; align-items: center; font-weight: 700; margin-bottom: 18px; }
.marca small { display: block; font-weight: 400; font-size: 12px; color: var(--n500); }
.punto { width: 12px; height: 12px; border-radius: 50%; background: var(--tierra); }
.tarjeta { background: #fff; border: 1px solid var(--n200); border-radius: 10px; padding: 20px; }
.campo { display: flex; flex-direction: column; gap: 4px; margin-bottom: 14px; font-size: 13px; color: var(--n500); }
.campo input {
  font: inherit; color: var(--cuero); padding: 9px 10px; border-radius: 8px;
  border: 1px solid var(--n200); background: var(--n50);
}
.campo input:focus { outline: 2px solid var(--tierra); outline-offset: 1px; }
.aviso-error {
  background: #FBEAE6; border: 1px solid #E8B3A6; color: var(--bad);
  border-radius: 8px; padding: 10px; font-size: 13px; margin: 0 0 14px;
}
.boton {
  width: 100%; background: var(--tierra-txt); color: #fff; border: 0;
  border-radius: 8px; padding: 10px 14px; font-weight: 600; cursor: pointer;
}
.boton:disabled { opacity: .5; cursor: not-allowed; }
</style>

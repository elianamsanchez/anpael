<script setup lang="ts">
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { login } from '@/api/auth'
import { useAuth } from '@/stores/auth'
import type { ErrorApi } from '@/api/client'
import Marca from '@/components/base/Marca.vue'
import Tarjeta from '@/components/base/Tarjeta.vue'
import Campo from '@/components/formularios/Campo.vue'
import Boton from '@/components/base/Boton.vue'
import Aviso from '@/components/avisos/Aviso.vue'

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
    <Marca bajada="Santa Ana · iniciar sesión" class="marca-login" />

    <Tarjeta>
      <form class="form-login" @submit.prevent="entrar">
        <Campo etiqueta="Usuario" v-model:valor="usuario" autocomplete="username" autofocus requerido />
        <Campo etiqueta="Contraseña" tipo="password" v-model:valor="password" autocomplete="current-password" requerido />

        <Aviso v-if="error" tono="error">{{ error.mensaje }}</Aviso>

        <Boton tipo="submit" ancho :deshabilitado="cargando">
          {{ cargando ? 'Entrando…' : 'Entrar' }}
        </Boton>
      </form>
    </Tarjeta>
  </main>
</template>

<style scoped>
.pantalla { max-width: var(--ancho-angosto); margin: 12vh auto; padding: 0 16px; }
header.marca-login { margin-bottom: 18px; }
.form-login { display: flex; flex-direction: column; gap: var(--gap-campo); }
</style>

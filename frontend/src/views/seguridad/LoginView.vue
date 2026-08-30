<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { login } from '@/api/auth'
import { useAuth } from '@/stores/auth'
import type { ErrorApi } from '@/api/client'
import fotoCampo from '@/assets/images/login-campo.jpg'

const router = useRouter()
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
    router.replace('/')
  } catch (e) {
    error.value = e as ErrorApi
  } finally {
    cargando.value = false
  }
}
</script>

<template>
  <main class="pantalla-login">
    <section class="panel-foto" :style="{ backgroundImage: `url(${fotoCampo})` }">
      <div class="capa-oscura"></div>
      <div class="bajada-foto">
        <h2>Información que impulsa decisiones</h2>
        <p>Gestioná tu campo de manera simple, eficiente y en un solo lugar.</p>

        <ul class="funciones-foto">
          <li>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20V10M12 20V4M20 20v-7"/></svg>
            Datos en tiempo real
          </li>
          <li>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3l7 3v5c0 4.5-3 8-7 10-4-2-7-5.5-7-10V6l7-3z"/><path d="M9 12l2 2 4-4"/></svg>
            Seguro y confiable
          </li>
          <li>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M7 18a4 4 0 0 1-.6-7.96A5.5 5.5 0 0 1 17 9a4.5 4.5 0 0 1 .5 9H7z"/></svg>
            Acceso desde donde estés
          </li>
        </ul>
      </div>
    </section>

    <section class="panel-form">
      <div class="tarjeta-login">
        <span class="insignia"><span class="punto-insignia"></span></span>
        <h1>Agropecuaria Anpael</h1>
        <p class="subtitulo">Iniciá sesión para continuar</p>

        <form class="form-login" @submit.prevent="entrar">
          <label class="campo">
            <span>Usuario</span>
            <input v-model="usuario" type="text" autocomplete="username" autofocus required />
          </label>

          <label class="campo">
            <span>Contraseña</span>
            <input v-model="password" type="password" autocomplete="current-password" required />
          </label>

          <p v-if="error" class="aviso-error">{{ error.mensaje }}</p>

          <button class="boton-entrar" type="submit" :disabled="cargando">
            {{ cargando ? 'Entrando…' : 'Iniciar sesión' }}
          </button>
        </form>
      </div>
    </section>
  </main>
</template>

<style scoped>
.pantalla-login {
  --login-verde: #123B1F;
  --login-verde-hover: #0D2C17;
  --login-verde-press: #091F10;
  --login-texto: #232E3B;
  --login-texto-muted: #6B7280;
  --login-borde: #E2E5E7;
  --login-badge-bg: #EAF3EC;

  display: flex;
  min-height: 100vh;
}

/* -- panel izquierdo: la foto -- */
.panel-foto {
  position: relative;
  flex: 1 1 45%;
  min-width: 0;
  background-size: cover;
  background-position: center;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  padding: 32px;
  box-sizing: border-box;
  color: #fff;
}
.capa-oscura {
  position: absolute;
  inset: 0;
  background: linear-gradient(to top, rgba(15, 20, 12, .78) 0%, rgba(15, 20, 12, .25) 40%, rgba(15, 20, 12, 0) 65%);
}
.bajada-foto { position: relative; max-width: 460px; }
.bajada-foto h2 { margin: 0 0 8px; font-size: var(--fs-28); font-weight: var(--fw-bold); }
.bajada-foto p { margin: 0; font-size: var(--fs-15); line-height: var(--lh-normal); color: rgba(255, 255, 255, .88); }

.funciones-foto {
  display: flex; flex-wrap: wrap; gap: 20px 28px;
  list-style: none; margin: 28px 0 0; padding: 0;
}
.funciones-foto li {
  display: flex; flex-direction: column; align-items: flex-start; gap: 8px;
  font-size: var(--fs-13); color: rgba(255, 255, 255, .92); max-width: 130px;
}
.funciones-foto svg { width: 22px; height: 22px; flex-shrink: 0; }

/* -- panel derecho: el formulario -- */
.panel-form {
  flex: 1 1 55%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--surface-app);
  padding: 32px 16px;
  box-sizing: border-box;
}
.tarjeta-login {
  width: 100%;
  max-width: 400px;
  background: #fff;
  border-radius: var(--radio-lg);
  box-shadow: var(--sombra-elevada);
  padding: 40px 36px;
  box-sizing: border-box;
  text-align: center;
}
.insignia {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 48px;
  height: 48px;
  border-radius: var(--radio-md);
  background: var(--login-badge-bg);
  margin-bottom: 18px;
}
.punto-insignia { width: 12px; height: 12px; border-radius: var(--radio-circulo); background: var(--login-verde); }
h1 { margin: 0 0 6px; font-size: var(--fs-20); color: var(--login-texto); }
.subtitulo { margin: 0 0 28px; font-size: var(--fs-135); color: var(--login-texto-muted); }

.form-login { display: flex; flex-direction: column; gap: var(--gap-campo); text-align: left; }
.campo { display: flex; flex-direction: column; gap: 4px; font-size: var(--fs-13); color: var(--login-texto-muted); }
.campo input {
  font: inherit; font-family: var(--font-ui); color: var(--login-texto);
  padding: 10px 12px; border-radius: var(--radio-md); border: 1px solid var(--login-borde);
  background: #fff;
}
.campo input:focus-visible { outline: 2px solid var(--login-verde); outline-offset: 1px; }

.aviso-error {
  background: var(--bad-bg); border: 1px solid var(--bad-border); color: var(--bad-text);
  border-radius: var(--radio-md); padding: 10px; font-size: var(--fs-13); margin: 0;
}

.boton-entrar {
  width: 100%; margin-top: 6px; background: var(--login-verde); color: #fff; border: 0;
  border-radius: var(--radio-md); padding: 12px 14px; font-weight: var(--fw-semibold);
  font-size: var(--fs-14); cursor: pointer; transition: var(--transicion-boton);
}
.boton-entrar:hover:not(:disabled) { background: var(--login-verde-hover); }
.boton-entrar:active:not(:disabled) { background: var(--login-verde-press); }
.boton-entrar:disabled { opacity: .5; cursor: not-allowed; }

@media (max-width: 780px) {
  .panel-foto { display: none; }
  .panel-form { min-height: 100vh; }
}
</style>

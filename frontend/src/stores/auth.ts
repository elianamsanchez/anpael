import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { setToken } from '@/api/client'

export type Rol = 'ADMIN' | 'GERENTE' | 'OPERATIVO'

export interface Usuario {
  id: string
  nombre: string
  email: string
  rol: Rol
}

/**
 * Store de autenticacion.
 *
 * ESQUELETO: la estructura de roles esta definida desde el dia 1 aunque las
 * validaciones lleguen despues. El documento de stack lo pide asi y tiene
 * razon: agregar un modelo de permisos sobre datos ya cargados es caro.
 *
 * El token se guarda en memoria, nunca en localStorage. Ver el comentario en
 * api/client.ts.
 */
export const useAuth = defineStore('auth', () => {
  const usuario = ref<Usuario | null>(null)
  const token = ref<string | null>(null)

  const autenticado = computed(() => token.value !== null)
  const esAdmin = computed(() => usuario.value?.rol === 'ADMIN')
  const puedeAprobar = computed(() =>
    usuario.value?.rol === 'ADMIN' || usuario.value?.rol === 'GERENTE')

  function entrar(u: Usuario, t: string) {
    usuario.value = u
    token.value = t
    setToken(t)
  }

  function salir() {
    usuario.value = null
    token.value = null
    setToken(null)
  }

  return { usuario, token, autenticado, esAdmin, puedeAprobar, entrar, salir }
})

import { api } from './client'
import type { Rol } from '@/stores/auth'

export interface LoginRespuesta {
  token: string
  expiraEn: string
  nombre: string
  rol: Rol
}

export function login(usuario: string, password: string) {
  return api.post<LoginRespuesta>('/api/auth/login', { usuario, password }).then(r => r.data)
}

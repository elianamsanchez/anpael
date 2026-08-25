import { api } from './client'

export interface Health {
  aplicacion: string
  hora: string
  base_de_datos: string
  usuarioBase?: string
  base?: string
  animales?: number
  detalle?: string
}

/** El paso 3 del arranque tecnico: que el frontend consuma algo del backend. */
export function getHealth() {
  return api.get<Health>('/api/health').then(r => r.data)
}

import { api } from './client'
import type { Animal } from './animales'

export function animalesDelRodeo(idRodeo: number) {
  return api.get<Animal[]>(`/api/rodeos/${idRodeo}/animales`).then(r => r.data)
}

export interface ResumenCarga {
  mensaje: string
  idTrabajo: number
  eventosCreados: number
}

export interface LineaTacto { idAnimal: number; resultado: string; tamano?: string; observaciones?: string }
export interface LineaPesada { idAnimal: number; kilos: number }
export interface LineaRevisionToros {
  idAnimal: number
  circunferenciaEscrotal?: number
  condicionCorporal?: number
  apto: boolean
}
export interface LineaSanidad { idAnimal: number; producto: string; dosis?: number }

export function cargarTacto(idRodeo: number, resultados: LineaTacto[]) {
  return api.post<ResumenCarga>('/api/trabajos/tacto', { idRodeo, resultados }).then(r => r.data)
}

export function cargarPesada(idRodeo: number, resultados: LineaPesada[]) {
  return api.post<ResumenCarga>('/api/trabajos/pesada', { idRodeo, resultados }).then(r => r.data)
}

export function cargarRevisionToros(idRodeo: number, resultados: LineaRevisionToros[]) {
  return api.post<ResumenCarga>('/api/trabajos/revision-toros', { idRodeo, resultados }).then(r => r.data)
}

export function cargarSanidad(idRodeo: number, resultados: LineaSanidad[]) {
  return api.post<ResumenCarga>('/api/trabajos/sanidad', { idRodeo, resultados }).then(r => r.data)
}

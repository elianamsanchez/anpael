import { api } from './client'
import type { Pagina } from '@/types/comun'

/**
 * Espejo de v_animal_lista (docs/modelo-datos.md): el padron listo para
 * mostrar. Los campos nullable del backend no viajan cuando son null
 * (jackson: non_null), asi que quedan opcionales aca.
 */
export interface Animal {
  idAnimal: number
  caravana?: string
  tipoIdent?: string
  sexo: string
  raza?: string
  categoriaCodigo?: string
  categoria?: string
  fechaNacimiento?: string
  fechaNacEsEstimada: boolean
  fechaIdent?: string
  fechaIdentEsEstimada: boolean
  cuig?: string
  activo: boolean
  tieneBaja: boolean
  validacion: string
  validacionObs?: string
  revisadoEn?: string
  revisadoPor?: string
  eventos: number
  sinFechaNac: boolean
  conFechaEstimada: boolean
  sinCategoria: boolean
  rodeo?: string
  enRodeoDesde?: string
}

export interface BuscarAnimalesParams {
  caravana?: string
  sinCategoria?: boolean
  sinRodeo?: boolean
  idRodeo?: number
  idCategoria?: number
  page?: number
  size?: number
}

export function buscarAnimales(params: BuscarAnimalesParams) {
  return api.get<Pagina<Animal>>('/api/animales', { params }).then(r => r.data)
}

export function getAnimal(idAnimal: number) {
  return api.get<Animal>(`/api/animales/${idAnimal}`).then(r => r.data)
}

/** Un evento del historial del animal (v_animal_evento, docs/modelo-datos.md). */
export interface AnimalEvento {
  idEvento: number
  fecha: string
  tipoTrabajo: string
  jornada?: string
  cuig?: string
  origenDato: string
  detalle?: string
  clase: string
  comentario?: string
}

export function historialAnimal(idAnimal: number) {
  return api.get<AnimalEvento[]>(`/api/animales/${idAnimal}/historial`).then(r => r.data)
}

export interface Categoria {
  idCategoria: number
  codigo: string
  nombre: string
  sexo: string
  orden: number
}

export interface Rodeo {
  idRodeo: number
  nombre: string
}

export interface AsignacionResultado {
  mensaje: string
  animal: Animal
}

export function listarCategorias() {
  return api.get<Categoria[]>('/api/categorias').then(r => r.data)
}

export function listarRodeos() {
  return api.get<Rodeo[]>('/api/rodeos').then(r => r.data)
}

export function asignarCategoria(idAnimal: number, idCategoria: number) {
  return api.post<AsignacionResultado>(`/api/animales/${idAnimal}/categoria`, { idCategoria }).then(r => r.data)
}

export function asignarRodeo(idAnimal: number, idRodeo: number) {
  return api.post<AsignacionResultado>(`/api/animales/${idAnimal}/rodeo`, { idRodeo }).then(r => r.data)
}

export interface CausaBaja {
  idCausaBaja: number
  tipoBaja: string
  descripcion: string
}

export interface DarDeBajaParams {
  idCausaBaja: number
  fecha?: string
  fechaEsEstimada?: boolean
  pesoSalidaKg?: number
  destino?: string
  observaciones?: string
}

export function listarCausasBaja() {
  return api.get<CausaBaja[]>('/api/causas-baja').then(r => r.data)
}

export function darDeBaja(idAnimal: number, params: DarDeBajaParams) {
  return api.post<AsignacionResultado>(`/api/animales/${idAnimal}/baja`, params).then(r => r.data)
}

export interface Raza {
  idRaza: number
  nombre: string
}

export interface Pelaje {
  idPelaje: number
  nombre: string
}

export interface CorregirAnimalParams {
  idRaza?: number
  idPelaje?: number
  fechaNacimiento?: string
  fechaNacEsEstimada?: boolean
  pesoNacerKg?: number
}

export function listarRazas() {
  return api.get<Raza[]>('/api/razas').then(r => r.data)
}

export function listarPelajes() {
  return api.get<Pelaje[]>('/api/pelajes').then(r => r.data)
}

export function corregirAnimal(idAnimal: number, params: CorregirAnimalParams) {
  return api.patch<Animal>(`/api/animales/${idAnimal}`, params).then(r => r.data)
}

export interface Cabana {
  idCabana: number
  nombre: string
  contacto?: string
}

export interface Establecimiento {
  idEstablecimiento: number
  cuig: string
  nombre: string
  esPropio: boolean
  activo: boolean
}

export function listarCabanas() {
  return api.get<Cabana[]>('/api/cabanas').then(r => r.data)
}

export function listarEstablecimientos() {
  return api.get<Establecimiento[]>('/api/establecimientos').then(r => r.data)
}

export interface NuevoAnimalParams {
  caravana: string
  sexo: string
  origen: string
  idRaza?: number
  idPelaje?: number
  idCabana?: number
  idEstabOrigen?: number
  fechaNacimiento?: string
  fechaNacEsEstimada?: boolean
  pesoNacerKg?: number
  fechaIngreso?: string
  idMadre?: number
  idPadre?: number
  idCategoria?: number
  idRodeo?: number
}

export function crearAnimal(params: NuevoAnimalParams) {
  return api.post<Animal>('/api/animales', params).then(r => r.data)
}

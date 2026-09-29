import { api } from './client'

/**
 * Terneros nacidos sin caravana, por ciclo productivo (migración
 * 20260929120000). Los campos null del backend no viajan (jackson:
 * non_null), por eso los opcionales.
 */

export type Linea = 'VACA' | 'VAQ'
export type Sexo = 'M' | 'H'

export const LINEAS: { valor: Linea; etiqueta: string }[] = [
  { valor: 'VACA', etiqueta: 'Vacas' },
  { valor: 'VAQ', etiqueta: 'Vaquillonas' }
]

export interface CicloProductivo {
  idCicloProductivo: number
  codigo: string
  linea: Linea
  fechaInicio: string
  paricionDesde: string
  paricionHasta: string
  fechaFin: string
  observaciones?: string
}

export interface GuardarCiclo {
  codigo: string
  linea: Linea
  fechaInicio: string
  paricionDesde: string
  paricionHasta: string
  fechaFin: string
  observaciones?: string
}

/** Una fila de v_ternero_sin_identificar_saldo. nivel TOTAL: por sexo, o general sin sexo. */
export interface SaldoTerneros {
  nivel: 'CICLO' | 'TOTAL'
  idCicloProductivo?: number
  ciclo?: string
  linea?: Linea
  paricionDesde?: string
  fechaFin?: string
  sexo?: Sexo
  nacidos: number
  identificados: number
  muertes: number
  otrasBajas: number
  saldo: number
  cicloCerrado?: boolean
}

export type TipoMovimiento = 'NACIMIENTO' | 'IDENTIFICACION' | 'MUERTE' | 'BAJA_OTRA' | 'ANULACION'

export interface MovimientoTerneros {
  idMov: number
  idCicloProductivo: number
  ciclo: string
  linea: Linea
  cicloManual: boolean
  fechaEvento: string
  fechaEsEstimada: boolean
  fechaRegistro: string
  sexo: Sexo
  cantidad: number
  tipo: TipoMovimiento
  idMovAnulado?: number
  idTrabajo?: number
  excedeSaldo: boolean
  observaciones?: string
  registradoPor?: string
  anulado: boolean
  delta: number
}

export interface AlertasTerneros {
  ciclosCerrados: { idCicloProductivo: number; ciclo: string; linea: Linea; fechaFin: string; sexo: Sexo; saldo: number }[]
  fueraDeCiclo: {
    idMov: number; tipo: TipoMovimiento; fechaEvento: string; sexo: Sexo; cantidad: number
    ciclo: string; cicloManual: boolean; fechaInicio: string; fechaFin: string
  }[]
}

export interface RegistrarTerneros {
  fecha: string
  fechaEsEstimada?: boolean
  sexo: Sexo
  cantidad: number
  linea: Linea
  idCicloProductivo?: number
  observaciones?: string
}

// ------------------------------------------------------------------ ciclos

export function listarCiclos() {
  return api.get<CicloProductivo[]>('/api/ciclos-productivos').then(r => r.data)
}

/** El ciclo de la línea al que pertenece la fecha, o null si no cae en ninguno (204). */
export function cicloSugerido(linea: Linea, fecha: string) {
  return api.get<CicloProductivo | ''>('/api/ciclos-productivos/sugerido', { params: { linea, fecha } })
    .then(r => (r.status === 204 || !r.data ? null : r.data))
}

export function crearCiclo(ciclo: GuardarCiclo) {
  return api.post<CicloProductivo>('/api/ciclos-productivos', ciclo).then(r => r.data)
}

export function editarCiclo(idCicloProductivo: number, ciclo: GuardarCiclo) {
  return api.put<CicloProductivo>(`/api/ciclos-productivos/${idCicloProductivo}`, ciclo).then(r => r.data)
}

// ---------------------------------------------------------------- terneros

export function saldoTerneros() {
  return api.get<SaldoTerneros[]>('/api/terneros-sin-identificar/saldo').then(r => r.data)
}

export function movimientosTerneros(idCicloProductivo?: number) {
  return api.get<MovimientoTerneros[]>('/api/terneros-sin-identificar/movimientos', {
    params: idCicloProductivo ? { idCicloProductivo } : undefined
  }).then(r => r.data)
}

export function alertasTerneros() {
  return api.get<AlertasTerneros>('/api/terneros-sin-identificar/alertas').then(r => r.data)
}

export function registrarNacimiento(pedido: RegistrarTerneros) {
  return api.post<MovimientoTerneros>('/api/terneros-sin-identificar/nacimientos', pedido).then(r => r.data)
}

export function registrarBajaTerneros(pedido: RegistrarTerneros & { tipo: 'MUERTE' | 'BAJA_OTRA' }) {
  return api.post<MovimientoTerneros>('/api/terneros-sin-identificar/bajas', pedido).then(r => r.data)
}

export function anularMovimiento(idMov: number, observaciones?: string) {
  return api.post<MovimientoTerneros>(`/api/terneros-sin-identificar/movimientos/${idMov}/anulacion`,
    { observaciones }).then(r => r.data)
}

export function reasignarMovimiento(idMov: number, idCicloProductivo: number, observaciones?: string) {
  return api.post<MovimientoTerneros>(`/api/terneros-sin-identificar/movimientos/${idMov}/reasignacion`,
    { idCicloProductivo, observaciones }).then(r => r.data)
}

// ------------------------------------------------------ candidatos a torito

export interface NuevoCandidatoTorito {
  caravanaAdicional: string
  fechaNacimiento: string
  fechaNacEsEstimada?: boolean
  idMadre?: number
  idPadre?: number
  padreNombre?: string
  pesoNacerKg?: number
  idRodeo?: number
  observaciones?: string
}

export function crearCandidatoTorito(pedido: NuevoCandidatoTorito) {
  return api.post<{ idAnimal: number; mensaje: string }>('/api/animales/candidatos-torito', pedido).then(r => r.data)
}

// ------------------------------------------------ trabajo de identificación

export interface GrupoIdentificacion { idCicloProductivo: number; sexo: Sexo; caravanas: string[] }
export interface ToritoIdentificacion { idAnimal: number; caravana: string }

export interface CargarIdentificacion {
  fecha: string
  idRodeo?: number
  grupos: GrupoIdentificacion[]
  toritos: ToritoIdentificacion[]
  confirmarExcesoSaldo: boolean
  observaciones?: string
}

export interface ResumenIdentificacion {
  mensaje: string
  idTrabajo: number
  animalesCreados: number
  toritosIdentificados: number
  descuentos: { idCicloProductivo: number; ciclo: string; sexo: Sexo; cantidad: number; excedeSaldo: boolean }[]
}

export function cargarIdentificacion(pedido: CargarIdentificacion) {
  return api.post<ResumenIdentificacion>('/api/trabajos/identificacion', pedido).then(r => r.data)
}

// ------------------------------------------------------------------ formato

/** '2026-08-01' -> '01/08/2026' (es-AR), sin pasar por Date para no correr el día por zona horaria. */
export function fechaAR(iso?: string) {
  if (!iso) return '—'
  const [a, m, d] = iso.slice(0, 10).split('-')
  return `${d}/${m}/${a}`
}

export function hoyISO() {
  const h = new Date()
  const p = (n: number) => String(n).padStart(2, '0')
  return `${h.getFullYear()}-${p(h.getMonth() + 1)}-${p(h.getDate())}`
}

export const ETIQUETA_TIPO: Record<TipoMovimiento, string> = {
  NACIMIENTO: 'Nacimiento',
  IDENTIFICACION: 'Identificación',
  MUERTE: 'Muerte',
  BAJA_OTRA: 'Otra baja',
  ANULACION: 'Anulación'
}

export function sexoPlural(sexo?: Sexo) {
  return sexo === 'M' ? 'Machos' : sexo === 'H' ? 'Hembras' : 'Total'
}

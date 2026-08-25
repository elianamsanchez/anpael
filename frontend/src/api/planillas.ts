import { api } from './client'

/** Los cuatro trabajos con planilla hoy (v0.2b). Destete queda afuera: es
 * caravana de madre + caravana de cría por fila, una forma distinta. */
export const TIPOS_TRABAJO_PLANILLA = [
  { valor: 'TACTO', etiqueta: 'Tacto' },
  { valor: 'PESADA', etiqueta: 'Pesada' },
  { valor: 'REVISION_TOROS', etiqueta: 'Revisión de toros' },
  { valor: 'SANIDAD', etiqueta: 'Sanidad' }
] as const

export function generarPlanilla(idRodeo: number, tipoTrabajo: string) {
  return api
    .get('/api/planillas', { params: { idRodeo, tipoTrabajo }, responseType: 'blob' })
    .then(r => r.data as Blob)
}

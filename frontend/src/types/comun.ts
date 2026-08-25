/**
 * Tipos espejo de los DTO del backend.
 *
 * Se escriben a mano a proposito: generarlos automaticamente desde OpenAPI es
 * una herramienta mas que mantener, y con un solo desarrollador el costo de
 * tenerlos al dia a mano es menor que el de la cadena de generacion.
 */

/** Respuesta paginada, igual que Page<T> de Spring Data. */
export interface Pagina<T> {
  content: T[]
  totalElements: number
  totalPages: number
  number: number
  size: number
}

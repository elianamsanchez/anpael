// Configuración de íconos por categoría de hacienda.
// Generado a partir del set visual aprobado (14 categorías, catálogo v3).
// Clave primaria de búsqueda: idCategoria (coincide con categoria.id_categoria en la base).
// codigo se incluye como respaldo/legibilidad (coincide con categoria.codigo).

export type ColorCategoria = 'hembra' | 'macho' | 'cut'
export type TamañoIcono = 'sm' | 'md' | 'lg'
export type Cuernos = 'none' | 'buds' | 'full'
export type Especial = 'cut' | null

export interface CategoriaIconConfig {
  idCategoria: number
  codigo: string
  nombre: string
  color: ColorCategoria
  size: TamañoIcono
  cuernos: Cuernos
  /** Texto corto mostrado en la insignia inferior derecha (etapa). Opcional. */
  badge?: string
  especial?: Especial
}

export const CATEGORIA_ICONOS: CategoriaIconConfig[] = [
  // ---- Hembras ----
  { idCategoria: 6, codigo: 'TERNERA', nombre: 'Ternera', color: 'hembra', size: 'sm', cuernos: 'none' },
  { idCategoria: 7, codigo: 'VAQ12M', nombre: 'Vaquillona 12M', color: 'hembra', size: 'md', cuernos: 'none', badge: '12' },
  { idCategoria: 8, codigo: 'VAQ24M', nombre: 'Vaquillona 24M', color: 'hembra', size: 'md', cuernos: 'none', badge: '24' },
  { idCategoria: 11, codigo: 'VACA2', nombre: 'Vaca 2da', color: 'hembra', size: 'lg', cuernos: 'none', badge: '2' },
  { idCategoria: 12, codigo: 'VACA3', nombre: 'Vaca 3era', color: 'hembra', size: 'lg', cuernos: 'none', badge: '3' },
  { idCategoria: 13, codigo: 'VACA4', nombre: 'Vaca 4ta', color: 'hembra', size: 'lg', cuernos: 'none', badge: '4' },
  { idCategoria: 14, codigo: 'VACA5', nombre: 'Vaca +4', color: 'hembra', size: 'lg', cuernos: 'none', badge: '+4' },
  { idCategoria: 15, codigo: 'CUT', nombre: 'CUT', color: 'cut', size: 'lg', cuernos: 'none', badge: 'CUT', especial: 'cut' },

  // ---- Machos ----
  { idCategoria: 1, codigo: 'TERNERO', nombre: 'Ternero', color: 'macho', size: 'sm', cuernos: 'none' },
  { idCategoria: 4, codigo: 'TORITO', nombre: 'Torito', color: 'macho', size: 'md', cuernos: 'buds', badge: 'T' },
  { idCategoria: 2, codigo: 'NOVILLITO', nombre: 'Novillito', color: 'macho', size: 'md', cuernos: 'none' },
  { idCategoria: 19, codigo: 'MEJ', nombre: 'Macho Entero Joven', color: 'macho', size: 'md', cuernos: 'buds', badge: 'MEJ' },
  { idCategoria: 3, codigo: 'NOVILLO', nombre: 'Novillo', color: 'macho', size: 'lg', cuernos: 'none' },
  { idCategoria: 5, codigo: 'TORO', nombre: 'Toro', color: 'macho', size: 'lg', cuernos: 'full' },
]

export const CATEGORIA_COLORES: Record<ColorCategoria, string> = {
  hembra: '#c17f5a',
  macho: '#4f6b63',
  cut: '#8a8a82',
}

export function getCategoriaIcon(params: { idCategoria?: number; codigo?: string }): CategoriaIconConfig | undefined {
  return CATEGORIA_ICONOS.find(
    (c) =>
      (params.idCategoria !== undefined && c.idCategoria === params.idCategoria) ||
      (params.codigo !== undefined && c.codigo === params.codigo)
  )
}

import * as React from 'react';

export interface ColumnaTabla {
  clave: string;
  titulo: string;
  /** Alinea a la derecha la celda y el encabezado. */
  alDerecha?: boolean;
  /** Cifras: pasa a monoespaciada con tabular-nums. Usalo para kilos, pesos, conteos. */
  numerico?: boolean;
  render?: (fila: Record<string, any>) => React.ReactNode;
}

/**
 * Tabla del padron: encabezado gris de 12px, filete de 1px entre filas, sin cebra.
 * @startingPoint section="Datos" subtitle="Tabla del padron con encabezado y filete" viewport="700x280"
 */
export interface TablaProps {
  columnas: ColumnaTabla[];
  filas: Array<Record<string, any>>;
  /** Texto cuando no hay filas. */
  vacio?: string;
  style?: React.CSSProperties;
}

export declare function Tabla(props: TablaProps): JSX.Element;

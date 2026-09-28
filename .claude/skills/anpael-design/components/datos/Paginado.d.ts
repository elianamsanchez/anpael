import * as React from 'react';

/**
 * Paginado centrado con dos botones sobrios y el conteo en el medio.
 * @startingPoint section="Datos" subtitle="Paginado de listados" viewport="700x120"
 */
export interface PaginadoProps {
  /** Base 0, como en el backend. */
  pagina: number;
  totalPaginas: number;
  onCambio?: (pagina: number) => void;
  style?: React.CSSProperties;
}

export declare function Paginado(props: PaginadoProps): JSX.Element;

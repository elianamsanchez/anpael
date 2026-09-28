import * as React from 'react';

export interface ItemDato {
  rotulo: string;
  valor: React.ReactNode;
  /** Monoespaciada con tabular-nums: kilos, conteos, CUIG. */
  numerico?: boolean;
}

/**
 * Ficha de datos: rotulo a la izquierda en gris, valor a la derecha en semibold.
 * @startingPoint section="Datos" subtitle="Ficha rotulo/valor del detalle de animal" viewport="700x260"
 */
export interface ListaDatosProps {
  items: ItemDato[];
  style?: React.CSSProperties;
}

export declare function ListaDatos(props: ListaDatosProps): JSX.Element;

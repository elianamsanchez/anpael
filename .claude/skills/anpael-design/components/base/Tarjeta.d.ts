import * as React from 'react';

/**
 * Contenedor blanco sobre el fondo arena. Es la unica superficie del producto.
 * @startingPoint section="Base" subtitle="Tarjeta blanca con borde de 1px, radio 10" viewport="700x220"
 */
export interface TarjetaProps {
  /** Titulo opcional (15px, bold). Sin titulo la tarjeta es solo un contenedor. */
  titulo?: string;
  /** Aclaracion chica bajo el titulo, en gris. */
  nota?: string;
  /** Padding 16/20 en vez de 20 - para tarjetas que contienen una tabla. */
  denso?: boolean;
  children?: React.ReactNode;
  style?: React.CSSProperties;
}

export declare function Tarjeta(props: TarjetaProps): JSX.Element;

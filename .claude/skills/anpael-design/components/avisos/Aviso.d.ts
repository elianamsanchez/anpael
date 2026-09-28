import * as React from 'react';

/**
 * Franja de mensaje en linea. ANPAEL no usa toasts: el mensaje queda junto al formulario que lo produjo.
 * @startingPoint section="Avisos" subtitle="Mensajes en linea: ok, error, atencion, info" viewport="700x230"
 */
export interface AvisoProps {
  tono?: 'ok' | 'error' | 'atencion' | 'info';
  /** Segunda oracion del backend (campo detalle de ErrorApi), en la misma linea. */
  detalle?: string;
  children?: React.ReactNode;
  style?: React.CSSProperties;
}

export declare function Aviso(props: AvisoProps): JSX.Element;

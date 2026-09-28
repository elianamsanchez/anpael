import * as React from 'react';

/**
 * Campo de busqueda de la barra de filtros. Fondo blanco, sin etiqueta.
 * @startingPoint section="Formularios" subtitle="Busqueda por caravana de la barra de filtros" viewport="700x120"
 */
export interface BuscadorProps {
  valor?: string;
  onChange?: React.ChangeEventHandler<HTMLInputElement>;
  placeholder?: string;
  /** min-width en px. 240 por defecto. */
  ancho?: number;
  style?: React.CSSProperties;
}

export declare function Buscador(props: BuscadorProps): JSX.Element;

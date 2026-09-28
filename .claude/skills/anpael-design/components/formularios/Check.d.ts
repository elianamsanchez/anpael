import * as React from 'react';

/**
 * Casilla de verificacion con etiqueta al lado.
 * @startingPoint section="Formularios" subtitle="Casillas de filtro y de fecha estimada" viewport="700x150"
 */
export interface CheckProps {
  etiqueta?: React.ReactNode;
  marcado?: boolean;
  onChange?: React.ChangeEventHandler<HTMLInputElement>;
  deshabilitado?: boolean;
  style?: React.CSSProperties;
}

export declare function Check(props: CheckProps): JSX.Element;

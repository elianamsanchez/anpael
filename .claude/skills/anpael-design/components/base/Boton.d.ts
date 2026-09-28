import * as React from 'react';

/**
 * Boton de ANPAEL. Cuatro variantes, dos tamanos.
 * @startingPoint section="Base" subtitle="Botones: primario, acento, sobrio y de texto" viewport="700x150"
 */
export interface BotonProps {
  /** primario = accion principal (marron tierra oscuro). acento = creacion en listados. sobrio = secundaria. texto = enlace en linea. */
  variante?: 'primario' | 'acento' | 'sobrio' | 'texto';
  tamano?: 'md' | 'sm';
  /** Ocupa todo el ancho disponible (formularios de una columna, celular). */
  ancho?: boolean;
  deshabilitado?: boolean;
  tipo?: 'button' | 'submit' | 'reset';
  onClick?: React.MouseEventHandler<HTMLButtonElement>;
  children?: React.ReactNode;
  style?: React.CSSProperties;
}

export declare function Boton(props: BotonProps): JSX.Element;

import * as React from 'react';

/**
 * Marca de estado en linea: dato faltante, tipo de trabajo, activo/inactivo.
 * @startingPoint section="Base" subtitle="Etiquetas de estado y de tipo de trabajo" viewport="700x150"
 */
export interface EtiquetaProps {
  /** falta = amarillo "sin categoria". tipo = versalita naranja del historial. ok/mal = estado del animal. */
  tono?: 'falta' | 'tipo' | 'ok' | 'mal' | 'atenuado';
  /** Fondo arena y forma de pildora. Por defecto la etiqueta es solo texto de color. */
  capsula?: boolean;
  children?: React.ReactNode;
  style?: React.CSSProperties;
}

export declare function Etiqueta(props: EtiquetaProps): JSX.Element;

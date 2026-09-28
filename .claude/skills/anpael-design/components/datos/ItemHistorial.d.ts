import * as React from 'react';

/**
 * Renglon del historial de trabajos de un animal. Va dentro de un <ul> sin estilos.
 * @startingPoint section="Datos" subtitle="Renglon del historial de trabajos" viewport="700x220"
 */
export interface ItemHistorialProps {
  /** Fecha en dd/mm/aaaa, monoespaciada. */
  fecha: string;
  /** Tipo de trabajo en mayusculas: TACTO, PESADA, REVISION_TOROS, SANIDAD, DESTETE. */
  tipo: string;
  detalle?: string;
  /** Comentario del peon, se muestra entre comillas y en gris. */
  comentario?: string;
  /** Saca el filete inferior en el ultimo renglon. */
  ultimo?: boolean;
  /** Accion "Corregir" y su formulario desplegable. */
  children?: React.ReactNode;
  style?: React.CSSProperties;
}

export declare function ItemHistorial(props: ItemHistorialProps): JSX.Element;

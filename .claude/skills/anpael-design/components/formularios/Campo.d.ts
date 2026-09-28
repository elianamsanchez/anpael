import * as React from 'react';

export interface OpcionCampo {
  valor: string | number | null;
  etiqueta: string;
}

/**
 * Campo de formulario con etiqueta arriba: input, select o textarea.
 * @startingPoint section="Formularios" subtitle="Campo con etiqueta: texto, select, fecha, numero" viewport="700x260"
 */
export interface CampoProps {
  /** Texto gris de 13px sobre el control. Si el campo es requerido se le agrega un asterisco. */
  etiqueta?: string;
  /** Cualquier type de input, o textarea. Ignorado si se pasan opciones. */
  tipo?: 'text' | 'password' | 'search' | 'number' | 'date' | 'textarea';
  /** Presente = el control es un select. */
  opciones?: OpcionCampo[];
  filas?: number;
  valor?: string | number;
  onChange?: React.ChangeEventHandler<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>;
  placeholder?: string;
  requerido?: boolean;
  deshabilitado?: boolean;
  /** El control va en blanco en vez de gris claro: para campos que viven fuera de una tarjeta, sobre el fondo de la app. */
  sobreFondo?: boolean;
  style?: React.CSSProperties;
}

export declare function Campo(props: CampoProps): JSX.Element;

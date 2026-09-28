import * as React from 'react';

/**
 * Cabecera de pantalla: punto tierra + nombre + bajada de contexto.
 * @startingPoint section="Base" subtitle="Cabecera de marca con punto, titulo y bajada" viewport="700x150"
 */
export interface MarcaProps {
  /** Por defecto "ANPAEL". En pantallas de detalle se reemplaza por la caravana del animal. */
  titulo?: string;
  /** Segunda linea, 12px gris: "Santa Ana - saneamiento del padron". */
  bajada?: string;
  /** El circulo de 12px color oliva. Se ignora si logo = true. */
  punto?: boolean;
  /** Muestra el logotipo horizontal en lugar del punto + nombre. */
  logo?: boolean;
  /** Ruta al PNG del logotipo, relativa a la pagina. Por defecto assets/logo-horizontal.png */
  logoSrc?: string;
  /** Acciones alineadas a la derecha (botones, nombre de usuario). */
  children?: React.ReactNode;
  style?: React.CSSProperties;
}

export declare function Marca(props: MarcaProps): JSX.Element;

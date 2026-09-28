import React from 'react';

const paleta = {
  primario: { background: 'var(--action-primary)', color: '#fff', border: '0' },
  acento: { background: 'var(--action-accent)', color: '#fff', border: '0' },
  sobrio: { background: 'none', color: 'var(--text-body)', border: '1px solid var(--action-quiet-border)' },
  texto: { background: 'none', color: 'var(--text-link)', border: '0', textDecoration: 'underline' },
};

const medidas = {
  md: { padding: '10px 14px', fontSize: 'var(--fs-14)' },
  sm: { padding: '6px 12px', fontSize: 'var(--fs-13)' },
};

export function Boton({
  variante = 'primario',
  tamano = 'md',
  ancho = false,
  deshabilitado = false,
  tipo = 'button',
  onClick,
  children,
  style,
  ...resto
}) {
  const v = paleta[variante] || paleta.primario;
  const m = medidas[tamano] || medidas.md;
  return (
    <button
      type={tipo}
      disabled={deshabilitado}
      onClick={onClick}
      style={{
        font: 'inherit',
        fontFamily: 'var(--font-ui)',
        fontWeight: 'var(--fw-semibold)',
        borderRadius: 'var(--radio-md)',
        cursor: deshabilitado ? 'not-allowed' : 'pointer',
        transition: 'var(--transicion-boton)',
        opacity: deshabilitado ? (variante === 'sobrio' ? 0.4 : 0.5) : 1,
        width: ancho ? '100%' : undefined,
        lineHeight: 'var(--lh-snug)',
        textAlign: 'center',
        whiteSpace: 'nowrap',
        ...m,
        ...v,
        ...(variante === 'texto' ? { padding: 0 } : null),
        ...style,
      }}
      {...resto}
    >
      {children}
    </button>
  );
}

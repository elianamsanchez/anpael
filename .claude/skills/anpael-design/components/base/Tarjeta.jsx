import React from 'react';

export function Tarjeta({ titulo, nota, denso = false, children, style, ...resto }) {
  return (
    <section
      style={{
        background: 'var(--surface-card)',
        border: 'var(--borde-fino)',
        borderRadius: 'var(--radio-lg)',
        padding: denso ? 'var(--pad-tarjeta-tabla)' : 'var(--pad-tarjeta)',
        color: 'var(--text-body)',
        font: 'var(--text-base)',
        ...style,
      }}
      {...resto}
    >
      {titulo ? (
        <h3 style={{ margin: nota ? '0 0 4px' : '0 0 12px', font: 'var(--text-h3)' }}>{titulo}</h3>
      ) : null}
      {nota ? (
        <p style={{ margin: '0 0 12px', font: 'var(--text-caption)', color: 'var(--text-muted)' }}>{nota}</p>
      ) : null}
      {children}
    </section>
  );
}

import React from 'react';

export function Buscador({ valor, onChange, placeholder = 'Buscar por caravana...', ancho = 240, style, ...resto }) {
  return (
    <input
      type="search"
      value={valor}
      onChange={onChange}
      placeholder={placeholder}
      style={{
        font: 'inherit',
        fontFamily: 'var(--font-ui)',
        fontSize: 'var(--fs-14)',
        color: 'var(--text-body)',
        padding: '9px 12px',
        borderRadius: 'var(--radio-md)',
        border: 'var(--borde-fino)',
        background: 'var(--surface-card)',
        minWidth: ancho,
        ...style,
      }}
      {...resto}
    />
  );
}

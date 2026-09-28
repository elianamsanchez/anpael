import React from 'react';

export function Check({ etiqueta, marcado, onChange, deshabilitado = false, style, ...resto }) {
  return (
    <label
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: '6px',
        font: 'var(--text-label)',
        color: 'var(--text-muted)',
        cursor: deshabilitado ? 'not-allowed' : 'pointer',
        opacity: deshabilitado ? 0.5 : 1,
        ...style,
      }}
    >
      <input
        type="checkbox"
        checked={marcado}
        onChange={onChange}
        disabled={deshabilitado}
        style={{ accentColor: 'var(--pasto-700)', width: 15, height: 15, margin: 0 }}
        {...resto}
      />
      {etiqueta}
    </label>
  );
}

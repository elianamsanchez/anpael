import React from 'react';
import { Etiqueta } from '../base/Etiqueta.jsx';

export function ItemHistorial({ fecha, tipo, detalle, comentario, ultimo = false, children, style, ...resto }) {
  return (
    <li
      style={{
        padding: '10px 0',
        borderBottom: ultimo ? 'none' : 'var(--borde-filete)',
        listStyle: 'none',
        fontFamily: 'var(--font-ui)',
        ...style,
      }}
      {...resto}
    >
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', gap: 10 }}>
        <span
          style={{
            fontSize: 'var(--fs-125)',
            color: 'var(--text-muted)',
            whiteSpace: 'nowrap',
            fontFamily: 'var(--font-mono)',
          }}
        >
          {fecha}
        </span>
        <Etiqueta tono="tipo">{tipo}</Etiqueta>
      </div>
      {detalle ? <p style={{ margin: '4px 0 0', fontSize: 'var(--fs-135)' }}>{detalle}</p> : null}
      {comentario ? (
        <p style={{ margin: '4px 0 0', fontSize: 'var(--fs-135)', color: 'var(--text-muted)' }}>"{comentario}"</p>
      ) : null}
      {children}
    </li>
  );
}

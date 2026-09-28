import React from 'react';

export function ListaDatos({ items = [], style, ...resto }) {
  return (
    <dl style={{ margin: 0, fontFamily: 'var(--font-ui)', ...style }} {...resto}>
      {items.map((it, i) => (
        <div
          key={it.rotulo + i}
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            gap: 16,
            padding: '8px 0',
            borderBottom: i === items.length - 1 ? 'none' : 'var(--borde-filete)',
          }}
        >
          <dt style={{ color: 'var(--text-muted)', fontSize: 'var(--fs-13)', flexShrink: 0 }}>{it.rotulo}</dt>
          <dd
            style={{
              margin: 0,
              fontWeight: 'var(--fw-semibold)',
              fontSize: 'var(--fs-14)',
              textAlign: 'right',
              fontVariantNumeric: it.numerico ? 'tabular-nums' : undefined,
              fontFamily: it.numerico ? 'var(--font-mono)' : undefined,
            }}
          >
            {it.valor}
          </dd>
        </div>
      ))}
    </dl>
  );
}

import React from 'react';

const tonos = {
  falta: { color: 'var(--falta-text)', fontSize: 'var(--fs-125)' },
  tipo: {
    color: 'var(--text-link)',
    fontSize: 'var(--fs-11)',
    fontWeight: 'var(--fw-bold)',
    letterSpacing: 'var(--ls-caps)',
    textTransform: 'uppercase',
  },
  ok: { color: 'var(--ok)', fontSize: 'var(--fs-135)', fontWeight: 'var(--fw-semibold)' },
  mal: { color: 'var(--bad)', fontSize: 'var(--fs-135)', fontWeight: 'var(--fw-semibold)' },
  atenuado: { color: 'var(--text-muted)', fontSize: 'var(--fs-125)' },
};

export function Etiqueta({ tono = 'falta', capsula = false, children, style, ...resto }) {
  const t = tonos[tono] || tonos.falta;
  return (
    <span
      style={{
        fontFamily: 'var(--font-ui)',
        whiteSpace: 'nowrap',
        ...t,
        ...(capsula ? { background: 'var(--surface-sunken)', borderRadius: 'var(--radio-pill)', padding: '2px 8px' } : null),
        ...style,
      }}
      {...resto}
    >
      {children}
    </span>
  );
}

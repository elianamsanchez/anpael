import React from 'react';

export function Marca({ titulo = 'ANPAEL', bajada, punto = true, logo = false, logoSrc = 'assets/logo-horizontal.png', children, style, ...resto }) {
  return (
    <header
      style={{
        display: 'flex',
        gap: '10px',
        alignItems: 'center',
        fontWeight: 'var(--fw-bold)',
        fontFamily: 'var(--font-ui)',
        fontSize: 'var(--fs-16)',
        color: 'var(--text-body)',
        ...style,
      }}
      {...resto}
    >
      {logo ? (
        <img src={logoSrc} alt="ANPAEL" style={{ height: 34, width: 'auto', display: 'block', flexShrink: 0 }} />
      ) : punto ? (
        <span
          aria-hidden="true"
          style={{ width: 12, height: 12, borderRadius: 'var(--radio-circulo)', background: 'var(--pasto-700)', flexShrink: 0 }}
        />
      ) : null}
      <div>
        {logo ? null : titulo}
        {bajada ? (
          <small style={{ display: 'block', fontWeight: 'var(--fw-regular)', font: 'var(--text-caption)', color: 'var(--text-muted)' }}>
            {bajada}
          </small>
        ) : null}
      </div>
      {children ? <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: '8px' }}>{children}</div> : null}
    </header>
  );
}

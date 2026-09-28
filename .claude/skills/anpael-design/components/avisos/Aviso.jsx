import React from 'react';

const tonos = {
  ok: { background: 'var(--ok-bg)', borderColor: 'var(--ok-border)', color: 'var(--ok-text)' },
  error: { background: 'var(--bad-bg)', borderColor: 'var(--bad-border)', color: 'var(--bad-text)' },
  atencion: { background: 'var(--warn-bg)', borderColor: 'var(--warn-border)', color: 'var(--warn-text)' },
  info: { background: 'var(--info-bg)', borderColor: 'var(--info-border)', color: 'var(--info-text)' },
};

export function Aviso({ tono = 'info', detalle, children, style, ...resto }) {
  const t = tonos[tono] || tonos.info;
  return (
    <p
      role={tono === 'error' ? 'alert' : undefined}
      style={{
        borderStyle: 'solid',
        borderWidth: 1,
        borderRadius: 'var(--radio-md)',
        padding: '10px',
        fontFamily: 'var(--font-ui)',
        fontSize: 'var(--fs-13)',
        lineHeight: 'var(--lh-normal)',
        margin: 0,
        ...t,
        ...style,
      }}
      {...resto}
    >
      {children}
      {detalle ? <span style={{ opacity: 0.8 }}> {'\u2014'} {detalle}</span> : null}
    </p>
  );
}

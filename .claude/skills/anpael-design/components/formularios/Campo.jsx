import React from 'react';

const baseControl = {
  font: 'inherit',
  fontFamily: 'var(--font-ui)',
  fontSize: 'var(--fs-135)',
  color: 'var(--text-body)',
  padding: '8px 10px',
  borderRadius: 'var(--radio-md)',
  border: 'var(--borde-fino)',
  background: 'var(--surface-field)',
  width: '100%',
  boxSizing: 'border-box',
};

export function Campo({
  etiqueta,
  tipo = 'text',
  opciones,
  filas,
  valor,
  onChange,
  placeholder,
  requerido = false,
  deshabilitado = false,
  sobreFondo = false,
  style,
  ...resto
}) {
  const control0 = sobreFondo ? { ...baseControl, background: 'var(--surface-card)' } : baseControl;
  const comun = { value: valor, onChange, placeholder, required: requerido, disabled: deshabilitado, ...resto };
  let control;
  if (opciones) {
    control = (
      <select style={control0} {...comun}>
        {opciones.map((o) => (
          <option key={String(o.valor)} value={o.valor === null ? '' : o.valor}>
            {o.etiqueta}
          </option>
        ))}
      </select>
    );
  } else if (tipo === 'textarea') {
    control = <textarea rows={filas || 2} style={{ ...control0, resize: 'vertical' }} {...comun} />;
  } else {
    control = <input type={tipo} style={control0} {...comun} />;
  }
  return (
    <label
      style={{
        display: 'flex',
        flexDirection: 'column',
        gap: '4px',
        font: 'var(--text-label)',
        color: 'var(--text-muted)',
        flex: 1,
        minWidth: 160,
        ...style,
      }}
    >
      {etiqueta ? <span>{etiqueta}{requerido ? ' *' : ''}</span> : null}
      {control}
    </label>
  );
}

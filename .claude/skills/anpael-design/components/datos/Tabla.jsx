import React from 'react';

export function Tabla({ columnas = [], filas = [], vacio = 'No hay resultados.', style, ...resto }) {
  if (!filas.length) {
    return <p style={{ color: 'var(--text-muted)', font: 'var(--text-base)', margin: 0 }}>{vacio}</p>;
  }
  return (
    <table
      style={{ width: '100%', borderCollapse: 'collapse', fontFamily: 'var(--font-ui)', fontSize: 'var(--fs-14)', ...style }}
      {...resto}
    >
      <thead>
        <tr>
          {columnas.map((c) => (
            <th
              key={c.clave}
              style={{
                textAlign: c.alDerecha ? 'right' : 'left',
                fontSize: 'var(--fs-12)',
                color: 'var(--text-muted)',
                fontWeight: 'var(--fw-semibold)',
                padding: '8px 10px',
                borderBottom: 'var(--borde-fino)',
                whiteSpace: 'nowrap',
              }}
            >
              {c.titulo}
            </th>
          ))}
        </tr>
      </thead>
      <tbody>
        {filas.map((fila, i) => (
          <tr key={fila.id != null ? fila.id : i}>
            {columnas.map((c) => (
              <td
                key={c.clave}
                style={{
                  padding: '8px 10px',
                  borderBottom: 'var(--borde-filete)',
                  textAlign: c.alDerecha ? 'right' : 'left',
                  fontVariantNumeric: c.numerico ? 'tabular-nums' : undefined,
                  fontFamily: c.numerico ? 'var(--font-mono)' : undefined,
                }}
              >
                {c.render ? c.render(fila) : fila[c.clave]}
              </td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  );
}

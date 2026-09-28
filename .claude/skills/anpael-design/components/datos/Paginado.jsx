import React from 'react';
import { Boton } from '../base/Boton.jsx';

export function Paginado({ pagina = 0, totalPaginas = 1, onCambio, style, ...resto }) {
  if (totalPaginas <= 1) return null;
  return (
    <nav
      style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 16, marginTop: 16, ...style }}
      {...resto}
    >
      <Boton variante="sobrio" tamano="sm" deshabilitado={pagina === 0} onClick={() => onCambio && onCambio(pagina - 1)}>
        {'\u2039'} Anterior
      </Boton>
      <span style={{ color: 'var(--text-muted)', fontFamily: 'var(--font-ui)', fontSize: 'var(--fs-13)' }}>
        pagina {pagina + 1} de {totalPaginas}
      </span>
      <Boton
        variante="sobrio"
        tamano="sm"
        deshabilitado={pagina >= totalPaginas - 1}
        onClick={() => onCambio && onCambio(pagina + 1)}
      >
        Siguiente {'\u203A'}
      </Boton>
    </nav>
  );
}

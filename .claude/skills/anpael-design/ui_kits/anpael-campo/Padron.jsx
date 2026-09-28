const { Marca, Tarjeta, Boton, Buscador, Check, Campo, Tabla, Paginado, Etiqueta } = window.ANPAELDesignSystem_5fc50e;

function Padron({ ir }) {
  const D = window.ANPAEL_DATOS;
  const [q, setQ] = React.useState('');
  const [sinCat, setSinCat] = React.useState(false);
  const [sinRodeo, setSinRodeo] = React.useState(false);
  const [pagina, setPagina] = React.useState(0);

  const filas = D.animales.filter((a) => {
    if (q && !(a.caravana || '').includes(q)) return false;
    if (sinCat && !a.sinCategoria) return false;
    if (sinRodeo && a.rodeo) return false;
    return true;
  });

  return (
    <main style={{ maxWidth: 'var(--ancho-tabla)', margin: '6vh auto', padding: '0 16px' }}>
      <Boton variante="texto" tamano="sm" onClick={() => ir('estado')} style={{ marginBottom: 14, textDecoration: 'none', color: 'var(--text-muted)' }}>‹ Inicio</Boton>
      <Marca logo logoSrc="../../assets/logo-horizontal.png" bajada="Santa Ana · saneamiento del padrón" style={{ marginBottom: 18 }}>
        <Boton variante="acento" tamano="sm" onClick={() => ir('nuevo')}>+ Nuevo animal</Boton>
      </Marca>

      <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 12, flexWrap: 'wrap' }}>
        <Buscador valor={q} onChange={(e) => { setQ(e.target.value); setPagina(0); }} />
        <Check etiqueta="Sin categoría" marcado={sinCat} onChange={(e) => setSinCat(e.target.checked)} />
        <Check etiqueta="Sin rodeo" marcado={sinRodeo} onChange={(e) => setSinRodeo(e.target.checked)} />
        <Campo style={{ flex: '0 0 auto', minWidth: 170 }} sobreFondo opciones={[{ valor: '', etiqueta: 'Todos los rodeos' }].concat(D.rodeos.map((r) => ({ valor: r.idRodeo, etiqueta: r.nombre })))} onChange={() => {}} />
        <Campo sobreFondo style={{ flex: '0 0 auto', minWidth: 170 }} opciones={[{ valor: '', etiqueta: 'Todas las categorías' }].concat(D.categorias.map((c) => ({ valor: c.idCategoria, etiqueta: c.nombre })))} onChange={() => {}} />
        <span style={{ marginLeft: 'auto', font: 'var(--text-label)', color: 'var(--text-muted)' }}>{filas.length.toLocaleString('es-AR')} animales</span>
      </div>

      <Tarjeta denso>
        <Tabla
          vacio="No hay animales que coincidan con la búsqueda."
          columnas={[
            { clave: 'caravana', titulo: 'Caravana', numerico: true, render: (a) => (
              <a href="#" onClick={(e) => { e.preventDefault(); ir('animal', a.idAnimal); }} style={{ color: 'var(--text-link)', fontWeight: 'var(--fw-semibold)', textDecoration: 'none' }}>{a.caravana}</a>
            ) },
            { clave: 'sexo', titulo: 'Sexo' },
            { clave: 'raza', titulo: 'Raza', render: (a) => a.raza || '—' },
            { clave: 'categoria', titulo: 'Categoría', render: (a) => (a.sinCategoria ? <Etiqueta tono="falta">sin categoría</Etiqueta> : a.categoria) },
            { clave: 'rodeo', titulo: 'Rodeo', render: (a) => (a.rodeo ? a.rodeo : <Etiqueta tono="falta">sin rodeo</Etiqueta>) },
            { clave: 'validacion', titulo: 'Validación' },
          ]}
          filas={filas.map((a) => Object.assign({ id: a.idAnimal }, a))}
        />
        <Paginado pagina={pagina} totalPaginas={58} onCambio={setPagina} />
      </Tarjeta>
    </main>
  );
}
window.Padron = Padron;

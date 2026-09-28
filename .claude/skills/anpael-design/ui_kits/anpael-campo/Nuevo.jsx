const { Marca, Tarjeta, Boton, Campo, Check } = window.ANPAELDesignSystem_5fc50e;

function Nuevo({ ir }) {
  const D = window.ANPAEL_DATOS;
  const [origen, setOrigen] = React.useState('NACIDO');
  const [caravana, setCaravana] = React.useState('');
  const [sexo, setSexo] = React.useState('');

  return (
    <main style={{ maxWidth: 'var(--ancho-forma)', margin: '6vh auto', padding: '0 16px' }}>
      <nav style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
        <Boton variante="texto" tamano="sm" onClick={() => ir('estado')} style={{ textDecoration: 'none', color: 'var(--text-muted)' }}>‹ Inicio</Boton>
        <span style={{ color: 'var(--text-muted)' }}>·</span>
        <Boton variante="texto" tamano="sm" onClick={() => ir('padron')} style={{ textDecoration: 'none', color: 'var(--text-muted)' }}>Volver al padrón</Boton>
      </nav>
      <Marca titulo="Nuevo animal" bajada="Alta con identificación visual en Santa Ana" style={{ marginBottom: 18 }} />
      <Tarjeta>
        <form onSubmit={(e) => { e.preventDefault(); ir('padron'); }} style={{ display: 'grid', gap: 14 }}>
          <div style={{ display: 'flex', gap: 14, flexWrap: 'wrap' }}>
            <Campo etiqueta="Caravana" requerido placeholder="Ej: 0075" valor={caravana} onChange={(e) => setCaravana(e.target.value)} />
            <Campo etiqueta="Sexo" requerido valor={sexo} onChange={(e) => setSexo(e.target.value)}
              opciones={[{ valor: '', etiqueta: 'Elegir…' }, { valor: 'H', etiqueta: 'Hembra' }, { valor: 'M', etiqueta: 'Macho' }]} />
          </div>
          <div style={{ display: 'flex', gap: 14, flexWrap: 'wrap' }}>
            <Campo etiqueta="Origen" requerido valor={origen} onChange={(e) => setOrigen(e.target.value)}
              opciones={[{ valor: 'NACIDO', etiqueta: 'Nacido en el campo' }, { valor: 'COMPRADO', etiqueta: 'Comprado' }, { valor: 'RECIBIDO', etiqueta: 'Recibido' }]} />
            {origen === 'COMPRADO' ? (
              <Campo etiqueta="Cabaña de origen" opciones={[{ valor: '', etiqueta: '(sin especificar)' }, { valor: 1, etiqueta: 'La Invernada' }]} onChange={() => {}} />
            ) : null}
            {origen !== 'NACIDO' ? (
              <Campo etiqueta="Establecimiento de origen" opciones={[{ valor: '', etiqueta: '(sin especificar)' }, { valor: 1, etiqueta: 'Santa Ana (AB123)' }]} onChange={() => {}} />
            ) : null}
          </div>
          <div style={{ display: 'flex', gap: 14, flexWrap: 'wrap' }}>
            <Campo etiqueta="Raza" opciones={[{ valor: '', etiqueta: '(sin especificar)' }, { valor: 1, etiqueta: 'Angus' }, { valor: 2, etiqueta: 'Braford' }]} onChange={() => {}} />
            <Campo etiqueta="Pelaje" opciones={[{ valor: '', etiqueta: '(sin especificar)' }, { valor: 1, etiqueta: 'Negro' }, { valor: 2, etiqueta: 'Colorado' }]} onChange={() => {}} />
          </div>
          <div style={{ display: 'flex', gap: 14, flexWrap: 'wrap', alignItems: 'flex-end' }}>
            <Campo etiqueta="Fecha de nacimiento" tipo="date" onChange={() => {}} />
            <Check etiqueta="Es estimada" marcado={false} onChange={() => {}} style={{ paddingBottom: 9, flex: '0 0 auto', minWidth: 0 }} />
            <Campo etiqueta="Peso al nacer (kg)" tipo="number" placeholder="10 a 70" onChange={() => {}} />
          </div>
          <div style={{ display: 'flex', gap: 14, flexWrap: 'wrap' }}>
            <Campo etiqueta="Categoría" opciones={[{ valor: '', etiqueta: '(sin asignar)' }].concat(D.categorias.map((c) => ({ valor: c.idCategoria, etiqueta: c.nombre })))} onChange={() => {}} />
            <Campo etiqueta="Rodeo" opciones={[{ valor: '', etiqueta: '(sin asignar)' }].concat(D.rodeos.map((r) => ({ valor: r.idRodeo, etiqueta: r.nombre })))} onChange={() => {}} />
          </div>
          <Boton variante="acento" tipo="submit" deshabilitado={!caravana || !sexo} style={{ justifySelf: 'start' }}>Dar de alta</Boton>
        </form>
      </Tarjeta>
    </main>
  );
}
window.Nuevo = Nuevo;

const { Marca, Tarjeta, Boton, Campo, Aviso } = window.ANPAELDesignSystem_5fc50e;

function Cargar({ ir }) {
  const D = window.ANPAEL_DATOS;
  const [rodeo, setRodeo] = React.useState('1');
  const [trabajo, setTrabajo] = React.useState('TACTO');
  const [valores, setValores] = React.useState({});
  const [guardado, setGuardado] = React.useState(null);
  const filas = D.animales.slice(0, 4);
  const cargadas = Object.values(valores).filter(Boolean).length;

  return (
    <main style={{ maxWidth: 'var(--ancho-forma)', margin: '6vh auto', padding: '0 16px' }}>
      <Boton variante="texto" tamano="sm" onClick={() => ir('planillas')} style={{ marginBottom: 14, textDecoration: 'none', color: 'var(--text-muted)' }}>‹ Planillas</Boton>
      <Marca bajada="Santa Ana · cargar resultados" style={{ marginBottom: 18 }} />
      <div style={{ display: 'flex', gap: 14, marginBottom: 12, flexWrap: 'wrap' }}>
        <Campo etiqueta="Rodeo" valor={rodeo} onChange={(e) => setRodeo(e.target.value)}
          opciones={D.rodeos.map((r) => ({ valor: r.idRodeo, etiqueta: r.nombre }))} />
        <Campo etiqueta="Trabajo" valor={trabajo} onChange={(e) => setTrabajo(e.target.value)}
          opciones={D.trabajos.map((t) => ({ valor: t.valor, etiqueta: t.etiqueta }))} />
      </div>
      <Tarjeta denso>
        <p style={{ font: 'var(--text-caption)', color: 'var(--text-muted)', margin: '0 0 12px' }}>
          Mismo orden que el PDF impreso. Dejá en blanco los animales que no trabajaste.
        </p>
        <div style={{ display: 'grid', gap: 8 }}>
          {filas.map((a) => (
            <div key={a.idAnimal} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '8px 0', borderBottom: 'var(--borde-filete)' }}>
              <span style={{ font: 'var(--text-dato)', fontVariantNumeric: 'tabular-nums', width: 64 }}>{a.caravana}</span>
              {trabajo === 'PESADA' ? (
                <Campo tipo="number" placeholder="Kilos" valor={valores[a.idAnimal] || ''} onChange={(e) => setValores(Object.assign({}, valores, { [a.idAnimal]: e.target.value }))} />
              ) : (
                <Campo valor={valores[a.idAnimal] || ''} onChange={(e) => setValores(Object.assign({}, valores, { [a.idAnimal]: e.target.value }))}
                  opciones={[{ valor: '', etiqueta: 'Resultado…' }, { valor: 'PRENADA', etiqueta: 'Preñada' }, { valor: 'VACIA', etiqueta: 'Vacía' }, { valor: 'DUDOSA', etiqueta: 'Dudosa' }]} />
              )}
            </div>
          ))}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginTop: 14 }}>
          <Boton deshabilitado={cargadas === 0} onClick={() => setGuardado(cargadas)}>Guardar {cargadas > 0 ? '(' + cargadas + ')' : ''}</Boton>
          {guardado ? <Aviso tono="ok" style={{ flex: 1 }}>Se registraron {guardado} resultados.</Aviso> : null}
        </div>
      </Tarjeta>
    </main>
  );
}
window.Cargar = Cargar;

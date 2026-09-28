const { Marca, Tarjeta, Boton, Campo, Tabla, Aviso } = window.ANPAELDesignSystem_5fc50e;

function Planillas({ ir }) {
  const D = window.ANPAEL_DATOS;
  const [rodeo, setRodeo] = React.useState('');
  const [trabajo, setTrabajo] = React.useState('');
  const [generado, setGenerado] = React.useState(false);

  return (
    <main style={{ maxWidth: 'var(--ancho-lectura)', margin: '8vh auto', padding: '0 16px' }}>
      <Boton variante="texto" tamano="sm" onClick={() => ir('estado')} style={{ marginBottom: 14, textDecoration: 'none', color: 'var(--text-muted)' }}>‹ Inicio</Boton>
      <Marca bajada="Santa Ana · planillas de trabajo" style={{ marginBottom: 18 }} />
      <Tarjeta>
        <p style={{ color: 'var(--text-muted)', font: 'var(--text-small)', margin: '0 0 16px' }}>
          Elegí el rodeo y el trabajo: se abre un PDF con las caravanas de ese rodeo, listo para imprimir.
        </p>
        <form onSubmit={(e) => { e.preventDefault(); setGenerado(true); }} style={{ display: 'grid', gap: 14 }}>
          <Campo etiqueta="Rodeo" valor={rodeo} onChange={(e) => { setRodeo(e.target.value); setGenerado(false); }}
            opciones={[{ valor: '', etiqueta: 'Elegir rodeo…' }].concat(D.rodeos.map((r) => ({ valor: r.idRodeo, etiqueta: r.nombre })))} />
          <Campo etiqueta="Trabajo" valor={trabajo} onChange={(e) => { setTrabajo(e.target.value); setGenerado(false); }}
            opciones={[{ valor: '', etiqueta: 'Elegir trabajo…' }].concat(D.trabajos.map((t) => ({ valor: t.valor, etiqueta: t.etiqueta })))} />
          <Boton tipo="submit" deshabilitado={!rodeo || !trabajo} style={{ justifySelf: 'start' }}>Generar PDF</Boton>
        </form>
        {generado ? (
          <div style={{ marginTop: 16, display: 'grid', gap: 12 }}>
            <Aviso tono="ok">La planilla se abrió en una pestaña nueva.</Aviso>
            <div style={{ border: 'var(--borde-fino)', borderRadius: 'var(--radio-md)', padding: 14, background: 'var(--n25)' }}>
              <div style={{ font: 'var(--text-eyebrow)', letterSpacing: 'var(--ls-caps)', color: 'var(--text-muted)', marginBottom: 10 }}>VISTA PREVIA DE LA PLANILLA</div>
              <Tabla columnas={[
                { clave: 'caravana', titulo: 'Caravana', numerico: true },
                { clave: 'r', titulo: 'Resultado' },
                { clave: 't', titulo: 'Tamaño' },
                { clave: 'o', titulo: 'Observaciones' },
              ]} filas={[
                { id: 1, caravana: '0075', r: '', t: '', o: '' },
                { id: 2, caravana: '0344', r: '', t: '', o: '' },
                { id: 3, caravana: '0902', r: '', t: '', o: '' },
                { id: 4, caravana: '', r: '', t: '', o: '' },
              ]} />
            </div>
          </div>
        ) : null}
        <p style={{ font: 'var(--text-caption)', color: 'var(--text-muted)', margin: '16px 0 0' }}>
          ¿Ya trabajaste con la planilla impresa?{' '}
          <a href="#" onClick={(e) => { e.preventDefault(); ir('cargar'); }} style={{ color: 'var(--text-link)', fontWeight: 'var(--fw-semibold)' }}>Cargar resultados</a>
        </p>
      </Tarjeta>
    </main>
  );
}
window.Planillas = Planillas;

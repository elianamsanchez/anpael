const { Marca, Tarjeta, Boton, Campo, Check, ListaDatos, ItemHistorial, Etiqueta, Aviso } = window.ANPAELDesignSystem_5fc50e;

function Animal({ idAnimal, ir }) {
  const D = window.ANPAEL_DATOS;
  const base = D.animales.find((a) => a.idAnimal === idAnimal) || D.animales[0];
  const [animal, setAnimal] = React.useState(base);
  const [rodeoElegido, setRodeoElegido] = React.useState('');
  const [msgRodeo, setMsgRodeo] = React.useState(null);
  const eventos = D.historial[animal.idAnimal] || [];

  function asignarRodeo(e) {
    e.preventDefault();
    if (!rodeoElegido) return;
    const r = D.rodeos.find((x) => String(x.idRodeo) === String(rodeoElegido));
    setAnimal(Object.assign({}, animal, { rodeo: r.nombre }));
    setMsgRodeo('Rodeo asignado: ' + r.nombre + '.');
  }

  return (
    <main style={{ maxWidth: 'var(--ancho-lectura)', margin: '6vh auto', padding: '0 16px', display: 'grid', gap: 16 }}>
      <nav style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <Boton variante="texto" tamano="sm" onClick={() => ir('estado')} style={{ textDecoration: 'none', color: 'var(--text-muted)' }}>‹ Inicio</Boton>
        <span style={{ color: 'var(--text-muted)' }}>·</span>
        <Boton variante="texto" tamano="sm" onClick={() => ir('padron')} style={{ textDecoration: 'none', color: 'var(--text-muted)' }}>Volver al padrón</Boton>
      </nav>

      <Marca titulo={animal.caravana} bajada={'VISUAL · ' + (animal.sexo === 'M' ? 'macho' : 'hembra')} />

      <Tarjeta>
        <ListaDatos items={[
          { rotulo: 'Raza', valor: animal.raza || '—' },
          { rotulo: 'Categoría', valor: animal.sinCategoria ? <Etiqueta tono="falta">sin asignar</Etiqueta> : animal.categoria },
          { rotulo: 'Rodeo', valor: animal.rodeo ? animal.rodeo : <Etiqueta tono="falta">sin asignar</Etiqueta> },
          { rotulo: 'Fecha de nacimiento', valor: '12/09/2023' },
          { rotulo: 'Establecimiento (CUIG)', valor: 'AB123', numerico: true },
          { rotulo: 'Estado', valor: <Etiqueta tono="ok">activo</Etiqueta> },
          { rotulo: 'Eventos registrados', valor: String(eventos.length), numerico: true },
          { rotulo: 'Validación del saneamiento', valor: animal.validacion },
        ]} />
        <form onSubmit={asignarRodeo} style={{ display: 'flex', gap: 8, marginTop: 14, alignItems: 'flex-end' }}>
          <Campo etiqueta="Asignar rodeo" valor={rodeoElegido} onChange={(e) => setRodeoElegido(e.target.value)}
            opciones={[{ valor: '', etiqueta: 'Asignar rodeo…' }].concat(D.rodeos.map((r) => ({ valor: r.idRodeo, etiqueta: r.nombre })))} />
          <Boton variante="sobrio" tamano="sm" tipo="submit" deshabilitado={!rodeoElegido} style={{ marginBottom: 1 }}>Asignar</Boton>
        </form>
        {msgRodeo ? <div style={{ marginTop: 8 }}><Aviso tono="ok">{msgRodeo}</Aviso></div> : null}
      </Tarjeta>

      <Tarjeta titulo="Historial de trabajos">
        {eventos.length === 0 ? (
          <p style={{ color: 'var(--text-muted)', margin: 0 }}>Sin eventos registrados todavía.</p>
        ) : (
          <ul style={{ margin: 0, padding: 0 }}>
            {eventos.map((ev, i) => (
              <ItemHistorial key={ev.idEvento} fecha={ev.fecha} tipo={ev.tipoTrabajo} detalle={ev.detalle}
                comentario={ev.comentario} ultimo={i === eventos.length - 1}>
                <Boton variante="texto" tamano="sm" style={{ fontSize: 'var(--fs-12)', paddingTop: 6 }}>Corregir</Boton>
              </ItemHistorial>
            ))}
          </ul>
        )}
      </Tarjeta>

      <Tarjeta titulo="Corregir / completar datos" nota="Dejá en blanco lo que no quieras cambiar.">
        <div style={{ display: 'grid', gap: 10 }}>
          <Campo etiqueta="Raza" opciones={[{ valor: '', etiqueta: '(sin cambios)' }, { valor: 1, etiqueta: 'Angus' }, { valor: 2, etiqueta: 'Braford' }, { valor: 3, etiqueta: 'Hereford' }]} onChange={() => {}} />
          <Campo etiqueta="Fecha de nacimiento" tipo="date" onChange={() => {}} />
          <Check etiqueta="Es estimada" marcado={false} onChange={() => {}} />
          <Campo etiqueta="Peso al nacer (kg)" tipo="number" placeholder="10 a 70" onChange={() => {}} />
          <Boton variante="sobrio" tamano="sm" style={{ justifySelf: 'start' }}>Guardar cambios</Boton>
        </div>
      </Tarjeta>

      <Tarjeta titulo="Dar de baja">
        <div style={{ display: 'grid', gap: 8 }}>
          <Campo opciones={[{ valor: '', etiqueta: 'Causa…' }, { valor: 1, etiqueta: 'VENTA · vendido en remate' }, { valor: 2, etiqueta: 'MUERTE · muerte en el campo' }, { valor: 3, etiqueta: 'REGULARIZACION · regularización inicial' }]} onChange={() => {}} />
          <Check etiqueta="La fecha es estimada (hoy, no el día real en que salió el animal)" marcado={false} onChange={() => {}} />
          <Campo placeholder="Destino (opcional)" onChange={() => {}} />
          <Campo tipo="textarea" placeholder="Observaciones (opcional)" onChange={() => {}} />
          <Boton variante="sobrio" tamano="sm" style={{ justifySelf: 'start' }}>Registrar baja</Boton>
        </div>
      </Tarjeta>
    </main>
  );
}
window.Animal = Animal;

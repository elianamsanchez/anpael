const { Marca, Tarjeta, Boton, ListaDatos, Aviso } = window.ANPAELDesignSystem_5fc50e;

function Estado({ usuario, ir, salir }) {
  return (
    <main style={{ maxWidth: 'var(--ancho-lectura)', margin: '8vh auto', padding: '0 16px' }}>
      <Marca logo logoSrc="../../assets/logo-horizontal.png" bajada="Santa Ana · estado del sistema" style={{ marginBottom: 18 }}>
        <Boton variante="sobrio" tamano="sm" onClick={() => ir('padron')}>Padrón</Boton>
        <Boton variante="sobrio" tamano="sm" onClick={() => ir('planillas')}>Planillas</Boton>
        <span style={{ font: 'var(--text-label)', color: 'var(--text-muted)' }}>{usuario}</span>
        <Boton variante="sobrio" tamano="sm" onClick={salir}>Salir</Boton>
      </Marca>
      <Tarjeta>
        <h2 style={{ margin: '0 0 14px', font: 'var(--text-h2)', color: 'var(--ok)' }}>Todo conectado</h2>
        <ListaDatos items={[
          { rotulo: 'Aplicación', valor: 'anpael' },
          { rotulo: 'Entorno', valor: 'local' },
          { rotulo: 'Base de datos', valor: 'ok' },
          { rotulo: 'Usuario', valor: 'postgres' },
          { rotulo: 'Animales', valor: '1.732', numerico: true },
          { rotulo: 'Eventos', valor: '3.164', numerico: true },
        ]} />
        <div style={{ marginTop: 16 }}><Boton>Volver a consultar</Boton></div>
      </Tarjeta>
      <div style={{ marginTop: 16 }}>
        <Aviso tono="atencion">El Supabase local tiene un dump de producción: el conteo no prueba a qué base te conectaste. Mirá siempre <b>entorno</b>.</Aviso>
      </div>
    </main>
  );
}
window.Estado = Estado;

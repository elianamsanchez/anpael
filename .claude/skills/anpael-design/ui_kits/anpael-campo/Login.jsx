const { Marca, Tarjeta, Boton, Campo, Aviso } = window.ANPAELDesignSystem_5fc50e;

function Login({ onEntrar }) {
  const [usuario, setUsuario] = React.useState('');
  const [password, setPassword] = React.useState('');
  const [cargando, setCargando] = React.useState(false);
  const [error, setError] = React.useState(null);

  function entrar(e) {
    e.preventDefault();
    if (!usuario || !password) { setError('Usuario o contraseña incorrectos.'); return; }
    setCargando(true);
    setTimeout(() => { setCargando(false); onEntrar(usuario); }, 500);
  }

  return (
    <main style={{ maxWidth: 'var(--ancho-angosto)', margin: '12vh auto', padding: '0 16px' }}>
      <Marca logo logoSrc="../../assets/logo-horizontal.png" bajada="Santa Ana · iniciar sesión" style={{ marginBottom: 22 }} />
      <Tarjeta>
        <form onSubmit={entrar}>
          <div style={{ display: 'grid', gap: 'var(--gap-campo)', marginBottom: 14 }}>
            <Campo etiqueta="Usuario" valor={usuario} onChange={(e) => setUsuario(e.target.value)} autoComplete="username" />
            <Campo etiqueta="Contraseña" tipo="password" valor={password} onChange={(e) => setPassword(e.target.value)} autoComplete="current-password" />
          </div>
          {error ? <div style={{ marginBottom: 14 }}><Aviso tono="error">{error}</Aviso></div> : null}
          <Boton tipo="submit" ancho deshabilitado={cargando}>{cargando ? 'Entrando…' : 'Entrar'}</Boton>
        </form>
      </Tarjeta>
    </main>
  );
}
window.Login = Login;

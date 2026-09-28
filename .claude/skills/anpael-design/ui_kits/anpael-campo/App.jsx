function App() {
  const [pantalla, setPantalla] = React.useState('login');
  const [usuario, setUsuario] = React.useState(null);
  const [idAnimal, setIdAnimal] = React.useState(101);

  function ir(p, id) {
    if (id != null) setIdAnimal(id);
    setPantalla(p);
  }

  if (!usuario) return <window.Login onEntrar={(u) => { setUsuario(u); setPantalla('estado'); }} />;
  if (pantalla === 'padron') return <window.Padron ir={ir} />;
  if (pantalla === 'animal') return <window.Animal idAnimal={idAnimal} ir={ir} />;
  if (pantalla === 'nuevo') return <window.Nuevo ir={ir} />;
  if (pantalla === 'planillas') return <window.Planillas ir={ir} />;
  if (pantalla === 'cargar') return <window.Cargar ir={ir} />;
  return <window.Estado usuario={usuario} ir={ir} salir={() => { setUsuario(null); setPantalla('login'); }} />;
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);

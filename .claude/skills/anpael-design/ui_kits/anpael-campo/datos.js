// Datos falsos con la forma real de la API (frontend/src/api/animales.ts).
window.ANPAEL_DATOS = (function () {
  const rodeos = [
    { idRodeo: 1, nombre: 'Rodeo 1 - Vacas CUT' },
    { idRodeo: 2, nombre: 'Rodeo 2 - Vaquillonas' },
    { idRodeo: 3, nombre: 'Rodeo 3 - Toros' },
    { idRodeo: 4, nombre: 'Rodeo 4 - Destete' },
  ];
  const categorias = [
    { idCategoria: 1, nombre: 'Vaca' },
    { idCategoria: 2, nombre: 'Vaquillona' },
    { idCategoria: 3, nombre: 'Toro' },
    { idCategoria: 4, nombre: 'Ternero' },
  ];
  const animales = [
    { idAnimal: 101, caravana: '0075', sexo: 'H', raza: 'Angus', categoria: 'Vaquillona', sinCategoria: false, rodeo: null, validacion: 'pendiente' },
    { idAnimal: 102, caravana: '0112', sexo: 'M', raza: 'Braford', categoria: null, sinCategoria: true, rodeo: 'Rodeo 3 - Toros', validacion: 'pendiente' },
    { idAnimal: 103, caravana: '0344', sexo: 'H', raza: 'Angus', categoria: 'Vaca', sinCategoria: false, rodeo: 'Rodeo 1 - Vacas CUT', validacion: 'ok' },
    { idAnimal: 104, caravana: '0501', sexo: 'H', raza: null, categoria: null, sinCategoria: true, rodeo: null, validacion: 'pendiente' },
    { idAnimal: 105, caravana: '0718', sexo: 'M', raza: 'Hereford', categoria: 'Ternero', sinCategoria: false, rodeo: 'Rodeo 4 - Destete', validacion: 'ok' },
    { idAnimal: 106, caravana: '0902', sexo: 'H', raza: 'Angus', categoria: 'Vaca', sinCategoria: false, rodeo: null, validacion: 'pendiente' },
  ];
  const historial = {
    101: [
      { idEvento: 9001, fecha: '14/03/2026', tipoTrabajo: 'TACTO', detalle: 'Prenada - mediana', comentario: null },
      { idEvento: 9002, fecha: '02/02/2026', tipoTrabajo: 'PESADA', detalle: '412,5 kg', comentario: 'pesada en la manga chica' },
      { idEvento: 9003, fecha: '11/11/2025', tipoTrabajo: 'SANIDAD', detalle: 'Ivermectina - 12 ml', comentario: null },
    ],
    102: [
      { idEvento: 9101, fecha: '20/02/2026', tipoTrabajo: 'REVISION_TOROS', detalle: 'CE 36,5 cm - CC 3,5 - apto', comentario: null },
    ],
  };
  const trabajos = [
    { valor: 'TACTO', etiqueta: 'Tacto' },
    { valor: 'PESADA', etiqueta: 'Pesada' },
    { valor: 'REVISION_TOROS', etiqueta: 'Revision de toros' },
    { valor: 'SANIDAD', etiqueta: 'Sanidad' },
    { valor: 'DESTETE', etiqueta: 'Destete' },
  ];
  return { rodeos, categorias, animales, historial, trabajos };
})();

/* @ds-bundle: {"format":4,"namespace":"ANPAELDesignSystem_5fc50e","components":[{"name":"Aviso","sourcePath":"components/avisos/Aviso.jsx"},{"name":"Boton","sourcePath":"components/base/Boton.jsx"},{"name":"Etiqueta","sourcePath":"components/base/Etiqueta.jsx"},{"name":"Marca","sourcePath":"components/base/Marca.jsx"},{"name":"Tarjeta","sourcePath":"components/base/Tarjeta.jsx"},{"name":"ItemHistorial","sourcePath":"components/datos/ItemHistorial.jsx"},{"name":"ListaDatos","sourcePath":"components/datos/ListaDatos.jsx"},{"name":"Paginado","sourcePath":"components/datos/Paginado.jsx"},{"name":"Tabla","sourcePath":"components/datos/Tabla.jsx"},{"name":"Buscador","sourcePath":"components/formularios/Buscador.jsx"},{"name":"Campo","sourcePath":"components/formularios/Campo.jsx"},{"name":"Check","sourcePath":"components/formularios/Check.jsx"}],"sourceHashes":{"components/avisos/Aviso.jsx":"c1bf7fcc730f","components/base/Boton.jsx":"80290de25c13","components/base/Etiqueta.jsx":"695bebf21722","components/base/Marca.jsx":"5393e75405b3","components/base/Tarjeta.jsx":"5bd4e8516613","components/datos/ItemHistorial.jsx":"20fd3a6474ac","components/datos/ListaDatos.jsx":"6bdb83ca2ca0","components/datos/Paginado.jsx":"d571b5deb478","components/datos/Tabla.jsx":"423cc09b72f2","components/formularios/Buscador.jsx":"f5198e13d6ae","components/formularios/Campo.jsx":"cfce65bb0206","components/formularios/Check.jsx":"e65758c46e37","ui_kits/anpael-campo/Animal.jsx":"a5f5696da50f","ui_kits/anpael-campo/App.jsx":"165ca2e3a767","ui_kits/anpael-campo/Cargar.jsx":"ad8d9038291c","ui_kits/anpael-campo/Estado.jsx":"eea7cda9dc36","ui_kits/anpael-campo/Login.jsx":"ce829a7cc242","ui_kits/anpael-campo/Nuevo.jsx":"2a17e040a312","ui_kits/anpael-campo/Padron.jsx":"9d7c419b1e9d","ui_kits/anpael-campo/Planillas.jsx":"ac2df2e84f7b","ui_kits/anpael-campo/datos.js":"d1a0aae28a77","ui_kits/anpael-campo/doc-page.js":"f52ae9c02fca"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.ANPAELDesignSystem_5fc50e = window.ANPAELDesignSystem_5fc50e || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/avisos/Aviso.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const tonos = {
  ok: {
    background: 'var(--ok-bg)',
    borderColor: 'var(--ok-border)',
    color: 'var(--ok-text)'
  },
  error: {
    background: 'var(--bad-bg)',
    borderColor: 'var(--bad-border)',
    color: 'var(--bad-text)'
  },
  atencion: {
    background: 'var(--warn-bg)',
    borderColor: 'var(--warn-border)',
    color: 'var(--warn-text)'
  },
  info: {
    background: 'var(--info-bg)',
    borderColor: 'var(--info-border)',
    color: 'var(--info-text)'
  }
};
function Aviso({
  tono = 'info',
  detalle,
  children,
  style,
  ...resto
}) {
  const t = tonos[tono] || tonos.info;
  return /*#__PURE__*/React.createElement("p", _extends({
    role: tono === 'error' ? 'alert' : undefined,
    style: {
      borderStyle: 'solid',
      borderWidth: 1,
      borderRadius: 'var(--radio-md)',
      padding: '10px',
      fontFamily: 'var(--font-ui)',
      fontSize: 'var(--fs-13)',
      lineHeight: 'var(--lh-normal)',
      margin: 0,
      ...t,
      ...style
    }
  }, resto), children, detalle ? /*#__PURE__*/React.createElement("span", {
    style: {
      opacity: 0.8
    }
  }, " ", '\u2014', " ", detalle) : null);
}
Object.assign(__ds_scope, { Aviso });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/avisos/Aviso.jsx", error: String((e && e.message) || e) }); }

// components/base/Boton.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const paleta = {
  primario: {
    background: 'var(--action-primary)',
    color: '#fff',
    border: '0'
  },
  acento: {
    background: 'var(--action-accent)',
    color: '#fff',
    border: '0'
  },
  sobrio: {
    background: 'none',
    color: 'var(--text-body)',
    border: '1px solid var(--action-quiet-border)'
  },
  texto: {
    background: 'none',
    color: 'var(--text-link)',
    border: '0',
    textDecoration: 'underline'
  }
};
const medidas = {
  md: {
    padding: '10px 14px',
    fontSize: 'var(--fs-14)'
  },
  sm: {
    padding: '6px 12px',
    fontSize: 'var(--fs-13)'
  }
};
function Boton({
  variante = 'primario',
  tamano = 'md',
  ancho = false,
  deshabilitado = false,
  tipo = 'button',
  onClick,
  children,
  style,
  ...resto
}) {
  const v = paleta[variante] || paleta.primario;
  const m = medidas[tamano] || medidas.md;
  return /*#__PURE__*/React.createElement("button", _extends({
    type: tipo,
    disabled: deshabilitado,
    onClick: onClick,
    style: {
      font: 'inherit',
      fontFamily: 'var(--font-ui)',
      fontWeight: 'var(--fw-semibold)',
      borderRadius: 'var(--radio-md)',
      cursor: deshabilitado ? 'not-allowed' : 'pointer',
      transition: 'var(--transicion-boton)',
      opacity: deshabilitado ? variante === 'sobrio' ? 0.4 : 0.5 : 1,
      width: ancho ? '100%' : undefined,
      lineHeight: 'var(--lh-snug)',
      textAlign: 'center',
      whiteSpace: 'nowrap',
      ...m,
      ...v,
      ...(variante === 'texto' ? {
        padding: 0
      } : null),
      ...style
    }
  }, resto), children);
}
Object.assign(__ds_scope, { Boton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/base/Boton.jsx", error: String((e && e.message) || e) }); }

// components/base/Etiqueta.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const tonos = {
  falta: {
    color: 'var(--falta-text)',
    fontSize: 'var(--fs-125)'
  },
  tipo: {
    color: 'var(--text-link)',
    fontSize: 'var(--fs-11)',
    fontWeight: 'var(--fw-bold)',
    letterSpacing: 'var(--ls-caps)',
    textTransform: 'uppercase'
  },
  ok: {
    color: 'var(--ok)',
    fontSize: 'var(--fs-135)',
    fontWeight: 'var(--fw-semibold)'
  },
  mal: {
    color: 'var(--bad)',
    fontSize: 'var(--fs-135)',
    fontWeight: 'var(--fw-semibold)'
  },
  atenuado: {
    color: 'var(--text-muted)',
    fontSize: 'var(--fs-125)'
  }
};
function Etiqueta({
  tono = 'falta',
  capsula = false,
  children,
  style,
  ...resto
}) {
  const t = tonos[tono] || tonos.falta;
  return /*#__PURE__*/React.createElement("span", _extends({
    style: {
      fontFamily: 'var(--font-ui)',
      whiteSpace: 'nowrap',
      ...t,
      ...(capsula ? {
        background: 'var(--surface-sunken)',
        borderRadius: 'var(--radio-pill)',
        padding: '2px 8px'
      } : null),
      ...style
    }
  }, resto), children);
}
Object.assign(__ds_scope, { Etiqueta });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/base/Etiqueta.jsx", error: String((e && e.message) || e) }); }

// components/base/Marca.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function Marca({
  titulo = 'ANPAEL',
  bajada,
  punto = true,
  logo = false,
  logoSrc = 'assets/logo-horizontal.png',
  children,
  style,
  ...resto
}) {
  return /*#__PURE__*/React.createElement("header", _extends({
    style: {
      display: 'flex',
      gap: '10px',
      alignItems: 'center',
      fontWeight: 'var(--fw-bold)',
      fontFamily: 'var(--font-ui)',
      fontSize: 'var(--fs-16)',
      color: 'var(--text-body)',
      ...style
    }
  }, resto), logo ? /*#__PURE__*/React.createElement("img", {
    src: logoSrc,
    alt: "ANPAEL",
    style: {
      height: 34,
      width: 'auto',
      display: 'block',
      flexShrink: 0
    }
  }) : punto ? /*#__PURE__*/React.createElement("span", {
    "aria-hidden": "true",
    style: {
      width: 12,
      height: 12,
      borderRadius: 'var(--radio-circulo)',
      background: 'var(--pasto-700)',
      flexShrink: 0
    }
  }) : null, /*#__PURE__*/React.createElement("div", null, logo ? null : titulo, bajada ? /*#__PURE__*/React.createElement("small", {
    style: {
      display: 'block',
      fontWeight: 'var(--fw-regular)',
      font: 'var(--text-caption)',
      color: 'var(--text-muted)'
    }
  }, bajada) : null), children ? /*#__PURE__*/React.createElement("div", {
    style: {
      marginLeft: 'auto',
      display: 'flex',
      alignItems: 'center',
      gap: '8px'
    }
  }, children) : null);
}
Object.assign(__ds_scope, { Marca });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/base/Marca.jsx", error: String((e && e.message) || e) }); }

// components/base/Tarjeta.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function Tarjeta({
  titulo,
  nota,
  denso = false,
  children,
  style,
  ...resto
}) {
  return /*#__PURE__*/React.createElement("section", _extends({
    style: {
      background: 'var(--surface-card)',
      border: 'var(--borde-fino)',
      borderRadius: 'var(--radio-lg)',
      padding: denso ? 'var(--pad-tarjeta-tabla)' : 'var(--pad-tarjeta)',
      color: 'var(--text-body)',
      font: 'var(--text-base)',
      ...style
    }
  }, resto), titulo ? /*#__PURE__*/React.createElement("h3", {
    style: {
      margin: nota ? '0 0 4px' : '0 0 12px',
      font: 'var(--text-h3)'
    }
  }, titulo) : null, nota ? /*#__PURE__*/React.createElement("p", {
    style: {
      margin: '0 0 12px',
      font: 'var(--text-caption)',
      color: 'var(--text-muted)'
    }
  }, nota) : null, children);
}
Object.assign(__ds_scope, { Tarjeta });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/base/Tarjeta.jsx", error: String((e && e.message) || e) }); }

// components/datos/ItemHistorial.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function ItemHistorial({
  fecha,
  tipo,
  detalle,
  comentario,
  ultimo = false,
  children,
  style,
  ...resto
}) {
  return /*#__PURE__*/React.createElement("li", _extends({
    style: {
      padding: '10px 0',
      borderBottom: ultimo ? 'none' : 'var(--borde-filete)',
      listStyle: 'none',
      fontFamily: 'var(--font-ui)',
      ...style
    }
  }, resto), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'baseline',
      gap: 10
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 'var(--fs-125)',
      color: 'var(--text-muted)',
      whiteSpace: 'nowrap',
      fontFamily: 'var(--font-mono)'
    }
  }, fecha), /*#__PURE__*/React.createElement(__ds_scope.Etiqueta, {
    tono: "tipo"
  }, tipo)), detalle ? /*#__PURE__*/React.createElement("p", {
    style: {
      margin: '4px 0 0',
      fontSize: 'var(--fs-135)'
    }
  }, detalle) : null, comentario ? /*#__PURE__*/React.createElement("p", {
    style: {
      margin: '4px 0 0',
      fontSize: 'var(--fs-135)',
      color: 'var(--text-muted)'
    }
  }, "\"", comentario, "\"") : null, children);
}
Object.assign(__ds_scope, { ItemHistorial });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/datos/ItemHistorial.jsx", error: String((e && e.message) || e) }); }

// components/datos/ListaDatos.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function ListaDatos({
  items = [],
  style,
  ...resto
}) {
  return /*#__PURE__*/React.createElement("dl", _extends({
    style: {
      margin: 0,
      fontFamily: 'var(--font-ui)',
      ...style
    }
  }, resto), items.map((it, i) => /*#__PURE__*/React.createElement("div", {
    key: it.rotulo + i,
    style: {
      display: 'flex',
      justifyContent: 'space-between',
      gap: 16,
      padding: '8px 0',
      borderBottom: i === items.length - 1 ? 'none' : 'var(--borde-filete)'
    }
  }, /*#__PURE__*/React.createElement("dt", {
    style: {
      color: 'var(--text-muted)',
      fontSize: 'var(--fs-13)',
      flexShrink: 0
    }
  }, it.rotulo), /*#__PURE__*/React.createElement("dd", {
    style: {
      margin: 0,
      fontWeight: 'var(--fw-semibold)',
      fontSize: 'var(--fs-14)',
      textAlign: 'right',
      fontVariantNumeric: it.numerico ? 'tabular-nums' : undefined,
      fontFamily: it.numerico ? 'var(--font-mono)' : undefined
    }
  }, it.valor))));
}
Object.assign(__ds_scope, { ListaDatos });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/datos/ListaDatos.jsx", error: String((e && e.message) || e) }); }

// components/datos/Paginado.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function Paginado({
  pagina = 0,
  totalPaginas = 1,
  onCambio,
  style,
  ...resto
}) {
  if (totalPaginas <= 1) return null;
  return /*#__PURE__*/React.createElement("nav", _extends({
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 16,
      marginTop: 16,
      ...style
    }
  }, resto), /*#__PURE__*/React.createElement(__ds_scope.Boton, {
    variante: "sobrio",
    tamano: "sm",
    deshabilitado: pagina === 0,
    onClick: () => onCambio && onCambio(pagina - 1)
  }, '\u2039', " Anterior"), /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--text-muted)',
      fontFamily: 'var(--font-ui)',
      fontSize: 'var(--fs-13)'
    }
  }, "pagina ", pagina + 1, " de ", totalPaginas), /*#__PURE__*/React.createElement(__ds_scope.Boton, {
    variante: "sobrio",
    tamano: "sm",
    deshabilitado: pagina >= totalPaginas - 1,
    onClick: () => onCambio && onCambio(pagina + 1)
  }, "Siguiente ", '\u203A'));
}
Object.assign(__ds_scope, { Paginado });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/datos/Paginado.jsx", error: String((e && e.message) || e) }); }

// components/datos/Tabla.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function Tabla({
  columnas = [],
  filas = [],
  vacio = 'No hay resultados.',
  style,
  ...resto
}) {
  if (!filas.length) {
    return /*#__PURE__*/React.createElement("p", {
      style: {
        color: 'var(--text-muted)',
        font: 'var(--text-base)',
        margin: 0
      }
    }, vacio);
  }
  return /*#__PURE__*/React.createElement("table", _extends({
    style: {
      width: '100%',
      borderCollapse: 'collapse',
      fontFamily: 'var(--font-ui)',
      fontSize: 'var(--fs-14)',
      ...style
    }
  }, resto), /*#__PURE__*/React.createElement("thead", null, /*#__PURE__*/React.createElement("tr", null, columnas.map(c => /*#__PURE__*/React.createElement("th", {
    key: c.clave,
    style: {
      textAlign: c.alDerecha ? 'right' : 'left',
      fontSize: 'var(--fs-12)',
      color: 'var(--text-muted)',
      fontWeight: 'var(--fw-semibold)',
      padding: '8px 10px',
      borderBottom: 'var(--borde-fino)',
      whiteSpace: 'nowrap'
    }
  }, c.titulo)))), /*#__PURE__*/React.createElement("tbody", null, filas.map((fila, i) => /*#__PURE__*/React.createElement("tr", {
    key: fila.id != null ? fila.id : i
  }, columnas.map(c => /*#__PURE__*/React.createElement("td", {
    key: c.clave,
    style: {
      padding: '8px 10px',
      borderBottom: 'var(--borde-filete)',
      textAlign: c.alDerecha ? 'right' : 'left',
      fontVariantNumeric: c.numerico ? 'tabular-nums' : undefined,
      fontFamily: c.numerico ? 'var(--font-mono)' : undefined
    }
  }, c.render ? c.render(fila) : fila[c.clave]))))));
}
Object.assign(__ds_scope, { Tabla });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/datos/Tabla.jsx", error: String((e && e.message) || e) }); }

// components/formularios/Buscador.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function Buscador({
  valor,
  onChange,
  placeholder = 'Buscar por caravana...',
  ancho = 240,
  style,
  ...resto
}) {
  return /*#__PURE__*/React.createElement("input", _extends({
    type: "search",
    value: valor,
    onChange: onChange,
    placeholder: placeholder,
    style: {
      font: 'inherit',
      fontFamily: 'var(--font-ui)',
      fontSize: 'var(--fs-14)',
      color: 'var(--text-body)',
      padding: '9px 12px',
      borderRadius: 'var(--radio-md)',
      border: 'var(--borde-fino)',
      background: 'var(--surface-card)',
      minWidth: ancho,
      ...style
    }
  }, resto));
}
Object.assign(__ds_scope, { Buscador });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/formularios/Buscador.jsx", error: String((e && e.message) || e) }); }

// components/formularios/Campo.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const baseControl = {
  font: 'inherit',
  fontFamily: 'var(--font-ui)',
  fontSize: 'var(--fs-135)',
  color: 'var(--text-body)',
  padding: '8px 10px',
  borderRadius: 'var(--radio-md)',
  border: 'var(--borde-fino)',
  background: 'var(--surface-field)',
  width: '100%',
  boxSizing: 'border-box'
};
function Campo({
  etiqueta,
  tipo = 'text',
  opciones,
  filas,
  valor,
  onChange,
  placeholder,
  requerido = false,
  deshabilitado = false,
  sobreFondo = false,
  style,
  ...resto
}) {
  const control0 = sobreFondo ? {
    ...baseControl,
    background: 'var(--surface-card)'
  } : baseControl;
  const comun = {
    value: valor,
    onChange,
    placeholder,
    required: requerido,
    disabled: deshabilitado,
    ...resto
  };
  let control;
  if (opciones) {
    control = /*#__PURE__*/React.createElement("select", _extends({
      style: control0
    }, comun), opciones.map(o => /*#__PURE__*/React.createElement("option", {
      key: String(o.valor),
      value: o.valor === null ? '' : o.valor
    }, o.etiqueta)));
  } else if (tipo === 'textarea') {
    control = /*#__PURE__*/React.createElement("textarea", _extends({
      rows: filas || 2,
      style: {
        ...control0,
        resize: 'vertical'
      }
    }, comun));
  } else {
    control = /*#__PURE__*/React.createElement("input", _extends({
      type: tipo,
      style: control0
    }, comun));
  }
  return /*#__PURE__*/React.createElement("label", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: '4px',
      font: 'var(--text-label)',
      color: 'var(--text-muted)',
      flex: 1,
      minWidth: 160,
      ...style
    }
  }, etiqueta ? /*#__PURE__*/React.createElement("span", null, etiqueta, requerido ? ' *' : '') : null, control);
}
Object.assign(__ds_scope, { Campo });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/formularios/Campo.jsx", error: String((e && e.message) || e) }); }

// components/formularios/Check.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function Check({
  etiqueta,
  marcado,
  onChange,
  deshabilitado = false,
  style,
  ...resto
}) {
  return /*#__PURE__*/React.createElement("label", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: '6px',
      font: 'var(--text-label)',
      color: 'var(--text-muted)',
      cursor: deshabilitado ? 'not-allowed' : 'pointer',
      opacity: deshabilitado ? 0.5 : 1,
      ...style
    }
  }, /*#__PURE__*/React.createElement("input", _extends({
    type: "checkbox",
    checked: marcado,
    onChange: onChange,
    disabled: deshabilitado,
    style: {
      accentColor: 'var(--pasto-700)',
      width: 15,
      height: 15,
      margin: 0
    }
  }, resto)), etiqueta);
}
Object.assign(__ds_scope, { Check });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/formularios/Check.jsx", error: String((e && e.message) || e) }); }

// ui_kits/anpael-campo/Animal.jsx
try { (() => {
const {
  Marca,
  Tarjeta,
  Boton,
  Campo,
  Check,
  ListaDatos,
  ItemHistorial,
  Etiqueta,
  Aviso
} = window.ANPAELDesignSystem_5fc50e;
function Animal({
  idAnimal,
  ir
}) {
  const D = window.ANPAEL_DATOS;
  const base = D.animales.find(a => a.idAnimal === idAnimal) || D.animales[0];
  const [animal, setAnimal] = React.useState(base);
  const [rodeoElegido, setRodeoElegido] = React.useState('');
  const [msgRodeo, setMsgRodeo] = React.useState(null);
  const eventos = D.historial[animal.idAnimal] || [];
  function asignarRodeo(e) {
    e.preventDefault();
    if (!rodeoElegido) return;
    const r = D.rodeos.find(x => String(x.idRodeo) === String(rodeoElegido));
    setAnimal(Object.assign({}, animal, {
      rodeo: r.nombre
    }));
    setMsgRodeo('Rodeo asignado: ' + r.nombre + '.');
  }
  return /*#__PURE__*/React.createElement("main", {
    style: {
      maxWidth: 'var(--ancho-lectura)',
      margin: '6vh auto',
      padding: '0 16px',
      display: 'grid',
      gap: 16
    }
  }, /*#__PURE__*/React.createElement("nav", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 8
    }
  }, /*#__PURE__*/React.createElement(Boton, {
    variante: "texto",
    tamano: "sm",
    onClick: () => ir('estado'),
    style: {
      textDecoration: 'none',
      color: 'var(--text-muted)'
    }
  }, "\u2039 Inicio"), /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--text-muted)'
    }
  }, "\xB7"), /*#__PURE__*/React.createElement(Boton, {
    variante: "texto",
    tamano: "sm",
    onClick: () => ir('padron'),
    style: {
      textDecoration: 'none',
      color: 'var(--text-muted)'
    }
  }, "Volver al padr\xF3n")), /*#__PURE__*/React.createElement(Marca, {
    titulo: animal.caravana,
    bajada: 'VISUAL · ' + (animal.sexo === 'M' ? 'macho' : 'hembra')
  }), /*#__PURE__*/React.createElement(Tarjeta, null, /*#__PURE__*/React.createElement(ListaDatos, {
    items: [{
      rotulo: 'Raza',
      valor: animal.raza || '—'
    }, {
      rotulo: 'Categoría',
      valor: animal.sinCategoria ? /*#__PURE__*/React.createElement(Etiqueta, {
        tono: "falta"
      }, "sin asignar") : animal.categoria
    }, {
      rotulo: 'Rodeo',
      valor: animal.rodeo ? animal.rodeo : /*#__PURE__*/React.createElement(Etiqueta, {
        tono: "falta"
      }, "sin asignar")
    }, {
      rotulo: 'Fecha de nacimiento',
      valor: '12/09/2023'
    }, {
      rotulo: 'Establecimiento (CUIG)',
      valor: 'AB123',
      numerico: true
    }, {
      rotulo: 'Estado',
      valor: /*#__PURE__*/React.createElement(Etiqueta, {
        tono: "ok"
      }, "activo")
    }, {
      rotulo: 'Eventos registrados',
      valor: String(eventos.length),
      numerico: true
    }, {
      rotulo: 'Validación del saneamiento',
      valor: animal.validacion
    }]
  }), /*#__PURE__*/React.createElement("form", {
    onSubmit: asignarRodeo,
    style: {
      display: 'flex',
      gap: 8,
      marginTop: 14,
      alignItems: 'flex-end'
    }
  }, /*#__PURE__*/React.createElement(Campo, {
    etiqueta: "Asignar rodeo",
    valor: rodeoElegido,
    onChange: e => setRodeoElegido(e.target.value),
    opciones: [{
      valor: '',
      etiqueta: 'Asignar rodeo…'
    }].concat(D.rodeos.map(r => ({
      valor: r.idRodeo,
      etiqueta: r.nombre
    })))
  }), /*#__PURE__*/React.createElement(Boton, {
    variante: "sobrio",
    tamano: "sm",
    tipo: "submit",
    deshabilitado: !rodeoElegido,
    style: {
      marginBottom: 1
    }
  }, "Asignar")), msgRodeo ? /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 8
    }
  }, /*#__PURE__*/React.createElement(Aviso, {
    tono: "ok"
  }, msgRodeo)) : null), /*#__PURE__*/React.createElement(Tarjeta, {
    titulo: "Historial de trabajos"
  }, eventos.length === 0 ? /*#__PURE__*/React.createElement("p", {
    style: {
      color: 'var(--text-muted)',
      margin: 0
    }
  }, "Sin eventos registrados todav\xEDa.") : /*#__PURE__*/React.createElement("ul", {
    style: {
      margin: 0,
      padding: 0
    }
  }, eventos.map((ev, i) => /*#__PURE__*/React.createElement(ItemHistorial, {
    key: ev.idEvento,
    fecha: ev.fecha,
    tipo: ev.tipoTrabajo,
    detalle: ev.detalle,
    comentario: ev.comentario,
    ultimo: i === eventos.length - 1
  }, /*#__PURE__*/React.createElement(Boton, {
    variante: "texto",
    tamano: "sm",
    style: {
      fontSize: 'var(--fs-12)',
      paddingTop: 6
    }
  }, "Corregir"))))), /*#__PURE__*/React.createElement(Tarjeta, {
    titulo: "Corregir / completar datos",
    nota: "Dej\xE1 en blanco lo que no quieras cambiar."
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gap: 10
    }
  }, /*#__PURE__*/React.createElement(Campo, {
    etiqueta: "Raza",
    opciones: [{
      valor: '',
      etiqueta: '(sin cambios)'
    }, {
      valor: 1,
      etiqueta: 'Angus'
    }, {
      valor: 2,
      etiqueta: 'Braford'
    }, {
      valor: 3,
      etiqueta: 'Hereford'
    }],
    onChange: () => {}
  }), /*#__PURE__*/React.createElement(Campo, {
    etiqueta: "Fecha de nacimiento",
    tipo: "date",
    onChange: () => {}
  }), /*#__PURE__*/React.createElement(Check, {
    etiqueta: "Es estimada",
    marcado: false,
    onChange: () => {}
  }), /*#__PURE__*/React.createElement(Campo, {
    etiqueta: "Peso al nacer (kg)",
    tipo: "number",
    placeholder: "10 a 70",
    onChange: () => {}
  }), /*#__PURE__*/React.createElement(Boton, {
    variante: "sobrio",
    tamano: "sm",
    style: {
      justifySelf: 'start'
    }
  }, "Guardar cambios"))), /*#__PURE__*/React.createElement(Tarjeta, {
    titulo: "Dar de baja"
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gap: 8
    }
  }, /*#__PURE__*/React.createElement(Campo, {
    opciones: [{
      valor: '',
      etiqueta: 'Causa…'
    }, {
      valor: 1,
      etiqueta: 'VENTA · vendido en remate'
    }, {
      valor: 2,
      etiqueta: 'MUERTE · muerte en el campo'
    }, {
      valor: 3,
      etiqueta: 'REGULARIZACION · regularización inicial'
    }],
    onChange: () => {}
  }), /*#__PURE__*/React.createElement(Check, {
    etiqueta: "La fecha es estimada (hoy, no el d\xEDa real en que sali\xF3 el animal)",
    marcado: false,
    onChange: () => {}
  }), /*#__PURE__*/React.createElement(Campo, {
    placeholder: "Destino (opcional)",
    onChange: () => {}
  }), /*#__PURE__*/React.createElement(Campo, {
    tipo: "textarea",
    placeholder: "Observaciones (opcional)",
    onChange: () => {}
  }), /*#__PURE__*/React.createElement(Boton, {
    variante: "sobrio",
    tamano: "sm",
    style: {
      justifySelf: 'start'
    }
  }, "Registrar baja"))));
}
window.Animal = Animal;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/anpael-campo/Animal.jsx", error: String((e && e.message) || e) }); }

// ui_kits/anpael-campo/App.jsx
try { (() => {
function App() {
  const [pantalla, setPantalla] = React.useState('login');
  const [usuario, setUsuario] = React.useState(null);
  const [idAnimal, setIdAnimal] = React.useState(101);
  function ir(p, id) {
    if (id != null) setIdAnimal(id);
    setPantalla(p);
  }
  if (!usuario) return /*#__PURE__*/React.createElement(window.Login, {
    onEntrar: u => {
      setUsuario(u);
      setPantalla('estado');
    }
  });
  if (pantalla === 'padron') return /*#__PURE__*/React.createElement(window.Padron, {
    ir: ir
  });
  if (pantalla === 'animal') return /*#__PURE__*/React.createElement(window.Animal, {
    idAnimal: idAnimal,
    ir: ir
  });
  if (pantalla === 'nuevo') return /*#__PURE__*/React.createElement(window.Nuevo, {
    ir: ir
  });
  if (pantalla === 'planillas') return /*#__PURE__*/React.createElement(window.Planillas, {
    ir: ir
  });
  if (pantalla === 'cargar') return /*#__PURE__*/React.createElement(window.Cargar, {
    ir: ir
  });
  return /*#__PURE__*/React.createElement(window.Estado, {
    usuario: usuario,
    ir: ir,
    salir: () => {
      setUsuario(null);
      setPantalla('login');
    }
  });
}
ReactDOM.createRoot(document.getElementById('root')).render(/*#__PURE__*/React.createElement(App, null));
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/anpael-campo/App.jsx", error: String((e && e.message) || e) }); }

// ui_kits/anpael-campo/Cargar.jsx
try { (() => {
const {
  Marca,
  Tarjeta,
  Boton,
  Campo,
  Aviso
} = window.ANPAELDesignSystem_5fc50e;
function Cargar({
  ir
}) {
  const D = window.ANPAEL_DATOS;
  const [rodeo, setRodeo] = React.useState('1');
  const [trabajo, setTrabajo] = React.useState('TACTO');
  const [valores, setValores] = React.useState({});
  const [guardado, setGuardado] = React.useState(null);
  const filas = D.animales.slice(0, 4);
  const cargadas = Object.values(valores).filter(Boolean).length;
  return /*#__PURE__*/React.createElement("main", {
    style: {
      maxWidth: 'var(--ancho-forma)',
      margin: '6vh auto',
      padding: '0 16px'
    }
  }, /*#__PURE__*/React.createElement(Boton, {
    variante: "texto",
    tamano: "sm",
    onClick: () => ir('planillas'),
    style: {
      marginBottom: 14,
      textDecoration: 'none',
      color: 'var(--text-muted)'
    }
  }, "\u2039 Planillas"), /*#__PURE__*/React.createElement(Marca, {
    bajada: "Santa Ana \xB7 cargar resultados",
    style: {
      marginBottom: 18
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 14,
      marginBottom: 12,
      flexWrap: 'wrap'
    }
  }, /*#__PURE__*/React.createElement(Campo, {
    etiqueta: "Rodeo",
    valor: rodeo,
    onChange: e => setRodeo(e.target.value),
    opciones: D.rodeos.map(r => ({
      valor: r.idRodeo,
      etiqueta: r.nombre
    }))
  }), /*#__PURE__*/React.createElement(Campo, {
    etiqueta: "Trabajo",
    valor: trabajo,
    onChange: e => setTrabajo(e.target.value),
    opciones: D.trabajos.map(t => ({
      valor: t.valor,
      etiqueta: t.etiqueta
    }))
  })), /*#__PURE__*/React.createElement(Tarjeta, {
    denso: true
  }, /*#__PURE__*/React.createElement("p", {
    style: {
      font: 'var(--text-caption)',
      color: 'var(--text-muted)',
      margin: '0 0 12px'
    }
  }, "Mismo orden que el PDF impreso. Dej\xE1 en blanco los animales que no trabajaste."), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gap: 8
    }
  }, filas.map(a => /*#__PURE__*/React.createElement("div", {
    key: a.idAnimal,
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      padding: '8px 0',
      borderBottom: 'var(--borde-filete)'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      font: 'var(--text-dato)',
      fontVariantNumeric: 'tabular-nums',
      width: 64
    }
  }, a.caravana), trabajo === 'PESADA' ? /*#__PURE__*/React.createElement(Campo, {
    tipo: "number",
    placeholder: "Kilos",
    valor: valores[a.idAnimal] || '',
    onChange: e => setValores(Object.assign({}, valores, {
      [a.idAnimal]: e.target.value
    }))
  }) : /*#__PURE__*/React.createElement(Campo, {
    valor: valores[a.idAnimal] || '',
    onChange: e => setValores(Object.assign({}, valores, {
      [a.idAnimal]: e.target.value
    })),
    opciones: [{
      valor: '',
      etiqueta: 'Resultado…'
    }, {
      valor: 'PRENADA',
      etiqueta: 'Preñada'
    }, {
      valor: 'VACIA',
      etiqueta: 'Vacía'
    }, {
      valor: 'DUDOSA',
      etiqueta: 'Dudosa'
    }]
  })))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 14,
      marginTop: 14
    }
  }, /*#__PURE__*/React.createElement(Boton, {
    deshabilitado: cargadas === 0,
    onClick: () => setGuardado(cargadas)
  }, "Guardar ", cargadas > 0 ? '(' + cargadas + ')' : ''), guardado ? /*#__PURE__*/React.createElement(Aviso, {
    tono: "ok",
    style: {
      flex: 1
    }
  }, "Se registraron ", guardado, " resultados.") : null)));
}
window.Cargar = Cargar;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/anpael-campo/Cargar.jsx", error: String((e && e.message) || e) }); }

// ui_kits/anpael-campo/Estado.jsx
try { (() => {
const {
  Marca,
  Tarjeta,
  Boton,
  ListaDatos,
  Aviso
} = window.ANPAELDesignSystem_5fc50e;
function Estado({
  usuario,
  ir,
  salir
}) {
  return /*#__PURE__*/React.createElement("main", {
    style: {
      maxWidth: 'var(--ancho-lectura)',
      margin: '8vh auto',
      padding: '0 16px'
    }
  }, /*#__PURE__*/React.createElement(Marca, {
    logo: true,
    logoSrc: "../../assets/logo-horizontal.png",
    bajada: "Santa Ana \xB7 estado del sistema",
    style: {
      marginBottom: 18
    }
  }, /*#__PURE__*/React.createElement(Boton, {
    variante: "sobrio",
    tamano: "sm",
    onClick: () => ir('padron')
  }, "Padr\xF3n"), /*#__PURE__*/React.createElement(Boton, {
    variante: "sobrio",
    tamano: "sm",
    onClick: () => ir('planillas')
  }, "Planillas"), /*#__PURE__*/React.createElement("span", {
    style: {
      font: 'var(--text-label)',
      color: 'var(--text-muted)'
    }
  }, usuario), /*#__PURE__*/React.createElement(Boton, {
    variante: "sobrio",
    tamano: "sm",
    onClick: salir
  }, "Salir")), /*#__PURE__*/React.createElement(Tarjeta, null, /*#__PURE__*/React.createElement("h2", {
    style: {
      margin: '0 0 14px',
      font: 'var(--text-h2)',
      color: 'var(--ok)'
    }
  }, "Todo conectado"), /*#__PURE__*/React.createElement(ListaDatos, {
    items: [{
      rotulo: 'Aplicación',
      valor: 'anpael'
    }, {
      rotulo: 'Entorno',
      valor: 'local'
    }, {
      rotulo: 'Base de datos',
      valor: 'ok'
    }, {
      rotulo: 'Usuario',
      valor: 'postgres'
    }, {
      rotulo: 'Animales',
      valor: '1.732',
      numerico: true
    }, {
      rotulo: 'Eventos',
      valor: '3.164',
      numerico: true
    }]
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 16
    }
  }, /*#__PURE__*/React.createElement(Boton, null, "Volver a consultar"))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 16
    }
  }, /*#__PURE__*/React.createElement(Aviso, {
    tono: "atencion"
  }, "El Supabase local tiene un dump de producci\xF3n: el conteo no prueba a qu\xE9 base te conectaste. Mir\xE1 siempre ", /*#__PURE__*/React.createElement("b", null, "entorno"), ".")));
}
window.Estado = Estado;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/anpael-campo/Estado.jsx", error: String((e && e.message) || e) }); }

// ui_kits/anpael-campo/Login.jsx
try { (() => {
const {
  Marca,
  Tarjeta,
  Boton,
  Campo,
  Aviso
} = window.ANPAELDesignSystem_5fc50e;
function Login({
  onEntrar
}) {
  const [usuario, setUsuario] = React.useState('');
  const [password, setPassword] = React.useState('');
  const [cargando, setCargando] = React.useState(false);
  const [error, setError] = React.useState(null);
  function entrar(e) {
    e.preventDefault();
    if (!usuario || !password) {
      setError('Usuario o contraseña incorrectos.');
      return;
    }
    setCargando(true);
    setTimeout(() => {
      setCargando(false);
      onEntrar(usuario);
    }, 500);
  }
  return /*#__PURE__*/React.createElement("main", {
    style: {
      maxWidth: 'var(--ancho-angosto)',
      margin: '12vh auto',
      padding: '0 16px'
    }
  }, /*#__PURE__*/React.createElement(Marca, {
    logo: true,
    logoSrc: "../../assets/logo-horizontal.png",
    bajada: "Santa Ana \xB7 iniciar sesi\xF3n",
    style: {
      marginBottom: 22
    }
  }), /*#__PURE__*/React.createElement(Tarjeta, null, /*#__PURE__*/React.createElement("form", {
    onSubmit: entrar
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'grid',
      gap: 'var(--gap-campo)',
      marginBottom: 14
    }
  }, /*#__PURE__*/React.createElement(Campo, {
    etiqueta: "Usuario",
    valor: usuario,
    onChange: e => setUsuario(e.target.value),
    autoComplete: "username"
  }), /*#__PURE__*/React.createElement(Campo, {
    etiqueta: "Contrase\xF1a",
    tipo: "password",
    valor: password,
    onChange: e => setPassword(e.target.value),
    autoComplete: "current-password"
  })), error ? /*#__PURE__*/React.createElement("div", {
    style: {
      marginBottom: 14
    }
  }, /*#__PURE__*/React.createElement(Aviso, {
    tono: "error"
  }, error)) : null, /*#__PURE__*/React.createElement(Boton, {
    tipo: "submit",
    ancho: true,
    deshabilitado: cargando
  }, cargando ? 'Entrando…' : 'Entrar'))));
}
window.Login = Login;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/anpael-campo/Login.jsx", error: String((e && e.message) || e) }); }

// ui_kits/anpael-campo/Nuevo.jsx
try { (() => {
const {
  Marca,
  Tarjeta,
  Boton,
  Campo,
  Check
} = window.ANPAELDesignSystem_5fc50e;
function Nuevo({
  ir
}) {
  const D = window.ANPAEL_DATOS;
  const [origen, setOrigen] = React.useState('NACIDO');
  const [caravana, setCaravana] = React.useState('');
  const [sexo, setSexo] = React.useState('');
  return /*#__PURE__*/React.createElement("main", {
    style: {
      maxWidth: 'var(--ancho-forma)',
      margin: '6vh auto',
      padding: '0 16px'
    }
  }, /*#__PURE__*/React.createElement("nav", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      marginBottom: 14
    }
  }, /*#__PURE__*/React.createElement(Boton, {
    variante: "texto",
    tamano: "sm",
    onClick: () => ir('estado'),
    style: {
      textDecoration: 'none',
      color: 'var(--text-muted)'
    }
  }, "\u2039 Inicio"), /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--text-muted)'
    }
  }, "\xB7"), /*#__PURE__*/React.createElement(Boton, {
    variante: "texto",
    tamano: "sm",
    onClick: () => ir('padron'),
    style: {
      textDecoration: 'none',
      color: 'var(--text-muted)'
    }
  }, "Volver al padr\xF3n")), /*#__PURE__*/React.createElement(Marca, {
    titulo: "Nuevo animal",
    bajada: "Alta con identificaci\xF3n visual en Santa Ana",
    style: {
      marginBottom: 18
    }
  }), /*#__PURE__*/React.createElement(Tarjeta, null, /*#__PURE__*/React.createElement("form", {
    onSubmit: e => {
      e.preventDefault();
      ir('padron');
    },
    style: {
      display: 'grid',
      gap: 14
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 14,
      flexWrap: 'wrap'
    }
  }, /*#__PURE__*/React.createElement(Campo, {
    etiqueta: "Caravana",
    requerido: true,
    placeholder: "Ej: 0075",
    valor: caravana,
    onChange: e => setCaravana(e.target.value)
  }), /*#__PURE__*/React.createElement(Campo, {
    etiqueta: "Sexo",
    requerido: true,
    valor: sexo,
    onChange: e => setSexo(e.target.value),
    opciones: [{
      valor: '',
      etiqueta: 'Elegir…'
    }, {
      valor: 'H',
      etiqueta: 'Hembra'
    }, {
      valor: 'M',
      etiqueta: 'Macho'
    }]
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 14,
      flexWrap: 'wrap'
    }
  }, /*#__PURE__*/React.createElement(Campo, {
    etiqueta: "Origen",
    requerido: true,
    valor: origen,
    onChange: e => setOrigen(e.target.value),
    opciones: [{
      valor: 'NACIDO',
      etiqueta: 'Nacido en el campo'
    }, {
      valor: 'COMPRADO',
      etiqueta: 'Comprado'
    }, {
      valor: 'RECIBIDO',
      etiqueta: 'Recibido'
    }]
  }), origen === 'COMPRADO' ? /*#__PURE__*/React.createElement(Campo, {
    etiqueta: "Caba\xF1a de origen",
    opciones: [{
      valor: '',
      etiqueta: '(sin especificar)'
    }, {
      valor: 1,
      etiqueta: 'La Invernada'
    }],
    onChange: () => {}
  }) : null, origen !== 'NACIDO' ? /*#__PURE__*/React.createElement(Campo, {
    etiqueta: "Establecimiento de origen",
    opciones: [{
      valor: '',
      etiqueta: '(sin especificar)'
    }, {
      valor: 1,
      etiqueta: 'Santa Ana (AB123)'
    }],
    onChange: () => {}
  }) : null), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 14,
      flexWrap: 'wrap'
    }
  }, /*#__PURE__*/React.createElement(Campo, {
    etiqueta: "Raza",
    opciones: [{
      valor: '',
      etiqueta: '(sin especificar)'
    }, {
      valor: 1,
      etiqueta: 'Angus'
    }, {
      valor: 2,
      etiqueta: 'Braford'
    }],
    onChange: () => {}
  }), /*#__PURE__*/React.createElement(Campo, {
    etiqueta: "Pelaje",
    opciones: [{
      valor: '',
      etiqueta: '(sin especificar)'
    }, {
      valor: 1,
      etiqueta: 'Negro'
    }, {
      valor: 2,
      etiqueta: 'Colorado'
    }],
    onChange: () => {}
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 14,
      flexWrap: 'wrap',
      alignItems: 'flex-end'
    }
  }, /*#__PURE__*/React.createElement(Campo, {
    etiqueta: "Fecha de nacimiento",
    tipo: "date",
    onChange: () => {}
  }), /*#__PURE__*/React.createElement(Check, {
    etiqueta: "Es estimada",
    marcado: false,
    onChange: () => {},
    style: {
      paddingBottom: 9,
      flex: '0 0 auto',
      minWidth: 0
    }
  }), /*#__PURE__*/React.createElement(Campo, {
    etiqueta: "Peso al nacer (kg)",
    tipo: "number",
    placeholder: "10 a 70",
    onChange: () => {}
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 14,
      flexWrap: 'wrap'
    }
  }, /*#__PURE__*/React.createElement(Campo, {
    etiqueta: "Categor\xEDa",
    opciones: [{
      valor: '',
      etiqueta: '(sin asignar)'
    }].concat(D.categorias.map(c => ({
      valor: c.idCategoria,
      etiqueta: c.nombre
    }))),
    onChange: () => {}
  }), /*#__PURE__*/React.createElement(Campo, {
    etiqueta: "Rodeo",
    opciones: [{
      valor: '',
      etiqueta: '(sin asignar)'
    }].concat(D.rodeos.map(r => ({
      valor: r.idRodeo,
      etiqueta: r.nombre
    }))),
    onChange: () => {}
  })), /*#__PURE__*/React.createElement(Boton, {
    variante: "acento",
    tipo: "submit",
    deshabilitado: !caravana || !sexo,
    style: {
      justifySelf: 'start'
    }
  }, "Dar de alta"))));
}
window.Nuevo = Nuevo;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/anpael-campo/Nuevo.jsx", error: String((e && e.message) || e) }); }

// ui_kits/anpael-campo/Padron.jsx
try { (() => {
const {
  Marca,
  Tarjeta,
  Boton,
  Buscador,
  Check,
  Campo,
  Tabla,
  Paginado,
  Etiqueta
} = window.ANPAELDesignSystem_5fc50e;
function Padron({
  ir
}) {
  const D = window.ANPAEL_DATOS;
  const [q, setQ] = React.useState('');
  const [sinCat, setSinCat] = React.useState(false);
  const [sinRodeo, setSinRodeo] = React.useState(false);
  const [pagina, setPagina] = React.useState(0);
  const filas = D.animales.filter(a => {
    if (q && !(a.caravana || '').includes(q)) return false;
    if (sinCat && !a.sinCategoria) return false;
    if (sinRodeo && a.rodeo) return false;
    return true;
  });
  return /*#__PURE__*/React.createElement("main", {
    style: {
      maxWidth: 'var(--ancho-tabla)',
      margin: '6vh auto',
      padding: '0 16px'
    }
  }, /*#__PURE__*/React.createElement(Boton, {
    variante: "texto",
    tamano: "sm",
    onClick: () => ir('estado'),
    style: {
      marginBottom: 14,
      textDecoration: 'none',
      color: 'var(--text-muted)'
    }
  }, "\u2039 Inicio"), /*#__PURE__*/React.createElement(Marca, {
    logo: true,
    logoSrc: "../../assets/logo-horizontal.png",
    bajada: "Santa Ana \xB7 saneamiento del padr\xF3n",
    style: {
      marginBottom: 18
    }
  }, /*#__PURE__*/React.createElement(Boton, {
    variante: "acento",
    tamano: "sm",
    onClick: () => ir('nuevo')
  }, "+ Nuevo animal")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 16,
      marginBottom: 12,
      flexWrap: 'wrap'
    }
  }, /*#__PURE__*/React.createElement(Buscador, {
    valor: q,
    onChange: e => {
      setQ(e.target.value);
      setPagina(0);
    }
  }), /*#__PURE__*/React.createElement(Check, {
    etiqueta: "Sin categor\xEDa",
    marcado: sinCat,
    onChange: e => setSinCat(e.target.checked)
  }), /*#__PURE__*/React.createElement(Check, {
    etiqueta: "Sin rodeo",
    marcado: sinRodeo,
    onChange: e => setSinRodeo(e.target.checked)
  }), /*#__PURE__*/React.createElement(Campo, {
    style: {
      flex: '0 0 auto',
      minWidth: 170
    },
    sobreFondo: true,
    opciones: [{
      valor: '',
      etiqueta: 'Todos los rodeos'
    }].concat(D.rodeos.map(r => ({
      valor: r.idRodeo,
      etiqueta: r.nombre
    }))),
    onChange: () => {}
  }), /*#__PURE__*/React.createElement(Campo, {
    sobreFondo: true,
    style: {
      flex: '0 0 auto',
      minWidth: 170
    },
    opciones: [{
      valor: '',
      etiqueta: 'Todas las categorías'
    }].concat(D.categorias.map(c => ({
      valor: c.idCategoria,
      etiqueta: c.nombre
    }))),
    onChange: () => {}
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      marginLeft: 'auto',
      font: 'var(--text-label)',
      color: 'var(--text-muted)'
    }
  }, filas.length.toLocaleString('es-AR'), " animales")), /*#__PURE__*/React.createElement(Tarjeta, {
    denso: true
  }, /*#__PURE__*/React.createElement(Tabla, {
    vacio: "No hay animales que coincidan con la b\xFAsqueda.",
    columnas: [{
      clave: 'caravana',
      titulo: 'Caravana',
      numerico: true,
      render: a => /*#__PURE__*/React.createElement("a", {
        href: "#",
        onClick: e => {
          e.preventDefault();
          ir('animal', a.idAnimal);
        },
        style: {
          color: 'var(--text-link)',
          fontWeight: 'var(--fw-semibold)',
          textDecoration: 'none'
        }
      }, a.caravana)
    }, {
      clave: 'sexo',
      titulo: 'Sexo'
    }, {
      clave: 'raza',
      titulo: 'Raza',
      render: a => a.raza || '—'
    }, {
      clave: 'categoria',
      titulo: 'Categoría',
      render: a => a.sinCategoria ? /*#__PURE__*/React.createElement(Etiqueta, {
        tono: "falta"
      }, "sin categor\xEDa") : a.categoria
    }, {
      clave: 'rodeo',
      titulo: 'Rodeo',
      render: a => a.rodeo ? a.rodeo : /*#__PURE__*/React.createElement(Etiqueta, {
        tono: "falta"
      }, "sin rodeo")
    }, {
      clave: 'validacion',
      titulo: 'Validación'
    }],
    filas: filas.map(a => Object.assign({
      id: a.idAnimal
    }, a))
  }), /*#__PURE__*/React.createElement(Paginado, {
    pagina: pagina,
    totalPaginas: 58,
    onCambio: setPagina
  })));
}
window.Padron = Padron;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/anpael-campo/Padron.jsx", error: String((e && e.message) || e) }); }

// ui_kits/anpael-campo/Planillas.jsx
try { (() => {
const {
  Marca,
  Tarjeta,
  Boton,
  Campo,
  Tabla,
  Aviso
} = window.ANPAELDesignSystem_5fc50e;
function Planillas({
  ir
}) {
  const D = window.ANPAEL_DATOS;
  const [rodeo, setRodeo] = React.useState('');
  const [trabajo, setTrabajo] = React.useState('');
  const [generado, setGenerado] = React.useState(false);
  return /*#__PURE__*/React.createElement("main", {
    style: {
      maxWidth: 'var(--ancho-lectura)',
      margin: '8vh auto',
      padding: '0 16px'
    }
  }, /*#__PURE__*/React.createElement(Boton, {
    variante: "texto",
    tamano: "sm",
    onClick: () => ir('estado'),
    style: {
      marginBottom: 14,
      textDecoration: 'none',
      color: 'var(--text-muted)'
    }
  }, "\u2039 Inicio"), /*#__PURE__*/React.createElement(Marca, {
    bajada: "Santa Ana \xB7 planillas de trabajo",
    style: {
      marginBottom: 18
    }
  }), /*#__PURE__*/React.createElement(Tarjeta, null, /*#__PURE__*/React.createElement("p", {
    style: {
      color: 'var(--text-muted)',
      font: 'var(--text-small)',
      margin: '0 0 16px'
    }
  }, "Eleg\xED el rodeo y el trabajo: se abre un PDF con las caravanas de ese rodeo, listo para imprimir."), /*#__PURE__*/React.createElement("form", {
    onSubmit: e => {
      e.preventDefault();
      setGenerado(true);
    },
    style: {
      display: 'grid',
      gap: 14
    }
  }, /*#__PURE__*/React.createElement(Campo, {
    etiqueta: "Rodeo",
    valor: rodeo,
    onChange: e => {
      setRodeo(e.target.value);
      setGenerado(false);
    },
    opciones: [{
      valor: '',
      etiqueta: 'Elegir rodeo…'
    }].concat(D.rodeos.map(r => ({
      valor: r.idRodeo,
      etiqueta: r.nombre
    })))
  }), /*#__PURE__*/React.createElement(Campo, {
    etiqueta: "Trabajo",
    valor: trabajo,
    onChange: e => {
      setTrabajo(e.target.value);
      setGenerado(false);
    },
    opciones: [{
      valor: '',
      etiqueta: 'Elegir trabajo…'
    }].concat(D.trabajos.map(t => ({
      valor: t.valor,
      etiqueta: t.etiqueta
    })))
  }), /*#__PURE__*/React.createElement(Boton, {
    tipo: "submit",
    deshabilitado: !rodeo || !trabajo,
    style: {
      justifySelf: 'start'
    }
  }, "Generar PDF")), generado ? /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 16,
      display: 'grid',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement(Aviso, {
    tono: "ok"
  }, "La planilla se abri\xF3 en una pesta\xF1a nueva."), /*#__PURE__*/React.createElement("div", {
    style: {
      border: 'var(--borde-fino)',
      borderRadius: 'var(--radio-md)',
      padding: 14,
      background: 'var(--n25)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--text-eyebrow)',
      letterSpacing: 'var(--ls-caps)',
      color: 'var(--text-muted)',
      marginBottom: 10
    }
  }, "VISTA PREVIA DE LA PLANILLA"), /*#__PURE__*/React.createElement(Tabla, {
    columnas: [{
      clave: 'caravana',
      titulo: 'Caravana',
      numerico: true
    }, {
      clave: 'r',
      titulo: 'Resultado'
    }, {
      clave: 't',
      titulo: 'Tamaño'
    }, {
      clave: 'o',
      titulo: 'Observaciones'
    }],
    filas: [{
      id: 1,
      caravana: '0075',
      r: '',
      t: '',
      o: ''
    }, {
      id: 2,
      caravana: '0344',
      r: '',
      t: '',
      o: ''
    }, {
      id: 3,
      caravana: '0902',
      r: '',
      t: '',
      o: ''
    }, {
      id: 4,
      caravana: '',
      r: '',
      t: '',
      o: ''
    }]
  }))) : null, /*#__PURE__*/React.createElement("p", {
    style: {
      font: 'var(--text-caption)',
      color: 'var(--text-muted)',
      margin: '16px 0 0'
    }
  }, "\xBFYa trabajaste con la planilla impresa?", ' ', /*#__PURE__*/React.createElement("a", {
    href: "#",
    onClick: e => {
      e.preventDefault();
      ir('cargar');
    },
    style: {
      color: 'var(--text-link)',
      fontWeight: 'var(--fw-semibold)'
    }
  }, "Cargar resultados"))));
}
window.Planillas = Planillas;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/anpael-campo/Planillas.jsx", error: String((e && e.message) || e) }); }

// ui_kits/anpael-campo/datos.js
try { (() => {
// Datos falsos con la forma real de la API (frontend/src/api/animales.ts).
window.ANPAEL_DATOS = function () {
  const rodeos = [{
    idRodeo: 1,
    nombre: 'Rodeo 1 - Vacas CUT'
  }, {
    idRodeo: 2,
    nombre: 'Rodeo 2 - Vaquillonas'
  }, {
    idRodeo: 3,
    nombre: 'Rodeo 3 - Toros'
  }, {
    idRodeo: 4,
    nombre: 'Rodeo 4 - Destete'
  }];
  const categorias = [{
    idCategoria: 1,
    nombre: 'Vaca'
  }, {
    idCategoria: 2,
    nombre: 'Vaquillona'
  }, {
    idCategoria: 3,
    nombre: 'Toro'
  }, {
    idCategoria: 4,
    nombre: 'Ternero'
  }];
  const animales = [{
    idAnimal: 101,
    caravana: '0075',
    sexo: 'H',
    raza: 'Angus',
    categoria: 'Vaquillona',
    sinCategoria: false,
    rodeo: null,
    validacion: 'pendiente'
  }, {
    idAnimal: 102,
    caravana: '0112',
    sexo: 'M',
    raza: 'Braford',
    categoria: null,
    sinCategoria: true,
    rodeo: 'Rodeo 3 - Toros',
    validacion: 'pendiente'
  }, {
    idAnimal: 103,
    caravana: '0344',
    sexo: 'H',
    raza: 'Angus',
    categoria: 'Vaca',
    sinCategoria: false,
    rodeo: 'Rodeo 1 - Vacas CUT',
    validacion: 'ok'
  }, {
    idAnimal: 104,
    caravana: '0501',
    sexo: 'H',
    raza: null,
    categoria: null,
    sinCategoria: true,
    rodeo: null,
    validacion: 'pendiente'
  }, {
    idAnimal: 105,
    caravana: '0718',
    sexo: 'M',
    raza: 'Hereford',
    categoria: 'Ternero',
    sinCategoria: false,
    rodeo: 'Rodeo 4 - Destete',
    validacion: 'ok'
  }, {
    idAnimal: 106,
    caravana: '0902',
    sexo: 'H',
    raza: 'Angus',
    categoria: 'Vaca',
    sinCategoria: false,
    rodeo: null,
    validacion: 'pendiente'
  }];
  const historial = {
    101: [{
      idEvento: 9001,
      fecha: '14/03/2026',
      tipoTrabajo: 'TACTO',
      detalle: 'Prenada - mediana',
      comentario: null
    }, {
      idEvento: 9002,
      fecha: '02/02/2026',
      tipoTrabajo: 'PESADA',
      detalle: '412,5 kg',
      comentario: 'pesada en la manga chica'
    }, {
      idEvento: 9003,
      fecha: '11/11/2025',
      tipoTrabajo: 'SANIDAD',
      detalle: 'Ivermectina - 12 ml',
      comentario: null
    }],
    102: [{
      idEvento: 9101,
      fecha: '20/02/2026',
      tipoTrabajo: 'REVISION_TOROS',
      detalle: 'CE 36,5 cm - CC 3,5 - apto',
      comentario: null
    }]
  };
  const trabajos = [{
    valor: 'TACTO',
    etiqueta: 'Tacto'
  }, {
    valor: 'PESADA',
    etiqueta: 'Pesada'
  }, {
    valor: 'REVISION_TOROS',
    etiqueta: 'Revision de toros'
  }, {
    valor: 'SANIDAD',
    etiqueta: 'Sanidad'
  }, {
    valor: 'DESTETE',
    etiqueta: 'Destete'
  }];
  return {
    rodeos,
    categorias,
    animales,
    historial,
    trabajos
  };
}();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/anpael-campo/datos.js", error: String((e && e.message) || e) }); }

// ui_kits/anpael-campo/doc-page.js
try { (() => {
// @ds-adherence-ignore -- omelette starter scaffold (raw elements/hex/px by design)
// Copied omelette starter. Re-running copy_starter_component with this kind overwrites this file with the latest version (page content is unaffected).
/* BEGIN USAGE */
/**
 * <doc-page> — paged-document shell for printable HTML.
 *
 * FIRST, decide how the document paginates — up front, before building:
 *
 * - FLOWING document (the default): write the whole document as one
 *   normal HTML flow inside <doc-page>; the browser's print engine
 *   splits it onto pages at export. Use for long-form documents with a
 *   single text flow: reports, memos, letters, essays.
 * - EXPLICIT pagination: a fixed set of pre-paginated pages, one
 *   <section class="page"> child per page. Use when the user asks for a
 *   specific page count, or the design implies one: a one-page resume, a
 *   two-sided flier, a poster, a certificate, a brochure — any richly
 *   laid-out document without a single text flow.
 * - If in doubt, ask the user as part of the build.
 *
 * PAGE SIZING — paper differs by country (letter vs A4), so the printed
 * sheet is not one fixed truth:
 * - FLOWING documents pin NO paper size: the print engine paginates
 *   onto the user's real paper, and the content reflows to it.
 * - EXPLICITLY PAGINATED documents print each page at a FIXED page box
 *   with overflow hidden — letter by default, size="a4" for a clearly
 *   metric user, the user's chosen paper when they export. Design each
 *   page to FILL that box, fitting letter and A4 alike without overlap.
 * - width/height pin an explicit fixed size, ONLY when the user gives
 *   one.
 * Never write your own @page rule or hard-code paper dimensions in the
 * content.
 *
 * Sizing modes (attributes):
 *   (none)                      — portrait: flowing docs use the user's
 *           paper; explicitly paginated pages use the named size box
 *           (letter unless size="a4")
 *   orientation="landscape"     — the same, landscape
 *   width / height              — explicit fixed size, ONLY when the user
 *           gives one (e.g. width="22in" height="30in" for a 22×30
 *           poster): the page IS the design's size, printed at true
 *           dimensions (or scaled onto the user's paper at print time).
 *           Any absolute CSS length: px/in/mm/cm/pt/pc.
 * The component announces the chosen mode to the host app at runtime (a
 * meta tag it injects), so the print path can inject the user's true
 * paper size.
 *
 * On screen the document renders on a desk background: a flowing
 * document as one tall scrolling sheet (Google Docs' pageless view);
 * explicitly paginated documents as one card per page.
 *
 * EXPLICIT pagination usage:
 *   <style>doc-page:not(:defined){visibility:hidden}</style>
 *   <doc-page>
 *     <section class="page" id="p1">…one page's design…</section>
 *     <section class="page" id="p2">…</section>
 *   </doc-page>
 *   <script src="doc-page.js"></script>
 * How the page box works, concretely: each .page prints as ONE full-bleed
 * sheet at a FIXED physical size — letter by default (set size="a4" for
 * a clearly metric user), the user's chosen paper when they export —
 * with overflow hidden. Nothing scrolls and nothing reflows onto a next
 * sheet: content that misses the box is CLIPPED. Design each page to
 * FILL that page box, and to fit it — letter and A4 alike — without
 * overlap. Each page is a size container; don't size anything in
 * viewport units (they track the window, not the page), and never set
 * width or height on the .page section itself (the component sizes the
 * page box; an authored height like 100% is meaningless at print and is
 * overridden). The component owns the page box, the screen card chrome,
 * and the page breaks (never add your own break-before/after). Don't mix
 * .page sections with flowing content or header/footer slots in the same
 * document.
 *
 * FLOWING usage:
 *   <style>doc-page:not(:defined){visibility:hidden}</style>
 *   <doc-page margin="0.75in">
 *     <h1>Title</h1>
 *     <p>…body…</p>
 *   </doc-page>
 *   <script src="doc-page.js"></script>
 * There is no manual page-splitting — the browser's print engine
 * paginates at export. Standard break-hygiene rules (`break-inside:
 * avoid` on figures, code blocks, images and table rows; `orphans/
 * widows: 3`) are applied so paragraphs and groups split cleanly. On
 * screen and at print, headings default to `text-wrap: balance` and
 * body text to `text-wrap: pretty`; the defaults have zero specificity,
 * so any text-wrap you declare wins.
 *
 * Other attributes:
 *   size    — letter | a4 | legal (default letter). Flowing documents:
 *           preview proportion only — it does NOT pin their printed
 *           paper (the print dialog's paper governs); leave it alone
 *           there. Explicitly paginated documents: it sets the page box
 *           the cards and the pinned @page share (the export dialog's
 *           choice overrides both at print) — set size="a4" for a
 *           clearly metric user. Scaled-fit: names the sheet the fit is
 *           computed against, same a4-for-metric-users advice.
 *   content-width / content-height — the design's own fixed dimensions
 *           (CSS lengths), for scaling a fixed-size design ONTO the
 *           named sheet: content lays out at exactly this size, and the
 *           component scales it to fit that sheet's printable area
 *           (centered horizontally, top-aligned; the export dialog
 *           re-fits to the user's actual paper choice where available).
 *           Both must be set; they do not change the page box. For pages
 *           WITHOUT running header/footer slots.
 *   margin  — printable inset on every page of a FLOWING document
 *           (default 0.75in); margin="0" makes pages full-bleed.
 *           Explicitly paginated pages are always full-bleed.
 *
 * Running header/footer (flowing documents only): give an element
 * `slot="header"` or `slot="footer"` and it repeats on every printed
 * page via `position: fixed`. To keep body text from sliding under it,
 * the component prints inside a single-cell table whose <thead>/<tfoot>
 * are spacers sized to the header/footer height — browsers repeat
 * thead/tfoot on every page, so each sheet's content starts below the
 * header and ends above the footer. On screen the header/footer render
 * once at the top/bottom of the sheet.
 *
 * At print the component injects `@page { margin: 0 }` (which leaves
 * Chrome no margin box to draw its date/URL/page-count header in) and
 * moves the visual margin onto the sheet's own padding. It also marks
 * the document as owning its print CSS (a
 * `meta[name="omelette-owns-print"]` it injects at runtime), so the
 * PDF export never injects page-geometry CSS of its own on top.
 *
 * Print best practices for the content you author:
 * - Multi-column text: use CSS columns (`column-count` +
 *   `column-gap`), never side-by-side flex/grid columns — only real
 *   CSS columns flow and break across pages. `column-span: all` lets
 *   a heading span the columns; `hyphens: auto` (needs `lang` on
 *   the html element) keeps narrow columns readable.
 * - Page breaks in flowing documents: `break-before: page` on an
 *   element that must start a new page (a chapter, an appendix). Add
 *   your own kept-together blocks (callouts, stat tiles, cards) to a
 *   `break-inside: avoid` rule, and keep each one shorter than a page.
 * - Extend `orphans: 3; widows: 3` to any custom text blocks you add
 *   (p and li are covered by default).
 * - Give long tables a <thead> — browsers repeat it on every printed
 *   page.
 * - No `position: fixed`/`sticky` and no viewport units in content:
 *   fixed elements stamp every printed page (running headers/footers go
 *   in the component's slots) and `100vh` mis-sizes at print.
 *
 * Author content as static HTML so the user can click-to-edit any text
 * directly. Do not set width/padding/background on the document body —
 * the component owns the sheet box.
 */
/* END USAGE */

(() => {
  const PAPER = {
    letter: ['8.5in', '11in'],
    a4: ['210mm', '297mm'],
    legal: ['8.5in', '14in']
  };
  const CSS_LENGTH = /^\d+(\.\d+)?(px|in|mm|cm|pt|pc)$/;
  // Unitless "0" is a valid CSS length and the natural way to write
  // margin="0"; normalise it to 0px so max()/calc() (which reject a bare
  // number) keep working.
  const safeLen = (v, fb) => {
    v = (v || '').trim();
    return v === '0' ? '0px' : CSS_LENGTH.test(v) ? v : fb;
  };
  // WebKit (Safari and every iOS browser shell) never repeats a table's
  // thead/tfoot on printed pages (WebKit bug 17205), so the spacer-borne
  // vertical margins of a FLOWING document reach only the first page
  // there. Engine check, not browser check: vendor is 'Apple Computer,
  // Inc.' exactly for WebKit and 'Google Inc.' for Blink.
  const WK_PRINT = /apple/i.test(navigator.vendor || '');
  // CSS length → px number (CSS absolute units are exact: 1in = 96px).
  // Returns NaN for anything safeLen would reject — callers gate on it.
  const PX_PER = {
    px: 1,
    in: 96,
    mm: 96 / 25.4,
    cm: 96 / 2.54,
    pt: 96 / 72,
    pc: 16
  };
  const toPx = v => {
    const m = /^(\d+(?:\.\d+)?)(px|in|mm|cm|pt|pc)$/.exec((v || '').trim());
    return m ? parseFloat(m[1]) * PX_PER[m[2]] : NaN;
  };
  const stylesheet = `
    :host {
      position: relative;
      display: block;
      /* When the viewport is narrower than the page, grow to wrap the
       * sheet (plus this padding) instead of staying viewport-width, so
       * the desk background and right margin reach the sheet's far edge
       * in the horizontal scroll. */
      min-width: max-content;
      min-height: 100vh;
      background: #f5f5f4;
      padding: 48px 24px;
      box-sizing: border-box;
      font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", Arial, sans-serif;
      --doc-page-w: 8.5in;
      --doc-page-h: 11in;
      --doc-page-margin: 0.75in;
      --doc-hdr-h: 0px;
      --doc-ftr-h: 0px;
      --doc-hdr-pad: 0px;
      --doc-ftr-pad: 0px;
    }
    .sheet {
      width: var(--doc-page-w);
      margin: 0 auto;
      background: #fff;
      box-shadow: 0 2px 10px rgba(20, 20, 19, 0.12);
      border-radius: 7px;
      box-sizing: border-box;
      padding: var(--doc-page-margin);
    }
    .frame { width: 100%; border-collapse: collapse; }
    /* Scaled-fit mode (content-width/content-height): the inner .fit box
     * lays the content out at its authored fixed size and scales it onto
     * the printable area; .fit-box reserves the scaled footprint in flow
     * (transforms don't affect layout) and centers it. Without the mode,
     * both divs are unstyled block pass-throughs. */
    /* Explicit pagination: direct .page children are the pages. The sheet
     * becomes a transparent stack and each page carries the card look on
     * screen; at print each page is exactly one full-bleed sheet. The
     * ::slotted defaults are deliberately weak (document CSS wins), so
     * authored page styling can override any of this. */
    .sheet.paginated {
      background: transparent;
      box-shadow: none;
      border-radius: 0;
      padding: 0;
    }
    .paginated ::slotted(.page) {
      position: relative;
      display: block;
      width: 100%;
      aspect-ratio: var(--doc-page-ar);
      container-type: size;
      overflow: hidden;
      box-sizing: border-box;
      background: #fff;
      border-radius: 7px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.25);
      print-color-adjust: exact;
      -webkit-print-color-adjust: exact;
      break-inside: avoid;
    }
    .paginated ::slotted(.page:not(:first-child)) { margin-top: 1rem; }
    @media print {
      .sheet.paginated { padding: 0; }
      /* The flowing-document vertical inset lives on the repeating
       * thead/tfoot spacers, not the sheet padding — they must go too,
       * or each full-sheet .page is pushed ~margin down and spills onto
       * a second sheet. Paginated pages are full-bleed by definition
       * (content owns its insets). */
      .sheet.paginated .hdr-space,
      .sheet.paginated .ftr-space { height: 0; }
      .paginated ::slotted(.page) {
        border-radius: 0 !important;
        box-shadow: none !important;
        margin: 0 !important;
        /* Physical page-box sizing, no viewport units: Safari resolves
         * 100vh against the window, not the page box, so a vh-sized card
         * paginates wrong there. --doc-page-w/h are the named size by
         * default and are overridden to the user's chosen paper by the
         * export path, so every card is exactly one sheet either way.
         * Width + height (same source values as @page size) rather than
         * width + aspect-ratio: the ratio is a 6-decimal rounding of the
         * same division, and a few millionths of overflow would spill a
         * blank sheet after every page. The screen-only aspect-ratio
         * (preview proportions) must not leak into print. cqh typography
         * tracks the same box.
         *
         * Every declaration is !important: per CSS Scoping, unimportant
         * shadow ::slotted rules LOSE to the document context, so a page
         * section's authored inline style would silently beat this print
         * geometry. A model-authored height:100% did exactly that — the
         * percentage resolves as auto in the all-auto print ancestry, the
         * base rule's size containment turns auto into ZERO, and
         * overflow:hidden then paints nothing: a blank PDF with perfect
         * page boxes. At print the component's geometry is the design's
         * whole contract, so it must win over any authored sizing. */
        aspect-ratio: auto !important;
        width: var(--doc-page-w) !important;
        height: var(--doc-page-h) !important;
        overflow: hidden !important;
      }
      .paginated ::slotted(.page:not(:first-child)) {
        break-before: page !important;
        margin-top: 0 !important;
      }
    }
    .fit-mode .fit-box {
      width: calc(var(--doc-fit-w) * var(--doc-fit-scale));
      height: calc(var(--doc-fit-h) * var(--doc-fit-scale));
      margin: 0 auto;
      break-inside: avoid;
    }
    /* Monolithic at print: Blink slices a transform-scaled child at
     * fragmentainer boundaries mapped in UNSCALED layout coordinates
     * (transforms are paint-time), so the .fit box (authored size, e.g.
     * 1400x990) gets cut at the page's free block space and spills onto
     * a second sheet even though its SCALED footprint fits the page by
     * construction. overflow:hidden makes .fit-box a scroll container —
     * monolithic under fragmentation (css-break-3) — so the scaled
     * content prints atomically on one sheet. No clipping for content
     * within the authored box: .fit-box is calc-sized to exactly the
     * scaled footprint. (Content that bleeds past content-width/height
     * is clipped at the footprint — fit mode's contract; it previously
     * painted beyond it at print.) Print-only, so the screen rendering
     * keeps visible overflow for editor affordances.
     * The export path injects the same rule into frozen copies
     * (print-eval.ts om-print-fit-contain). The .fit-mode scope is
     * load-bearing: .fit-box wraps slotted content in EVERY mode, and an
     * unscoped overflow:hidden would make whole flowing documents
     * monolithic (one truncated sheet). overflow:hidden, never clip —
     * clip is not a scroll container, so not monolithic. */
    @media print {
      .fit-mode .fit-box { overflow: hidden; }
    }
    .fit-mode .fit {
      width: var(--doc-fit-w);
      height: var(--doc-fit-h);
      transform: scale(var(--doc-fit-scale));
      transform-origin: top left;
    }
    .frame td, .frame th { padding: 0; text-align: left; font-weight: inherit; }
    .hdr-space { height: var(--doc-hdr-h); }
    .ftr-space { height: var(--doc-ftr-h); }
    ::slotted([slot="header"]),
    ::slotted([slot="footer"]) { display: block; box-sizing: border-box; }
    @media print {
      :host { background: none; padding: 0; min-width: 0; min-height: 0; }
      .sheet {
        width: auto; margin: 0; box-shadow: none; border-radius: 0;
        padding: 0 var(--doc-page-margin);
      }
      /* The thead/tfoot spacers repeat on every page, so they carry the
       * vertical page margin (which the sheet's own padding cannot, since
       * that padding is consumed once on the first/last page). The running
       * header/footer are fixed inside that band. */
      /* The 0.35in is breathing room between a running header/footer and
       * the body; without one the spacer is exactly the page margin, so a
       * margin="0" full-bleed document gets truly full-bleed pages. */
      .hdr-space { height: max(var(--doc-page-margin), calc(var(--doc-hdr-h) + var(--doc-hdr-pad))); }
      .ftr-space { height: max(var(--doc-page-margin), calc(var(--doc-ftr-h) + var(--doc-ftr-pad))); }
      /* WebKit flowing documents: @page carries the vertical margin (see
       * _syncPrintPageRule), so the spacers keep only whatever a running
       * header/footer needs BEYOND it — page 1 would otherwise double its
       * top inset. Paginated sheets already zero their spacers above. */
      .sheet.wk-print:not(.paginated) .hdr-space { height: max(0px, calc(max(var(--doc-page-margin), calc(var(--doc-hdr-h) + var(--doc-hdr-pad))) - var(--doc-page-margin))); }
      .sheet.wk-print:not(.paginated) .ftr-space { height: max(0px, calc(max(var(--doc-page-margin), calc(var(--doc-ftr-h) + var(--doc-ftr-pad))) - var(--doc-page-margin))); }
      ::slotted([slot="header"]) {
        position: fixed; top: 0; left: 0; right: 0; margin: 0;
        padding: calc(var(--doc-page-margin) * 0.45) var(--doc-page-margin) 0;
      }
      ::slotted([slot="footer"]) {
        position: fixed; bottom: 0; left: 0; right: 0; margin: 0;
        padding: 0 var(--doc-page-margin) calc(var(--doc-page-margin) * 0.45);
      }
    }
  `;
  class DocPage extends HTMLElement {
    static get observedAttributes() {
      return ['size', 'width', 'height', 'margin', 'orientation', 'content-width', 'content-height'];
    }
    constructor() {
      super();
      this._root = this.attachShadow({
        mode: 'open'
      });
      this._mo = typeof MutationObserver === 'function' ? new MutationObserver(() => this._scheduleMeasure()) : null;
    }

    /** The named paper's [w, h], swapped when orientation="landscape".
     *  Only the named size swaps — explicit width/height are exact values
     *  the author already oriented. */
    _paperSize() {
      const named = PAPER[(this.getAttribute('size') || '').toLowerCase()] || PAPER.letter;
      const landscape = (this.getAttribute('orientation') || '').trim().toLowerCase() === 'landscape';
      return landscape ? [named[1], named[0]] : named;
    }
    get pageWidth() {
      return safeLen(this.getAttribute('width'), this._paperSize()[0]);
    }
    get pageHeight() {
      return safeLen(this.getAttribute('height'), this._paperSize()[1]);
    }
    get pageMargin() {
      return safeLen(this.getAttribute('margin'), '0.75in');
    }

    /** Scaled-fit mode's content box [w, h] as CSS lengths, or null when
     *  the mode is off (either attribute missing/invalid/zero — a partial
     *  declaration falls back to normal flow rather than guessing). */
    _contentFit() {
      const w = safeLen(this.getAttribute('content-width'), null);
      const h = safeLen(this.getAttribute('content-height'), null);
      if (!w || !h) return null;
      const wPx = toPx(w),
        hPx = toPx(h);
      return wPx > 0 && hPx > 0 ? [w, h, wPx, hPx] : null;
    }
    connectedCallback() {
      if (!this._sheet) this._render();
      this._syncSize();
      this._syncPrintPageRule();
      this._ensureTextWrapDefaults();
      this._ensureOwnsPrintMeta();
      this._syncFixedSizeMeta();
      this._syncPrintSizingMeta();
      if (this._mo) this._mo.observe(this, {
        subtree: true,
        childList: true,
        characterData: true,
        attributes: true
      });
      this._onResize = () => this._scheduleMeasure();
      window.addEventListener('resize', this._onResize);
      if (document.fonts && document.fonts.ready) {
        document.fonts.ready.then(() => this._scheduleMeasure());
      }
      this._scheduleMeasure();
    }
    disconnectedCallback() {
      window.removeEventListener('resize', this._onResize);
      if (this._mo) this._mo.disconnect();
      if (this._raf) {
        cancelAnimationFrame(this._raf);
        this._raf = null;
      }
      // Drop the head rules when the last doc-page leaves, so a deleted
      // document's @page geometry and text-wrap defaults can't apply to
      // whatever replaces it.
      const survivor = document.querySelector('doc-page');
      if (!survivor) {
        ['doc-page-print', 'doc-page-text-wrap', 'doc-page-owns-print', 'doc-page-fixed-size', 'doc-page-print-sizing'].forEach(id => {
          const tag = document.getElementById(id);
          if (tag) tag.remove();
        });
        // A live deck-stage deferred its own print-sizing meta to ours —
        // hand the page-global meta over so the deck isn't left unmarked.
        const deck = document.querySelector('deck-stage');
        if (deck && typeof deck._ensurePrintSizingMeta === 'function') {
          deck._ensurePrintSizingMeta();
        }
      } else {
        // A departed owner hands each page-global meta to whatever
        // doc-page remains (or it's removed).
        if (typeof survivor._syncFixedSizeMeta === 'function') {
          survivor._syncFixedSizeMeta();
        }
        if (typeof survivor._syncPrintSizingMeta === 'function') {
          survivor._syncPrintSizingMeta();
        }
      }
    }
    attributeChangedCallback() {
      if (!this._sheet) return;
      this._syncSize();
      this._syncPrintPageRule();
      this._syncFixedSizeMeta();
      this._syncPrintSizingMeta();
      this._scheduleMeasure();
    }
    _render() {
      this._root.innerHTML = `
        <style>${stylesheet}</style>
        <style id="vars"></style>
        <div class="sheet" data-screen-label="Document">
          <table class="frame" role="presentation">
            <thead><tr><th><div class="hdr-space"><slot name="header"></slot></div></th></tr></thead>
            <tbody><tr><td class="body"><div class="fit-box"><div class="fit"><slot></slot></div></div></td></tr></tbody>
            <tfoot><tr><td><div class="ftr-space"><slot name="footer"></slot></div></td></tr></tfoot>
          </table>
        </div>`;
      this._sheet = this._root.querySelector('.sheet');
      this._vars = this._root.getElementById('vars');
    }

    /** Runtime sizing lives in a shadow <style> :host rule, never on the
     *  light-DOM host element, so serialize-persist can't write it back. */
    _syncSize(hdrH, ftrH) {
      // Scaled-fit mode: content at its authored size, scaled onto the
      // printable area (page minus margins on both axes). The factor is a
      // plain number var so calc(length * number) stays valid; 4 decimals
      // keeps the shadow style stable across re-measures. Upscaling is
      // allowed — print transforms are vector, so text and CSS stay crisp
      // (raster images soften, which the catalog bullet warns about).
      const fit = this._contentFit();
      let fitVars = '';
      if (fit) {
        const marginPx = toPx(this.pageMargin) || 0;
        const availW = toPx(this.pageWidth) - 2 * marginPx;
        const availH = toPx(this.pageHeight) - 2 * marginPx;
        const scale = Math.min(availW / fit[2], availH / fit[3]);
        if (scale > 0 && Number.isFinite(scale)) {
          fitVars = '--doc-fit-w:' + fit[0] + ';' + '--doc-fit-h:' + fit[1] + ';' + '--doc-fit-scale:' + scale.toFixed(4) + ';';
        }
      }
      this._sheet.classList.toggle('fit-mode', !!fitVars);
      // Numeric w/h ratio for the paginated page cards' aspect-ratio —
      // aspect-ratio takes a number, not a length ratio, so compute it
      // here (CSS length division isn't portable). 6 decimals keeps the
      // shadow style stable across re-syncs.
      const arW = toPx(this.pageWidth);
      const arH = toPx(this.pageHeight);
      const ar = arW > 0 && arH > 0 ? (arW / arH).toFixed(6) : '0.772727';
      this._vars.textContent = ':host{' + fitVars + '--doc-page-ar:' + ar + ';' + '--doc-page-w:' + this.pageWidth + ';' + '--doc-page-h:' + this.pageHeight + ';' + '--doc-page-margin:' + this.pageMargin + ';' + '--doc-hdr-h:' + (hdrH || 0) + 'px;' + '--doc-ftr-h:' + (ftrH || 0) + 'px;' + '--doc-hdr-pad:' + (hdrH ? '0.35in' : '0px') + ';' + '--doc-ftr-pad:' + (ftrH ? '0.35in' : '0px') + '}';
    }

    /** @page is a no-op inside shadow DOM, so the rule lives in <head>.
     *  Re-appended on every sync so it stays last in source order — the
     *  @page cascade is source-order per descriptor, so this rule wins
     *  over any other @page rule in the document.
     *
     *  The @page SIZE is pinned where the page box IS part of the design:
     *  explicit-fixed-size mode (width + height authored), scaled-fit
     *  mode (the named sheet the fit targets), and explicit pagination
     *  (the named size the cards share — so card and sheet agree on
     *  every print path, and the export path's chosen paper overrides
     *  BOTH with one later rule). For FLOWING documents no paper size is
     *  emitted at all — the true size comes from the user's preference,
     *  injected by the export path or chosen in the print dialog — so a
     *  flowing document never fights the paper it lands on.
     *  margin: 0 is emitted in every mode: it leaves Chrome no margin box
     *  to draw its date/URL/page-count header in, and the visual margin
     *  lives on the sheet's own padding. */
    _syncPrintPageRule() {
      const id = 'doc-page-print';
      let tag = document.getElementById(id);
      if (!tag) {
        tag = document.createElement('style');
        tag.id = id;
      }
      document.head.appendChild(tag);
      // Three print-geometry regimes:
      // - true-size: the page IS the design — pin its exact size.
      // - scaled-fit (content-width/height): the fit factor is computed
      //   against the NAMED paper's printable area, so that paper must
      //   stay pinned or the scaled content overflows a smaller sheet
      //   (the export path re-fits and re-pins at print time on top).
      // - default modes: no paper size — but landscape still needs the
      //   paper-agnostic 'size: landscape' keyword, because the size
      //   descriptor is what carries orientation; without it a landscape
      //   document prints portrait whenever nothing injects a size.
      const landscape = (this.getAttribute('orientation') || '').trim().toLowerCase() === 'landscape';
      // Explicit pagination pins the page box to the SAME values that
      // size the cards (the named size by default, the export path's
      // chosen paper when its later rule overrides both) — card and
      // sheet agree on every print path, and a mismatched real paper
      // shrinks-to-fit in the dialog instead of clipping a Letter card
      // on A4. Declared before the paginated read below so both derive
      // from one check.
      const paginatedNow = this.querySelector(':scope > .page') !== null;
      const sizeDescriptor = this._trueSizePx() ? 'size: ' + this.pageWidth + ' ' + this.pageHeight + '; ' : this._contentFit() ? 'size: ' + this.pageWidth + ' ' + this.pageHeight + '; ' : paginatedNow ? 'size: ' + this.pageWidth + ' ' + this.pageHeight + '; ' : landscape ? 'size: landscape; ' : '';
      // WebKit never repeats the thead/tfoot spacers that carry a flowing
      // document's vertical page margins (see WK_PRINT above), so pages
      // after the first print edge-to-edge there. Carry the VERTICAL
      // margins on @page for WebKit instead, and the shadow print CSS
      // trims the first-page spacers by the same amount (.sheet.wk-print
      // rules). Horizontal inset stays on the sheet's own padding in
      // every engine. Blink keeps margin: 0 (a nonzero margin there
      // re-opens the box Chrome draws its header furniture in). One cost,
      // learned in testing: Safari's own date/URL headers are a USER
      // dialog setting ("Print headers and footers") that renders in the
      // margin area when room exists — margin: 0 only suppressed it by
      // leaving no room, and no CSS controls it. The export dialog's
      // Safari guide teaches turning the setting off for flowing
      // documents. Explicitly paginated and fixed-size documents keep
      // margin: 0 everywhere: their pages ARE the sheet.
      const wkFlowing = WK_PRINT && !paginatedNow && !this._trueSizePx() && !this._contentFit();
      const marginDescriptor = wkFlowing ? 'margin: ' + this.pageMargin + ' 0; ' : 'margin: 0; ';
      // Shadow-internal marker (never serialized), kept in lockstep with
      // the @page decision above: the print CSS trims the first-page
      // spacers ONLY while @page actually carries the margins — a
      // true-size or scaled-fit sheet keeps margin: 0 and must keep its
      // spacers too. Re-synced here so attribute changes and pagination
      // flips move both together.
      if (this._sheet) this._sheet.classList.toggle('wk-print', wkFlowing);
      tag.textContent = '@page { ' + sizeDescriptor + marginDescriptor + '} ' + '@media print { html, body { margin: 0 !important; padding: 0 !important; background: none !important; height: auto !important; overflow: visible !important; } ' + 'h1,h2,h3,h4,h5,h6 { break-after: avoid; } ' + 'figure,pre,blockquote,img,svg,tr { break-inside: avoid; } ' + 'p,li { orphans: 3; widows: 3; } ' + '* { -webkit-print-color-adjust: exact; print-color-adjust: exact; ' + 'backdrop-filter: none !important; -webkit-backdrop-filter: none !important; } ' + '*, *::before, *::after { animation-delay: -99s !important; animation-duration: .001s !important; ' + 'animation-iteration-count: 1 !important; animation-fill-mode: both !important; ' + 'animation-play-state: running !important; transition-duration: 0s !important; } }';
    }

    /** Typographic defaults for document text: balance headings, avoid
     *  widowed/orphaned words in body copy (browsers without text-wrap
     *  support drop the declarations). Zero-specificity via :where() so
     *  any text-wrap authored on those elements wins; document-level so the
     *  rules reach the slotted (light DOM) content — shadow styles can't.
     *  data-omelette-injected marks the tag for the host editor to strip
     *  at serialize, so it is never written back as authored source. */
    _ensureTextWrapDefaults() {
      if (document.getElementById('doc-page-text-wrap')) return;
      const tag = document.createElement('style');
      tag.id = 'doc-page-text-wrap';
      tag.setAttribute('data-omelette-injected', '');
      tag.textContent = ':where(h1,h2,h3,h4,h5,h6){text-wrap:balance}' + ':where(p,li,blockquote,figcaption){text-wrap:pretty}';
      document.head.appendChild(tag);
    }

    /** Declares that this document owns its print CSS. The instant-PDF
     *  export checks for the meta by NAME PRESENCE alone (content is
     *  ignored) and skips its automatic print-CSS injections, so the
     *  component's @page geometry is never overridden by a heuristic.
     *  data-omelette-injected keeps it out of serialized source. */
    _ensureOwnsPrintMeta() {
      if (document.getElementById('doc-page-owns-print')) return;
      const tag = document.createElement('meta');
      tag.id = 'doc-page-owns-print';
      tag.name = 'omelette-owns-print';
      tag.content = 'true';
      tag.setAttribute('data-omelette-injected', '');
      document.head.appendChild(tag);
    }

    /** This page's valid true-size page box (explicit width AND height)
     *  as [w, h] px ints, or null when the mode is off. */
    _trueSizePx() {
      if (!safeLen(this.getAttribute('width'), null) || !safeLen(this.getAttribute('height'), null)) return null;
      const w = Math.round(toPx(this.pageWidth));
      const h = Math.round(toPx(this.pageHeight));
      return w > 0 && h > 0 ? [w, h] : null;
    }

    /** True-size pages (explicit width AND height) also declare the page
     *  box as the preview size: the in-app preview reads
     *  meta[name="omelette-fixed-size"] (content "W,H" in px ints) and
     *  scales the sheet into view — without it an 18in poster previews at
     *  true size with scrollbars. Never overrides an author-set meta
     *  (only the component's own id is managed). The meta is page-global
     *  while doc-page instances are not, so every sync recomputes the
     *  page-wide owner — the first connected true-size doc-page — and a
     *  non-true-size sibling's sync can never delete the owner's meta.
     *  Removed when no true-size page remains (the owner's disconnect
     *  re-syncs via any survivor) or when an author-set meta exists. */
    _syncFixedSizeMeta() {
      const id = 'doc-page-fixed-size';
      const own = document.getElementById(id);
      const authored = document.querySelector('meta[name="omelette-fixed-size"]:not([data-omelette-injected])');
      // The page-wide owner, not this instance: an upgraded true-size page
      // anywhere in the document keeps the meta alive and sized.
      let box = null;
      for (const el of document.querySelectorAll('doc-page')) {
        box = typeof el._trueSizePx === 'function' ? el._trueSizePx() : null;
        if (box) break;
      }
      if (!box || authored) {
        if (own) own.remove();
        return;
      }
      const tag = own || document.createElement('meta');
      tag.id = id;
      tag.name = 'omelette-fixed-size';
      tag.content = box[0] + ',' + box[1];
      tag.setAttribute('data-omelette-injected', '');
      if (!own) document.head.appendChild(tag);
    }

    /** This page's print-sizing mode: 'fixed' when an explicit width AND
     *  height are authored (the page is the design's own size), else the
     *  default paper in the authored orientation. */
    _printSizingMode() {
      if (this._trueSizePx()) return 'fixed';
      const landscape = (this.getAttribute('orientation') || '').trim().toLowerCase() === 'landscape';
      return landscape ? 'default-landscape' : 'default-portrait';
    }

    /** Announces the print-sizing mode to the host app:
     *  meta[name="omelette-print-sizing"] with content 'default-portrait',
     *  'default-landscape', or 'fixed' (fixed pages also carry the
     *  omelette-fixed-size meta with the page box in px). The export path
     *  probes it to decide what true paper size to inject at print time —
     *  in the default modes the component emits no paper size of its own.
     *  Same page-global ownership rules as the fixed-size meta above:
     *  first connected doc-page owns it, an authored meta is never
     *  overridden, removed when no doc-page remains. */
    _syncPrintSizingMeta() {
      const id = 'doc-page-print-sizing';
      const own = document.getElementById(id);
      const authored = document.querySelector('meta[name="omelette-print-sizing"]:not([data-omelette-injected])');
      // A fixed page wins outright (mirroring the fixed-size loop above,
      // so the two metas can never contradict each other in a mixed
      // multi-page document); otherwise the first page's mode holds.
      let mode = null;
      for (const el of document.querySelectorAll('doc-page')) {
        if (typeof el._printSizingMode !== 'function') continue;
        const m = el._printSizingMode();
        if (m === 'fixed') {
          mode = m;
          break;
        }
        if (mode === null) mode = m;
      }
      if (!mode || authored) {
        if (own) own.remove();
        return;
      }
      // A deck-stage that connected first injected its own meta and
      // defers to any existing one — take it over, or the document ends
      // up with two conflicting injected metas (a doc-page page is the
      // document; the deck re-ensures its meta if every doc-page leaves).
      const deckMeta = document.getElementById('deck-stage-print-sizing');
      if (deckMeta) deckMeta.remove();
      const tag = own || document.createElement('meta');
      tag.id = id;
      tag.name = 'omelette-print-sizing';
      tag.content = mode;
      tag.setAttribute('data-omelette-injected', '');
      if (!own) document.head.appendChild(tag);
    }
    _scheduleMeasure() {
      if (this._raf) return;
      this._raf = requestAnimationFrame(() => {
        this._raf = null;
        this._measure();
      });
    }

    /** Slot heights feed the print spacers (--doc-hdr-h / --doc-ftr-h), so
     *  they re-measure on content mutation, resize, and font load. The
     *  same pass detects explicit pagination (direct .page children) and
     *  toggles the sheet between the flowing-document card and the
     *  page-per-card stack — content edits can add or remove pages at any
     *  time, so this tracks the same mutations the measurement does. */
    _measure() {
      const hdr = this.querySelector(':scope > [slot="header"]');
      const ftr = this.querySelector(':scope > [slot="footer"]');
      const wasPaginated = this._sheet.classList.contains('paginated');
      this._sheet.classList.toggle('paginated', this.querySelector(':scope > .page') !== null);
      // The WebKit @page margin is flowing-only, so a pagination flip
      // must re-emit the rule (content edits can add or remove .page
      // sections at any time).
      if (this._sheet.classList.contains('paginated') !== wasPaginated) {
        this._syncPrintPageRule();
      }
      this._syncSize(hdr ? hdr.offsetHeight : 0, ftr ? ftr.offsetHeight : 0);
    }
  }
  if (!customElements.get('doc-page')) {
    customElements.define('doc-page', DocPage);
  }
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/anpael-campo/doc-page.js", error: String((e && e.message) || e) }); }

__ds_ns.Aviso = __ds_scope.Aviso;

__ds_ns.Boton = __ds_scope.Boton;

__ds_ns.Etiqueta = __ds_scope.Etiqueta;

__ds_ns.Marca = __ds_scope.Marca;

__ds_ns.Tarjeta = __ds_scope.Tarjeta;

__ds_ns.ItemHistorial = __ds_scope.ItemHistorial;

__ds_ns.ListaDatos = __ds_scope.ListaDatos;

__ds_ns.Paginado = __ds_scope.Paginado;

__ds_ns.Tabla = __ds_scope.Tabla;

__ds_ns.Buscador = __ds_scope.Buscador;

__ds_ns.Campo = __ds_scope.Campo;

__ds_ns.Check = __ds_scope.Check;

})();

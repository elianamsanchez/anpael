Tabla de listado (padron, resultados). Encabezado gris chico, filete de 1px entre filas, sin cebra ni bordes verticales.

```jsx
<Tabla
  columnas={[{ clave: "caravana", titulo: "Caravana" }, { clave: "kilos", titulo: "Kilos", numerico: true, alDerecha: true }]}
  filas={animales}
/>
```

Va dentro de una `<Tarjeta denso>`. Las columnas con cifras usan `numerico` para pasar a monoespaciada con tabular-nums; una caravana se compara de un vistazo o no sirve.

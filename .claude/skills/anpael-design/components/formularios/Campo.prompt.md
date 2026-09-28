Campo de formulario con etiqueta encima; cubre input, select y textarea con un solo componente.

```jsx
<Campo etiqueta="Caravana" placeholder="Ej: 0075" requerido />
<Campo etiqueta="Rodeo" opciones={[{ valor: null, etiqueta: "(sin asignar)" }, { valor: 3, etiqueta: "Rodeo 3" }]} />
```

La etiqueta va en gris 13px y el control en gris claro (#F1F4F1) dentro de la tarjeta blanca: el campo se hunde, no se eleva. Con `sobreFondo` el control pasa a blanco, para los filtros que viven fuera de una tarjeta. Los campos se apilan con 14px; en fila usan `display:flex; gap:14px` y cada uno tiene `min-width:160px`.

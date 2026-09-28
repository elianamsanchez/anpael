Boton de accion: usalo para cualquier accion del sistema, no hay otro control de accion en ANPAEL.

```jsx
<Boton variante="primario" tipo="submit" ancho>Entrar</Boton>
<Boton variante="sobrio" tamano="sm">‹ Anterior</Boton>
```

- `primario` (monte-700 #2F5238) para la accion principal de una tarjeta o formulario. Uno solo por pantalla.
- `acento` (pasto-700 #47702F) para acciones de creacion en cabeceras de listado ("+ Nuevo animal").
- `sobrio` para acciones secundarias y paginado; `texto` para "Corregir" dentro de una fila.
- Foco: anillo cielo #3A6E8F de 2px con 1px de separacion.
- Deshabilitado baja la opacidad (.5 en llenos, .4 en sobrio) y no cambia el color. Nunca se oculta el boton.

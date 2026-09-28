Busqueda de la barra de filtros; va en blanco y sin etiqueta, porque vive en la barra de filtros, fuera de la tarjeta. Los campos que van dentro de una tarjeta usan trigo claro; los que van sobre el fondo de la app, blanco.

```jsx
<Buscador valor={caravana} onChange={(e) => setCaravana(e.target.value)} />
```

En el padron la busqueda tiene un debounce de 350ms y resetea la pagina a 0. El placeholder termina en puntos suspensivos.

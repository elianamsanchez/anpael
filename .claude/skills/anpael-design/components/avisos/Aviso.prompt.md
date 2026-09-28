Mensaje en linea junto al formulario que lo produjo; ANPAEL no usa notificaciones flotantes ni toasts.

```jsx
<Aviso tono="error" detalle={error.detalle}>{error.mensaje}</Aviso>
<Aviso tono="ok">Categoria asignada.</Aviso>
```

Los cuatro tonos comparten estructura: fondo claro + borde de 1px del mismo matiz + texto saturado. Radio 8px, 13px de tipografia. Van debajo del control, con 8px de aire.

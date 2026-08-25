# Etapas del proyecto

El criterio de corte de cada versión es **qué puede hacer una persona en el
campo que antes no podía**, no cuántas pantallas hay.

---

## Etapa 1 — que el sistema reemplace al Excel para trabajar

Tres cosas, en este orden. El orden no es negociable: sin seguridad no se
puede sanear con trazabilidad de quién cambió qué, y sin datos saneados las
planillas salen con caravanas equivocadas.

### v0.1 · Seguridad y acceso

- **Bloqueada por ADR-001** (`decisiones.md`): Spring Security o RLS. Hay que
  decidirlo antes de escribir una línea del módulo.
- Login, JWT, roles (Peón, Gestor, Gerente, Propietario).
- Reimplementar la autoría en Java si se elige la Opción A. **No dejarlo para
  después**: es lo único que se pierde en silencio, y es justo lo que sirve
  para auditar.

*Terminada cuando:* entrás con usuario y contraseña desde el celular, y cada
registro que cargás queda con tu nombre.

### v0.2a · Saneamiento

Los datos migrados están completos pero no todos están al día. Falta:

| qué falta | cuántos |
|---|---|
| animales sin categoría asignada | 381 |
| animales sin rodeo | 1.463 de 1.732 |
| animales que ya no están en el campo y siguen figurando | a determinar |
| potreros | la tabla está vacía |

Pantallas necesarias:

- buscar un animal por caravana y ver todo lo que se sabe de él;
- asignar categoría y rodeo, de a uno y **por lote** (marcar 40 y asignarles
  el mismo rodeo de una vez — de a uno son horas);
- dar de baja con causa;
- corregir y completar datos.

Antes de arrancar hay que agregar la causa `regularizacion_inicial` al
catálogo `causa_baja`. Sin ella, las bajas del saneamiento se mezclan con las
muertes reales e inflan la mortandad del primer año.

*Terminada cuando:* `v_qa_sin_categoria` da 0 filas y el stock del sistema
coincide con el conteo real del campo.

*Indicador para seguirlo:* animales saneados sobre total, por semana. Si el
ritmo no llega a terminar antes del próximo trabajo grande, conviene priorizar
los rodeos que se van a tocar primero en lugar de ir en orden.

### v0.2b · Generador de planillas

El entregable que más se va a usar. Un PDF imprimible con las caravanas de un
rodeo y las columnas que corresponden al trabajo:

| trabajo | columnas |
|---|---|
| tacto | caravana · resultado · tamaño de preñez · observaciones |
| pesada | caravana · kilos |
| revisión de toros | caravana · marca a fuego · circunferencia escrotal · condición corporal · apto S/N |
| sanidad | caravana · producto · dosis |
| destete | caravana madre · caravana cría · sexo · peso |

Filas ordenadas por caravana, con renglones en blanco al final para los
animales que aparecen y no estaban en la lista — en el campo siempre aparecen.

*Terminada cuando:* imprimís la planilla de un rodeo, trabajás con ella, y
después cargás los resultados sin transcribir nada dos veces.

---

## Etapa 2 — que el campo cargue en el momento

- Carga en el celular durante el trabajo, con la planilla en pantalla.
- Funcionamiento sin señal (PWA) y sincronización al volver.
- Acá recién tiene sentido lo de los UUID de ADR-002.

## Etapa 3 — que los datos sirvan para decidir

- Indicadores: preñez por rodeo y por toro, destete, ADPV, mortandad.
- Comparación entre años y entre rodeos.
- Alertas: vaca vacía dos servicios seguidos, toro con circunferencia
  escrotal por debajo del umbral, animal sin evento en X meses.

Esta etapa es la que devuelve la inversión de las anteriores. Pero **no se
puede adelantar**: un indicador calculado sobre datos sin sanear es peor que
no tener indicador, porque se le cree.

---

## Lo que puede salir mal

| riesgo | señal temprana | qué hacer |
|---|---|---|
| el saneamiento se estanca porque es tedioso | menos de 100 animales por semana | priorizar por rodeo, no por padrón completo |
| las planillas salen y nadie las usa | vuelven anotadas a mano en papel propio | preguntar qué columna falta, no insistir |
| ADR-001 queda sin decidir y se escribe código que después hay que tirar | el módulo Seguridad arranca sin la decisión cerrada | no arrancarlo |
| una sola persona prueba todo | ya es así | mantener los tests de integración al día; son el segundo par de ojos |

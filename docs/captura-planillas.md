# Cómo entran al sistema los datos de la planilla de campo

Documento de diseño. Todavía no hay nada construido de esto: la decisión que
hay que tomar **ahora** es la del diseño de la planilla impresa (v0.2b),
porque condiciona todo lo demás.

Pregunta que le da origen: *¿cómo evitamos que alguien tenga que tipear a
mano lo que se anotó en el papel?*

---

## Las dos ideas de partida

| idea | veredicto |
|---|---|
| Mandar la foto a Claude y que devuelva el SQL | **Sirve ahora, no como arquitectura** |
| Que Claude devuelva un JSON y la aplicación lo importe | **El camino correcto**, pero el formato es la parte fácil |

**Por qué la primera no puede quedarse.** Mete a Claude en el camino crítico
de la producción: si no está disponible, no se carga nada. El SQL generado no
se puede revisar fila por fila a volumen. Y no queda registro de qué se leyó
ni con cuánta confianza. Como puente para el saneamiento inicial está bien;
como forma de trabajar todos los meses, no.

**Por qué la segunda no alcanza sola.** El JSON resuelve el transporte, no el
problema. Las preguntas que quedan abiertas son las que importan.

---

## La pregunta real

No es *SQL o JSON*. Es:

1. **¿Quién lee la imagen?** ¿Claude en un chat —manual, dependiente de una
   persona— o el backend llamando a una API de visión —repetible, sin nadie
   en el medio?
2. **¿Qué se hace con lo leído?** ¿Va directo a la base, o pasa por una
   pantalla donde alguien confirma?

**La respuesta a las dos:** la lectura vive en el backend, y nada se escribe
sin que una persona confirme lo dudoso.

Un dato transcripto por una máquina y guardado sin mirar es un dato en el que
nadie confía. Un sistema en el que nadie confía se abandona, y se vuelve al
Excel.

---

## Lo que cambia el juego: la planilla la diseñamos nosotros

Esto es lo más importante del documento.

En la v0.2b el sistema **genera la planilla que se imprime**. No estamos
leyendo un papel cualquiera: controlamos el formato. Eso convierte un
problema difícil —OCR de escritura manuscrita libre— en uno mucho más
manejable: leer marcas en posiciones conocidas.

### Tres decisiones de diseño de la planilla

**1 · Un QR en el encabezado** con el identificador de la sesión de trabajo.

La foto se auto-identifica: qué rodeo, qué tipo de trabajo, qué fecha, qué
página de cuántas. Nadie tiene que elegir nada de un menú al importar, y no
hay forma de cargar la planilla del tacto de marzo como si fuera la de
agosto.

**2 · Caravanas pre-impresas, una por renglón, en orden.**

El peón no escribe la caravana: la ubica y marca al lado. Esto ataca el error
más caro, que se explica más abajo.

Al final de cada planilla van **renglones en blanco** para los animales que
aparecen y no estaban en la lista. En el campo eso pasa siempre.

**3 · Casillas para tildar en vez de espacios para escribir.**

- tacto: `P` / `V`  y  `G` / `M` / `CH`
- condición corporal: casilleros del 1 al 5
- apto sí/no: dos casillas

Una cruz en un casillero se lee bien casi siempre. Un número manuscrito en
una manga, con la mano sucia y apurado, no. Solo los pesos necesitan dígitos.

---

## El error que importa no es el que parece

Un **peso** mal transcripto es un dato malo: queda fuera de rango, se nota y
se corrige.

Una **caravana** mal transcripta es otra cosa: asigna el dato **a otro
animal**. Corrompe dos registros a la vez y ninguno de los dos se ve raro
—una vaca vacía queda preñada y una preñada queda vacía—, y eso después es
una decisión de venta equivocada.

**Toda la certeza hay que ponerla en la identificación, no en los valores.**
Con las caravanas pre-impresas, lo único a confirmar a mano son los animales
que se anotaron en los renglones en blanco.

---

## Cómo funcionaría la importación

| paso | qué pasa |
|---|---|
| 1 | Se saca la foto de la planilla y se sube |
| 2 | El backend lee el QR → sabe de qué sesión se trata |
| 3 | Transcribe cada celda **con un nivel de confianza** |
| 4 | Valida contra la base |
| 5 | Muestra **solo lo dudoso y lo que no validó** |
| 6 | Una persona confirma, y recién ahí se escribe |
| 7 | La foto queda guardada, atada al trabajo |

### Qué valida el paso 4

- la caravana existe y está en ese rodeo
- la condición corporal está entre 1 y 5
- la dentadura está en el catálogo
- el resultado de tacto es coherente con el tamaño de preñez
- el animal no está dado de baja

Son las mismas restricciones que ya tiene la base. La diferencia es que acá
se aplican **antes** de escribir, para poder dar un mensaje entendible en vez
de una excepción de PostgreSQL.

### Tres detalles que parecen menores y no lo son

**Mostrar solo lo dudoso.** La diferencia entre *"revisá estas 200 filas"* y
*"revisá estas 12 celdas"* es la diferencia entre que se use y que no.

**Nada se descarta en silencio.** Lo que no valida va a una lista de
pendientes, con el motivo. Es la lección de la dentadura `-1/4D` durante la
migración: un dato accesorio que no se puede guardar **nunca** puede tumbar
la carga entera, pero tampoco puede desaparecer sin dejar rastro.

**Importar dos veces la misma foto no puede duplicar nada.** Con el
identificador de sesión más el número de renglón alcanza.

**Guardar la foto** cuesta casi nada y resuelve toda discusión futura: *"la
planilla dice 3 y el sistema dice 5"* se contesta abriendo la imagen.

---

## Dónde se apoya esto en el modelo

Las tablas del circuito de planillas todavía no existen. Van a ser las
primeras con **UUID** en lugar de enteros, según ADR-002, porque son las que
después se van a crear sin señal en el campo:

| tabla | qué guarda |
|---|---|
| `sesion_trabajo` | la planilla como objeto: qué rodeo, qué tipo de trabajo, qué fecha, quién, cuántas páginas. Es lo que codifica el QR |
| `linea_planilla` | un renglón: el animal, lo transcripto, el nivel de confianza, si fue confirmado y por quién |

`linea_planilla` es lo que permite volver atrás: qué decía el papel, qué leyó
la máquina, qué confirmó la persona. Sin esa tabla, una vez escrito el evento
no hay forma de auditar de dónde salió el número.

---

## Otras opciones

### Dictado por voz en la manga

*"A728, preñada grande, condición 3"*

En la manga las manos están ocupadas y sucias. Hablar es más rápido que
escribir y mucho más rápido que tipear. Se transcribe y se confirma después,
con la misma pantalla de confirmación de la importación por foto.

Para el veterinario tactando es probablemente la mejor opción que existe.

### Bastón lector de RFID

Ya hay 344 animales con RFID en el padrón. Un lector conectado al celular
**elimina por completo** el error de identificación, que es el caro.

Cuesta plata en hardware y solo sirve para los animales que tienen botón,
pero es la única solución que ataca el problema de raíz en vez de mitigarlo.

### Carga directa en el celular

Etapa 2. Es el destino final: sin papel, sin transcripción, sin error de
lectura. La planilla impresa sigue existiendo como respaldo para cuando no
hay señal ni batería, que en el campo pasa.

---

## El orden

| cuándo | qué |
|---|---|
| **ahora** | Foto → SQL generado por Claude, con revisión humana. Puente temporal para el saneamiento, y está bien que sea temporal |
| **v0.2b** | La planilla impresa **con QR y casilleros**. Hay que hacerlo bien de entrada |
| **v0.3** | Importación por foto con pantalla de confirmación |
| **Etapa 2** | Carga directa en el celular. La foto queda como camino alternativo |

**El orden importa.** Si la planilla no se diseña pensando en que después se
va a fotografiar, la importación nace lisiada. Es la decisión que hay que
tomar ahora, aunque la importación se construya dentro de tres meses.

---

## Cierre

- **Acción recomendada:** diseñar la planilla de la v0.2b con QR de sesión,
  caravanas pre-impresas y casilleros; usar mientras tanto el puente
  foto → SQL para el saneamiento.
- **Beneficio esperado:** la transcripción deja de ser un trabajo y pasa a
  ser una confirmación de excepciones. El dato entra el mismo día del
  trabajo, no la semana siguiente.
- **Riesgos:** que la lectura automática genere confianza injustificada —se
  controla mostrando el nivel de confianza y guardando la foto—. Y un riesgo
  de alcance: la importación por foto es de las funcionalidades que más
  tiempo consumen; no conviene arrancarla antes de cerrar el saneamiento.
- **Cómo medir si funcionó:** dos números por planilla — cuántas celdas
  necesitaron confirmación humana, y cuántas correcciones se hicieron
  **después** de importar. El segundo dice si la lectura es confiable; si no
  baja con el tiempo, el problema está en el diseño de la planilla, no en el
  lector.

---

## Lo que falta saber

**¿Quién completa hoy las planillas en el campo, y en qué condiciones?**

No es lo mismo el veterinario anotando en un tablero, sentado, que un peón
escribiendo apoyado en el alambrado. Eso define cuánto se le puede pedir al
papel, si conviene ir directo al dictado por voz, y cuántas columnas entran
razonablemente en una hoja.

Sin esa respuesta, el diseño de la planilla es una suposición.

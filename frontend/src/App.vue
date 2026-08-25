<script setup lang="ts">
// Cascara minima. El layout con menu lateral entra en la v0.1, junto con el
// login: antes de eso no hay nada que menuear.
</script>

<template>
  <RouterView />
</template>

<style>
/* Tokens de la paleta "Cuero y campo", los mismos del sistema de diseño ya
   validado por contraste. Se dejan como variables CSS para que PrimeVue y el
   codigo propio tomen del mismo lugar. */
:root {
  --cuero: #5C3D2E;
  --monte: #6B7A4F;
  --tierra: #B5651D;
  --tierra-txt: #964D00;
  --arena: #E8DFD1;
  --n50: #F9F3E9;
  --n200: #D9D3CA;
  --n500: #766F63;
  --ok: #3F7A44;
  --warn: #8A6100;
  --bad: #9A3324;
}

body {
  margin: 0;
  background: var(--n50);
  color: var(--cuero);
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
}
</style>

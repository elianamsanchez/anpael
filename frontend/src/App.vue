<script setup lang="ts">
// Cascara minima. El layout con menu lateral entra en la v0.1, junto con el
// login: antes de eso no hay nada que menuear.
</script>

<template>
  <RouterView />
</template>

<style>
/* Los tokens de la paleta "Cuero y campo" viven en src/assets/tokens/
   (importados una sola vez en main.ts), para que PrimeVue y el codigo propio
   tomen del mismo lugar. */
body {
  margin: 0;
  min-height: 100vh;
  background: var(--surface-app);
  color: var(--text-body);
  font-family: var(--font-ui);
}
</style>

<script setup lang="ts">
defineProps<{
  items: { rotulo: string; valor: string | number; numerico?: boolean }[]
}>()
</script>

<template>
  <dl class="lista-datos">
    <div v-for="(it, i) in items" :key="it.rotulo + i" :class="{ 'lista-datos-fila--ultima': i === items.length - 1 }">
      <dt class="lista-datos-rotulo">{{ it.rotulo }}</dt>
      <dd class="lista-datos-valor" :class="{ 'lista-datos-valor--numerico': it.numerico }">{{ it.valor }}</dd>
    </div>
  </dl>
</template>

<style scoped>
.lista-datos { margin: 0; font-family: var(--font-ui); }
.lista-datos > div {
  display: flex; justify-content: space-between; gap: 16px; padding: 8px 0;
  border-bottom: var(--borde-filete);
}
.lista-datos-fila--ultima { border-bottom: none; }
.lista-datos-rotulo { color: var(--text-muted); font-size: var(--fs-13); flex-shrink: 0; }
.lista-datos-valor { margin: 0; font-weight: var(--fw-semibold); font-size: var(--fs-14); text-align: right; }
.lista-datos-valor--numerico { font-variant-numeric: tabular-nums; font-family: var(--font-mono); }
</style>

<script setup lang="ts">
withDefaults(
  defineProps<{
    titulo?: string
    nota?: string
    denso?: boolean
  }>(),
  { denso: false }
)
</script>

<template>
  <section class="tarjeta" :class="{ 'tarjeta--densa': denso }">
    <h3 v-if="titulo" class="tarjeta-titulo" :class="{ 'tarjeta-titulo--con-nota': nota }">{{ titulo }}</h3>
    <p v-if="nota" class="tarjeta-nota">{{ nota }}</p>
    <slot />
  </section>
</template>

<style scoped>
.tarjeta {
  background: var(--surface-card);
  border: var(--borde-fino);
  border-radius: var(--radio-lg);
  padding: var(--pad-tarjeta);
  color: var(--text-body);
  font: var(--text-base);
}
.tarjeta--densa { padding: var(--pad-tarjeta-tabla); }
.tarjeta-titulo { margin: 0 0 12px; font: var(--text-h3); }
.tarjeta-titulo--con-nota { margin: 0 0 4px; }
.tarjeta-nota { margin: 0 0 12px; font: var(--text-caption); color: var(--text-muted); }
</style>

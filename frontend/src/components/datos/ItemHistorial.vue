<script setup lang="ts">
import Etiqueta from '@/components/base/Etiqueta.vue'

withDefaults(
  defineProps<{
    fecha: string
    tipo: string
    detalle?: string
    comentario?: string
    ultimo?: boolean
  }>(),
  { ultimo: false }
)
</script>

<template>
  <li class="item-historial" :class="{ 'item-historial--ultimo': ultimo }">
    <div class="item-historial-fila">
      <span class="item-historial-fecha">{{ fecha }}</span>
      <Etiqueta tono="tipo">{{ tipo }}</Etiqueta>
    </div>
    <p v-if="detalle" class="item-historial-detalle">{{ detalle }}</p>
    <p v-if="comentario" class="item-historial-comentario">"{{ comentario }}"</p>
    <slot />
  </li>
</template>

<style scoped>
.item-historial {
  padding: 10px 0;
  border-bottom: var(--borde-filete);
  list-style: none;
  font-family: var(--font-ui);
}
.item-historial--ultimo { border-bottom: none; }
.item-historial-fila { display: flex; justify-content: space-between; align-items: baseline; gap: 10px; }
.item-historial-fecha { font-size: var(--fs-125); color: var(--text-muted); white-space: nowrap; font-family: var(--font-mono); }
.item-historial-detalle { margin: 4px 0 0; font-size: var(--fs-135); }
.item-historial-comentario { margin: 4px 0 0; font-size: var(--fs-135); color: var(--text-muted); }
</style>

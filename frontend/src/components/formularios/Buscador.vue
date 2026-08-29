<script setup lang="ts">
withDefaults(
  defineProps<{
    valor?: string
    placeholder?: string
    ancho?: number
  }>(),
  { placeholder: 'Buscar por caravana...', ancho: 240 }
)

defineEmits<{ 'update:valor': [valor: string] }>()
</script>

<template>
  <input
    type="search"
    class="buscador"
    :value="valor"
    :placeholder="placeholder"
    :style="{ minWidth: `${ancho}px` }"
    @input="$emit('update:valor', ($event.target as HTMLInputElement).value)"
  />
</template>

<style scoped>
.buscador {
  font: inherit;
  font-family: var(--font-ui);
  font-size: var(--fs-14);
  color: var(--text-body);
  padding: 9px 12px;
  border-radius: var(--radio-md);
  border: var(--borde-fino);
  background: var(--surface-card);
}
.buscador:focus-visible { outline: var(--foco-anillo); outline-offset: var(--foco-offset); }
</style>

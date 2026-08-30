<script setup lang="ts">
withDefaults(
  defineProps<{
    etiqueta?: string
    marcado?: boolean
    deshabilitado?: boolean
  }>(),
  { marcado: false, deshabilitado: false }
)

defineEmits<{ 'update:marcado': [marcado: boolean] }>()
</script>

<template>
  <label class="check" :class="{ 'check--deshabilitado': deshabilitado }">
    <input
      type="checkbox"
      class="check-input"
      :checked="marcado"
      :disabled="deshabilitado"
      @change="$emit('update:marcado', ($event.target as HTMLInputElement).checked)"
    />
    {{ etiqueta }}
  </label>
</template>

<style scoped>
.check {
  display: flex;
  align-items: center;
  gap: 6px;
  font: var(--text-label);
  color: var(--text-muted);
  cursor: pointer;
}
.check--deshabilitado { cursor: not-allowed; opacity: .5; }
.check-input { accent-color: var(--pasto-700); width: 15px; height: 15px; margin: 0; }
</style>

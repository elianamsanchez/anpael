<script setup lang="ts">
withDefaults(
  defineProps<{
    etiqueta?: string
    tipo?: string
    opciones?: { valor: string | number | null; etiqueta: string }[]
    filas?: number
    valor?: string | number | null
    placeholder?: string
    requerido?: boolean
    deshabilitado?: boolean
    sobreFondo?: boolean
  }>(),
  {
    tipo: 'text',
    requerido: false,
    deshabilitado: false,
    sobreFondo: false
  }
)

defineEmits<{ 'update:valor': [valor: string] }>()
defineOptions({ inheritAttrs: false })
</script>

<template>
  <label class="campo" :class="{ 'campo--sobre-fondo': sobreFondo }">
    <span v-if="etiqueta">{{ etiqueta }}{{ requerido ? ' *' : '' }}</span>
    <select
      v-if="opciones"
      class="campo-control"
      v-bind="$attrs"
      :value="valor ?? ''"
      :required="requerido"
      :disabled="deshabilitado"
      @change="$emit('update:valor', ($event.target as HTMLSelectElement).value)"
    >
      <option v-for="o in opciones" :key="String(o.valor)" :value="o.valor === null ? '' : o.valor">
        {{ o.etiqueta }}
      </option>
    </select>
    <textarea
      v-else-if="tipo === 'textarea'"
      class="campo-control campo-control--textarea"
      v-bind="$attrs"
      :rows="filas || 2"
      :value="valor ?? ''"
      :placeholder="placeholder"
      :required="requerido"
      :disabled="deshabilitado"
      @input="$emit('update:valor', ($event.target as HTMLTextAreaElement).value)"
    ></textarea>
    <input
      v-else
      class="campo-control"
      v-bind="$attrs"
      :type="tipo"
      :value="valor ?? ''"
      :placeholder="placeholder"
      :required="requerido"
      :disabled="deshabilitado"
      @input="$emit('update:valor', ($event.target as HTMLInputElement).value)"
    />
  </label>
</template>

<style scoped>
.campo {
  display: flex;
  flex-direction: column;
  gap: 4px;
  font: var(--text-label);
  color: var(--text-muted);
  flex: 1;
  min-width: 160px;
}
.campo-control {
  font: inherit;
  font-family: var(--font-ui);
  font-size: var(--fs-135);
  color: var(--text-body);
  padding: 8px 10px;
  border-radius: var(--radio-md);
  border: var(--borde-fino);
  background: var(--surface-field);
  width: 100%;
  box-sizing: border-box;
}
.campo--sobre-fondo .campo-control { background: var(--surface-card); }
.campo-control--textarea { resize: vertical; }
.campo-control:focus-visible { outline: var(--foco-anillo); outline-offset: var(--foco-offset); }
.campo-control:disabled { opacity: .5; cursor: not-allowed; }
</style>

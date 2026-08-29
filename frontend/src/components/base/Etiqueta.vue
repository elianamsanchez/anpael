<script setup lang="ts">
withDefaults(
  defineProps<{
    tono?: 'falta' | 'tipo' | 'ok' | 'mal' | 'atenuado'
    capsula?: boolean
  }>(),
  { tono: 'falta', capsula: false }
)
</script>

<template>
  <span class="etiqueta" :class="[`etiqueta--${tono}`, { 'etiqueta--capsula': capsula }]">
    <slot />
  </span>
</template>

<style scoped>
.etiqueta { font-family: var(--font-ui); white-space: nowrap; }
.etiqueta--falta { color: var(--falta-text); font-size: var(--fs-125); }
.etiqueta--tipo {
  color: var(--text-link); font-size: var(--fs-11); font-weight: var(--fw-bold);
  letter-spacing: var(--ls-caps); text-transform: uppercase;
}
.etiqueta--ok { color: var(--ok); font-size: var(--fs-135); font-weight: var(--fw-semibold); }
.etiqueta--mal { color: var(--bad); font-size: var(--fs-135); font-weight: var(--fw-semibold); }
.etiqueta--atenuado { color: var(--text-muted); font-size: var(--fs-125); }
.etiqueta--capsula { background: var(--surface-sunken); border-radius: var(--radio-pill); padding: 2px 8px; }
</style>

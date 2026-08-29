<script setup lang="ts">
withDefaults(
  defineProps<{
    variante?: 'primario' | 'acento' | 'sobrio' | 'texto'
    tamano?: 'md' | 'sm'
    ancho?: boolean
    deshabilitado?: boolean
    tipo?: 'button' | 'submit'
  }>(),
  {
    variante: 'primario',
    tamano: 'md',
    ancho: false,
    deshabilitado: false,
    tipo: 'button'
  }
)
</script>

<template>
  <button
    :type="tipo"
    :disabled="deshabilitado"
    class="boton"
    :class="[`boton--${variante}`, `boton--${tamano}`, { 'boton--ancho': ancho }]"
  >
    <slot />
  </button>
</template>

<style scoped>
.boton {
  font: inherit;
  font-family: var(--font-ui);
  font-weight: var(--fw-semibold);
  line-height: var(--lh-snug);
  border-radius: var(--radio-md);
  text-align: center;
  white-space: nowrap;
  cursor: pointer;
  transition: var(--transicion-boton);
}
.boton--md { padding: 10px 14px; font-size: var(--fs-14); }
.boton--sm { padding: 6px 12px; font-size: var(--fs-13); }
.boton--ancho { width: 100%; }

.boton--primario { background: var(--action-primary); color: #fff; border: 0; }
.boton--primario:hover:not(:disabled) { background: var(--action-primary-hover); }
.boton--primario:active:not(:disabled) { background: var(--action-primary-press); }

.boton--acento { background: var(--action-accent); color: #fff; border: 0; }
.boton--acento:hover:not(:disabled) { background: var(--action-accent-hover); }

.boton--sobrio { background: none; color: var(--text-body); border: 1px solid var(--action-quiet-border); }
.boton--sobrio:hover:not(:disabled) { background: var(--surface-sunken); }

.boton--texto { background: none; color: var(--text-link); border: 0; text-decoration: underline; padding: 0; }
.boton--texto.boton--sm, .boton--texto.boton--md { padding: 0; }

.boton:focus-visible { outline: var(--foco-anillo); outline-offset: var(--foco-offset); }

.boton:disabled { cursor: not-allowed; }
.boton--primario:disabled, .boton--acento:disabled, .boton--texto:disabled { opacity: var(--action-disabled-opacity); }
.boton--sobrio:disabled { opacity: .4; }
</style>

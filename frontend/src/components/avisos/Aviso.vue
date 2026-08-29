<script setup lang="ts">
withDefaults(
  defineProps<{
    tono?: 'ok' | 'error' | 'atencion' | 'info'
    detalle?: string
  }>(),
  { tono: 'info' }
)
</script>

<template>
  <p class="aviso" :class="`aviso--${tono}`" :role="tono === 'error' ? 'alert' : undefined">
    <slot />
    <span v-if="detalle" class="aviso-detalle"> — {{ detalle }}</span>
  </p>
</template>

<style scoped>
.aviso {
  border-style: solid;
  border-width: 1px;
  border-radius: var(--radio-md);
  padding: 10px;
  font-family: var(--font-ui);
  font-size: var(--fs-13);
  line-height: var(--lh-normal);
  margin: 0;
}
.aviso--ok { background: var(--ok-bg); border-color: var(--ok-border); color: var(--ok-text); }
.aviso--error { background: var(--bad-bg); border-color: var(--bad-border); color: var(--bad-text); }
.aviso--atencion { background: var(--warn-bg); border-color: var(--warn-border); color: var(--warn-text); }
.aviso--info { background: var(--info-bg); border-color: var(--info-border); color: var(--info-text); }
.aviso-detalle { opacity: .8; }
</style>

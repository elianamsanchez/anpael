<script setup lang="ts">
withDefaults(
  defineProps<{
    titulo?: string
    bajada?: string
    punto?: boolean
    logo?: boolean
    logoSrc?: string
  }>(),
  {
    titulo: 'ANPAEL',
    punto: true,
    logo: false,
    logoSrc: '/assets/logo-horizontal.png'
  }
)
</script>

<template>
  <header class="marca">
    <img v-if="logo" :src="logoSrc" alt="ANPAEL" class="marca-logo" />
    <span v-else-if="punto" class="marca-punto" aria-hidden="true"></span>
    <div>
      <template v-if="!logo">{{ titulo }}</template>
      <small v-if="bajada" class="marca-bajada">{{ bajada }}</small>
    </div>
    <div v-if="$slots.default" class="marca-acciones">
      <slot />
    </div>
  </header>
</template>

<style scoped>
.marca {
  display: flex;
  gap: 10px;
  align-items: center;
  font-weight: var(--fw-bold);
  font-family: var(--font-ui);
  font-size: var(--fs-16);
  color: var(--text-body);
}
.marca-logo { height: 34px; width: auto; display: block; flex-shrink: 0; }
.marca-punto { width: 12px; height: 12px; border-radius: var(--radio-circulo); background: var(--pasto-700); flex-shrink: 0; }
.marca-bajada { display: block; font-weight: var(--fw-regular); font: var(--text-caption); color: var(--text-muted); }
.marca-acciones { margin-left: auto; display: flex; align-items: center; gap: 8px; }
</style>

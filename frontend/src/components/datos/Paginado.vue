<script setup lang="ts">
import Boton from '@/components/base/Boton.vue'

const props = withDefaults(
  defineProps<{
    pagina?: number
    totalPaginas?: number
  }>(),
  { pagina: 0, totalPaginas: 1 }
)

const emit = defineEmits<{ cambio: [pagina: number] }>()
</script>

<template>
  <nav v-if="totalPaginas > 1" class="paginado">
    <Boton variante="sobrio" tamano="sm" :deshabilitado="pagina === 0" @click="emit('cambio', pagina - 1)">
      ‹ Anterior
    </Boton>
    <span class="paginado-texto">pagina {{ props.pagina + 1 }} de {{ props.totalPaginas }}</span>
    <Boton
      variante="sobrio"
      tamano="sm"
      :deshabilitado="pagina >= totalPaginas - 1"
      @click="emit('cambio', pagina + 1)"
    >
      Siguiente ›
    </Boton>
  </nav>
</template>

<style scoped>
.paginado { display: flex; align-items: center; justify-content: center; gap: 16px; margin-top: 16px; }
.paginado-texto { color: var(--text-muted); font-family: var(--font-ui); font-size: var(--fs-13); }
</style>

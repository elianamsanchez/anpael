<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { getHealth } from '@/api/health'

/**
 * Franja fija arriba de toda la app (montada una sola vez en App.vue, así
 * que aparece en cualquier pantalla, login incluido) con el "entorno" de
 * /api/health -el único campo que distingue local de producción, porque
 * el local tiene un dump de producción y devuelve los mismos números
 * (docs/modelo-datos.md, README). Sin esto es fácil no notar contra qué
 * base se está trabajando y cargar o corregir datos donde no corresponde.
 *
 * Si /api/health no contesta, no se muestra nada: cada pantalla ya avisa
 * por su cuenta que no hay conexión (EstadoView, etc.), no hace falta
 * duplicarlo acá.
 */
const entorno = ref<string | null>(null)

onMounted(async () => {
  try {
    const salud = await getHealth()
    entorno.value = salud.entorno
  } catch {
    entorno.value = null
  }
})

const clase = computed(() => {
  if (entorno.value === 'produccion') return 'barra-entorno--produccion'
  if (entorno.value === 'local') return 'barra-entorno--local'
  return 'barra-entorno--indefinido'
})

const texto = computed(() => {
  if (entorno.value === 'produccion') return 'PRODUCCIÓN · datos reales'
  if (entorno.value === 'local') return 'local'
  return `entorno sin definir (${entorno.value})`
})
</script>

<template>
  <div v-if="entorno" class="barra-entorno" :class="clase">{{ texto }}</div>
</template>

<style scoped>
.barra-entorno {
  font-family: var(--font-ui);
  font-size: var(--fs-11);
  font-weight: var(--fw-bold);
  letter-spacing: var(--ls-caps);
  text-transform: uppercase;
  text-align: center;
  padding: 4px 8px;
}
.barra-entorno--produccion {
  background: var(--bad-bg);
  border-bottom: 2px solid var(--bad);
  color: var(--bad);
  font-size: var(--fs-16);
  padding: 8px;
}
.barra-entorno--local { background: var(--surface-banda); color: var(--text-muted); }
.barra-entorno--indefinido { background: var(--ambar-500); color: var(--text-on-brand); }
</style>

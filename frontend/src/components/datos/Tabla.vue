<script setup lang="ts">
withDefaults(
  defineProps<{
    columnas: { clave: string; titulo: string; alDerecha?: boolean; numerico?: boolean }[]
    filas: Record<string, unknown>[]
    vacio?: string
  }>(),
  { vacio: 'No hay resultados.' }
)
</script>

<template>
  <p v-if="!filas.length" class="tabla-vacia">{{ vacio }}</p>
  <table v-else class="tabla">
    <thead>
      <tr>
        <th v-for="c in columnas" :key="c.clave" :class="{ 'tabla-th--derecha': c.alDerecha }">
          {{ c.titulo }}
        </th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="(fila, i) in filas" :key="(fila.id as string | number | undefined) ?? i">
        <td
          v-for="c in columnas"
          :key="c.clave"
          :class="{ 'tabla-td--derecha': c.alDerecha, 'tabla-td--numerico': c.numerico }"
        >
          <slot :name="`celda-${c.clave}`" :fila="fila">{{ fila[c.clave] }}</slot>
        </td>
      </tr>
    </tbody>
  </table>
</template>

<style scoped>
.tabla-vacia { color: var(--text-muted); font: var(--text-base); margin: 0; }
.tabla { width: 100%; border-collapse: collapse; font-family: var(--font-ui); font-size: var(--fs-14); }
.tabla th {
  text-align: left; font-size: var(--fs-12); color: var(--text-muted); font-weight: var(--fw-semibold);
  padding: 8px 10px; border-bottom: var(--borde-fino); white-space: nowrap;
}
.tabla-th--derecha { text-align: right; }
.tabla td { padding: 8px 10px; border-bottom: var(--borde-filete); text-align: left; }
.tabla-td--derecha { text-align: right; }
.tabla-td--numerico { font-variant-numeric: tabular-nums; font-family: var(--font-mono); }
</style>

<script setup lang="ts">
import { ref, computed, onBeforeUnmount } from 'vue'
import CategoriaIcon from '@/components/icons/CategoriaIcon.vue'
import { getCategoriaIcon } from '@/components/icons/categoriaIconos'

/**
 * Como Campo con opciones, pero como <option> nativo no puede llevar un ícono
 * SVG adelante, este es un desplegable propio para elegir categoría.
 */
const props = withDefaults(
  defineProps<{
    opciones: { valor: number | null; etiqueta: string }[]
    valor?: number | null
    sobreFondo?: boolean
  }>(),
  { valor: null, sobreFondo: false }
)

const emit = defineEmits<{ 'update:valor': [valor: number | null] }>()

const abierto = ref(false)
const raiz = ref<HTMLElement | null>(null)

const opcionElegida = computed(() => props.opciones.find(o => o.valor === props.valor) ?? props.opciones[0])

function alternar() {
  abierto.value = !abierto.value
}
function elegir(valor: number | null) {
  emit('update:valor', valor)
  abierto.value = false
}
function alPerderFoco(evento: FocusEvent) {
  if (!raiz.value?.contains(evento.relatedTarget as Node)) abierto.value = false
}
function alTeclado(evento: KeyboardEvent) {
  if (evento.key === 'Escape') abierto.value = false
}

document.addEventListener('keydown', alTeclado)
onBeforeUnmount(() => document.removeEventListener('keydown', alTeclado))
</script>

<template>
  <div
    ref="raiz"
    class="selector"
    :class="{ 'selector--sobre-fondo': sobreFondo }"
    @focusout="alPerderFoco"
  >
    <button type="button" class="selector-boton" :aria-expanded="abierto" aria-haspopup="listbox" @click="alternar">
      <span v-if="getCategoriaIcon({ idCategoria: opcionElegida?.valor ?? undefined })" class="selector-icono" aria-hidden="true">
        <CategoriaIcon :id-categoria="opcionElegida?.valor ?? undefined" :size="18" />
      </span>
      <span class="selector-texto">{{ opcionElegida?.etiqueta }}</span>
      <span class="selector-flecha" aria-hidden="true">▾</span>
    </button>

    <ul v-if="abierto" class="selector-lista" role="listbox">
      <li
        v-for="o in opciones"
        :key="String(o.valor)"
        role="option"
        :aria-selected="o.valor === valor"
        class="selector-opcion"
        :class="{ 'selector-opcion--elegida': o.valor === valor }"
        tabindex="0"
        @click="elegir(o.valor)"
        @keydown.enter="elegir(o.valor)"
        @keydown.space.prevent="elegir(o.valor)"
      >
        <span v-if="getCategoriaIcon({ idCategoria: o.valor ?? undefined })" class="selector-icono" aria-hidden="true">
          <CategoriaIcon :id-categoria="o.valor ?? undefined" :size="18" />
        </span>
        <span v-else class="selector-icono selector-icono--vacio" aria-hidden="true" />
        <span>{{ o.etiqueta }}</span>
      </li>
    </ul>
  </div>
</template>

<style scoped>
.selector { position: relative; flex: 1; min-width: 160px; }
.selector-boton {
  display: flex; align-items: center; gap: 6px; width: 100%; box-sizing: border-box;
  font: inherit; font-family: var(--font-ui); font-size: var(--fs-135); color: var(--text-body);
  padding: 8px 10px; border-radius: var(--radio-md); border: var(--borde-fino);
  background: var(--surface-field); cursor: pointer; text-align: left;
}
.selector--sobre-fondo .selector-boton { background: var(--surface-card); }
.selector-boton:focus-visible { outline: var(--foco-anillo); outline-offset: var(--foco-offset); }
.selector-texto { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.selector-flecha { color: var(--text-muted); font-size: var(--fs-13); }
.selector-icono { display: inline-flex; align-items: center; flex: 0 0 auto; }
.selector-icono--vacio { width: 18px; }

.selector-lista {
  position: absolute; z-index: 20; top: calc(100% + 4px); left: 0; right: 0; margin: 0; padding: 4px;
  list-style: none; max-height: 320px; overflow-y: auto;
  background: var(--surface-card); border: var(--borde-fino); border-radius: var(--radio-md);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);
}
.selector-opcion {
  display: flex; align-items: center; gap: 8px; padding: 7px 8px; border-radius: var(--radio-sm, 6px);
  font-size: var(--fs-135); color: var(--text-body); cursor: pointer;
}
.selector-opcion:hover, .selector-opcion:focus-visible { background: var(--surface-field); outline: none; }
.selector-opcion--elegida { font-weight: var(--fw-semibold); }
</style>

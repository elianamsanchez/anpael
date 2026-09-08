<script setup lang="ts">
withDefaults(
  defineProps<{
    fecha: string
    tipo: string
    detalle?: string
    comentario?: string
    origenDato?: string
    apto?: boolean
    ultimo?: boolean
  }>(),
  { ultimo: false }
)

/**
 * Ícono y color por tipo de trabajo (diseño "Opción A" del historial). Los
 * tipos que no están acá -por ejemplo un OTRO- caen al color/ícono
 * genérico de abajo, no hace falta agregarlos a mano.
 */
const TIPOS: Record<string, { color: string; bg: string; icono: string }> = {
  TACTO: {
    color: 'var(--cielo-700)', bg: 'var(--cielo-100)',
    icono: '<rect x="6" y="4" width="12" height="17" rx="2"/><path d="M9 4V3a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v1"/><path d="M9 12l2 2 4-4"/>'
  },
  SANIDAD: {
    color: 'var(--pasto-700)', bg: 'var(--pasto-100)',
    icono: '<path d="M12 3l7 3v5c0 4.5-3 7.7-7 9-4-1.3-7-4.5-7-9V6l7-3Z"/><path d="M9.5 12l1.8 1.8L14.8 10"/>'
  },
  PESADA: {
    color: 'var(--ambar-500)', bg: 'var(--ambar-100)',
    icono: '<path d="M12 3v18M7 21h10M5 7h6M13 7h6M5 7l-2 5a3 3 0 0 0 6 0L5 7Zm14 0l-2 5a3 3 0 0 0 6 0l-4-5Z"/>'
  },
  REVISION_TOROS: {
    color: 'var(--monte-700)', bg: 'var(--monte-100)',
    icono: '<circle cx="11" cy="11" r="6"/><path d="M20 20l-4.35-4.35"/>'
  },
  IDENTIFICACION: {
    color: 'var(--piedra-700)', bg: 'var(--piedra-100)',
    icono: '<path d="M3 12l8-8h7a1 1 0 0 1 1 1v7l-8 8a1 1 0 0 1-1.4 0l-6.6-6.6a1 1 0 0 1 0-1.4Z"/><circle cx="15" cy="8" r="1.5"/>'
  }
}
const GENERICO = { color: 'var(--text-muted)', bg: 'var(--surface-sunken)', icono: '<circle cx="12" cy="12" r="3"/>' }

const ETIQUETA_ORIGEN: Record<string, string> = {
  VOZ: 'cargado por voz',
  RFID: 'leído por RFID',
  BALANZA: 'leído de balanza',
  IMPORTACION: 'de la migración inicial'
}
</script>

<template>
  <li class="item-historial" :class="{ 'item-historial--ultimo': ultimo }">
    <div class="item-historial-fila">
      <div class="item-historial-rail">
        <div
          class="item-historial-dot"
          :style="{ color: (TIPOS[tipo] ?? GENERICO).color, background: (TIPOS[tipo] ?? GENERICO).bg }"
        >
          <svg class="item-historial-icono" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6"
               stroke-linecap="round" stroke-linejoin="round" v-html="(TIPOS[tipo] ?? GENERICO).icono" />
        </div>
      </div>
      <div class="item-historial-cuerpo">
        <div class="item-historial-encabezado">
          <span class="item-historial-fecha">{{ fecha }}</span>
          <span
            class="item-historial-badge"
            :style="{ color: (TIPOS[tipo] ?? GENERICO).color, background: (TIPOS[tipo] ?? GENERICO).bg }"
          >{{ tipo }}</span>
          <span
            v-if="apto !== undefined"
            class="item-historial-apto"
            :class="apto ? 'item-historial-apto--si' : 'item-historial-apto--no'"
          >{{ apto ? 'Apto' : 'No apto' }}</span>
          <span v-if="origenDato && ETIQUETA_ORIGEN[origenDato]" class="item-historial-origen">
            {{ ETIQUETA_ORIGEN[origenDato] }}
          </span>
        </div>
        <p v-if="detalle" class="item-historial-detalle">{{ detalle }}</p>
        <p v-if="comentario" class="item-historial-comentario">"{{ comentario }}"</p>
        <slot />
      </div>
    </div>
  </li>
</template>

<style scoped>
.item-historial { list-style: none; font-family: var(--font-ui); }
.item-historial-fila { display: grid; grid-template-columns: 32px 1fr; gap: 12px; padding: 10px 0; }
.item-historial--ultimo .item-historial-fila { padding-bottom: 0; }

.item-historial-rail { position: relative; display: flex; justify-content: center; }
.item-historial-rail::before {
  content: ''; position: absolute; top: 30px; bottom: -10px; width: 1px; background: var(--border-hairline);
}
.item-historial--ultimo .item-historial-rail::before { display: none; }
.item-historial-dot {
  width: 30px; height: 30px; border-radius: 50%; flex: 0 0 auto; z-index: 1;
  display: flex; align-items: center; justify-content: center;
}
.item-historial-icono { width: 15px; height: 15px; }

.item-historial-cuerpo { min-width: 0; }
.item-historial-encabezado { display: flex; align-items: baseline; gap: 8px; flex-wrap: wrap; }
.item-historial-fecha { font-size: var(--fs-125); color: var(--text-muted); font-family: var(--font-mono); }
.item-historial-badge {
  font-size: var(--fs-11); font-weight: var(--fw-bold); letter-spacing: var(--ls-caps);
  padding: 2px 8px; border-radius: var(--radio-sm);
}
.item-historial-apto {
  font-size: var(--fs-11); font-weight: var(--fw-bold); letter-spacing: var(--ls-caps);
  padding: 2px 8px; border-radius: var(--radio-sm);
}
.item-historial-apto--si { color: var(--ok-text); background: var(--ok-bg); }
.item-historial-apto--no { color: var(--bad-text); background: var(--bad-bg); }
.item-historial-origen { font-size: var(--fs-11); color: var(--text-muted); }
.item-historial-detalle { margin: 5px 0 0; font-size: var(--fs-135); }
.item-historial-comentario { margin: 4px 0 0; font-size: var(--fs-135); color: var(--text-muted); font-style: italic; }
</style>

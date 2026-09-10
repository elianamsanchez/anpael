<template>
  <svg
    :width="size"
    :height="size"
    viewBox="0 0 52 52"
    role="img"
    :aria-label="ariaLabel"
    v-html="innerMarkup"
  />
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { CATEGORIA_ICONOS, CATEGORIA_COLORES, type CategoriaIconConfig } from './categoriaIconos'

/**
 * Ícono de categoría de hacienda (cabeza bovina simplificada).
 * Lenguaje visual: color = sexo, cuernos = madurez/entereza, insignia = etapa.
 *
 * Uso:
 *   <CategoriaIcon :id-categoria="animal.idCategoria" :size="24" />
 *   <CategoriaIcon codigo="TORO" :size="32" />
 */
const props = withDefaults(
  defineProps<{
    idCategoria?: number
    codigo?: string
    size?: number
  }>(),
  {
    size: 32,
  }
)

const config = computed<CategoriaIconConfig | undefined>(() =>
  CATEGORIA_ICONOS.find(
    (c) =>
      (props.idCategoria !== undefined && c.idCategoria === props.idCategoria) ||
      (props.codigo !== undefined && c.codigo === props.codigo)
  )
)

const ariaLabel = computed(() => config.value?.nombre ?? 'Categoría sin ícono')

function buildMarkup(cfg: CategoriaIconConfig | undefined): string {
  if (!cfg) return ''
  const color = CATEGORIA_COLORES[cfg.color]
  const scale = cfg.size === 'sm' ? 0.8 : cfg.size === 'lg' ? 1.12 : 1
  const cx = 24
  const cy = 27
  const rx = 14 * scale
  const ry = 12 * scale
  const earRx = 5.5 * scale
  const earRy = 4 * scale

  let horn = ''
  if (cfg.cuernos === 'buds') {
    horn = `<circle cx="${cx - 9 * scale}" cy="${cy - ry - 1}" r="2" fill="${color}"/><circle cx="${cx + 9 * scale}" cy="${cy - ry - 1}" r="2" fill="${color}"/>`
  } else if (cfg.cuernos === 'full') {
    horn = `<path d="M ${cx - 9 * scale} ${cy - ry + 2} Q ${cx - 19 * scale} ${cy - ry - 6} ${cx - 15 * scale} ${cy - ry - 12}" stroke="${color}" stroke-width="2.6" fill="none" stroke-linecap="round"/>
            <path d="M ${cx + 9 * scale} ${cy - ry + 2} Q ${cx + 19 * scale} ${cy - ry - 6} ${cx + 15 * scale} ${cy - ry - 12}" stroke="${color}" stroke-width="2.6" fill="none" stroke-linecap="round"/>`
  }

  let extra = ''
  if (cfg.especial === 'cut') {
    extra += `<line x1="10" y1="10" x2="38" y2="44" stroke="${color}" stroke-width="1.4" opacity="0.5"/>`
  }

  let badgeSvg = ''
  if (cfg.badge) {
    const wide = cfg.badge.length > 2
    const bw = wide ? 8.5 + (cfg.badge.length - 2) * 3.2 : 8.5
    const bfs = wide ? 7 : 9
    badgeSvg = wide
      ? `<rect x="${38 - bw}" y="31.5" width="${bw * 2}" height="17" rx="8.5" fill="#3b322a"/>
         <text x="38" y="43" font-size="${bfs}" font-weight="700" fill="#fff" text-anchor="middle" font-family="sans-serif">${cfg.badge}</text>`
      : `<circle cx="38" cy="40" r="8.5" fill="#3b322a"/>
         <text x="38" y="43.2" font-size="${bfs}" font-weight="700" fill="#fff" text-anchor="middle" font-family="sans-serif">${cfg.badge}</text>`
  }

  return `
    ${horn}
    <ellipse cx="${cx - earRx - earRx * 0.4}" cy="${cy - ry * 0.3}" rx="${earRx}" ry="${earRy}" fill="${color}" transform="rotate(-25 ${cx - earRx - earRx * 0.4} ${cy - ry * 0.3})"/>
    <ellipse cx="${cx + earRx + earRx * 0.4}" cy="${cy - ry * 0.3}" rx="${earRx}" ry="${earRy}" fill="${color}" transform="rotate(25 ${cx + earRx + earRx * 0.4} ${cy - ry * 0.3})"/>
    <ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="${color}"/>
    <ellipse cx="${cx}" cy="${cy + ry * 0.55}" rx="${rx * 0.42}" ry="${ry * 0.4}" fill="#fff" opacity="0.35"/>
    <circle cx="${cx - 3.5}" cy="${cy + ry * 0.55}" r="1" fill="${color}"/>
    <circle cx="${cx + 3.5}" cy="${cy + ry * 0.55}" r="1" fill="${color}"/>
    ${extra}
    ${badgeSvg}
  `
}

const innerMarkup = computed(() => buildMarkup(config.value))
</script>

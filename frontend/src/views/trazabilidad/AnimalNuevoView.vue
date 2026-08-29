<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import {
  crearAnimal, listarCategorias, listarRodeos, listarRazas, listarPelajes,
  listarCabanas, listarEstablecimientos,
  type Categoria, type Rodeo, type Raza, type Pelaje, type Cabana, type Establecimiento
} from '@/api/animales'
import type { ErrorApi } from '@/api/client'
import Marca from '@/components/base/Marca.vue'
import Tarjeta from '@/components/base/Tarjeta.vue'
import Campo from '@/components/formularios/Campo.vue'
import Check from '@/components/formularios/Check.vue'
import Boton from '@/components/base/Boton.vue'
import Aviso from '@/components/avisos/Aviso.vue'

/**
 * Alta de un animal nuevo (v0.2a): un ternero que nace o un animal que se
 * compra necesita entrar por primera vez. La caravana es siempre VISUAL en
 * Santa Ana -el backend lo resuelve solo-, así que acá no se pide
 * establecimiento para la identificación.
 */
const router = useRouter()

const categorias = ref<Categoria[]>([])
const rodeos = ref<Rodeo[]>([])
const razas = ref<Raza[]>([])
const pelajes = ref<Pelaje[]>([])
const cabanas = ref<Cabana[]>([])
const establecimientos = ref<Establecimiento[]>([])

const caravana = ref('')
const sexo = ref('')
const origen = ref('NACIDO')
const idRaza = ref<number | null>(null)
const idPelaje = ref<number | null>(null)
const idCabana = ref<number | null>(null)
const idEstabOrigen = ref<number | null>(null)
const fechaNacimiento = ref('')
const fechaNacEsEstimada = ref(false)
const pesoNacerKg = ref('')
const fechaIngreso = ref('')
const idMadre = ref('')
const idPadre = ref('')
const idCategoria = ref<number | null>(null)
const idRodeo = ref<number | null>(null)

const guardando = ref(false)
const error = ref<ErrorApi | null>(null)

async function guardar() {
  guardando.value = true
  error.value = null
  try {
    const animal = await crearAnimal({
      caravana: caravana.value.trim(),
      sexo: sexo.value,
      origen: origen.value,
      idRaza: idRaza.value ?? undefined,
      idPelaje: idPelaje.value ?? undefined,
      idCabana: origen.value === 'COMPRADO' ? (idCabana.value ?? undefined) : undefined,
      idEstabOrigen: origen.value !== 'NACIDO' ? (idEstabOrigen.value ?? undefined) : undefined,
      fechaNacimiento: fechaNacimiento.value || undefined,
      fechaNacEsEstimada: fechaNacimiento.value ? fechaNacEsEstimada.value : undefined,
      pesoNacerKg: pesoNacerKg.value ? Number(pesoNacerKg.value) : undefined,
      fechaIngreso: fechaIngreso.value || undefined,
      idMadre: idMadre.value ? Number(idMadre.value) : undefined,
      idPadre: idPadre.value ? Number(idPadre.value) : undefined,
      idCategoria: idCategoria.value ?? undefined,
      idRodeo: idRodeo.value ?? undefined
    })
    router.push(`/animales/${animal.idAnimal}`)
  } catch (e) {
    error.value = e as ErrorApi
  } finally {
    guardando.value = false
  }
}

onMounted(() => {
  listarCategorias().then(c => { categorias.value = c })
  listarRodeos().then(r => { rodeos.value = r })
  listarRazas().then(r => { razas.value = r })
  listarPelajes().then(p => { pelajes.value = p })
  listarCabanas().then(c => { cabanas.value = c })
  listarEstablecimientos().then(e => { establecimientos.value = e })
})
</script>

<template>
  <main class="pantalla">
    <nav class="migas">
      <RouterLink to="/" class="volver">‹ Inicio</RouterLink>
      <span class="atenuado">·</span>
      <RouterLink to="/animales" class="volver">Volver al padrón</RouterLink>
    </nav>

    <Marca titulo="Nuevo animal" bajada="Alta con identificación visual en Santa Ana" class="marca-nuevo" />

    <Tarjeta>
      <form class="form-nuevo" @submit.prevent="guardar">
        <div class="fila">
          <Campo etiqueta="Caravana" requerido placeholder="Ej: 0075" v-model:valor="caravana" />
          <Campo
            etiqueta="Sexo" requerido
            :opciones="[{ valor: '', etiqueta: 'Elegir…' }, { valor: 'H', etiqueta: 'Hembra' }, { valor: 'M', etiqueta: 'Macho' }]"
            v-model:valor="sexo"
          />
        </div>

        <div class="fila">
          <Campo
            etiqueta="Origen" requerido
            :opciones="[{ valor: 'NACIDO', etiqueta: 'Nacido en el campo' }, { valor: 'COMPRADO', etiqueta: 'Comprado' }, { valor: 'RECIBIDO', etiqueta: 'Recibido' }]"
            v-model:valor="origen"
          />
          <Campo
            v-if="origen === 'COMPRADO'"
            etiqueta="Cabaña de origen"
            :opciones="[{ valor: null, etiqueta: '(sin especificar)' }, ...cabanas.map(c => ({ valor: c.idCabana, etiqueta: c.nombre }))]"
            :valor="idCabana"
            @update:valor="idCabana = $event === '' ? null : Number($event)"
          />
          <Campo
            v-if="origen !== 'NACIDO'"
            etiqueta="Establecimiento de origen"
            :opciones="[{ valor: null, etiqueta: '(sin especificar)' }, ...establecimientos.map(e => ({ valor: e.idEstablecimiento, etiqueta: `${e.nombre} (${e.cuig})` }))]"
            :valor="idEstabOrigen"
            @update:valor="idEstabOrigen = $event === '' ? null : Number($event)"
          />
        </div>

        <div class="fila">
          <Campo
            etiqueta="Raza"
            :opciones="[{ valor: null, etiqueta: '(sin especificar)' }, ...razas.map(r => ({ valor: r.idRaza, etiqueta: r.nombre }))]"
            :valor="idRaza"
            @update:valor="idRaza = $event === '' ? null : Number($event)"
          />
          <Campo
            etiqueta="Pelaje"
            :opciones="[{ valor: null, etiqueta: '(sin especificar)' }, ...pelajes.map(p => ({ valor: p.idPelaje, etiqueta: p.nombre }))]"
            :valor="idPelaje"
            @update:valor="idPelaje = $event === '' ? null : Number($event)"
          />
        </div>

        <div class="fila">
          <Campo etiqueta="Fecha de nacimiento" tipo="date" v-model:valor="fechaNacimiento" />
          <Check v-if="fechaNacimiento" etiqueta="Es estimada" class="check-fila" v-model:marcado="fechaNacEsEstimada" />
          <Campo etiqueta="Peso al nacer (kg)" tipo="number" min="10" max="70" step="0.1" placeholder="10 a 70" v-model:valor="pesoNacerKg" />
        </div>

        <div class="fila">
          <Campo etiqueta="Fecha de ingreso" tipo="date" v-model:valor="fechaIngreso" />
          <Campo etiqueta="N° de madre (id animal)" tipo="number" min="1" placeholder="Opcional" v-model:valor="idMadre" />
          <Campo etiqueta="N° de padre (id animal)" tipo="number" min="1" placeholder="Opcional" v-model:valor="idPadre" />
        </div>

        <div class="fila">
          <Campo
            etiqueta="Categoría"
            :opciones="[{ valor: null, etiqueta: '(sin asignar)' }, ...categorias.map(c => ({ valor: c.idCategoria, etiqueta: c.nombre }))]"
            :valor="idCategoria"
            @update:valor="idCategoria = $event === '' ? null : Number($event)"
          />
          <Campo
            etiqueta="Rodeo"
            :opciones="[{ valor: null, etiqueta: '(sin asignar)' }, ...rodeos.map(r => ({ valor: r.idRodeo, etiqueta: r.nombre }))]"
            :valor="idRodeo"
            @update:valor="idRodeo = $event === '' ? null : Number($event)"
          />
        </div>

        <Boton class="boton-guardar" tipo="submit" :deshabilitado="!caravana || !sexo || guardando">
          {{ guardando ? 'Guardando…' : 'Dar de alta' }}
        </Boton>
        <Aviso v-if="error" tono="error">{{ error.mensaje }} <span v-if="error.detalle">— {{ error.detalle }}</span></Aviso>
      </form>
    </Tarjeta>
  </main>
</template>

<style scoped>
.pantalla { max-width: var(--ancho-forma); margin: 6vh auto; padding: 0 16px; }
.migas { display: flex; align-items: center; gap: 8px; margin-bottom: 14px; }
.volver { color: var(--text-muted); font-size: var(--fs-13); text-decoration: none; }
.volver:hover { text-decoration: underline; }
.atenuado { color: var(--text-muted); }
header.marca-nuevo { margin-bottom: 18px; }

.form-nuevo { display: flex; flex-direction: column; gap: var(--gap-campo); }
.fila { display: flex; gap: var(--gap-campo); flex-wrap: wrap; align-items: flex-end; }
label.check-fila { padding-bottom: 9px; }

button.boton-guardar { align-self: flex-start; }
</style>

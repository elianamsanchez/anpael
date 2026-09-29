<script setup lang="ts">
import { ref, onMounted } from 'vue'
import {
  LINEAS, fechaAR, listarCiclos, crearCiclo, editarCiclo,
  type CicloProductivo, type GuardarCiclo
} from '@/api/terneros'
import type { ErrorApi } from '@/api/client'
import Marca from '@/components/base/Marca.vue'
import Tarjeta from '@/components/base/Tarjeta.vue'
import Campo from '@/components/formularios/Campo.vue'
import Boton from '@/components/base/Boton.vue'
import Aviso from '@/components/avisos/Aviso.vue'

/**
 * Ciclos productivos, editables. Un ciclo va del inicio del servicio al fin
 * del destete; lo que decide a qué ciclo pertenece un ternero es el tramo
 * desde el inicio de la parición hasta el fin, que no se puede superponer
 * con otro ciclo de la misma línea. Cambiar fechas no mueve lo ya cargado.
 */
const ciclos = ref<CicloProductivo[]>([])
const editando = ref<number | 'nuevo' | null>(null)
const form = ref<GuardarCiclo>(vacio())
const guardando = ref(false)
const mensaje = ref<string | null>(null)
const error = ref<ErrorApi | null>(null)

function vacio(): GuardarCiclo {
  return { codigo: '', linea: 'VACA', fechaInicio: '', paricionDesde: '', paricionHasta: '', fechaFin: '', observaciones: '' }
}

async function consultar() {
  try {
    ciclos.value = await listarCiclos()
  } catch (e) {
    error.value = e as ErrorApi
  }
}
onMounted(consultar)

function editar(c: CicloProductivo) {
  editando.value = c.idCicloProductivo
  form.value = { ...c, observaciones: c.observaciones ?? '' }
}

function nuevo() {
  editando.value = 'nuevo'
  form.value = vacio()
}

async function guardar() {
  guardando.value = true
  mensaje.value = null
  error.value = null
  try {
    const pedido = { ...form.value, observaciones: form.value.observaciones || undefined }
    const c = editando.value === 'nuevo' ? await crearCiclo(pedido) : await editarCiclo(editando.value as number, pedido)
    mensaje.value = `Ciclo ${c.codigo} guardado.`
    editando.value = null
    await consultar()
  } catch (e) {
    error.value = e as ErrorApi
  } finally {
    guardando.value = false
  }
}
</script>

<template>
  <main class="pantalla">
    <RouterLink to="/terneros" class="volver">‹ Terneros sin identificar</RouterLink>

    <Marca bajada="Santa Ana · ciclos productivos" class="marca-ciclos" />

    <Aviso v-if="error" tono="error" :detalle="error.detalle" class="aviso-fila">{{ error.mensaje }}</Aviso>
    <Aviso v-if="mensaje" tono="ok" class="aviso-fila">{{ mensaje }}</Aviso>

    <Tarjeta denso class="bloque">
      <table class="tabla">
        <thead>
          <tr><th>Ciclo</th><th>Madres</th><th>Servicio desde</th><th>Parición</th><th>Fin</th><th></th></tr>
        </thead>
        <tbody>
          <tr v-for="c in ciclos" :key="c.idCicloProductivo">
            <td class="ciclo">{{ c.codigo }}</td>
            <td>{{ c.linea === 'VACA' ? 'Vacas' : 'Vaquillonas' }}</td>
            <td class="mono">{{ fechaAR(c.fechaInicio) }}</td>
            <td class="mono">{{ fechaAR(c.paricionDesde) }} – {{ fechaAR(c.paricionHasta) }}</td>
            <td class="mono">{{ fechaAR(c.fechaFin) }}</td>
            <td class="acciones"><Boton variante="texto" tamano="sm" @click="editar(c)">Corregir</Boton></td>
          </tr>
        </tbody>
      </table>
      <Boton v-if="editando === null" variante="sobrio" tamano="sm" @click="nuevo">+ Nuevo ciclo</Boton>
    </Tarjeta>

    <Tarjeta
      v-if="editando !== null"
      :titulo="editando === 'nuevo' ? 'Nuevo ciclo' : `Corregir ${form.codigo}`"
      nota="Si cambiás fechas, lo ya cargado queda en su ciclo. Lo que quede afuera aparece como alerta en terneros."
      class="bloque"
    >
      <form class="form" @submit.prevent="guardar">
        <div class="fila">
          <Campo etiqueta="Código" requerido placeholder="2027-28 o VAQ2027-28" v-model:valor="form.codigo" />
          <Campo etiqueta="Madres" requerido :opciones="LINEAS" v-model:valor="form.linea" />
        </div>
        <div class="fila">
          <Campo etiqueta="Inicio del servicio" tipo="date" requerido v-model:valor="form.fechaInicio" />
          <Campo etiqueta="Fin del ciclo (destete)" tipo="date" requerido v-model:valor="form.fechaFin" />
        </div>
        <div class="fila">
          <Campo etiqueta="Parición desde" tipo="date" requerido v-model:valor="form.paricionDesde" />
          <Campo etiqueta="Parición hasta" tipo="date" requerido v-model:valor="form.paricionHasta" />
        </div>
        <Campo etiqueta="Observaciones" tipo="textarea" v-model:valor="form.observaciones" />
        <div class="botones">
          <Boton tipo="submit" :deshabilitado="guardando">{{ guardando ? 'Guardando…' : 'Guardar ciclo' }}</Boton>
          <Boton variante="sobrio" @click="editando = null">Cancelar</Boton>
        </div>
      </form>
    </Tarjeta>
  </main>
</template>

<style scoped>
.pantalla { max-width: var(--ancho-forma); margin: 6vh auto; padding: 0 16px; }
.volver { display: inline-block; margin-bottom: 14px; color: var(--text-muted); font-size: var(--fs-13); text-decoration: none; }
.volver:hover { text-decoration: underline; }
header.marca-ciclos { margin-bottom: 18px; }
p.aviso-fila { margin: 0 0 14px; }
section.bloque { margin-bottom: 18px; }

.form { display: flex; flex-direction: column; gap: var(--gap-campo); }
.fila { display: flex; gap: 14px; flex-wrap: wrap; }
.botones { display: flex; gap: 10px; }
.mono { font-family: var(--font-mono); white-space: nowrap; }

.tabla { width: 100%; border-collapse: collapse; font-size: var(--fs-135); margin-bottom: 12px; }
.tabla th { text-align: left; font-size: 11.5px; color: var(--text-muted); font-weight: var(--fw-semibold); padding: 6px 8px; border-bottom: var(--borde-fino); }
.tabla td { padding: 6px 8px; border-bottom: var(--borde-filete); }
.tabla td.ciclo { font-weight: var(--fw-semibold); }
.tabla td.acciones { text-align: right; }
</style>

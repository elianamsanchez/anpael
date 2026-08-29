<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import {
  crearAnimal, listarCategorias, listarRodeos, listarRazas, listarPelajes,
  listarCabanas, listarEstablecimientos,
  type Categoria, type Rodeo, type Raza, type Pelaje, type Cabana, type Establecimiento
} from '@/api/animales'
import type { ErrorApi } from '@/api/client'

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

    <header class="marca">
      <span class="punto"></span>
      <div>
        Nuevo animal
        <small>Alta con identificación visual en Santa Ana</small>
      </div>
    </header>

    <section class="tarjeta">
      <form class="form-nuevo" @submit.prevent="guardar">
        <div class="fila">
          <label class="campo">
            <span>Caravana *</span>
            <input v-model="caravana" type="text" placeholder="Ej: 0075" required />
          </label>
          <label class="campo">
            <span>Sexo *</span>
            <select v-model="sexo" required>
              <option value="" disabled>Elegir…</option>
              <option value="H">Hembra</option>
              <option value="M">Macho</option>
            </select>
          </label>
        </div>

        <div class="fila">
          <label class="campo">
            <span>Origen *</span>
            <select v-model="origen" required>
              <option value="NACIDO">Nacido en el campo</option>
              <option value="COMPRADO">Comprado</option>
              <option value="RECIBIDO">Recibido</option>
            </select>
          </label>
          <label class="campo" v-if="origen === 'COMPRADO'">
            <span>Cabaña de origen</span>
            <select v-model.number="idCabana">
              <option :value="null">(sin especificar)</option>
              <option v-for="c in cabanas" :key="c.idCabana" :value="c.idCabana">{{ c.nombre }}</option>
            </select>
          </label>
          <label class="campo" v-if="origen !== 'NACIDO'">
            <span>Establecimiento de origen</span>
            <select v-model.number="idEstabOrigen">
              <option :value="null">(sin especificar)</option>
              <option v-for="e in establecimientos" :key="e.idEstablecimiento" :value="e.idEstablecimiento">
                {{ e.nombre }} ({{ e.cuig }})
              </option>
            </select>
          </label>
        </div>

        <div class="fila">
          <label class="campo">
            <span>Raza</span>
            <select v-model.number="idRaza">
              <option :value="null">(sin especificar)</option>
              <option v-for="r in razas" :key="r.idRaza" :value="r.idRaza">{{ r.nombre }}</option>
            </select>
          </label>
          <label class="campo">
            <span>Pelaje</span>
            <select v-model.number="idPelaje">
              <option :value="null">(sin especificar)</option>
              <option v-for="p in pelajes" :key="p.idPelaje" :value="p.idPelaje">{{ p.nombre }}</option>
            </select>
          </label>
        </div>

        <div class="fila">
          <label class="campo">
            <span>Fecha de nacimiento</span>
            <input v-model="fechaNacimiento" type="date" />
          </label>
          <label class="check" v-if="fechaNacimiento">
            <input v-model="fechaNacEsEstimada" type="checkbox" /> Es estimada
          </label>
          <label class="campo">
            <span>Peso al nacer (kg)</span>
            <input v-model="pesoNacerKg" type="number" min="10" max="70" step="0.1" placeholder="10 a 70" />
          </label>
        </div>

        <div class="fila">
          <label class="campo">
            <span>Fecha de ingreso</span>
            <input v-model="fechaIngreso" type="date" />
          </label>
          <label class="campo">
            <span>N° de madre (id animal)</span>
            <input v-model="idMadre" type="number" min="1" placeholder="Opcional" />
          </label>
          <label class="campo">
            <span>N° de padre (id animal)</span>
            <input v-model="idPadre" type="number" min="1" placeholder="Opcional" />
          </label>
        </div>

        <div class="fila">
          <label class="campo">
            <span>Categoría</span>
            <select v-model.number="idCategoria">
              <option :value="null">(sin asignar)</option>
              <option v-for="c in categorias" :key="c.idCategoria" :value="c.idCategoria">{{ c.nombre }}</option>
            </select>
          </label>
          <label class="campo">
            <span>Rodeo</span>
            <select v-model.number="idRodeo">
              <option :value="null">(sin asignar)</option>
              <option v-for="r in rodeos" :key="r.idRodeo" :value="r.idRodeo">{{ r.nombre }}</option>
            </select>
          </label>
        </div>

        <button class="boton-guardar" type="submit" :disabled="!caravana || !sexo || guardando">
          {{ guardando ? 'Guardando…' : 'Dar de alta' }}
        </button>
        <p v-if="error" class="aviso-error">{{ error.mensaje }} <span v-if="error.detalle">— {{ error.detalle }}</span></p>
      </form>
    </section>
  </main>
</template>

<style scoped>
.pantalla { max-width: 720px; margin: 6vh auto; padding: 0 16px; }
.migas { display: flex; align-items: center; gap: 8px; margin-bottom: 14px; }
.volver { color: var(--n500); font-size: 13px; text-decoration: none; }
.volver:hover { text-decoration: underline; }
.atenuado { color: var(--n500); }
.marca { display: flex; gap: 10px; align-items: center; font-weight: 700; margin-bottom: 18px; }
.marca small { display: block; font-weight: 400; font-size: 12px; color: var(--n500); }
.punto { width: 12px; height: 12px; border-radius: 50%; background: var(--tierra); }
.tarjeta { background: #fff; border: 1px solid var(--n200); border-radius: 10px; padding: 20px; }

.form-nuevo { display: flex; flex-direction: column; gap: 14px; }
.fila { display: flex; gap: 14px; flex-wrap: wrap; align-items: flex-end; }
.campo { display: flex; flex-direction: column; gap: 4px; font-size: 13px; color: var(--n500); flex: 1; min-width: 160px; }
.campo select, .campo input {
  font: inherit; font-size: 13.5px; padding: 8px 10px; border-radius: 8px;
  border: 1px solid var(--n200); background: var(--n50); color: var(--cuero);
}
.check { display: flex; align-items: center; gap: 6px; font-size: 13px; color: var(--n500); padding-bottom: 9px; }

.boton-guardar {
  align-self: flex-start; background: var(--tierra); color: #fff; border: none;
  border-radius: 8px; padding: 10px 18px; font-size: 14px; font-weight: 600; cursor: pointer;
}
.boton-guardar:disabled { opacity: .5; cursor: not-allowed; }
.aviso-error {
  background: #FBEAE6; border: 1px solid #E8B3A6; color: var(--bad);
  border-radius: 8px; padding: 8px 10px; font-size: 13px; margin: 0;
}
</style>

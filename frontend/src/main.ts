import { createApp } from 'vue'
import { createPinia } from 'pinia'
import PrimeVue from 'primevue/config'
import Aura from '@primevue/themes/aura'
import 'primeicons/primeicons.css'
import './assets/tokens/index.css'

import App from './App.vue'
import router from './router'

const app = createApp(App)

app.use(createPinia())
app.use(router)
app.use(PrimeVue, {
  theme: {
    preset: Aura,
    options: {
      // Sin modo oscuro automatico: la app se usa en una oficina y en el
      // celular a pleno sol. Un solo modo, legible, y despues se decide.
      darkModeSelector: '.modo-oscuro'
    }
  },
  locale: {
    dayNames: ['Domingo','Lunes','Martes','Miercoles','Jueves','Viernes','Sabado'],
    dayNamesShort: ['Dom','Lun','Mar','Mie','Jue','Vie','Sab'],
    dayNamesMin: ['D','L','M','X','J','V','S'],
    monthNames: ['Enero','Febrero','Marzo','Abril','Mayo','Junio',
                 'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'],
    monthNamesShort: ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'],
    today: 'Hoy', clear: 'Limpiar', weekHeader: 'Sem', firstDayOfWeek: 1,
    dateFormat: 'dd/mm/yy'
  }
})

app.mount('#app')

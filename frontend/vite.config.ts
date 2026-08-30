import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { VitePWA } from 'vite-plugin-pwa'
import { fileURLToPath, URL } from 'node:url'

export default defineConfig({
  plugins: [
    vue(),
    // PWA elegido DEFENSIVAMENTE, como dice el documento de stack: hoy no
    // habilita nada offline, pero el dia que haga falta en Fase 2 no hay que
    // reescribir el empaquetado. Registro manual para que no aparezca el
    // cartel de "hay una version nueva" en medio de una carga.
    VitePWA({
      registerType: 'prompt',
      manifest: {
        name: 'ANPAEL · Santa Ana',
        short_name: 'ANPAEL',
        description: 'Gestion ganadera',
        theme_color: '#2F5238',
        background_color: '#F5F7F5',
        display: 'standalone',
        start_url: '/'
      }
    })
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  },
  server: {
    port: 5173,
    // EL PROXY ES LO QUE HACE QUE EL PASO 3 DEL ARRANQUE SEA BARATO.
    // El navegador pide a localhost:5173/api/... y Vite lo reenvia al
    // backend. Para el navegador es el mismo origen, asi que CORS no
    // interviene en desarrollo y no hay que pelearse con dos cosas a la vez.
    //
    // Si algun dia queres probar CORS de verdad, apunta el axios directo a
    // http://localhost:8080 con VITE_API_URL y saca este proxy.
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true
      }
    }
  }
})

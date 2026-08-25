import axios, { AxiosError } from 'axios'

/**
 * Cliente HTTP unico de la aplicacion.
 *
 * baseURL vacio a proposito: asi las llamadas salen a /api/... del mismo
 * origen y las atiende el proxy de Vite en desarrollo. Para pegarle directo
 * al backend, definir VITE_API_URL en .env.local (y ahi entra CORS).
 */
export const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '',
  timeout: 20000,
  headers: { 'Content-Type': 'application/json' }
})

/**
 * Interceptor de salida: agrega el token a cada pedido.
 *
 * El token vive en memoria, en el store de auth, NO en localStorage. Un token
 * en localStorage queda ahi para cualquiera que use esa computadora y lo
 * pueden leer scripts de terceros. El costo es tener que volver a entrar
 * despues de recargar la pagina, que para una app de oficina es aceptable.
 */
let tokenEnMemoria: string | null = null
export function setToken(t: string | null) { tokenEnMemoria = t }
export function getToken() { return tokenEnMemoria }

api.interceptors.request.use((config) => {
  if (tokenEnMemoria) {
    config.headers.Authorization = `Bearer ${tokenEnMemoria}`
  }
  return config
})

/**
 * Interceptor de entrada: traduce los errores a algo que se pueda mostrar.
 *
 * Es importante distinguir "el servidor no contesta" de "el servidor dijo que
 * no": el primero es un problema de conexion o de que el backend no esta
 * levantado, el segundo es una respuesta legitima. Confundirlos hace perder
 * mucho tiempo al depurar.
 */
export interface ErrorApi {
  estado: number
  mensaje: string
  detalle?: string
}

api.interceptors.response.use(
  (r) => r,
  (e: AxiosError<any>) => {
    if (!e.response) {
      return Promise.reject({
        estado: 0,
        mensaje: 'No se pudo contactar al servidor.',
        detalle: 'Verifica que el backend este levantado en el puerto 8080.'
      } as ErrorApi)
    }
    const d = e.response.data
    return Promise.reject({
      estado: e.response.status,
      mensaje: d?.mensaje ?? `Error ${e.response.status}`,
      detalle: d?.detalle
    } as ErrorApi)
  }
)

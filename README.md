# ANPAEL · Gestión ganadera Santa Ana

Backend Java + frontend móvil para llevar la gestión del ganado en el campo.
La base de datos ya existe y está poblada: 1.732 animales, 1.782
identificaciones y 3.164 eventos migrados desde las planillas Excel.

---

## Qué hay acá adentro

```
anpael/
├── backend/            Spring Boot 3.3.5 · Java 21 · monolito modular
│   └── src/main/java/com/anpael/
│       ├── AnpaelApplication.java
│       └── shared/          config, excepciones, auditoría, /api/health
├── frontend/           Vue 3 · TypeScript · Vite · PrimeVue · PWA
├── supabase/
│   └── migrations/     los .sql que le dan forma a la base
├── docs/
│   ├── decisiones.md   ADR: por qué está hecho así  ← LEER PRIMERO
│   └── modelo-datos.md qué tablas hay y qué significan
└── .github/workflows/  compilar y testear en cada push
```

Los módulos de negocio (`trazabilidad`, `sanidad`, `reproduccion`,
`planillas`, `seguridad`) todavía no existen. Se crean cada uno como paquete
bajo `com.anpael/`, con su propio controller, service y repository. La regla
del monolito modular: **un módulo no importa clases de otro módulo**; si
necesita datos ajenos, los pide por un servicio público o por una vista.

---

## Arrancar por primera vez

**Atajo**, una vez que ya tenés Supabase local corriendo y los `.env`
armados (ver abajo): `bash scripts/levantar_local.sh` levanta backend y
frontend, espera a que contesten y avisa cuándo está todo listo.
`bash scripts/bajar_local.sh` los baja. Ninguno de los dos toca Supabase.
`bash scripts/usuario_prueba_local.sh <usuario> <contraseña>` arma una
contraseña de prueba para loguearte a mano en local sin pasar por Supabase
Auth -y `... <usuario> --borrar` la saca de nuevo.

Hace falta: **JDK 21**, **Maven 3.9+**, **Node 20+**, y **Docker** solo si
querés correr los tests de integración.

### 1 · Backend

Hay dos plantillas, una por entorno. Copiá la que corresponda a `.env`:

```bash
cd backend
cp .env.local.example .env        # contra el Supabase local en Docker
# o, para hablarle a la base real:
cp .env.production.example .env
```

`.env` queda igual en los dos casos — lo que cambia es de dónde salió. Nunca
tengas los dos entornos completados en el mismo `.env` a la vez.

Cargá las variables y arrancá:

```bash
set -a; source .env; set +a
mvn spring-boot:run
```

En IntelliJ es más cómodo: `Run → Edit Configurations → Environment
variables` y pegar ahí el contenido del `.env`.

**Qué mirar para saber que anduvo.** Con el backend levantado:

```bash
curl http://localhost:8080/api/health
```

Tiene que devolver algo así:

```json
{
  "aplicacion": "anpael",
  "entorno": "local",
  "hora": "2026-08-24T10:00:00-03:00",
  "usuarioBase": "postgres",
  "base": "postgres",
  "animales": 1732,
  "base_de_datos": "ok"
}
```

El `animales: 1732` prueba que conectó y que el esquema es el correcto, pero
**ya no prueba a qué base te conectaste**: el Supabase local tiene un dump
de producción, así que va a devolver el mismo número. Para eso está
`entorno` — mirá siempre ese campo antes de cargar o corregir algo, sobre
todo si vas a escribir en la base.

Si devuelve **503** con `"base_de_datos": "ERROR"`, el problema es la cadena
de conexión, no la aplicación. Ver *Problemas conocidos* abajo.

### 2 · Frontend

En otra terminal:

```bash
cd frontend
cp .env.example .env.local
npm install
npm run dev
```

Abrir <http://localhost:5173>. La pantalla de estado consulta
`/api/health` a través del proxy de Vite, así que **no hay CORS** en
desarrollo: para el navegador, backend y frontend viven en el mismo lugar.

Si el frontend muestra "sin conexión con el servidor" pero el `curl` de
arriba anda, el backend está en otro puerto: revisá `ANPAEL_PORT` y el
`target` del proxy en `vite.config.ts`.

---

## Problemas conocidos al conectar con Supabase

| Síntoma | Causa | Solución |
|---|---|---|
| `prepared statement "S_1" already exists`, y **a veces sí y a veces no** | el pooler de transacciones no soporta *prepared statements* con nombre | agregar `?prepareThreshold=0` a la URL (ya está en `.env.example`) |
| `permission denied for view v_...` | falta el `GRANT`. RLS y GRANT son candados distintos | correr `mig_20_permisos.sql` |
| `Connection refused` en el puerto 5432 | el plan gratuito puede no tener conexión directa por IPv4 | usar el pooler, puerto **6543** |
| la aplicación no arranca y dice *Schema-validation: missing table* | una entidad JPA no coincide con la tabla real | corregir la entidad; **no** poner `ddl-auto: update` |

Ese último merece una aclaración: `ddl-auto: validate` está puesto a
propósito. Si Hibernate pudiera modificar el esquema habría dos fuentes de
verdad —los `.sql` y las entidades— y tarde o temprano se pisan. Que la
aplicación no arranque es la señal de que hay que arreglar algo, no un
estorbo.

---

## Los secretos

Ningún archivo del repositorio tiene una clave adentro, y así tiene que
quedar. Todo entra por variables de entorno.

- `.env` está en `.gitignore`. `.env.example` es la plantilla, sin valores.
- La clave `sb_secret_` / *service role* de Supabase **no se usa acá** y no
  tiene que estar en ninguna máquina de desarrollo: saltea toda la seguridad
  de la base.
- Si alguna vez se sube un secreto por error, hay que **rotarlo**. Borrarlo
  con un commit nuevo no sirve: queda en el historial.

---

## Estado del proyecto

| | |
|---|---|
| Base de datos migrada y verificada | ✅ |
| Esqueleto del repositorio | ✅ ← acá estamos |
| `/api/health` conectado de punta a punta | ⏳ falta que lo corras |
| Módulo Seguridad | ⏳ bloqueado por **ADR-001** |
| Saneamiento de datos | ⏳ |
| Generador de planillas | ⏳ |

**Antes de escribir el módulo Seguridad hay que cerrar ADR-001**
(`docs/decisiones.md`): quién manda en la autorización, Spring Security o
las 112 políticas RLS que ya tiene la base. No es un detalle de
configuración; las dos capas no se suman, compiten.

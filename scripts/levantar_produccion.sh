#!/usr/bin/env bash
# =====================================================================
# Levanta el backend y el frontend contra la BASE DE DATOS REAL de
# Santa Ana (1.732 animales migrados y en uso). Pensado para correr con
# Git Bash en Windows.
#
# Uso:
#   bash scripts/levantar_produccion.sh
#
# A diferencia de levantar_local.sh:
#   - No toca Docker ni Supabase local: la base ya existe en la nube.
#   - Exige backend/.env.production completo (sin defaults inventados:
#     no hay contraseña "segura" que poner por vos).
#   - Pide confirmación explícita antes de arrancar nada.
#   - Después de levantar, chequea /api/health y aborta si "entorno" no
#     es el esperado -mejor cortar ahí que dejarte escribir a ciegas.
# =====================================================================
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
estado_dir="$repo_dir/.dev"
mkdir -p "$estado_dir"

backend_log="$estado_dir/backend-produccion.log"
frontend_log="$estado_dir/frontend-produccion.log"
backend_pid_file="$estado_dir/backend-produccion.pid"
frontend_pid_file="$estado_dir/frontend-produccion.pid"

frontend_port=5173

responde() {
  curl -s -o /dev/null -w '%{http_code}' "$1" 2>/dev/null | grep -q "${2:-200}"
}

entorno_actual() {
  curl -s "http://localhost:${1}/api/health" 2>/dev/null | grep -o '"entorno"[^,}]*' | grep -o '"[^"]*"$' | tr -d '"'
}

echo "== 0. Variables de entorno =="
cd "$repo_dir/backend"
if [ ! -f .env.production ]; then
  echo "No existe backend/.env.production."
  echo "Copiá la plantilla y completala con los datos reales de Supabase:"
  echo "  cp .env.production.example .env.production"
  exit 1
fi
echo "Usando backend/.env.production"
set -a; source .env.production; set +a
cd "$repo_dir"

for var in ANPAEL_DB_URL ANPAEL_DB_USER ANPAEL_DB_PASSWORD ANPAEL_JWT_SECRETO; do
  if [ -z "${!var:-}" ]; then
    echo "Falta completar $var en backend/.env.production. No arranco."
    exit 1
  fi
done

anpael_port="${ANPAEL_PORT:-8080}"
entorno_esperado="${ANPAEL_ENTORNO:-produccion}"

echo
echo "== 1. Confirmación =="
echo "Esto va a conectar el backend a la base REAL (entorno=\"$entorno_esperado\")."
echo "Lo que cargues, corrijas o borres desde acá impacta los datos de verdad."
read -r -p "Escribí 'produccion' para confirmar: " confirmacion
if [ "$confirmacion" != "produccion" ]; then
  echo "No coincide. Corto sin tocar nada."
  exit 1
fi

echo
echo "== 2. Backend =="
if responde "http://localhost:$anpael_port/api/health"; then
  entorno_activo="$(entorno_actual "$anpael_port")"
  if [ "$entorno_activo" != "$entorno_esperado" ]; then
    echo "Ya hay un backend respondiendo en :$anpael_port, pero con entorno=\"$entorno_activo\"."
    echo "No es el que esperaba (\"$entorno_esperado\"). Bajalo primero (bash scripts/bajar_local.sh) y volvé a correr esto."
    exit 1
  fi
  echo "Ya hay un backend de \"$entorno_esperado\" respondiendo en :$anpael_port, no arranco otro."
else
  (
    cd "$repo_dir/backend"
    set -a; source .env.production; set +a
    export ANPAEL_PORT="$anpael_port"
    nohup mvn -q spring-boot:run > "$backend_log" 2>&1 &
    echo $! > "$backend_pid_file"
  )
  echo "Esperando a que conteste /api/health (hasta 90s)…"
  ok=0
  for _ in $(seq 1 45); do
    if responde "http://localhost:$anpael_port/api/health"; then ok=1; break; fi
    sleep 2
  done
  if [ "$ok" != 1 ]; then
    echo "El backend no respondió a tiempo. Mirá $backend_log"
    exit 1
  fi

  entorno_activo="$(entorno_actual "$anpael_port")"
  if [ "$entorno_activo" != "$entorno_esperado" ]; then
    echo "El backend arrancó pero /api/health dice entorno=\"$entorno_activo\", no \"$entorno_esperado\"."
    echo "Algo no está usando backend/.env.production. Revisá antes de seguir -no bajo el proceso por las dudas, hacelo con bash scripts/bajar_local.sh."
    exit 1
  fi
  echo "Backend arriba en :$anpael_port contra PRODUCCIÓN (log en $backend_log)"
fi

echo
echo "== 3. Frontend =="
if curl -s -o /dev/null "http://localhost:$frontend_port" 2>/dev/null; then
  echo "Ya hay algo respondiendo en :$frontend_port, no arranco otro."
else
  (
    cd "$repo_dir/frontend"
    nohup npm run dev > "$frontend_log" 2>&1 &
    echo $! > "$frontend_pid_file"
  )
  echo "Esperando a que Vite conteste (hasta 30s)…"
  ok=0
  for _ in $(seq 1 15); do
    if curl -s -o /dev/null "http://localhost:$frontend_port" 2>/dev/null; then ok=1; break; fi
    sleep 2
  done
  if [ "$ok" != 1 ]; then
    echo "El frontend no respondió a tiempo. Mirá $frontend_log"
    exit 1
  fi
  echo "Frontend arriba en :$frontend_port (log en $frontend_log)"
fi

echo
echo "=========================================================="
echo " CONECTADO A PRODUCCIÓN -entorno=\"$entorno_esperado\""
echo "=========================================================="
echo "  Backend:  http://localhost:$anpael_port/api/health"
echo "  Frontend: http://localhost:$frontend_port"
echo
echo "Para bajar todo (backend y frontend, sea local o producción):"
echo "  bash scripts/bajar_local.sh"

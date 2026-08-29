#!/usr/bin/env bash
# =====================================================================
# Levanta el ambiente local completo: Supabase (Docker), backend y
# frontend. Pensado para correr con Git Bash en Windows.
#
# Uso:
#   bash scripts/levantar_local.sh
#
# Supabase local NO lo levanta este script: si no está corriendo, avisa
# cómo levantarlo (`supabase start`, o tu docker-compose si lo armaste a
# mano) y corta. Backend y frontend sí, y si ya estaban arriba no
# arranca una segunda copia.
# =====================================================================
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
estado_dir="$repo_dir/.dev"
mkdir -p "$estado_dir"

backend_log="$estado_dir/backend.log"
frontend_log="$estado_dir/frontend.log"
backend_pid_file="$estado_dir/backend.pid"
frontend_pid_file="$estado_dir/frontend.pid"

anpael_port="${ANPAEL_PORT:-8080}"
frontend_port=5173

responde() {
  curl -s -o /dev/null -w '%{http_code}' "$1" 2>/dev/null | grep -q "${2:-200}"
}

echo "== 1. Supabase local (Docker) =="
if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^supabase_db_'; then
  echo "No encuentro un contenedor supabase_db_* corriendo."
  echo "Levantalo con 'supabase start' (o tu docker-compose, si lo armaste a mano) y volvé a correr este script."
  exit 1
fi
echo "Supabase local: OK"

echo
echo "== 2. Backend =="
if responde "http://localhost:$anpael_port/api/health"; then
  echo "Ya hay un backend respondiendo en :$anpael_port, no arranco otro."
else
  (
    cd "$repo_dir/backend"
    if [ -f .env ]; then
      echo "Usando backend/.env"
      set -a; source .env; set +a
    else
      echo "No hay backend/.env: uso los defaults del Supabase local en Docker."
      export ANPAEL_ENTORNO=local
      export ANPAEL_DB_URL="jdbc:postgresql://127.0.0.1:54322/postgres"
      export ANPAEL_DB_USER=postgres
      export ANPAEL_DB_PASSWORD=postgres
      export ANPAEL_CORS_ORIGENES="http://localhost:5173,http://127.0.0.1:5173"
      export ANPAEL_JWT_SECRETO="clave-de-desarrollo-local-nunca-usar-en-produccion"
    fi
    export ANPAEL_PORT="$anpael_port"
    nohup mvn -q spring-boot:run -Dspring-boot.run.profiles=local > "$backend_log" 2>&1 &
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
  echo "Backend arriba en :$anpael_port (log en $backend_log)"
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
echo "Todo arriba:"
echo "  Backend:  http://localhost:$anpael_port/api/health"
echo "  Frontend: http://localhost:$frontend_port"
echo
echo "Para loguearte necesitás un usuario con contraseña armada -ver"
echo "scripts/usuario_prueba_local.sh- salvo que ya tengas uno."
echo
echo "Para bajar todo: bash scripts/bajar_local.sh"

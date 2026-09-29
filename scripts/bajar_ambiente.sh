#!/usr/bin/env bash
# =====================================================================
# Baja el backend y el frontend levantados por levantar_local.sh.
# Supabase (Docker) NO lo toca -es infraestructura de más largo plazo,
# no algo que se reinicia en cada sesión de trabajo.
#
# Mata por PID guardado y, si no alcanza, por lo que esté escuchando en
# el puerto -en Windows, `npm run dev` deja el proceso real en un
# node.exe que el PID de bash no siempre alcanza a matar.
#
# Uso:
#   bash scripts/bajar_local.sh
# =====================================================================
set -uo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
estado_dir="$repo_dir/.dev"

anpael_port="${ANPAEL_PORT:-8080}"
frontend_port=5173

matar_pid_guardado() {
  local archivo="$1"
  [ -f "$archivo" ] || return 0
  local pid; pid="$(cat "$archivo")"
  if [ -n "$pid" ]; then
    kill "$pid" 2>/dev/null || true
  fi
  rm -f "$archivo"
}

# Mata todo lo que esté escuchando en el puerto dado. Usa taskkill de
# Windows -netstat/kill de bash no ven el PID real de un proceso nativo
# de Windows como node.exe o java.exe.
matar_puerto() {
  local puerto="$1"
  local pids
  pids="$(netstat -ano 2>/dev/null | grep -E "LISTENING" | grep -E ":$puerto[[:space:]]" | awk '{print $NF}' | sort -u)"
  if [ -z "$pids" ]; then
    echo "  nada escuchando en :$puerto"
    return 0
  fi
  local pid
  for pid in $pids; do
    echo "  matando PID $pid (puerto $puerto)"
    taskkill //F //PID "$pid" >/dev/null 2>&1 || true
  done
}

echo "== Backend (:$anpael_port) =="
matar_pid_guardado "$estado_dir/backend.pid"
matar_puerto "$anpael_port"

echo "== Frontend (:$frontend_port) =="
matar_pid_guardado "$estado_dir/frontend.pid"
matar_puerto "$frontend_port"

echo
echo "Listo. Supabase local sigue corriendo -bajalo con 'supabase stop' si también lo querés parar."

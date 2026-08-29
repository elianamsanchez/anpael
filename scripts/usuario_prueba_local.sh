#!/usr/bin/env bash
# =====================================================================
# Pone (o saca) una contraseña de prueba en persona.password_hash, SOLO
# para loguearse a mano en /api/auth/login contra el Supabase LOCAL
# mientras se desarrolla. No toca Supabase Auth (auth.users) ni el
# flujo real de login de la app -es un atajo de desarrollo, nada más.
#
# NUNCA correr esto contra la base de producción.
#
# Uso:
#   bash scripts/usuario_prueba_local.sh eliana test1234   # poner
#   bash scripts/usuario_prueba_local.sh eliana --borrar   # sacar
# =====================================================================
set -euo pipefail

usuario="${1:-}"
clave="${2:-}"

if [ -z "$usuario" ] || [ -z "$clave" ]; then
  echo "Uso: $0 <usuario> <contraseña>"
  echo "     $0 <usuario> --borrar"
  exit 1
fi

contenedor="$(docker ps --format '{{.Names}}' 2>/dev/null | grep '^supabase_db_' | head -1)"
if [ -z "$contenedor" ]; then
  echo "No encuentro un contenedor supabase_db_* corriendo. ¿Está levantado el Supabase local?"
  exit 1
fi

if [ "$clave" = "--borrar" ]; then
  # -c NO interpola variables (:'var' queda literal); por eso el SQL va por
  # stdin, donde psql sí lo procesa.
  echo "update persona set password_hash = null where usuario = :'usuario';" \
    | docker exec -i "$contenedor" psql -U postgres -d postgres -v usuario="$usuario"
  echo "Contraseña de prueba borrada para '$usuario'."
else
  echo "update persona set password_hash = crypt(:'clave', gen_salt('bf')) where usuario = :'usuario';" \
    | docker exec -i "$contenedor" psql -U postgres -d postgres -v usuario="$usuario" -v clave="$clave"
  echo "Contraseña de prueba puesta para '$usuario'."
  echo "No te olvides de borrarla cuando termines: bash scripts/usuario_prueba_local.sh $usuario --borrar"
fi

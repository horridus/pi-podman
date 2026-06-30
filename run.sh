#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

source .env

required_env_vars=(
  MARIADB_DATABASE
  MARIADB_USER
  MARIADB_PASSWORD
  MARIADB_ROOT_PASSWORD
)

for required_env_var in "${required_env_vars[@]}"; do
  if [[ -z "${!required_env_var:-}" ]]; then
    echo "❌ Errore: definisci ${required_env_var} nel file .env prima di avviare il container."
    exit 1
  fi
done

if [[ "$MARIADB_PASSWORD" == "REPLACE_WITH_SECURE_USER_PASSWORD" || "$MARIADB_ROOT_PASSWORD" == "REPLACE_WITH_SECURE_ROOT_PASSWORD" ]]; then
  echo "❌ Errore: sostituisci le password placeholder di MariaDB nel file .env con valori casuali sicuri."
  exit 1
fi

if command -v podman-compose >/dev/null 2>&1; then
  compose() {
    podman-compose --env-file .env -f podman-compose.yml "$@"
  }
elif podman compose version >/dev/null 2>&1; then
  compose() {
    podman compose --env-file .env -f podman-compose.yml "$@"
  }
else
  echo "❌ Errore: installa podman-compose (pip install podman-compose) oppure usa una versione recente di Podman con 'podman compose'."
  exit 1
fi

wait_for_mariadb() {
  local status=""

  if ! podman container exists pi-mariadb 2>/dev/null; then
    echo "❌ Errore: il container MariaDB non è stato creato correttamente."
    return 1
  fi

  for _ in $(seq 1 30); do
    status="$(podman inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}starting{{end}}' pi-mariadb 2>/dev/null || true)"

    if [[ "$status" == "healthy" ]]; then
      return 0
    fi

    sleep 2
  done

  echo "❌ Errore: MariaDB non è diventato healthy in tempo utile."
  podman logs pi-mariadb | tail -n 50 || true
  return 1
}

# Se il primo argomento è una directory, usalo come workspace override
if [[ -n "${1:-}" ]]; then
  PIPODMAN_WORKSPACE_PATH="$(realpath "$1")"
  shift
fi

if [[ -z "${PIPODMAN_WORKSPACE_PATH:-}" ]]; then
  echo "❌ Errore: passa un percorso di workspace come argomento o definisci PIPODMAN_WORKSPACE_PATH nel file .env."
  exit 1
fi

# Verifica che la cartella esista
if [[ ! -d "$PIPODMAN_WORKSPACE_PATH" ]]; then
  echo "❌ Errore: la cartella '$PIPODMAN_WORKSPACE_PATH' non esiste."
  exit 1
fi

export PIPODMAN_WORKSPACE_PATH
echo "📂 Workspace: ${PIPODMAN_WORKSPACE_PATH}"

# Build dell'immagine se non esiste
echo "🔨 Build immagine pi..."
compose build pi

# Avvia/aggiorna MariaDB in background con volume persistente
echo "🗄️ Avvio MariaDB..."
compose up -d mariadb
wait_for_mariadb

# Avvia pi in modo interattivo
echo "🤖 Avvio pi..."
compose run --rm pi "$@"

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

source .env

if command -v podman-compose >/dev/null 2>&1; then
  compose() {
    podman-compose --env-file .env "$@"
  }
elif podman compose version >/dev/null 2>&1; then
  compose() {
    podman compose --env-file .env -f podman-compose.yml "$@"
  }
else
  echo "❌ Errore: installa podman-compose oppure usa una versione di Podman con 'podman compose'."
  exit 1
fi

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

# Avvia pi in modo interattivo
echo "🤖 Avvio pi..."
compose run --rm pi "$@"

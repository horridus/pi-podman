#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

source .env

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
podman-compose --env-file .env build pi

# Avvia pi in modo interattivo
echo "🤖 Avvio pi..."
podman-compose --env-file .env run --rm pi "$@"

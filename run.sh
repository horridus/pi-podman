#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

source .env

# Se il primo argomento è una directory, usalo come workspace override
if [[ -n "${1:-}" && -d "$1" ]]; then
  WORKSPACE_PATH="$(realpath "$1")"
  shift
fi

if [[ -z "${WORKSPACE_PATH:-}" ]]; then
  echo "❌ Errore: WORKSPACE_PATH non impostata in .env."
  exit 1
fi
echo "📂 Workspace: ${WORKSPACE_PATH}"

# Verifica che la cartella esista
if [[ ! -d "$WORKSPACE_PATH" ]]; then
  echo "❌ Errore: la cartella '$WORKSPACE_PATH' non esiste."
  exit 1
fi

# Crea un file .env temporaneo con WORKSPACE_PATH aggiornato, così podman-compose
# usa il valore corretto anche quando viene sovrascritta da riga di comando.
_TMPENV=$(mktemp /tmp/pi-env.XXXXXX)
trap 'rm -f "$_TMPENV"' EXIT
grep -v '^WORKSPACE_PATH=' .env > "$_TMPENV" || true
echo "WORKSPACE_PATH=${WORKSPACE_PATH}" >> "$_TMPENV"

# Build dell'immagine se non esiste
echo "🔨 Build immagine pi..."
podman-compose --env-file "$_TMPENV" build pi

# Avvia pi in modo interattivo
echo "🤖 Avvio pi..."
if [[ "$#" -gt 0 ]]; then
  podman-compose --env-file "$_TMPENV" run --rm pi "$@"
else
  if [[ -n "${OLLAMA_MODEL:-}" ]]; then
    podman-compose --env-file "$_TMPENV" run --rm pi --provider ollama --model "${OLLAMA_MODEL}"
  elif [[ -n "${LLAMACPP_BASE_URL:-}" ]]; then
    podman-compose --env-file "$_TMPENV" run --rm pi --provider llamacpp --model "${LLAMACPP_MODEL:-llamacpp}"
  else
    echo "❌ Errore: nessun provider configurato in .env (imposta OLLAMA_MODEL o LLAMACPP_BASE_URL)."
    exit 1
  fi
fi

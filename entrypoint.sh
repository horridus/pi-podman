#!/usr/bin/env bash
set -euo pipefail

# Configura Ollama come provider personalizzato se OLLAMA_BASE_URL è impostata
if [[ -n "${OLLAMA_BASE_URL:-}" && -n "${OLLAMA_MODEL:-}" ]]; then
  mkdir -p ~/.pi/agent

  cat > ~/.pi/agent/models.json << MODELS_EOF
{
  "providers": {
    "ollama": {
      "baseUrl": "${OLLAMA_BASE_URL}/v1",
      "api": "openai-completions",
      "apiKey": "ollama",
      "compat": {
        "supportsDeveloperRole": false,
        "supportsReasoningEffort": false
      },
      "models": [
        { "id": "${OLLAMA_MODEL}" }
      ]
    }
  }
}
MODELS_EOF
fi

exec pi "$@"

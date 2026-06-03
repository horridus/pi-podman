#!/usr/bin/env bash
set -euo pipefail

# Configura i provider locali personalizzati in models.json
if [[ -n "${OLLAMA_BASE_URL:-}" && -n "${OLLAMA_MODEL:-}" ]] || [[ -n "${LLAMACPP_BASE_URL:-}" ]]; then
  mkdir -p ~/.pi/agent

  PROVIDERS=""

  # Provider Ollama
  if [[ -n "${OLLAMA_BASE_URL:-}" && -n "${OLLAMA_MODEL:-}" ]]; then
    PROVIDERS=$(cat << OLLAMA_EOF
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
OLLAMA_EOF
)
  fi

  # Provider llama.cpp (espone API compatibile OpenAI su /v1)
  if [[ -n "${LLAMACPP_BASE_URL:-}" ]]; then
    LLAMACPP_MODEL_ID="${LLAMACPP_MODEL:-llamacpp}"
    LLAMACPP_ENTRY=$(cat << LLAMACPP_EOF
    "llamacpp": {
      "baseUrl": "${LLAMACPP_BASE_URL}/v1",
      "api": "openai-completions",
      "apiKey": "no-key",
      "compat": {
        "supportsDeveloperRole": false,
        "supportsReasoningEffort": false
      },
      "models": [
        { "id": "${LLAMACPP_MODEL_ID}" }
      ]
    }
LLAMACPP_EOF
)
    if [[ -n "$PROVIDERS" ]]; then
      PROVIDERS="${PROVIDERS},"$'\n'"${LLAMACPP_ENTRY}"
    else
      PROVIDERS="${LLAMACPP_ENTRY}"
    fi
  fi

  cat > ~/.pi/agent/models.json << MODELS_EOF
{
  "providers": {
${PROVIDERS}
  }
}
MODELS_EOF
fi

exec pi "$@"

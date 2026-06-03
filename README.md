# pi in Podman + Ollama / llama.cpp

Esegui [pi](https://pi.dev/) in un container Podman isolato, usando un server **Ollama** o **llama.cpp** locale come backend LLM.

```
┌─────────────────────────────────────────┐
│  Host Linux                             │
│                                         │
│  ┌─────────────┐                        │
│  │     pi      │                        │
│  │  (Podman)   │                        │
│  └──────┬──────┘                        │
│         │                               │
└─────────┼───────────────────────────────┘
          │
          ▼
 192.168.0.188:11434  (Ollama)
 192.168.0.188:8080   (llama.cpp)
```

## Requisiti

- Podman
- podman-compose (`pip install podman-compose`)
- Un server **Ollama** raggiungibile (es. `192.168.0.188:11434`) **oppure** un server **llama.cpp** (`llama-server`) raggiungibile (es. `192.168.0.188:8080`)

## Setup

```bash
# 1. Clona il repository
git clone https://github.com/horridus/pi-podman.git
cd pi-podman

# 2. Crea il file .env con il percorso della tua cartella di lavoro
cp env.example .env
nano .env   # imposta WORKSPACE_PATH, il backend LLM (Ollama o llama.cpp) e, opzionalmente, PI_CONFIG_PATH

# 3. Rendi eseguibile lo script
chmod +x run.sh
```

## Utilizzo

```bash
# Usa il percorso definito in .env
./run.sh

# Oppure passa il percorso direttamente
./run.sh /home/tuoutente/progetti/mio-progetto

# Oppure passa argomenti direttamente a pi (es. provider e modello)
./run.sh --provider ollama --model qwen2.5-coder:32b
```

## Configurazione modelli

### Ollama

```bash
# Seleziona endpoint e modello Ollama
OLLAMA_BASE_URL=http://192.168.0.188:11434
OLLAMA_MODEL=qwen2.5-coder:32b

# Elenca i modelli disponibili sul tuo server Ollama
curl http://192.168.0.188:11434/api/tags
```

Modelli consigliati per il coding:
| Modello | Dimensione | Note |
|---|---|---|
| `qwen2.5-coder:32b` | ~20GB | Migliore qualità |
| `qwen2.5-coder:7b` | ~4GB | Veloce, leggero |
| `deepseek-coder-v2:16b` | ~9GB | Ottimo compromesso |
| `codellama:13b` | ~8GB | Classico |

### llama.cpp

```bash
# Seleziona endpoint llama.cpp (commenta le righe Ollama nel .env)
LLAMACPP_BASE_URL=http://192.168.0.188:8080
LLAMACPP_MODEL=qwen2.5-coder   # nome libero, usato solo internamente da pi
```

llama.cpp (`llama-server`) espone un'API compatibile OpenAI su `/v1`. Carica un solo modello per volta, quindi `LLAMACPP_MODEL` è un nome descrittivo arbitrario.

I due provider sono mutuamente esclusivi in `run.sh`: se entrambi sono impostati, Ollama ha la precedenza.

## Come funziona la configurazione provider

All'avvio del container, lo script `entrypoint.sh` genera automaticamente il file `~/.pi/agent/models.json` a partire dalle variabili definite in `.env`. Questo file configura Ollama e/o llama.cpp come provider personalizzati per pi.

## Persistenza configurazione pi

La configurazione di pi viene montata dall'host nel container su `/root/.pi`, così credenziali, preferenze e cronologia persistono tra una sessione e l'altra.

Per default viene usato `~/.pi` sull'host. Se vuoi usare un percorso diverso, imposta `PI_CONFIG_PATH` nel file `.env`:

```bash
PI_CONFIG_PATH=~/.pi
```

## Sicurezza

- Il container accede **solo** alla cartella specificata in `WORKSPACE_PATH`
- pi si connette direttamente a `OLLAMA_BASE_URL` o `LLAMACPP_BASE_URL`
- Telemetry di pi disabilitata di default all'interno del container
- Flag `no-new-privileges` attivo sul container

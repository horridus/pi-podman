# pi in Podman + Ollama

Esegui [pi](https://pi.dev/) in un container Podman isolato, usando un server **Ollama** locale come backend LLM.

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
 192.168.0.188:11434
 (Ollama su rete locale)
```

## Requisiti

- Podman
- podman-compose (`pip install podman-compose`)
- Un server Ollama raggiungibile su `192.168.0.188:11434`

## Setup

```bash
# 1. Clona il repository
git clone https://github.com/horridus/pi-podman.git
cd pi-podman

# 2. Crea il file .env con il percorso della tua cartella di lavoro
cp env.example .env
nano .env   # imposta WORKSPACE_PATH, OLLAMA_BASE_URL, OLLAMA_MODEL e, opzionalmente, PI_CONFIG_PATH

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

Configura il modello direttamente in `.env`:

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

## Come funziona la configurazione Ollama

All'avvio del container, lo script `entrypoint.sh` genera automaticamente il file `~/.pi/agent/models.json` a partire dalle variabili `OLLAMA_BASE_URL` e `OLLAMA_MODEL` definite in `.env`. Questo file configura Ollama come provider personalizzato per pi.

## Persistenza configurazione pi

La configurazione di pi viene montata dall'host nel container su `/root/.pi`, così credenziali, preferenze e cronologia persistono tra una sessione e l'altra.

Per default viene usato `~/.pi` sull'host. Se vuoi usare un percorso diverso, imposta `PI_CONFIG_PATH` nel file `.env`:

```bash
PI_CONFIG_PATH=~/.pi
```

## Sicurezza

- Il container accede **solo** alla cartella specificata in `WORKSPACE_PATH`
- pi si connette direttamente a `OLLAMA_BASE_URL`
- Telemetry di pi disabilitata di default all'interno del container
- Flag `no-new-privileges` attivo sul container

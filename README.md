# pi in Podman con Ollama / llama.cpp

Esegui **[pi](https://pi.dev/)**, l'agente di coding AI di GitHub, in un container **Podman** isolato, utilizzando un server **Ollama** o **llama.cpp** locale come backend per i modelli linguistici.

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

---

## 🚀 Requisiti

- **Podman** ([download](https://podman.io/docs/installation))
- **podman-compose** (`pip install podman-compose`) **oppure** `podman compose` (già incluso nelle versioni recenti di Podman)
- Un server **Ollama** raggiungibile (es. `192.168.0.188:11434`) **oppure** un server **llama.cpp** (`llama-server`) raggiungibile (es. `192.168.0.188:8080)`

---

## 📦 Setup Iniziale

```bash
# 1. Clona il repository
git clone https://github.com/horridus/pi-podman.git
cd pi-podman

# 2. Crea il file .env con il percorso della tua cartella di lavoro
cp env.example .env
nano .env   # imposta PIPODMAN_WORKSPACE_PATH e il backend LLM (Ollama o llama.cpp)

# 3. Rendi eseguibile lo script
chmod +x run.sh
```

---

## ▶️ Avvio

### Metodo 1: Usa il percorso definito in `.env`
```bash
./run.sh
```

### Metodo 2: Passa il percorso direttamente
```bash
./run.sh /home/tuoutente/progetti/mio-progetto
```

### Metodo 3: Passa argomenti direttamente a pi
```bash
./run.sh --provider ollama --model qwen3.5
```

---

## ⚙️ Configurazione

### 📄 File `.env`

```bash
# 📁 Percorso assoluto della cartella workspace
PIPODMAN_WORKSPACE_PATH=/home/tuoutente/workspace

# 🛠️ Percorso di configurazione di pi (opzionale, default: ~/.pi)
# PI_CONFIG_PATH=/home/tuoutente/.pi

# 🗄️ Configurazione MariaDB
MARIADB_DATABASE=pi
MARIADB_USER=pi
MARIADB_PASSWORD=CHANGE_ME_STRONG_USER_PASSWORD
MARIADB_ROOT_PASSWORD=CHANGE_ME_STRONG_ROOT_PASSWORD
```

> ⚠️ Aggiorna sempre le password di esempio nel file `.env` prima di avviare MariaDB.

---

### 🔌 Configurazione Modelli Ollama

```bash
# Elenca i modelli disponibili sul tuo server Ollama
curl http://192.168.0.188:11434/api/tags
```

**Modelli consigliati per il coding**:

| Modello | Dimensione | Note |
|---|---|---|
| `qwen3.5` | ~4-20GB* | Migliore qualità, 128K context |
| `qwen2.5-coder:32b` | ~20GB | Alternativa, ottima qualità |
| `qwen2.5-coder:7b` | ~4GB | Veloce, leggero |
| `deepseek-coder-v2:16b` | ~9GB | Ottimo compromesso |
| `codellama:13b` | ~8GB | Classico |

> *La dimensione dipende dalla quantizzazione (q4, q5, q8)

---


## 📂 Struttura models.json

```json
{
  "providers": {
    "llamacpp": {
      "baseUrl": "http://192.168.0.188:8080/v1",
      "api": "openai-completions",
      "apiKey": "no-key",
      "compat": {
        "supportsDeveloperRole": false,
        "supportsReasoningEffort": false
      },
      "models": [
        {
          "id": "qwen35-9b-flash-q4km",
          "input": ["text", "image"],
          "contextWindow": 128000,
          "reasoning": true
        }
      ]
    },
    "ollama": {
      "baseUrl": "http://192.168.0.188:11434/v1",
      "api": "openai-completions",
      "apiKey": "no-key",
      "compat": {
        "supportsDeveloperRole": false,
        "supportsReasoningEffort": false
      },
      "models": [
        {
          "id": "qwen3.5",
          "input": ["text", "image"],
          "contextWindow": 128000,
          "reasoning": true
        }
      ]
    }
  }
}
```

---

## 💾 Persistenza

La configurazione di **pi** viene montata dall'host nel container su `/root/.pi`, così credenziali, preferenze e cronologia persistono tra una sessione e l'altra.
MariaDB usa inoltre un volume nominato dedicato montato su `/var/lib/mysql`, quindi i dati del database restano disponibili anche dopo `build`, `up --force-recreate` o ricreazione del container.

### MariaDB inclusa nel setup

- `./run.sh` avvia automaticamente il servizio `mariadb` in background prima di eseguire `pi`
- Dal container `pi` il database è raggiungibile all'host `mariadb` sulla porta `3306`
- Il client `mariadb` è installato nel container `pi`, quindi puoi verificare la connessione direttamente da lì

Esempio di connessione dal container `pi`:

```bash
mariadb -h mariadb -u "$MARIADB_USER" -p"$MARIADB_PASSWORD" "$MARIADB_DATABASE"
```

### Cambiare percorso di configurazione

Per default viene usato `~/.pi` sull'host. Se vuoi usare un percorso diverso:

```bash
PI_CONFIG_PATH=/home/tuoutente/.pi
```

---

## 🔒 Sicurezza

- ✅ Il container accede **solo** alla cartella specificata in `PIPODMAN_WORKSPACE_PATH`
- ✅ **pi** si connette direttamente a `OLLAMA_BASE_URL` o `LLAMACPP_BASE_URL`
- ✅ Telemetry di **pi** disabilitata di default all'interno del container
- ✅ Flag `no-new-privileges` attivo sul container
- ✅ Accesso a internet abilitato tramite rete bridge (condivisione DNS dell'host)

---

## 📝 Variabili di Ambiente

| Variabile | Descrizione | Default | Necessaria |
|-----------|-------------|---------|----------|
| `PIPODMAN_WORKSPACE_PATH` | Percorso assoluto della cartella workspace | N/A | **Sì** |
| `PI_CONFIG_PATH` | Percorso configurazione pi | `~/.pi` | No |
| `MARIADB_DATABASE` | Database creato automaticamente al primo avvio | `pi` | No |
| `MARIADB_USER` | Utente applicativo MariaDB | `pi` | No |
| `MARIADB_PASSWORD` | Password utente applicativo MariaDB | `CHANGE_ME_STRONG_USER_PASSWORD` | No |
| `MARIADB_ROOT_PASSWORD` | Password utente `root` MariaDB | `CHANGE_ME_STRONG_ROOT_PASSWORD` | No |

---

## 🛠️ Comandi Utili

### Verifica che i servizi LLM siano attivi

**Ollama**:
```bash
curl http://192.168.0.188:11434/api/tags
curl http://192.168.0.188:11434/api/generate -d '{"model": "qwen3.5", "prompt": "hello"}'
```

**llama.cpp**:
```bash
curl http://192.168.0.188:8080/v1/models
curl http://192.168.0.188:8080/v1/chat/completions -H "Content-Type: application/json" -d '{
  "model": "qwen35-9b-flash-q4km",
  "messages": [{"role": "user", "content": "hello"}]
}'
```

### Gestione container

```bash
# Elenco container
podman ps

# Ferma il container
terminal -x pi

# Rimuovi container (non distrugge i dati)
podman stop pi && podman rm pi

# Rebuild immagine
podman-compose --env-file .env build pi

# Ferma anche MariaDB senza cancellare il volume dati
podman-compose --env-file .env stop mariadb

# Elenca il volume persistente di MariaDB
podman volume ls | grep mariadb-data
```

---

## 🐛 Troubleshooting

**"Errore: la cartella 'X' non esiste"**
- Verifica che `PIPODMAN_WORKSPACE_PATH` punti a un percorso assoluto esistente

**"Connection refused" su Ollama**
- Controlla che il servizio Ollama sia attivo: `curl http://192.168.0.188:11434`
- Verifica che la porta 11434 non sia bloccata dal firewall

**"Connection refused" su llama.cpp**
- Assicurati che `llama-server` sia in esecuzione
- Controlla che la porta 8080 sia accessibile

**I modelli non appaiono in models.json**
- Esegui `podman-compose --env-file .env build pi` per forzare la rigenerazione

**Devo ricreare MariaDB ma tenere i dati**
- Usa `podman-compose --env-file .env up -d --force-recreate mariadb`: il volume su `/var/lib/mysql` verrà riutilizzato

---

## 📄 Licenza

Questo progetto è open source. Consulta il repository per i dettagli della licenza.

---

**Sviluppato con ❤️ per la community AI e Open Source**

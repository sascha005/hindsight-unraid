# Hindsight Unraid

Ein Docker-Container und Unraid Community Application Template für **Hindsight local-embedded memory server**.

## Was ist das?

Hindsight ist ein Long-Term Memory System für Hermes Agent mit Knowledge Graph, Entity Resolution und Semantic Search. Dieses Image läuft als eigenständiger Hindsight-Daemon und verbindet sich mit deinem bestehenden Ollama-Server. Alle Daten bleiben lokal.

## Was du brauchst

- **Ollama** läuft bereits (lokal oder im Netzwerk) — GPU wird dort genutzt
- **PostgreSQL** (optional, Hindsight nutzt embedded SQLite) — falls du Postgres haben willst, anpassen im nächsten Schritt
- **Unraid Server** mit Docker aktiviert

## Repository-Struktur

| Datei | Zweck |
|-------|-------|
| `Dockerfile` | Container-Image mit hindsight-client + hindsight-embed |
| `entrypoint.sh` | Startet Hindsight-Daemon + Web-UI |
| `templates/Hindsight-Memory.xml` | Unraid CA Template (einmalig bei Community Apps eintragen) |
| `.github/workflows/docker-image.yml` | Auto-Build & Push zu GHCR bei Push auf main |

## Schnellstart

### 1. Image bilden

```bash
docker build -t hindsight-unraid .
```

Oder einfach warten: Bei Push in `main` baut GitHub Actions automatisch nach `ghcr.io/sascha005/hindsight-unraid:latest`.

### 2. Unraid Template eintragen

In Unraid: **Apps** → **Install** → **Add custom template URL**:
```
https://raw.githubusercontent.com/sascha005/hindsight-unraid/main/templates/Hindsight-Memory.xml
```

### 3. Konfigurieren

| Parameter | Standard | Beschreibung |
|-----------|----------|--------------|
| `OLLAMA_BASE_URL` | `http://192.168.179.171:11434` | Dein Ollama Server |
| `HINDSIGHT_LLM_MODEL` | `gemma3` | Ollama-Modellname |
| `HINDSIGHT_BANK_ID` | `hermes` | Memory-Bank (pro Agent separierbar) |
| `HINDSIGHT_RECALL_BUDGET` | `mid` | Recall-Gründlichkeit: `low` / `mid` / `high` |

### 4. Hermes Agent anbinden

In der Hermes Config:
```yaml
memory:
  provider: hindsight
```

In `~/.hermes/hindsight/config.json`:
```json
{
  "mode": "local_external",
  "api_url": "http://hindsight-memory:8888",
  "llm_provider": "ollama",
  "llm_base_url": "http://192.168.179.171:11434",
  "llm_model": "gemma3",
  "bank_id_template": "hermes-{profile}"
}
```

### 5. Isolation: Lokal vs Cloud Agent

Um den Cloud-Agenten vom lokalen Wissen auszuschließen:
- **Lokaler Agent**: Bank `hermes-local`, Zugriff auf alle internen Dienste freigegeben
- **Cloud-Agent**: Bank `hermes-cloud`, Docker-Netzwerk hat keinen Zugriff auf `hermes-local`-Bank oder lokale Hindsight-Instanz

## Ports

| Port | Beschreibung |
|------|-------------|
| `8888/tcp` | Hindsight API (REST) |
| `18888/tcp`| Hindsight Web UI |

## Datenspeicherung

| Path | Inhalt |
|------|--------|
| `/mnt/user/appdata/hindsight-memory/data` | Persistent: Hindsight Profile, Logs, SQLite |

## Lizenz

MIT — wie das Original Hindsight-Projekt.

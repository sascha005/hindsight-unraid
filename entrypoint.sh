#!/usr/bin/env bash
set -uo pipefail

# ── Config from ENV ───────────────────────────────────────────────
: "${HINDSIGHT_PORT:=8888}"
: "${HINDSIGHT_LLM_PROVIDER:=ollama}"
: "${HINDSIGHT_LLM_MODEL:=gemma3}"
: "${HINDSIGHT_LLM_BASE_URL:=}"
: "${HINDSIGHT_LLM_API_KEY:=}"
: "${HINDSIGHT_BANK_ID:=hermes}"
: "${HINDSIGHT_BANK_MISSION:=}"
: "${HINDSIGHT_BANK_RETAIN_MISSION:=}"
: "${HINDSIGHT_RECALL_BUDGET:=mid}"
: "${HINDSIGHT_AUTO_RECALL:=true}"
: "${HINDSIGHT_AUTO_RETAIN:=true}"
: "${HINDSIGHT_MEMORY_MODE:=hybrid}"

# ── Ensure data dirs ─────────────────────────────────────────────
mkdir -p "${HOME}/.hindsight/profiles"
echo "[entrypoint] Hindsight data dir: ${HOME}/.hindsight"

# Fix permissions: hindsight uid may differ between image and host
echo "[entrypoint] Fixing permissions on data directory ..."
chown -R hindsight:hindsight "${HOME}/.hindsight" 2>/dev/null || true
# Also ensure the user exists if the container was rebuilt
id hindsight 2>/dev/null || useradd -m -d "${HOME}" hindsight 2>/dev/null || true

# ── Create hindsight profile ─────────────────────────────────────
echo "[entrypoint] Creating profile '${HINDSIGHT_BANK_ID}' ..."
# Don't die on failure here — profile may already exist
hindsight-embed profile create "${HINDSIGHT_BANK_ID}" --port "${HINDSIGHT_PORT}" \
  --env "LLM_PROVIDER=${HINDSIGHT_LLM_PROVIDER}" \
  --env "LLM_MODEL=${HINDSIGHT_LLM_MODEL}" \
  ${HINDSIGHT_LLM_BASE_URL:+  --env "LLM_BASE_URL=${HINDSIGHT_LLM_BASE_URL}"} \
  --merge || true

# ── Start daemon (foreground so errors are visible) ────────────────
echo "[entrypoint] Starting daemon ..."
hindsight-embed -p "${HINDSIGHT_BANK_ID}" daemon start 2>&1

# ── Wait for daemon ─────────────────────────────────────────────
DAEMON_OK=false
for i in $(seq 1 30); do
  if hindsight-embed -p "${HINDSIGHT_BANK_ID}" daemon status 2>/dev/null | grep -q "running"; then
    echo "[entrypoint] Daemon is running."
    DAEMON_OK=true
    break
  fi
  echo "[entrypoint] Waiting for daemon... ($i/30)"
  sleep 1
done

if [ "$DAEMON_OK" != "true" ]; then
  echo "[entrypoint] ERROR: Daemon did not start. Aborting container."
  exit 1
fi

# ── Start UI ──────────────────────────────────────────────────────
echo "[entrypoint] Starting web UI ..."
hindsight-embed -p "${HINDSIGHT_BANK_ID}" ui start 2>&1 || true

# ── Keep container alive ────────────────────────────────────────
echo "[entrypoint] Container ready. Holding process ..."
exec tail -f /dev/null

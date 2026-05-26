#!/usr/bin/env bash
set -euo pipefail

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

# ── Create hindsight profile ─────────────────────────────────────
CMD=(hindsight-embed profile create "${HINDSIGHT_BANK_ID}" --port "${HINDSIGHT_PORT}")
[ -n "${HINDSIGHT_LLM_BASE_URL:-}" ] && CMD+=(--env "LLM_BASE_URL=${HINDSIGHT_LLM_BASE_URL}")
[ -n "${HINDSIGHT_LLM_API_KEY:-}" ] && CMD+=(--env "LLM_API_KEY=${HINDSIGHT_LLM_API_KEY}")
# standard provider/model are handled by hindsight defaults, but let's be explicit
CMD+=(--env "LLM_PROVIDER=${HINDSIGHT_LLM_PROVIDER}")
CMD+=(--env "LLM_MODEL=${HINDSIGHT_LLM_MODEL}")
CMD+=(--merge)

"${CMD[@]}"

# ── Start daemon ──────────────────────────────────────────────────
echo "Starting Hindsight daemon for profile '${HINDSIGHT_BANK_ID}' on port ${HINDSIGHT_PORT} ..."
echo "  LLM Provider: ${HINDSIGHT_LLM_PROVIDER}"
echo "  LLM Model: ${HINDSIGHT_LLM_MODEL}"
if [ -n "${HINDSIGHT_LLM_BASE_URL:-}" ]; then
  echo "  LLM Base URL: ${HINDSIGHT_LLM_BASE_URL}"
fi

hindsight-embed -p "${HINDSIGHT_BANK_ID}" daemon start

# ── Wait for daemon ready ─────────────────────────────────────────
for i in {1..30}; do
  if hindsight-embed -p "${HINDSIGHT_BANK_ID}" daemon status 2>/dev/null | grep -q "running"; then
    echo "Hindsight daemon is ready on port ${HINDSIGHT_PORT}."
    break
  fi
  sleep 1
done

# ── Start UI ──────────────────────────────────────────────────────
echo "Starting Hindsight web UI ..."
hindsight-embed -p "${HINDSIGHT_BANK_ID}" ui start --port "$((HINDSIGHT_PORT + 10000))"

# ── Keep container alive ────────────────────────────────────────
LOG_FILE="${HOME}/.hindsight/profiles/${HINDSIGHT_BANK_ID}.log"
if [ -f "$LOG_FILE" ]; then
  echo "Tailing logs from ${LOG_FILE} ..."
  tail -F "$LOG_FILE"
else
  # Fallback: just sleep-loop and poll status every 30s
  while true; do
    if ! hindsight-embed -p "${HINDSIGHT_BANK_ID}" daemon status 2>/dev/null | grep -q "running"; then
      echo "Hindsight daemon exited unexpectedly."
      exit 1
    fi
    sleep 30
  done
fi

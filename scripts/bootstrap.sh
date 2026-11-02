#!/bin/sh
# Entrypoint wrapper for the render-tools image.
#
# Runs as root (PID-1 child of tini). On every boot it:
#   1. Ensures /opt/data exists and is owned by hermes:hermes.
#   2. Tries to restore Hermes data from GitHub if local data is missing.
#   3. Seeds a custom SOUL.md with preferred identity if missing.
#   4. Runs the config patcher.
#   5. Starts a background backup loop.
#   6. Exec's the upstream entrypoint chain.

set -eu

DATA_DIR="${HERMES_HOME:-/opt/data}"
PATCHER="/opt/render-tools/patch-config.py"
RESTORE_SCRIPT="/opt/render-tools/restore-from-github.sh"
SEED_SOUL="/opt/render-tools/seed-soul.sh"
BACKUP_LOOP="/opt/render-tools/start-backup-loop.sh"

# Make sure the data dir exists and the hermes user can write to it
mkdir -p "${DATA_DIR}"
if ! chown -R hermes:hermes "${DATA_DIR}" 2>/dev/null; then
  echo "[render-tools] warning: could not chown ${DATA_DIR}; continuing" >&2
fi

# Restore from GitHub if data is missing (critical for free plan)
if [ -x "${RESTORE_SCRIPT}" ]; then
  echo "[render-tools] Checking if restore from GitHub is needed..."
  gosu hermes "${RESTORE_SCRIPT}" || echo "[render-tools] restore script finished with warnings"
fi

# Seed custom identity (Messenger of the Digital (eras')) if SOUL.md does not exist
if [ -x "${SEED_SOUL}" ]; then
  "${SEED_SOUL}" || true
fi

# Patch config.yaml
if [ -x "${PATCHER}" ]; then
  if ! gosu hermes "${PATCHER}" "${DATA_DIR}/config.yaml"; then
    echo "[render-tools] warning: config patch failed; continuing with unmodified config" >&2
  fi
else
  echo "[render-tools] warning: ${PATCHER} not found or not executable; skipping" >&2
fi

# Start background backup loop (every 12 min while awake)
if [ -x "${BACKUP_LOOP}" ] && [ -n "${GITHUB_BACKUP_TOKEN:-}" ]; then
  echo "[render-tools] Starting background backup loop..."
  gosu hermes "${BACKUP_LOOP}" &
fi

# Hand off to the upstream entrypoint
exec /opt/hermes/docker/entrypoint.sh "$@"

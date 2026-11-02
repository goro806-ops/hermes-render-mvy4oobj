#!/bin/sh
# Background loop that backs up Hermes data every 12 minutes while the service is alive
set -eu

BACKUP_SCRIPT="/opt/render-tools/backup-to-github.sh"

if [ ! -x "$BACKUP_SCRIPT" ]; then
  echo "[backup-loop] Backup script not found"
  exit 0
fi

echo "[backup-loop] Starting background backup loop (every 12 minutes)"

while true; do
  sleep 720   # 12 minutes
  "$BACKUP_SCRIPT" || true
done

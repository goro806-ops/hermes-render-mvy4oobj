#!/bin/sh
# Restore Hermes data from GitHub backup if local data is missing/empty
set -eu

DATA_DIR="${HERMES_HOME:-/opt/data}"
REPO="goro806-ops/hermes-render-mvy4oobj"
BRANCH="main"
TARGET_PATH="hermes-data-backup"

if [ -z "${GITHUB_BACKUP_TOKEN:-}" ]; then
  echo "[restore] GITHUB_BACKUP_TOKEN not set - skipping restore"
  exit 0
fi

# Check if we already have meaningful data
if [ -f "$DATA_DIR/state.db" ] || [ -d "$DATA_DIR/skills" ] && [ "$(ls -A $DATA_DIR/skills 2>/dev/null)" ]; then
  echo "[restore] Local data already present - skipping restore"
  exit 0
fi

echo "[restore] Local data missing or empty. Trying to restore from GitHub..."

cd /tmp
rm -rf repo-clone 2>/dev/null || true
git clone --depth 1 --branch "$BRANCH" "https://x-access-token:${GITHUB_BACKUP_TOKEN}@github.com/${REPO}.git" repo-clone

if [ -d "repo-clone/$TARGET_PATH" ]; then
  echo "[restore] Restoring files..."
  mkdir -p "$DATA_DIR"
  cp -a "repo-clone/$TARGET_PATH"/* "$DATA_DIR/" 2>/dev/null || true
  chown -R hermes:hermes "$DATA_DIR" 2>/dev/null || true
  echo "[restore] Restore completed"
else
  echo "[restore] No backup found in repository yet"
fi

rm -rf /tmp/repo-clone

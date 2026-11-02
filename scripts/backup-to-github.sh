#!/bin/sh
# Backup important Hermes data to GitHub so self-improvement survives free plan sleeps
set -eu

DATA_DIR="${HERMES_HOME:-/opt/data}"
BACKUP_DIR="/tmp/hermes-backup-$$"
REPO="goro806-ops/hermes-render-mvy4oobj"
BRANCH="main"
TARGET_PATH="hermes-data-backup"

# Need the token
if [ -z "${GITHUB_BACKUP_TOKEN:-}" ]; then
  echo "[backup] GITHUB_BACKUP_TOKEN not set - skipping backup"
  exit 0
fi

echo "[backup] Starting backup of Hermes data..."

mkdir -p "$BACKUP_DIR"

# Copy the important parts (skip large logs and caches)
cp -a "$DATA_DIR/skills" "$BACKUP_DIR/" 2>/dev/null || true
cp -a "$DATA_DIR/memories" "$BACKUP_DIR/" 2>/dev/null || true
cp -a "$DATA_DIR/state.db" "$BACKUP_DIR/" 2>/dev/null || true
cp -a "$DATA_DIR/SOUL.md" "$BACKUP_DIR/" 2>/dev/null || true
cp -a "$DATA_DIR/config.yaml" "$BACKUP_DIR/" 2>/dev/null || true
# Optional: keep a small recent log
cp -a "$DATA_DIR/logs" "$BACKUP_DIR/" 2>/dev/null || true

# Create a simple timestamp
echo "Backup created at $(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$BACKUP_DIR/BACKUP_INFO.txt"

# Use git to push (simple approach using GitHub API would be more complex)
cd /tmp
rm -rf repo-clone 2>/dev/null || true
git clone --depth 1 --branch "$BRANCH" "https://x-access-token:${GITHUB_BACKUP_TOKEN}@github.com/${REPO}.git" repo-clone
cd repo-clone

rm -rf "$TARGET_PATH"
mkdir -p "$TARGET_PATH"
cp -a "$BACKUP_DIR"/* "$TARGET_PATH/"

git config user.email "hermes-backup@local"
git config user.name "Hermes Backup"
git add "$TARGET_PATH"
git commit -m "Auto backup of Hermes self-improvement data $(date -u +%Y-%m-%d_%H-%M)" || echo "[backup] Nothing new to commit"
git push origin "$BRANCH" || echo "[backup] Push failed"

echo "[backup] Backup finished"
rm -rf /tmp/repo-clone "$BACKUP_DIR"

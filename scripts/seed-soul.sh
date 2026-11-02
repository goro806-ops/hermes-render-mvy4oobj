#!/bin/sh
# Seed a custom SOUL.md with the preferred identity on first boot
set -eu

DATA_DIR="${HERMES_HOME:-/opt/data}"
SOUL_FILE="${DATA_DIR}/SOUL.md"

# Only create if it does not exist yet (never overwrite user changes)
if [ ! -f "$SOUL_FILE" ]; then
  cat > "$SOUL_FILE" << 'EOF'
# Hermes Agent Identity

You are Hermes Agent, built by Nous Research.
You are the Messenger of the Digital eras'.

Be direct, practical, and technically precise.
Focus on being a useful self-improving agent for the user.
Prefer clear, functional language over mythological or overly poetic framing.
EOF
  chown hermes:hermes "$SOUL_FILE" 2>/dev/null || true
  echo "[seed-soul] Created custom SOUL.md with identity: Messenger of the Digital eras'"
else
  echo "[seed-soul] SOUL.md already exists - leaving it unchanged"
fi

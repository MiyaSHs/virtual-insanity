#!/usr/bin/env bash
set -euo pipefail
source "$GM_ROOT_DIR/lib/common.sh"

run() {
  log "User/session defaults…"

  # Create group for session switching requests (non-root)
  if ! getent group gmswitch >/dev/null 2>&1; then
    groupadd gmswitch || true
  fi
  usermod -aG gmswitch "${GM_USER}" || true

  # Make sure NetworkManager can be controlled by the user (plugdev)
  usermod -aG plugdev "${GM_USER}" || true

  log "User/session done."
}

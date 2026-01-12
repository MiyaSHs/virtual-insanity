#!/usr/bin/env bash
set -euo pipefail
source "$GM_ROOT_DIR/lib/common.sh"

run() {
  log "Applying ROG Ally handheld module…"

  # seatd helps gamescope on handhelds
  systemctl enable seatd || true

  # Install Handheld Daemon (HHD) local install (updates independently)
  # https://github.com/hhd-dev/hhd
  log "Installing hhd (local install)…"
  su - "${GM_USER}" -c "curl -fsSL https://github.com/hhd-dev/hhd/raw/master/install.sh | bash" || true

  # Enable user instance service (best-effort; unit name per upstream script)
  systemctl enable "hhd_local@${GM_USER}" 2>/dev/null || true
  systemctl enable "hhd@${GM_USER}" 2>/dev/null || true

  # Handheld UX defaults
  # Prefer performance profile
  systemctl enable power-profiles-daemon || true

  log "ROG Ally module done."
}

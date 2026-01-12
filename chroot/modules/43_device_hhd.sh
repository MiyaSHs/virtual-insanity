#!/usr/bin/env bash
set -euo pipefail
source "$GM_ROOT_DIR/lib/common.sh"

run() {
  log "Applying HHD handheld module…"

  # Ensure seatd is present (helps gamescope + input on many handhelds)
  emerge --quiet-build=y sys-apps/seatd 2>/dev/null || true
  systemctl enable seatd 2>/dev/null || true

  # Install Handheld Daemon (HHD) - best-effort upstream installer.
  # If you later add a Gentoo ebuild/overlay, replace this with emerge.
  if command -v curl >/dev/null 2>&1; then
    log "Installing HHD (upstream installer)…"
    # Run as root to install system-wide
    curl -fsSL https://github.com/hhd-dev/hhd/raw/master/install.sh | bash || true
  else
    warn "curl missing; cannot install HHD automatically."
  fi

  # Enable services if present (names may vary by installer)
  systemctl enable --now hhd 2>/dev/null || true
  systemctl enable --now "hhd@${GM_USER}" 2>/dev/null || true
  systemctl enable --now "hhd_local@${GM_USER}" 2>/dev/null || true

  # Handheld defaults
  systemctl enable power-profiles-daemon 2>/dev/null || true

  log "HHD module done."
}

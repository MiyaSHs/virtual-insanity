#!/usr/bin/env bash
set -euo pipefail
source "$GM_ROOT_DIR/lib/common.sh"

run() {
  if [[ "${GM_FLATPAK:-no}" != "yes" ]]; then
    log "Flatpak disabled; skipping."
    return 0
  fi

  log "Enabling Flatpak + Flathub…"
  emerge --quiet-build=y sys-apps/flatpak || true

  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

  if [[ "${GM_FLATPAK_STORE:-none}" == "bazaar" ]]; then
    # Bazaar app id on Flathub: io.github.kolunmi.Bazaar
    flatpak install -y --system flathub io.github.kolunmi.Bazaar || true
  fi

  # Discover is handled by Plasma package set (kde-apps/discover)
  log "Flatpak done."
}

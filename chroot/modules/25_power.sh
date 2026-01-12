#!/usr/bin/env bash
set -euo pipefail
source "$GM_ROOT_DIR/lib/common.sh"

run() {
  log "Power policy: ${GM_POWER_POLICY:-desktop_none}"

  case "${GM_POWER_POLICY:-desktop_none}" in
    handheld_ppd)
      emerge --quiet-build=y sys-power/power-profiles-daemon || true
      systemctl enable power-profiles-daemon || true
      systemctl disable --now tlp 2>/dev/null || true
      systemctl mask tlp 2>/dev/null || true
      ;;
    laptop_tlp)
      emerge --quiet-build=y sys-power/tlp || true
      systemctl enable tlp || true
      # Avoid conflicts: do not run power-profiles-daemon with TLP.
      systemctl disable --now power-profiles-daemon 2>/dev/null || true
      systemctl mask power-profiles-daemon 2>/dev/null || true
      ;;
    desktop_none|*)
      systemctl disable --now power-profiles-daemon 2>/dev/null || true
      systemctl mask power-profiles-daemon 2>/dev/null || true
      systemctl disable --now tlp 2>/dev/null || true
      systemctl mask tlp 2>/dev/null || true
      ;;
  esac

  log "Power policy applied."
}

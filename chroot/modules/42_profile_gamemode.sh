#!/usr/bin/env bash
set -euo pipefail

run() {
  # Plasma + Steam stack
  source "${ROOT_DIR}/chroot/modules/41_profile_plasma.sh"
  run

  emerge --quiet-build     games-util/steam-launcher     gui-wm/gamescope     games-util/gamemode

  gm_ok "Gamemode profile installed (Steam+Gamescope+Gamemode)."
}

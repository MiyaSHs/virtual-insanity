#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="/root/golden-master"
GM_CONF="/root/gm-install.conf"

source "${ROOT_DIR}/lib/common.sh"
source "${ROOT_DIR}/lib/ui.sh"
source "${ROOT_DIR}/lib/hw.sh"
export GM_CONF

gm_banner "Golden Master Gentoo Installer (chroot phase)"

run_mod() {
  local f="$1"
  [[ -f "$f" ]] || gm_die "Missing chroot module: $f"
  gm_banner "Chroot module: $(basename "$f")"
  # shellcheck source=/dev/null
  source "$f"
  run
}

run_mod "${ROOT_DIR}/chroot/modules/00_base.sh"
run_mod "${ROOT_DIR}/chroot/modules/10_portage.sh"
run_mod "${ROOT_DIR}/chroot/modules/20_kernel_boot.sh"
run_mod "${ROOT_DIR}/chroot/modules/30_users.sh"

PROFILE="$(gm_read_conf PROFILE)"
case "$PROFILE" in
  tty*)      run_mod "${ROOT_DIR}/chroot/modules/40_profile_tty.sh" ;;
  plasma*)   run_mod "${ROOT_DIR}/chroot/modules/41_profile_plasma.sh" ;;
  gamemode*) run_mod "${ROOT_DIR}/chroot/modules/42_profile_gamemode.sh" ;;
  *) gm_die "Unknown PROFILE: $PROFILE" ;;
esac

DEVICE="$(gm_read_conf DEVICE)"
if [[ "$DEVICE" == rog-ally* ]]; then
  run_mod "${ROOT_DIR}/chroot/modules/43_device_rog_ally.sh"
fi

if [[ "$(gm_read_conf FLATPAK)" == "yes" ]]; then
  run_mod "${ROOT_DIR}/chroot/modules/50_flatpak.sh"
fi

run_mod "${ROOT_DIR}/chroot/modules/60_perf_fdo_propeller.sh"
run_mod "${ROOT_DIR}/chroot/modules/90_finalize.sh"

gm_ok "Chroot install completed."

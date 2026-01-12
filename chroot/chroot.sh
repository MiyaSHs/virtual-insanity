#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="/root/golden-master"
STATE_FILE="${ROOT_DIR}/gm.conf"
export GM_ROOT_DIR="$ROOT_DIR"
export GM_STATE_FILE="$STATE_FILE"

# shellcheck source=lib/common.sh
source "$ROOT_DIR/lib/common.sh"

[[ -f "$STATE_FILE" ]] || die "Missing $STATE_FILE"
# shellcheck disable=SC1090
source "$STATE_FILE"

run_module() {
  local mod="$1"
  # shellcheck disable=SC1090
  source "$ROOT_DIR/$mod"
  run
}

log "Golden Master chroot phase starting…"

run_module "chroot/modules/00_base.sh"
run_module "chroot/modules/10_portage.sh"
run_module "chroot/modules/20_kernel_boot.sh"
run_module "chroot/modules/30_users.sh"

case "${GM_PROFILE}" in
  tty)     run_module "chroot/modules/40_profile_tty.sh" ;;
  plasma)  run_module "chroot/modules/41_profile_plasma.sh" ;;
  gamemode)run_module "chroot/modules/42_profile_gamemode.sh" ;;
  *) die "Unknown profile: $GM_PROFILE" ;;
esac

if [[ "${GM_DEVICE:-generic}" == "hhd" ]]; then
  run_module "chroot/modules/43_device_hhd.sh"
fi

run_module "chroot/modules/50_flatpak.sh"
run_module "chroot/modules/60_perf_fdo_propeller.sh"
run_module "chroot/modules/90_finalize.sh"

log "Chroot phase complete."

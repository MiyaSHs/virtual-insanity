#!/usr/bin/env bash
set -euo pipefail

run() {
  gm_need_root

  command -v curl >/dev/null 2>&1 || gm_die "curl is required."
  command -v lsblk >/dev/null 2>&1 || gm_die "lsblk is required."
  command -v parted >/dev/null 2>&1 || gm_die "parted is required."
  command -v mkfs.vfat >/dev/null 2>&1 || gm_die "mkfs.vfat is required."

  if ! gm_has_internet; then
    gm_die "No internet. Connect first. (Installer is online-only.)"
  fi

  [[ -d /sys/firmware/efi ]] || gm_die "UEFI mode required (boot USB in UEFI)."

  gm_ok "Prereqs OK."
}

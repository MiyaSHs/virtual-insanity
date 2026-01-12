#!/usr/bin/env bash
set -euo pipefail

run() {
  local disk
  echo
  lsblk -dpno NAME,SIZE,MODEL | sed 's/^/  /'

  disk="$(gm_ask "Enter target DISK path (e.g. /dev/nvme0n1) [WILL WIPE]")"
  [[ -b "$disk" ]] || gm_die "Not a block device: $disk"

  echo
  gm_warn "About to WIPE: $disk"
  gm_warn "Layout: EFI (1G) + ROOT (rest)"
  local confirm
  confirm="$(gm_ask "Type WIPE-${disk##*/} to confirm")"
  [[ "$confirm" == "WIPE-${disk##*/}" ]] || gm_die "Confirmation failed."

  gm_cmd umount -R "$GM_MNT" 2>/dev/null || true
  gm_cmd mkdir -p "$GM_MNT"

  gm_cmd parted -s "$disk" mklabel gpt
  gm_cmd parted -s "$disk" mkpart ESP fat32 1MiB 1025MiB
  gm_cmd parted -s "$disk" set 1 esp on
  gm_cmd parted -s "$disk" mkpart ROOT 1025MiB 100%

  local esp="${disk}1"
  local rootp="${disk}2"
  if [[ "$disk" == *"nvme"* ]]; then
    esp="${disk}p1"
    rootp="${disk}p2"
  fi

  gm_cmd mkfs.vfat -F 32 -n EFI "$esp"

  local fs enc
  fs="$(gm_read_conf FS)"
  enc="$(gm_read_conf ENC)"

  local rootdev="$rootp"
  if [[ "$enc" == "luks" ]]; then
    command -v cryptsetup >/dev/null 2>&1 || gm_die "cryptsetup missing in live env."
    gm_cmd cryptsetup luksFormat --type luks2 "$rootp"
    gm_cmd cryptsetup open "$rootp" cryptroot
    rootdev="/dev/mapper/cryptroot"
  fi

  case "$fs" in
    btrfs*) mkfs.btrfs -f -L ROOT "$rootdev" ;;
    ext4*)  mkfs.ext4 -F -L ROOT "$rootdev" ;;
    xfs*)   mkfs.xfs -f -L ROOT "$rootdev" ;;
    bcachefs*)
      command -v bcachefs >/dev/null 2>&1 || gm_die "bcachefs tools not found in live env."
      bcachefs format -f -L ROOT "$rootdev"
      ;;
    *) gm_die "Unknown FS: $fs" ;;
  esac

  gm_cmd mount "$rootdev" "$GM_MNT"
  gm_cmd mkdir -p "$GM_MNT/boot"
  gm_cmd mount "$esp" "$GM_MNT/boot"

  gm_write_conf DISK "$disk"
  gm_write_conf ESP "$esp"
  gm_write_conf ROOTP "$rootp"
  gm_write_conf ROOTDEV "$rootdev"

  gm_ok "Disk prepared and mounted at $GM_MNT"
}

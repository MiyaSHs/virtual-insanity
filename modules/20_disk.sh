#!/usr/bin/env bash
set -euo pipefail
source "$GM_ROOT_DIR/lib/common.sh"

run() {
  load_state
  local disk="$GM_DISK"
  [[ -b "$disk" ]] || die "Disk not found: $disk"

  local mnt="/mnt/gm"
  mkdir -p "$mnt"
  save_kv GM_MNT "$mnt"

  log "WIPING DISK: $disk"
  wipefs -a "$disk" || true
  sgdisk --zap-all "$disk" || true

  log "Partitioning (GPT): EFI 1G + ROOT rest"
  sgdisk -n 1:0:+1G -t 1:ef00 -c 1:"EFI" "$disk"
  sgdisk -n 2:0:0   -t 2:8300 -c 2:"ROOT" "$disk"
  partprobe "$disk" || true

  local p1 p2
  if [[ "$disk" =~ nvme ]]; then
    p1="${disk}p1"; p2="${disk}p2"
  else
    p1="${disk}1"; p2="${disk}2"
  fi

  mkfs.fat -F32 "$p1"

  local rootdev="$p2"
  local cryptname="gmroot"
  if [[ "$GM_ENCRYPTION" == "luks_tpm" || "$GM_ENCRYPTION" == "luks_pass" ]]; then
    log "Encrypting root with LUKS2…"
    echo -n "$GM_ROOTPW" | cryptsetup luksFormat --type luks2 --batch-mode "$p2" -
    echo -n "$GM_ROOTPW" | cryptsetup open "$p2" "$cryptname" -
    rootdev="/dev/mapper/$cryptname"
    save_kv GM_LUKS_DEV "$p2"
    save_kv GM_LUKS_NAME "$cryptname"
  fi

  case "$GM_FS" in
    btrfs) mkfs.btrfs -f "$rootdev" ;;
    ext4)  mkfs.ext4 -F "$rootdev" ;;
    xfs)   mkfs.xfs -f "$rootdev" ;;
    *) die "Unknown FS: $GM_FS" ;;
  esac

  mount "$rootdev" "$mnt"
  mkdir -p "$mnt/boot"
  mount "$p1" "$mnt/boot"

  if [[ "$GM_FS" == "btrfs" ]]; then
    log "Creating Btrfs subvolumes…"
    btrfs subvolume create "$mnt/@"
    btrfs subvolume create "$mnt/@home"
    btrfs subvolume create "$mnt/@var"
    btrfs subvolume create "$mnt/@steam"
    btrfs subvolume create "$mnt/@snapshots" || true
    umount "$mnt"
    local opts_root="noatime,ssd,compress=zstd:3,space_cache=v2"
    local opts_steam="noatime,ssd,compress=zstd:1,space_cache=v2"
    mount -o "$opts_root,subvol=@ " "$rootdev" "$mnt"
    mkdir -p "$mnt/home" "$mnt/var" "$mnt/steam" "$mnt/.snapshots"
    mount -o "$opts_root,subvol=@home" "$rootdev" "$mnt/home"
    mount -o "$opts_root,subvol=@var"  "$rootdev" "$mnt/var"
    mount -o "$opts_steam,subvol=@steam" "$rootdev" "$mnt/steam"
    mount -o "$opts_root,subvol=@snapshots" "$rootdev" "$mnt/.snapshots" || true
    # Re-mount EFI
    mount "$p1" "$mnt/boot"
  fi

  save_kv GM_EFI_PART "$p1"
  save_kv GM_ROOT_PART "$p2"
  save_kv GM_ROOTDEV "$rootdev"

  log "Disk ready, mounted at $mnt"
}

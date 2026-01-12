#!/usr/bin/env bash
set -euo pipefail
source "$GM_ROOT_DIR/lib/common.sh"
source "$GM_ROOT_DIR/lib/ui.sh"
source "$GM_ROOT_DIR/lib/hw.sh"

list_disks() {
  # show non-removable disks (best-effort)
  lsblk -dpno NAME,SIZE,MODEL,TYPE | awk '$4=="disk"{print $1 " (" $2 " " $3 ")"}'
}

run() {
  log "Collecting install choices…"

  local disk_choice
  local -a menu=()
  while read -r line; do
    [[ -n "$line" ]] || continue
    local dev="${line%% *}"
    menu+=("$dev" "$line")
  done < <(list_disks)

  [[ ${#menu[@]} -gt 0 ]] || die "No disks detected."

  disk_choice=$(ui_menu "Disk" "Select the target disk (WILL BE WIPED)" "${menu[@]}")
  save_kv GM_DISK "$disk_choice"

  local fs_choice
  fs_choice=$(ui_menu "Filesystem" "Choose filesystem" \
    "btrfs" "Btrfs (recommended: snapshots + compression)" \
    "ext4" "Ext4 (simple, stable)" \
    "xfs"  "XFS (fast, no compression by default)")
  save_kv GM_FS "$fs_choice"

  local enc_choice="none"
  if ui_yesno "Encryption" "Enable root encryption (LUKS2)?" "yes"; then
    if has_tpm2 && ui_yesno "Encryption" "TPM2 detected. Use TPM2 auto-unlock (no prompt on boot, fallback passphrase kept)?" "yes"; then
      enc_choice="luks_tpm"
    else
      enc_choice="luks_pass"
    fi
  fi
  save_kv GM_ENCRYPTION "$enc_choice"

  local prof
  prof=$(ui_menu "Profile" "Select base profile" \
    "gamemode" "Steam + Gamescope at boot (Plasma desktop available)" \
    "plasma" "Plasma Wayland desktop" \
    "tty" "Minimal console-only")
  save_kv GM_PROFILE "$prof"


  # Kernel strategy
  local kstrat="bin"
  if ui_yesno "Kernel" "Use CachyOS-kernels overlay (cachyos-sources) for an optimized kernel later? (We'll still install a bootable gentoo-kernel-bin fallback)" "yes"; then
    kstrat="cachyos"
  fi
  save_kv GM_KERNEL_STRATEGY "$kstrat"

  local device="generic"
  if ui_yesno "Device" "Apply ROG Ally module (hhd + handheld defaults)?" "no"; then
    device="rog_ally"
  fi
  save_kv GM_DEVICE "$device"

  local hostname
  hostname=$(ui_input "Hostname" "Set hostname" "gentoo")
  save_kv GM_HOSTNAME "$hostname"

  local username
  username=$(ui_input "User" "Create a primary user" "gamer")
  save_kv GM_USER "$username"

  # Passwords
  local rootpw userpw
  echo "Set root password:"
  read -r -s -p "root password: " rootpw; echo
  read -r -s -p "confirm: " rootpw2; echo
  [[ "$rootpw" == "$rootpw2" ]] || die "Root passwords did not match."
  save_kv GM_ROOTPW "$rootpw"

  echo "Set password for user '$username':"
  read -r -s -p "user password: " userpw; echo
  read -r -s -p "confirm: " userpw2; echo
  [[ "$userpw" == "$userpw2" ]] || die "User passwords did not match."
  save_kv GM_USERPW "$userpw"

  # Big binary choices
  # (These apply when profile is plasma/gamemode, but we allow always.)
  local firefox="source"
  if ui_yesno "Binary packages" "Use firefox-bin to save compile time?" "yes"; then firefox="bin"; fi
  save_kv GM_FIREFOX "$firefox"

  local llvm="source"
  if ui_yesno "Binary packages" "Use llvm-bin (if available) to save compile time? (recommended: NO for bleeding edge)" "no"; then llvm="bin"; fi
  save_kv GM_LLVM "$llvm"


  # Flatpak
  local flatpak="no"
  local store="none"
  if [[ "$prof" != "tty" ]] && ui_yesno "Flatpak" "Enable Flatpak + Flathub?" "yes"; then
    flatpak="yes"
    store=$(ui_menu "Flatpak store" "Choose a GUI Flatpak store" \
      "bazaar" "Bazaar (like Bazzite)" \
      "discover" "KDE Discover (Flatpak backend)" \
      "none" "None")
  fi
  save_kv GM_FLATPAK "$flatpak"
  save_kv GM_FLATPAK_STORE "$store"

  log "Choices saved to ${GM_STATE_DIR}/gm.conf"
}

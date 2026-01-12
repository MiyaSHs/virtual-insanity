#!/usr/bin/env bash
set -euo pipefail

run() {
  : > "$GM_CONF"

  local profile fs enc flatpak flatpak_store device

  profile="$(gm_menu "Choose system profile:"     "tty (no desktop, base + optimization stack)"     "plasma (desktop, Wayland, PipeWire)"     "gamemode (Steam+Gamescope + Plasma fallback)")"

  fs="$(gm_menu "Choose filesystem for root:"     "btrfs (recommended: easy compression/snapshots)"     "ext4 (simple, fast, stable)"     "xfs (fast; no shrink)"     "bcachefs (EXPERIMENTAL; risk)")"

  if gm_yesno "Enable full disk encryption (LUKS2 root)?" "y"; then
    enc="luks"
  else
    enc="none"
  fi

  device="$(gm_menu "Device module:"     "generic"     "rog-ally (installs handheld tweaks + hhd placeholder)")"

  if [[ "$profile" != tty* ]]; then
    flatpak="no"
    if gm_yesno "Enable Flatpak?" "y"; then
      flatpak="yes"
      flatpak_store="$(gm_menu "Flatpak store UI:"         "none (just flatpak enabled)"         "plasma-discover (KDE Discover backend)"         "gnome-software (works, heavier)")"
    else
      flatpak_store="none"
    fi
  else
    flatpak="no"
    flatpak_store="none"
  fi

  local firefox_bin java_bin kernel_bin
  firefox_bin="no"
  java_bin="no"
  kernel_bin="yes"

  if gm_yesno "Use firefox-bin instead of compiling Firefox?" "y"; then firefox_bin="yes"; fi
  if gm_yesno "Use gentoo-kernel-bin (fast) instead of compiling kernel sources?" "y"; then kernel_bin="yes"; else kernel_bin="no"; fi
  if gm_yesno "Use OpenJDK binary when Java is installed later?" "y"; then java_bin="yes"; fi

  local hostname username
  hostname="$(gm_ask "Hostname" "goldenmaster")"
  username="$(gm_ask "Primary username" "gamer")"

  gm_write_conf PROFILE "$profile"
  gm_write_conf FS "$fs"
  gm_write_conf ENC "$enc"
  gm_write_conf DEVICE "$device"
  gm_write_conf FLATPAK "$flatpak"
  gm_write_conf FLATPAK_STORE "$flatpak_store"
  gm_write_conf FIREFOX_BIN "$firefox_bin"
  gm_write_conf JAVA_BIN "$java_bin"
  gm_write_conf KERNEL_BIN "$kernel_bin"
  gm_write_conf HOSTNAME "$hostname"
  gm_write_conf USERNAME "$username"

  gm_write_conf CPU_VENDOR "$(gm_detect_cpu_vendor)"
  gm_write_conf CPU_FLAGS_X86 "$(gm_detect_cpu_flags_x86)"
  gm_write_conf VIDEO_CARDS "$(gm_guess_video_cards)"

  gm_ok "Config saved to $GM_CONF"
}

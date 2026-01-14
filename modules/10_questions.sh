#!/usr/bin/env bash
set -euo pipefail
source "$GM_ROOT_DIR/lib/common.sh"
source "$GM_ROOT_DIR/lib/ui.sh"
source "$GM_ROOT_DIR/lib/hw.sh"

list_disks() {
  lsblk -dpno NAME,SIZE,MODEL,TYPE | awk '$4=="disk"{print $1 " (" $2 " " $3 ")"}'
}

has_token() { [[ " ${1:-} " == *" ${2} "* ]]; }

run() {
  log "Collecting install choices…"

  # Profile
  local prof
  prof=$(ui_menu "Profile" "Choose the base system profile" \
    "gamemode" "Handheld Game Mode (Steam+Gamescope + Plasma fallback)" \
    "plasma"   "Plasma desktop (general use)" \
    "tty"      "TTY only (server/minimal)") || die "No profile selected."
  save_kv GM_PROFILE "$prof"

  # Components checklist (heavy/optional things)
  local -a feats=()
  feats+=("java"     "Install Java (OpenJDK/GraalVM) + runtime tuning helper" "OFF")
  feats+=("handheld" "Enable HHD handheld support (device-agnostic)" "$( [[ "$prof" == "gamemode" ]] && echo ON || echo OFF )")
  feats+=("iwd"      "Use iwd backend for Wi-Fi (recommended)" "ON")
  feats+=("bluetooth" "Enable Bluetooth (BlueZ + service)" "$( [[ "$prof" == "tty" ]] && echo OFF || echo ON )")
  if [[ "$prof" != "tty" ]]; then
    feats+=("browser" "Install/configure a desktop browser" "ON")
    feats+=("flatpak" "Enable Flatpak + Flathub" "ON")
  fi

  local features
  features=$(ui_checklist "Components" "Select which components to install/configure" 22 90 12 "${feats[@]}") || features=""
  features="$(echo "$features" | tr -s ' ' | sed 's/^ *//;s/ *$//')"
  save_kv GM_FEATURES "$features"

  # Networking backend
  if has_token "$features" iwd; then
    save_kv GM_WIFI_BACKEND "iwd"
  else
    save_kv GM_WIFI_BACKEND "wpa"
  fi
  save_kv GM_ENABLE_BT "$(has_token "$features" bluetooth && echo yes || echo no)"

  # Power policy (separate from profile)
  # - handheld_ppd: power-profiles-daemon (good UX + per-game holding)
  # - laptop_tlp: TLP (battery-first policy)
  # - desktop_none: no power daemon (assume always-plugged desktop)
  local default_power="desktop_none"
  if [[ "$prof" == "gamemode" ]] || has_token "$features" handheld; then
    default_power="handheld_ppd"
  elif has_battery; then
    default_power="laptop_tlp"
  fi

  local power
  power=$(ui_menu "Power policy" "Choose system power management policy" \
    "handheld_ppd" "Handheld: power-profiles-daemon (use performance holds for games)" \
    "laptop_tlp"   "Laptop: TLP (battery-first tuning)" \
    "desktop_none" "Desktop: no power daemon (keep it simple)") || power="$default_power"
  save_kv GM_POWER_POLICY "$power"

  # CPU tuning strategy
  local cflags_mode
  cflags_mode=$(ui_menu "CFLAGS strategy" "Choose global compile strategy" \
    "balanced" "Balanced (recommended baseline)" \
    "aggressive" "Aggressive (more O3 targets; higher build risk)") || cflags_mode="balanced"
  save_kv GM_CFLAGS_MODE "$cflags_mode"

  # Kernel strategy
  local kstrat
  kstrat=$(ui_menu "Kernel" "Choose kernel strategy (hands-free updates)" \
    "cachyos"    "CachyOS sources (BORE + AutoFDO + Propeller + ThinLTO; auto rebuild via timer)" \
    "gentoo-bin" "Gentoo distribution kernel (gentoo-kernel-bin; fastest install)" \
    "gentoo-src" "Gentoo distribution kernel (gentoo-kernel; compile)" \
  ) || die "No kernel strategy selected."
  save_kv GM_KERNEL_STRATEGY "$kstrat"

  # Optional sched-ext (scx) toggle (works best with CachyOS kernel)
  if ui_yesno "sched_ext" "Enable sched_ext userspace scheduler (scx_lavd) when available?" "no"; then
    save_kv GM_ENABLE_SCX "yes"
  else
    save_kv GM_ENABLE_SCX "no"
  fi

  # Device / HHD
  local device="generic"
  if has_token "$features" handheld; then
    device="hhd"
  fi
  save_kv GM_DEVICE "$device"

  # Hostname
  local hostname
  hostname=$(ui_input "Hostname" "Set hostname" "gentoo")
  save_kv GM_HOSTNAME "$hostname"

  # Username
  local username
  username=$(ui_input "User" "Create a non-root user" "gamer")
  save_kv GM_USER "$username"

  # Passwords (stored in state temporarily; scrubbed at end)
  local rootpw userpw rootpw2 userpw2
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

  # Desktop browser choice (only relevant when not tty, and if browser component enabled)
  local browser="none"
  if [[ "$prof" != "tty" ]] && has_token "$features" browser; then
    browser=$(ui_menu "Browser" "Choose your default desktop browser" \
      "firefox"  "Firefox" \
      "librewolf" "LibreWolf (privacy-focused; may require more build time)" \
      "none"     "None / later")
  fi
  save_kv GM_BROWSER "$browser"

  # Flatpak store (optional)
  local flatpak="no" store="none"
  if [[ "$prof" != "tty" ]] && has_token "$features" flatpak; then
    flatpak="yes"
    store=$(ui_menu "Flatpak store" "Choose a GUI Flatpak store" \
      "bazaar" "Bazaar (like Bazzite)" \
      "discover" "KDE Discover (Flatpak backend)" \
      "none" "None")
  fi
  save_kv GM_FLATPAK "$flatpak"
  save_kv GM_FLATPAK_STORE "$store"

  # Java enable is based on checklist
  save_kv GM_ENABLE_JAVA "$(has_token "$features" java && echo yes || echo no)"

  # Binary packages selection (only show relevant ones)
  local -a binopts=()
  if [[ "$browser" == "firefox" ]]; then
    binopts+=("firefox-bin" "Use www-client/firefox-bin (much faster install)" "ON")
  fi
  if [[ "$browser" == "librewolf" ]]; then
    binopts+=("librewolf-bin" "Use www-client/librewolf-bin (from LibreWolf overlay)" "OFF")
  fi
  if [[ "${GM_ENABLE_JAVA:-no}" == "yes" ]]; then
    binopts+=("openjdk-bin" "Use dev-java/openjdk-bin (binary JDK)" "OFF")
  fi
  local binpkgs=""
  if ((${#binopts[@]})); then
    binpkgs=$(ui_checklist "Binary packages" "Select packages to use prebuilt binaries" 18 90 10 "${binopts[@]}") || binpkgs=""
    binpkgs="$(echo "$binpkgs" | tr -s ' ' | sed 's/^ *//;s/ *$//')"
  fi
  save_kv GM_BINPKGS "$binpkgs"


  # Perf/FDO pipeline: always enabled (not prompted)
  save_kv GM_ENABLE_PERF "yes"

  log "Choices saved to ${GM_STATE_DIR}/gm.conf"
}

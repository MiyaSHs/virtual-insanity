#!/usr/bin/env bash
set -euo pipefail
source "$GM_ROOT_DIR/lib/common.sh"
source "$GM_ROOT_DIR/lib/ui.sh"
source "$GM_ROOT_DIR/lib/hw.sh"

list_disks() {
  # show non-removable disks (best-effort)
  lsblk -dpno NAME,SIZE,MODEL,TYPE | awk '$4=="disk"{print $1 " (" $2 " " $3 ")"}'
}

# helper: token-in-string
has_token() { [[ " ${1:-} " == *" ${2} "* ]]; }

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
  if ui_yesno "Kernel" "Use CachyOS-kernels overlay (cachyos-sources) for an optimized kernel later? (A bootable Gentoo kernel will be installed based on your binary choices.)" "yes"; then
    kstrat="cachyos"
  fi
  save_kv GM_KERNEL_STRATEGY "$kstrat"

  local device="generic"
  if ui_yesno "Device" "Enable HHD handheld support (Handheld Daemon: gamepad/handheld integration)?" "yes"; then
    device="hhd"
  fi
  save_kv GM_DEVICE "$device"

  local hostname
  hostname=$(ui_input "Hostname" "Set hostname" "gentoo")
  save_kv GM_HOSTNAME "$hostname"

  local username
  username=$(ui_input "User" "Create a primary user" "gamer")
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

  # Desktop browser choice (only relevant when not tty)
  local browser="none"
  if [[ "$prof" != "tty" ]]; then
    browser=$(ui_menu "Browser" "Choose your default desktop browser" \
      "firefox"  "Firefox" \
      "librewolf" "LibreWolf (privacy-focused; may require more build time)" \
      "none"     "None / later")
  fi
  save_kv GM_BROWSER "$browser"

  # Java (runtime tuning via JAVA_TOOL_OPTIONS + optional JDK install)
  local java_enable="no"
  if ui_yesno "Java" "Enable Java install + runtime tuning (useful for Minecraft and Java games/apps)?" "$( [[ "$prof" == "tty" ]] && echo no || echo yes )"; then
    java_enable="yes"
  fi
  save_kv GM_ENABLE_JAVA "$java_enable"

  local java_impl="openjdk"
  if [[ "$java_enable" == "yes" ]]; then
    java_impl=$(ui_menu "Java" "Choose the JVM implementation (we'll fall back if unavailable)" \
      "openjdk" "OpenJDK (recommended baseline)" \
      "graalvm" "GraalVM (if available in repos; otherwise falls back to OpenJDK)")
  fi
  save_kv GM_JAVA_IMPL "$java_impl"

  # Binary package preferences (time saver switches)
  # Stored as a space-separated token list in GM_BINPKGS.
  local -a items=()

  # Defaults: kernel-bin ON; rust-bin ON; openjdk-bin ON when Java enabled; llvm-bin OFF
  items+=("kernel-bin" "Use gentoo-kernel-bin (fast install, good fallback)" "ON")
  items+=("rust-bin"   "Use rust-bin (massive compile time saver)" "ON")
  if [[ "$java_enable" == "yes" ]]; then
    items+=("openjdk-bin" "Use openjdk-bin (skip big JDK build)" "ON")
  fi
  items+=("llvm-bin"   "Use llvm-bin/clang-bin/lld-bin (faster, but less bleeding-edge)" "OFF")

  if [[ "$browser" == "firefox" ]]; then
    items+=("firefox-bin" "Use firefox-bin (skip a very long build)" "ON")
  elif [[ "$browser" == "librewolf" ]]; then
    items+=("librewolf-bin" "Try librewolf-bin if available (otherwise build from source)" "OFF")
  fi

  local binpkgs
  binpkgs=$(ui_checklist "Binary packages" "Select which packages should prefer binary variants" 22 90 12 "${items[@]}") || binpkgs=""
  # normalize
  binpkgs="$(echo "$binpkgs" | tr -s ' ' | sed 's/^ *//;s/ *$//')"
  save_kv GM_BINPKGS "$binpkgs"

  # Back-compat keys (older modules may read these)
  save_kv GM_LLVM "$(has_token "$binpkgs" llvm-bin && echo bin || echo source)"
  save_kv GM_FIREFOX "$(has_token "$binpkgs" firefox-bin && echo bin || echo source)"
  save_kv GM_KERNEL_PKG "$(has_token "$binpkgs" kernel-bin && echo gentoo-kernel-bin || echo gentoo-kernel)"

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

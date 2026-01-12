#!/usr/bin/env bash
set -euo pipefail
source "$GM_ROOT_DIR/lib/common.sh"

has_bin() { [[ " ${GM_BINPKGS:-} " == *" $1 "* ]]; }

install_steam() {
  # steam-launcher is in steam-overlay
  emerge --quiet-build=y games-util/steam-launcher games-util/steam-devices || true
}

install_browser() {
  [[ "${GM_BROWSER:-none}" != "none" ]] || return 0

  case "${GM_BROWSER}" in
    firefox)
      if has_bin firefox-bin; then
        emerge --quiet-build=y www-client/firefox-bin || true
      else
        emerge --quiet-build=y www-client/firefox || true
      fi
      ;;
    librewolf)
      if has_bin librewolf-bin && emerge -p www-client/librewolf-bin >/dev/null 2>&1; then
        emerge --quiet-build=y www-client/librewolf-bin || true
      elif emerge -p www-client/librewolf >/dev/null 2>&1; then
        emerge --quiet-build=y www-client/librewolf || true
      else
        warn "LibreWolf not available in repos; falling back to Firefox."
        emerge --quiet-build=y www-client/firefox-bin || emerge --quiet-build=y www-client/firefox || true
      fi
      ;;
  esac
}

run() {
  log "Installing GameMode profile…"

  # Plasma fallback (Return to Desktop)
  emerge --quiet-build=y \
    kde-plasma/plasma-meta \
    kde-plasma/plasma-wayland-session \
    x11-misc/sddm \
    media-video/pipewire media-video/wireplumber \
    app-admin/xdg-desktop-portal-kde \
    sys-power/power-profiles-daemon \
    || true

  # Gaming stack
  emerge --quiet-build=y \
    gui-wm/gamescope \
    games-util/gamemode \
    games-util/mangohud \
    sys-apps/seatd \
    media-libs/vulkan-loader \
    || true

  install_steam
  install_browser

  systemctl enable gamemoded || true
  systemctl enable seatd || true
  systemctl enable power-profiles-daemon || true

  # Install scripts
  install -Dm755 "$GM_ROOT_DIR/files/scripts/gm-gamemode" /usr/local/bin/gm-gamemode
  install -Dm755 "$GM_ROOT_DIR/files/scripts/gm-desktop"  /usr/local/bin/gm-desktop
  install -Dm755 "$GM_ROOT_DIR/files/scripts/gm-tty"      /usr/local/bin/gm-tty

  # Steam library tuning on Btrfs
  if mountpoint -q /steam; then
    mkdir -p /steam/SteamLibrary
    chown -R "${GM_USER}:${GM_USER}" /steam
    # NOCOW for heavy-write directories (created later by Steam)
    mkdir -p /steam/SteamLibrary/steamapps/{shadercache,compatdata}
    chattr +C /steam/SteamLibrary/steamapps/shadercache || true
    chattr +C /steam/SteamLibrary/steamapps/compatdata || true
  fi

  # Disable SDDM by default; user can `sudo gm-desktop`
  systemctl disable sddm || true
  systemctl set-default multi-user.target || true

  log "GameMode profile done."
}

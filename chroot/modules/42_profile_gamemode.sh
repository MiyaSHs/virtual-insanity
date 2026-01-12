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
    kde-plasma/bluedevil \
    x11-misc/sddm \
    media-video/pipewire media-video/wireplumber \
    app-admin/xdg-desktop-portal-kde \
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

  # SDDM autologin straight into Game Mode, with Plasma fallback.
  mkdir -p /usr/share/wayland-sessions
  cat > /usr/share/wayland-sessions/gm-gamemode.desktop <<'EOF'
[Desktop Entry]
Name=GM Game Mode
Comment=Steam Gamepad UI inside Gamescope
Exec=/usr/local/bin/gm-gamemode
Type=Application
DesktopNames=GM
EOF

  mkdir -p /etc/sddm.conf.d
  cat > /etc/sddm.conf.d/00-gm.conf <<EOF
[Autologin]
User=${GM_USER}
Session=gm-gamemode.desktop
Relogin=true
EOF

  # Session switching helpers ("Return to Desktop" and back)
  install -Dm755 "$GM_ROOT_DIR/files/scripts/gm-session-switchd" /usr/local/sbin/gm-session-switchd
  install -Dm755 "$GM_ROOT_DIR/files/scripts/gm-return-to-desktop" /usr/local/bin/gm-return-to-desktop
  install -Dm755 "$GM_ROOT_DIR/files/scripts/gm-return-to-gamemode" /usr/local/bin/gm-return-to-gamemode
  install -Dm644 "$GM_ROOT_DIR/files/systemd/system/gm-session-switchd.service" /etc/systemd/system/gm-session-switchd.service
  install -Dm644 "$GM_ROOT_DIR/files/systemd/system/gm-session-switchd.path" /etc/systemd/system/gm-session-switchd.path
  install -Dm644 "$GM_ROOT_DIR/files/templates/gm-tmpfiles.conf" /etc/tmpfiles.d/gm.conf
  install -Dm644 "$GM_ROOT_DIR/files/templates/gm-return-to-desktop.desktop" /usr/share/applications/gm-return-to-desktop.desktop
  install -Dm644 "$GM_ROOT_DIR/files/templates/gm-return-to-gamemode.desktop" /usr/share/applications/gm-return-to-gamemode.desktop
  systemd-tmpfiles --create /etc/tmpfiles.d/gm.conf || true
  systemctl enable gm-session-switchd.path || true

  systemctl enable sddm || true
  systemctl set-default graphical.target || true

  log "GameMode profile done."
}

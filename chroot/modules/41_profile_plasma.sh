#!/usr/bin/env bash
set -euo pipefail
source "$GM_ROOT_DIR/lib/common.sh"

has_bin() { [[ " ${GM_BINPKGS:-} " == *" $1 "* ]]; }

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
      # Ensure LibreWolf overlay is available
      if ! eselect repository list 2>/dev/null | grep -q "\<librewolf\>"; then
        eselect repository add librewolf git https://codeberg.org/librewolf/gentoo.git || true
      fi
      emaint -r librewolf sync || true

      # Try librewolf-bin if user asked; otherwise source.
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
  log "Installing Plasma Wayland profile…"

  emerge --quiet-build=y \
    kde-plasma/plasma-meta \
    kde-plasma/plasma-wayland-session \
    kde-plasma/bluedevil \
    kde-apps/kde-apps-meta \
    x11-misc/sddm \
    media-video/pipewire media-video/wireplumber \
    media-libs/mesa media-libs/vulkan-loader \
    x11-apps/xrandr \
    app-admin/xdg-desktop-portal-kde \
    sys-power/power-profiles-daemon \
    app-misc/usbutils \
    || true

  install_browser

  systemctl enable sddm || true

  # Try install OSK (best-effort)
  emerge --quiet-build=y app-i18n/maliit-keyboard || true


  # Session switching helpers (for Steam/GameMode "Return to Desktop" style flow)
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

  systemctl set-default graphical.target || true
  log "Plasma profile done."
}

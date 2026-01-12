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
  systemctl enable power-profiles-daemon || true

  # Try install OSK (best-effort)
  emerge --quiet-build=y app-i18n/maliit-keyboard || true

  systemctl set-default graphical.target || true
  log "Plasma profile done."
}

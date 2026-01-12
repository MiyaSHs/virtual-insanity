#!/usr/bin/env bash
set -euo pipefail
source "$GM_ROOT_DIR/lib/common.sh"

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

  systemctl enable sddm || true
  systemctl enable power-profiles-daemon || true

  # Try install OSK (best-effort)
  emerge --quiet-build=y app-i18n/maliit-keyboard || true

  systemctl set-default graphical.target || true
  log "Plasma profile done."
}

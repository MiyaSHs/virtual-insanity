#!/usr/bin/env bash
set -euo pipefail

run() {
  emerge --quiet-build     gui-libs/xdg-desktop-portal     gui-libs/xdg-desktop-portal-kde     kde-plasma/plasma-meta     kde-apps/konsole     media-video/pipewire     media-sound/wireplumber     sys-apps/xdg-user-dirs

  systemctl enable sddm
  systemctl --global enable pipewire pipewire-pulse wireplumber || true

  gm_ok "Plasma profile installed."
}

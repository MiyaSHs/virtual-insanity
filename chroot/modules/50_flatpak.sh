#!/usr/bin/env bash
set -euo pipefail

run() {
  local store
  store="$(gm_read_conf FLATPAK_STORE)"

  emerge --quiet-build sys-apps/flatpak

  case "$store" in
    plasma-discover*)
      emerge --quiet-build kde-apps/discover
      ;;
    gnome-software*)
      emerge --quiet-build gnome-extra/gnome-software
      ;;
    none*) : ;;
  esac

  gm_ok "Flatpak enabled."
}

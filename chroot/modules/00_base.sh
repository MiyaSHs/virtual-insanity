#!/usr/bin/env bash
set -euo pipefail

run() {
  [[ -f /etc/gentoo-release ]] || gm_die "Not in Gentoo stage3?"

  mkdir -p /boot /etc/portage/package.use /etc/portage/package.env /etc/portage/env
  mkdir -p /etc/gm

  # minimal locale baseline (you can expand later)
  cp -f "${ROOT_DIR}/files/templates/locale.gen" /etc/locale.gen || true
  locale-gen >/dev/null 2>&1 || true

  cp -f "${ROOT_DIR}/files/templates/vconsole.conf" /etc/vconsole.conf || true

  gm_ok "Base prep done."
}

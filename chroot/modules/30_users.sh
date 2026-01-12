#!/usr/bin/env bash
set -euo pipefail

run() {
  local username
  username="$(gm_read_conf USERNAME)"

  useradd -m -G wheel,video,audio,input -s /bin/bash "$username" || true
  echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/10-wheel

  echo
  gm_warn "Set user password now (recommended)."
  passwd "$username" || true

  gm_ok "User created: $username"
}

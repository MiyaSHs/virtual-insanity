#!/usr/bin/env bash
set -euo pipefail
source "$GM_ROOT_DIR/lib/common.sh"

run() {
  log "Installing TTY profile packages…"
  emerge --quiet-build=y app-editors/neovim app-misc/tmux sys-apps/mlocate \
    net-misc/openssh || true
  systemctl enable sshd || true

  systemctl set-default multi-user.target || true
  log "TTY profile done."
}

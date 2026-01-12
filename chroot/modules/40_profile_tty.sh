#!/usr/bin/env bash
set -euo pipefail

run() {
  emerge --quiet-build sys-apps/dbus
  systemctl enable dbus
  gm_ok "TTY profile ready."
}

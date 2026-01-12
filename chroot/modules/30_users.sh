#!/usr/bin/env bash
set -euo pipefail
source "$GM_ROOT_DIR/lib/common.sh"

run() {
  log "User/session defaults…"

  # Allow wheel sudo already configured.

  # If gamemode: autologin on tty1 into user
  if [[ "${GM_PROFILE}" == "gamemode" ]]; then
    mkdir -p /etc/systemd/system/getty@tty1.service.d
    cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ${GM_USER} --noclear %I \$TERM
Type=idle
EOF

    # User bash_profile auto-launch
    local home="/home/${GM_USER}"
    cat >> "${home}/.bash_profile" <<'EOF'

# Golden Master: auto-start gamemode on tty1
if [[ -z "${DISPLAY:-}" && "$(tty)" == "/dev/tty1" && -x /usr/local/bin/gm-gamemode ]]; then
  exec /usr/local/bin/gm-gamemode
fi
EOF
    chown "${GM_USER}:${GM_USER}" "${home}/.bash_profile"
  fi

  log "User/session done."
}

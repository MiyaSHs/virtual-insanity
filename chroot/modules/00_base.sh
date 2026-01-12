#!/usr/bin/env bash
set -euo pipefail
source "$GM_ROOT_DIR/lib/common.sh"

run() {
  log "Base system configuration…"

  echo "${GM_HOSTNAME}" > /etc/hostname

  ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime || true
  echo 'clock="local"' > /etc/conf.d/hwclock 2>/dev/null || true

  # Locale
  cp -f "$GM_ROOT_DIR/files/templates/locale.gen" /etc/locale.gen
  locale-gen
  echo "LANG=en_US.UTF-8" > /etc/locale.conf

  # Root password
  echo "root:${GM_ROOTPW}" | chpasswd

  # User
  useradd -m -G wheel,audio,video,input,plugdev,games -s /bin/bash "${GM_USER}" || true
  echo "${GM_USER}:${GM_USERPW}" | chpasswd

  # Sudo
  emerge --quiet-build=y app-admin/sudo
  sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

  log "Base done."
}

#!/usr/bin/env bash
set -euo pipefail

run() {
  local cpu_flags video_cards hostname
  cpu_flags="$(gm_read_conf CPU_FLAGS_X86)"
  video_cards="$(gm_read_conf VIDEO_CARDS)"
  hostname="$(gm_read_conf HOSTNAME)"

  echo "$hostname" > /etc/hostname

  # make.conf
  sed -e "s|@CPU_FLAGS_X86@|${cpu_flags}|g" -e "s|@VIDEO_CARDS@|${video_cards}|g"     < "${ROOT_DIR}/files/templates/make.conf.tpl" > /etc/portage/make.conf

  # sync
  emerge-webrsync
  emerge --sync

  # baseline packages
  emerge --quiet-build --noreplace     app-portage/cpuid2cpuflags     app-portage/gentoolkit     sys-fs/cryptsetup     sys-apps/pciutils     sys-apps/usbutils     sys-apps/systemd     sys-process/cronie     app-admin/sudo     net-misc/networkmanager     sys-fs/dosfstools     sys-kernel/installkernel-gentoo

  systemctl enable NetworkManager
  gm_ok "Portage + base packages installed."
}

#!/usr/bin/env bash
set -euo pipefail

run() {
  gm_mount_pseudos

  gm_cmd mkdir -p "$GM_MNT/root/golden-master"
  gm_cmd rsync -a --delete "${GM_ROOT_DIR}/" "$GM_MNT/root/golden-master/"

  gm_cmd cp -f "$GM_CONF" "$GM_MNT/root/gm-install.conf"

  gm_banner "Entering chroot"
  gm_cmd chroot "$GM_MNT" /bin/bash -lc "cd /root/golden-master && bash chroot/chroot.sh"

  gm_umount_pseudos
  gm_ok "Chroot phase finished."
}

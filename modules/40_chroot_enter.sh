#!/usr/bin/env bash
set -euo pipefail
source "$GM_ROOT_DIR/lib/common.sh"

run() {
  load_state
  local mnt="$GM_MNT"

  log "Preparing chroot mounts…"
  mount -t proc /proc "$mnt/proc"
  mount --rbind /sys "$mnt/sys"
  mount --make-rslave "$mnt/sys"
  mount --rbind /dev "$mnt/dev"
  mount --make-rslave "$mnt/dev"

  log "Entering chroot…"
  cp -f "$GM_STATE_DIR/gm.conf" "$mnt/root/golden-master/gm.conf"
  chroot_run "$mnt" /bin/bash /root/golden-master/chroot/chroot.sh

  log "Chroot phase complete."
}

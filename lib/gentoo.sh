#!/usr/bin/env bash
set -euo pipefail

gm_mount_pseudos() {
  gm_cmd mount -t proc /proc "${GM_MNT}/proc"
  gm_cmd mount --rbind /sys "${GM_MNT}/sys"
  gm_cmd mount --make-rslave "${GM_MNT}/sys"
  gm_cmd mount --rbind /dev "${GM_MNT}/dev"
  gm_cmd mount --make-rslave "${GM_MNT}/dev"
}

gm_umount_pseudos() {
  umount -l "${GM_MNT}/dev" 2>/dev/null || true
  umount -l "${GM_MNT}/sys" 2>/dev/null || true
  umount -l "${GM_MNT}/proc" 2>/dev/null || true
}

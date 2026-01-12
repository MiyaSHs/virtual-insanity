#!/usr/bin/env bash
set -euo pipefail

render_tpl() {
  local tpl="$1"
  shift
  local out="$1"
  shift
  local s
  s="$(cat "$tpl")"
  while (( "$#" )); do
    local k="$1" v="$2"
    shift 2
    s="${s//${k}/${v}}"
  done
  printf "%s\n" "$s" > "$out"
}

run() {
  local kernel_bin enc rootp rootdev esp fs
  kernel_bin="$(gm_read_conf KERNEL_BIN)"
  enc="$(gm_read_conf ENC)"
  rootp="$(gm_read_conf ROOTP)"
  rootdev="$(gm_read_conf ROOTDEV)"
  esp="$(gm_read_conf ESP)"
  fs="$(gm_read_conf FS)"

  emerge --quiet-build sys-kernel/dracut

  if [[ "$kernel_bin" == "yes" ]]; then
    emerge --quiet-build sys-kernel/gentoo-kernel-bin
  else
    emerge --quiet-build sys-kernel/gentoo-kernel
  fi

  bootctl install

  local kver
  kver="$(ls -1 /lib/modules | sort -V | tail -n1)"
  [[ -n "$kver" ]] || gm_die "No kernel modules found under /lib/modules"

  dracut --force "/boot/initramfs-${kver}.img" "${kver}"

  local root_partuuid
  root_partuuid="$(blkid -s PARTUUID -o value "$rootp")"

  mkdir -p /boot/loader/entries
  cat >/boot/loader/loader.conf <<EOF
default gentoo.conf
timeout 0
console-mode max
editor no
EOF

  local kernel_img="/boot/vmlinuz-${kver}"
  [[ -f "$kernel_img" ]] || kernel_img="/boot/kernel-${kver}"
  [[ -f "$kernel_img" ]] || gm_die "Kernel image not found in /boot for ${kver}"

  local options="root=PARTUUID=${root_partuuid} rw quiet loglevel=3 rd.systemd.show_status=auto rd.udev.log_level=3"
  if [[ "$enc" == "luks" ]]; then
    local luks_uuid
    luks_uuid="$(blkid -s UUID -o value "$rootp")"
    options="rd.luks.uuid=${luks_uuid} ${options}"
  fi

  cat >/boot/loader/entries/gentoo.conf <<EOF
title   Gentoo (Golden Master)
linux   ${kernel_img#/boot/}
initrd  initramfs-${kver}.img
options ${options}
EOF

  local fstype="ext4"
  case "$fs" in
    btrfs*) fstype="btrfs" ;;
    ext4*)  fstype="ext4" ;;
    xfs*)   fstype="xfs" ;;
    bcachefs*) fstype="bcachefs" ;;
  esac

  local root_uuid esp_uuid
  esp_uuid="$(blkid -s UUID -o value "$esp")"
  if [[ "$enc" == "luks" ]]; then
    root_uuid="$(blkid -s UUID -o value "$rootdev")"
  else
    root_uuid="$(blkid -s UUID -o value "$rootp")"
  fi

  render_tpl "${ROOT_DIR}/files/templates/fstab.tpl" /etc/fstab     "@ROOT_UUID@" "$root_uuid"     "@FSTYPE@" "$fstype"     "@ESP_UUID@" "$esp_uuid"

  gm_ok "Kernel + systemd-boot configured."
}

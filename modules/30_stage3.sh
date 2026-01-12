#!/usr/bin/env bash
set -euo pipefail

run() {
  local stage3_base="https://distfiles.gentoo.org/releases/amd64/autobuilds"
  local stage3_txt="${stage3_base}/current-stage3-amd64-systemd/latest-stage3-amd64-systemd.txt"

  gm_cmd mkdir -p "$GM_MNT"
  gm_cmd cd "$GM_MNT"

  gm_banner "Fetching stage3 list"
  local tarball
  tarball="$(curl -fsSL "$stage3_txt" | awk '$1 !~ /^#/ {print $1; exit}')"
  [[ -n "$tarball" ]] || gm_die "Could not parse stage3 tarball from $stage3_txt"

  gm_banner "Downloading stage3: $tarball"
  gm_cmd curl -fL --progress-bar "${stage3_base}/${tarball}" -o stage3.tar.xz

  gm_banner "Extracting stage3"
  gm_cmd tar xpf stage3.tar.xz --xattrs-include='*.*' --numeric-owner

  gm_cmd cp -f /etc/resolv.conf "$GM_MNT/etc/resolv.conf"
  gm_ok "Stage3 installed."
}

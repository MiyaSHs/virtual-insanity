#!/usr/bin/env bash
set -euo pipefail
source "$GM_ROOT_DIR/lib/common.sh"
source "$GM_ROOT_DIR/lib/gentoo.sh"

run() {
  load_state
  local mnt="$GM_MNT"
  [[ -d "$mnt" ]] || die "Mount not found: $mnt"

  local arch="amd64"
  local flavor="desktop-systemd"
  local url
  url=$(stage3_url_for "$arch" "$flavor") || die "Failed to resolve stage3 URL."
  save_kv GM_STAGE3_URL "$url"

  download_stage3 "$url" "$GM_STATE_DIR"

  log "Extracting stage3…"
  tar xpf "$GM_STATE_DIR/stage3.tar.xz" -C "$mnt" --xattrs-include='*.*' --numeric-owner

  log "Copying DNS config…"
  cp -L /etc/resolv.conf "$mnt/etc/resolv.conf"

  # Copy repo into new system (so chroot can access files/)
  log "Copying installer repo into target…"
  mkdir -p "$mnt/root/golden-master"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "$GM_ROOT_DIR/" "$mnt/root/golden-master/"
  else
    cp -a "$GM_ROOT_DIR/." "$mnt/root/golden-master/"
  fi

  log "Stage3 ready."
}

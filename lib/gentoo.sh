#!/usr/bin/env bash
set -euo pipefail

# Utilities for stage3 selection/download.

stage3_url_for() {
  local arch="$1" flavor="$2"
  # flavor: "desktop-systemd" (default)
  local base="https://distfiles.gentoo.org/releases/${arch}/autobuilds"
  local latest="latest-stage3-${arch}-${flavor}.txt"
  local txt
  txt=$(curl -fsSL "${base}/${latest}")
  # file format: <path> <sha256> <size>
  local path
  path=$(echo "$txt" | awk 'NF>=1 && $1 ~ /\.tar\.xz$/ {print $1; exit}')
  [[ -n "$path" ]] || return 1
  echo "${base}/${path}"
}

download_stage3() {
  local url="$1" dest="$2"
  mkdir -p "$dest"
  log "Downloading stage3: $url"
  curl -fL --retry 5 --retry-delay 2 -o "$dest/stage3.tar.xz" "$url"
}

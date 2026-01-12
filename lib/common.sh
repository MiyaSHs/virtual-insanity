#!/usr/bin/env bash
set -euo pipefail

log() { echo -e "[gm] $*"; }
warn() { echo -e "[gm][WARN] $*" >&2; }
die() { echo -e "[gm][FATAL] $*" >&2; exit 1; }

require_root() {
  [[ "${EUID:-$(id -u)}" -eq 0 ]] || die "Run as root."
}

on_error() {
  local rc="$1" line="$2"
  warn "Error (rc=$rc) at line $line"
  warn "Last command: ${BASH_COMMAND:-unknown}"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

net_required() {
  if ! ping -c1 -W1 1.1.1.1 >/dev/null 2>&1; then
    die "No internet connectivity. This installer is online-only."
  fi
}

is_uefi_boot() {
  [[ -d /sys/firmware/efi/efivars ]]
}

load_state() {
  local f="${GM_STATE_DIR}/gm.conf"
  [[ -f "$f" ]] || die "Missing state file $f"
  # shellcheck disable=SC1090
  source "$f"
}

save_kv() {
  local key="$1" val="$2"
  local f="${GM_STATE_DIR}/gm.conf"
  mkdir -p "$GM_STATE_DIR"
  if [[ ! -f "$f" ]]; then
    echo "# Golden Master installer state" >"$f"
  fi
  # remove existing
  grep -vE "^${key}=" "$f" >"$f.tmp" || true
  mv "$f.tmp" "$f"
  printf "%s=%q\n" "$key" "$val" >>"$f"
}

chroot_run() {
  local root="$1"; shift
  chroot "$root" /usr/bin/env -i \
    HOME=/root TERM="${TERM:-xterm-256color}" \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    "$@"
}


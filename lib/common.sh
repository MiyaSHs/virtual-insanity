#!/usr/bin/env bash
set -euo pipefail

gm_banner() { echo -e "\n==> $*\n"; }
gm_ok()     { echo -e "[OK] $*"; }
gm_warn()   { echo -e "[WARN] $*" >&2; }
gm_die()    { echo -e "[FATAL] $*" >&2; exit 1; }

gm_need_root() {
  [[ "${EUID:-$(id -u)}" -eq 0 ]] || gm_die "Run as root."
}

gm_cmd() {
  echo "+ $*"
  "$@"
}

gm_has_internet() {
  curl -fsSL --max-time 5 https://www.gentoo.org >/dev/null 2>&1
}

gm_run_module() {
  local f="$1"
  [[ -f "$f" ]] || gm_die "Missing module: $f"
  gm_banner "Running module: $(basename "$f")"
  # shellcheck source=/dev/null
  source "$f"
  run
}

gm_write_conf() {
  local k="$1" v="$2"
  grep -q "^${k}=" "$GM_CONF" 2>/dev/null && sed -i "s|^${k}=.*|${k}=\"${v}\"|" "$GM_CONF" || echo "${k}=\"${v}\"" >> "$GM_CONF"
}

gm_read_conf() {
  local k="$1"
  # shellcheck disable=SC1090
  source "$GM_CONF"
  eval "echo \"\${${k}:-}\""
}

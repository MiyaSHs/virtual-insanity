#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export GM_ROOT_DIR="$ROOT_DIR"
export GM_STATE_DIR="${GM_STATE_DIR:-/tmp/golden-master}"
mkdir -p "$GM_STATE_DIR"

# shellcheck source=lib/common.sh
source "$ROOT_DIR/lib/common.sh"
# shellcheck source=lib/ui.sh
source "$ROOT_DIR/lib/ui.sh"

require_root
trap 'on_error $? $LINENO' ERR

log "Golden Master installer starting (live environment)."
log "State dir: $GM_STATE_DIR"

run_module() {
  local mod="$1"
  # shellcheck disable=SC1090
  source "$ROOT_DIR/$mod"
  run
}

# Live-side modules
run_module "modules/00_prereqs.sh"
run_module "modules/10_questions.sh"
run_module "modules/20_disk.sh"
run_module "modules/30_stage3.sh"
run_module "modules/40_chroot_enter.sh"

log "Install completed. You can reboot into the new system."

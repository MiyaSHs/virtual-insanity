#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/common.sh
source "${ROOT_DIR}/lib/common.sh"
# shellcheck source=lib/ui.sh
source "${ROOT_DIR}/lib/ui.sh"
# shellcheck source=lib/hw.sh
source "${ROOT_DIR}/lib/hw.sh"
# shellcheck source=lib/gentoo.sh
source "${ROOT_DIR}/lib/gentoo.sh"

export GM_ROOT_DIR="$ROOT_DIR"
export GM_CONF="/tmp/gm-install.conf"
export GM_MNT="/mnt/gentoo"

gm_banner "Golden Master Gentoo Installer (live phase)"

gm_run_module "${ROOT_DIR}/modules/00_prereqs.sh"
gm_run_module "${ROOT_DIR}/modules/10_questions.sh"
gm_run_module "${ROOT_DIR}/modules/20_disk.sh"
gm_run_module "${ROOT_DIR}/modules/30_stage3.sh"
gm_run_module "${ROOT_DIR}/modules/40_chroot_enter.sh"

gm_ok "Install completed. You can reboot now."

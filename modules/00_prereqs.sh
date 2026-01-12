#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=lib/common.sh
source "$GM_ROOT_DIR/lib/common.sh"
# shellcheck source=lib/hw.sh
source "$GM_ROOT_DIR/lib/hw.sh"

run() {
  net_required

  is_uefi_boot || die "This installer requires UEFI boot mode."

  for c in curl tar xz lsblk blkid sgdisk parted mkfs.ext4 mkfs.fat; do
    command -v "${c%% *}" >/dev/null 2>&1 || warn "Command not found (might still work later): $c"
  done

  log "CPU vendor: $(detect_cpu_vendor)"
  log "GPU vendor: $(detect_gpu_vendor)"
  log "RAM: $(mem_gib) GiB"
  if has_tpm2; then log "TPM2: present"; else warn "TPM2: not detected"; fi
  if secure_boot_enabled; then log "Secure Boot: enabled"; else log "Secure Boot: disabled/unknown"; fi
}

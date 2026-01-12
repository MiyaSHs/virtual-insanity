#!/usr/bin/env bash
set -euo pipefail

run() {
  systemctl enable systemd-timesyncd || true

  # Best-effort TPM auto-unlock enrollment (will fall back to passphrase)
  if [[ "$(gm_read_conf ENC)" == "luks" ]]; then
    if [[ -c /dev/tpmrm0 || -c /dev/tpm0 ]]; then
      if command -v systemd-cryptenroll >/dev/null 2>&1; then
        gm_warn "Attempting TPM enrollment for LUKS auto-unlock (best-effort)."
        systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+4 "$(gm_read_conf ROOTP)" || true
      fi
    else
      gm_warn "No TPM found; LUKS will prompt for passphrase."
    fi
  fi

  gm_ok "Finalize done."
}

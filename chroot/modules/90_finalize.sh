#!/usr/bin/env bash
set -euo pipefail
source "$GM_ROOT_DIR/lib/common.sh"

try_tpm_enroll() {
  [[ "$GM_ENCRYPTION" == "luks_tpm" ]] || return 0
  command -v systemd-cryptenroll >/dev/null 2>&1 || return 0
  [[ -b "$GM_LUKS_DEV" ]] || return 0

  log "Enrolling TPM2 key for LUKS device (stable mode)…"

  # If Secure Boot is ON, bind to PCR7 (SB state) for stronger security.
  # If Secure Boot is OFF, bind WITHOUT PCRs to avoid breakage when boot state changes.
  if mokutil --sb-state 2>/dev/null | grep -qi "enabled"; then
    systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 "$GM_LUKS_DEV" || true
  else
    systemd-cryptenroll --tpm2-device=auto --tpm2-without-pcrs "$GM_LUKS_DEV" || true
  fi

  log "TPM enroll attempted (passphrase remains as fallback)."
}

scrub_state_secrets() {
  # State file contains passwords; remove it from the installed system.
  rm -f /root/golden-master/gm.conf || true
}

run() {
  log "Finalizing system…"

  # timezone/locale are handled in base module; keep final tidy-ups here.
  try_tpm_enroll

  # Update Java flags block once more in the installed system
  if command -v gm-java-tune >/dev/null 2>&1; then
    gm-java-tune || true
  fi

  # Ensure systemd-boot doesn't wait on editor
  mkdir -p /boot/loader
  sed -i 's/^editor .*/editor no/' /boot/loader/loader.conf 2>/dev/null || true

  scrub_state_secrets

  log "Finalize done."
}

#!/usr/bin/env bash
set -euo pipefail
source "$GM_ROOT_DIR/lib/common.sh"
source "$GM_ROOT_DIR/lib/hw.sh"

try_tpm_enroll() {
  [[ "${GM_ENCRYPTION}" == "luks_tpm" ]] || return 0
  command -v systemd-cryptenroll >/dev/null 2>&1 || return 0
  [[ -b "${GM_LUKS_DEV:-}" ]] || return 0

  log "Enrolling TPM2 auto-unlock for ${GM_LUKS_DEV}…"
  if secure_boot_enabled; then
    # PCR7 is SecureBoot policy. Good if SB enabled.
    systemd-cryptenroll "${GM_LUKS_DEV}" --tpm2-device=auto --tpm2-pcrs=7 || true
  else
    # Avoid binding to fragile PCRs when SecureBoot is off.
    systemd-cryptenroll "${GM_LUKS_DEV}" --tpm2-device=auto --tpm2-without-pcrs 2>/dev/null || \
      systemd-cryptenroll "${GM_LUKS_DEV}" --tpm2-device=auto || true
  fi
}

drop_plasma_shortcuts() {
  if [[ "${GM_PROFILE}" == "plasma" || "${GM_PROFILE}" == "gamemode" ]]; then
    mkdir -p /usr/share/applications
    install -Dm644 "$GM_ROOT_DIR/files/systemd/user/gm-optimize.desktop" /usr/share/applications/gm-optimize.desktop
    # Put on Desktop for the user (best-effort)
    local desk="/home/${GM_USER}/Desktop"
    mkdir -p "$desk"
    cp -f /usr/share/applications/gm-optimize.desktop "$desk/Golden-Master-Optimize.desktop" || true
    chown -R "${GM_USER}:${GM_USER}" "$desk"
    chmod +x "$desk/Golden-Master-Optimize.desktop" || true
  fi
}

run() {
  log "Finalize…"

  # Basic QoL
  emerge --quiet-build=y sys-apps/mlocate app-shells/bash-completion || true

  try_tpm_enroll
  drop_plasma_shortcuts

  log "Finalize done."
}

#!/usr/bin/env bash
set -euo pipefail
source "$GM_ROOT_DIR/lib/common.sh"

install_units() {
  install -Dm644 "$GM_ROOT_DIR/files/systemd/system/gm-perf-profiler.service" /etc/systemd/system/gm-perf-profiler.service
  install -Dm644 "$GM_ROOT_DIR/files/systemd/system/gm-fdo-accumulate.service" /etc/systemd/system/gm-fdo-accumulate.service
  install -Dm644 "$GM_ROOT_DIR/files/systemd/system/gm-fdo-accumulate.timer" /etc/systemd/system/gm-fdo-accumulate.timer

  systemctl daemon-reload || true
  systemctl enable gm-perf-profiler.service || true
  systemctl enable gm-fdo-accumulate.timer || true
}

install_scripts() {
  install -Dm755 "$GM_ROOT_DIR/files/scripts/gm-perf-profiler" /usr/local/bin/gm-perf-profiler
  install -Dm755 "$GM_ROOT_DIR/files/scripts/gm-fdo-accumulate" /usr/local/bin/gm-fdo-accumulate
  install -Dm755 "$GM_ROOT_DIR/files/scripts/gm-optimize" /usr/local/bin/gm-optimize
  install -Dm755 "$GM_ROOT_DIR/files/scripts/gm-portage-env-apply" /usr/local/bin/gm-portage-env-apply
  install -Dm755 "$GM_ROOT_DIR/files/scripts/gm-java-tune" /usr/local/bin/gm-java-tune
  install -Dm644 "$GM_ROOT_DIR/files/scripts/gm-fdo-targets.conf" /etc/gm-fdo-targets.conf
}

install_portage_hooks() {
  install -Dm644 "$GM_ROOT_DIR/files/templates/portage-bashrc" /etc/portage/bashrc
}

run() {
  log "Setting up perf → sample-PGO (AutoFDO-style) + optional Propeller…"

  # perf tool
  emerge --quiet-build=y sys-kernel/linux-tools || true

  # ensure llvm tools exist (already installed)
  emerge --quiet-build=y sys-devel/llvm || true

  # profile storage
  mkdir -p /var/lib/gm/perf/chunks /var/lib/gm/profiles
  chmod 700 /var/lib/gm/perf/chunks /var/lib/gm/profiles

  install_scripts
  install_units
  install_portage_hooks

  # Build portage env mapping
  /usr/local/bin/gm-portage-env-apply || true

  # Ensure Java tuning block exists if Java is installed
  /usr/local/bin/gm-java-tune || true

  log "Perf/FDO pipeline installed."
}

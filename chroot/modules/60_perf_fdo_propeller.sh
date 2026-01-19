#!/usr/bin/env bash
set -euo pipefail
source "$GM_ROOT_DIR/lib/common.sh"

install_units() {
  install -Dm644 "$GM_ROOT_DIR/files/systemd/system/gm-perf-profiler.service" /etc/systemd/system/gm-perf-profiler.service
  install -Dm644 "$GM_ROOT_DIR/files/systemd/system/gm-perf-profiler.timer" /etc/systemd/system/gm-perf-profiler.timer

  install -Dm644 "$GM_ROOT_DIR/files/systemd/system/gm-fdo-accumulate.service" /etc/systemd/system/gm-fdo-accumulate.service
  install -Dm644 "$GM_ROOT_DIR/files/systemd/system/gm-fdo-accumulate.timer" /etc/systemd/system/gm-fdo-accumulate.timer

  systemctl daemon-reload || true

  # Start/stop policy should be driven by timers.
  systemctl disable gm-perf-profiler.service >/dev/null 2>&1 || true
  systemctl enable gm-perf-profiler.timer  >/dev/null 2>&1 || true
  systemctl enable gm-fdo-accumulate.timer >/dev/null 2>&1 || true
}

install_scripts() {
  install -Dm755 "$GM_ROOT_DIR/files/scripts/gm-perf-profiler" /usr/local/bin/gm-perf-profiler
  install -Dm755 "$GM_ROOT_DIR/files/scripts/gm-fdo-accumulate" /usr/local/bin/gm-fdo-accumulate
  install -Dm755 "$GM_ROOT_DIR/files/scripts/gm-optimize" /usr/local/bin/gm-optimize
  install -Dm755 "$GM_ROOT_DIR/files/scripts/gm-portage-env-apply" /usr/local/bin/gm-portage-env-apply

  if [[ "${GM_ENABLE_JAVA:-no}" == "yes" ]]; then
    install -Dm755 "$GM_ROOT_DIR/files/scripts/gm-java-tune" /usr/local/bin/gm-java-tune
  fi

  install -Dm644 "$GM_ROOT_DIR/files/scripts/gm-fdo-targets.conf" /etc/gm-fdo-targets.conf
}

install_portage_hooks() {
  install -Dm644 "$GM_ROOT_DIR/files/templates/portage-bashrc" /etc/portage/bashrc
}

run() {
  if [[ "${GM_ENABLE_PERF:-yes}" != "yes" ]]; then
    log "Perf/FDO pipeline disabled; skipping."
    return 0
  fi

  log "Setting up perf → sample-PGO (AutoFDO-style) + optional Propeller…"

  # perf tool (most Gentoo systems provide it via linux-tools)
  emerge --quiet-build=y sys-kernel/linux-tools || true

  # LLVM toolchain (prefer modern split; fall back if needed)
  emerge --quiet-build=y llvm-core/llvm llvm-core/clang llvm-core/lld >/dev/null 2>&1 || \
    emerge --quiet-build=y sys-devel/llvm sys-devel/clang sys-devel/lld || true

  # profile storage
  mkdir -p /var/lib/gm/perf/chunks /var/lib/gm/profiles
  chmod 700 /var/lib/gm/perf/chunks /var/lib/gm/profiles

  install_scripts
  install_units
  install_portage_hooks

  # Build portage env mapping (package.env / env snippets)
  /usr/local/bin/gm-portage-env-apply || true

  # Apply Java tuning if installed/enabled
  if command -v gm-java-tune >/dev/null 2>&1; then
    gm-java-tune || true
  fi

  log "Perf/FDO pipeline installed."
}

#!/usr/bin/env bash
set -euo pipefail

run() {
  # tools: perf + LLVM
  emerge --quiet-build     sys-kernel/linux-tools     sys-devel/llvm     sys-devel/clang     sys-devel/lld

  install -d /usr/local/lib/gm
  install -m 0755 "${ROOT_DIR}/files/scripts/gm-perf-profiler" /usr/local/lib/gm/gm-perf-profiler
  install -m 0755 "${ROOT_DIR}/files/scripts/gm-fdo-accumulate" /usr/local/lib/gm/gm-fdo-accumulate
  install -m 0644 "${ROOT_DIR}/files/scripts/gm-fdo-targets.conf" /etc/gm-fdo-targets.conf
  install -m 0755 "${ROOT_DIR}/files/scripts/gm-portage-env-apply" /usr/local/lib/gm/gm-portage-env-apply
  install -m 0755 "${ROOT_DIR}/files/scripts/gm-optimize" /usr/local/bin/gm-optimize

  # systemd units
  install -d /etc/systemd/system
  install -m 0644 "${ROOT_DIR}/files/systemd/system/gm-perf-profiler.service" /etc/systemd/system/gm-perf-profiler.service
  install -m 0644 "${ROOT_DIR}/files/systemd/system/gm-perf-profiler.timer"   /etc/systemd/system/gm-perf-profiler.timer
  install -m 0644 "${ROOT_DIR}/files/systemd/system/gm-fdo-accumulate.service" /etc/systemd/system/gm-fdo-accumulate.service
  install -m 0644 "${ROOT_DIR}/files/systemd/system/gm-fdo-accumulate.timer"   /etc/systemd/system/gm-fdo-accumulate.timer

  systemctl enable gm-perf-profiler.timer
  systemctl enable gm-fdo-accumulate.timer

  gm_ok "Perf/FDO/Propeller automation framework installed."
}

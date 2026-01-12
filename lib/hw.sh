#!/usr/bin/env bash
set -euo pipefail

detect_cpu_vendor() {
  if grep -qi "AuthenticAMD" /proc/cpuinfo; then echo "amd"; return; fi
  if grep -qi "GenuineIntel" /proc/cpuinfo; then echo "intel"; return; fi
  echo "unknown"
}

detect_gpu_vendor() {
  if lspci -nn | grep -qiE "VGA|3D"; then
    if lspci -nn | grep -qi "NVIDIA"; then echo "nvidia"; return; fi
    if lspci -nn | grep -qiE "AMD|ATI"; then echo "amd"; return; fi
    if lspci -nn | grep -qi "Intel"; then echo "intel"; return; fi
  fi
  echo "unknown"
}

mem_gib() {
  awk '/MemTotal/ {printf "%.0f\n", $2/1024/1024}' /proc/meminfo
}

has_tpm2() {
  [[ -c /dev/tpmrm0 || -c /dev/tpm0 ]]
}

secure_boot_enabled() {
  # On most distros this exists; in live env may not.
  if [[ -r /sys/firmware/efi/efivars/SecureBoot-* ]]; then
    # 5th byte indicates enabled (1)
    local f
    f=$(ls /sys/firmware/efi/efivars/SecureBoot-* 2>/dev/null | head -n1 || true)
    [[ -n "$f" ]] || return 1
    local v
    v=$(hexdump -v -e '1/1 "%02x"' "$f" 2>/dev/null | tail -c 2 || true)
    [[ "$v" == "01" ]]
  else
    return 1
  fi
}



has_battery() {
  ls /sys/class/power_supply/BAT* >/dev/null 2>&1
}

has_wifi() {
  # crude: any wireless interface
  ls /sys/class/net 2>/dev/null | while read -r i; do
    [[ -d "/sys/class/net/$i/wireless" ]] && exit 0
  done
  return 1
}

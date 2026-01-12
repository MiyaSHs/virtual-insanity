#!/usr/bin/env bash
set -euo pipefail

gm_detect_cpu_vendor() {
  if grep -q "GenuineIntel" /proc/cpuinfo; then echo "intel"; return; fi
  if grep -q "AuthenticAMD" /proc/cpuinfo; then echo "amd"; return; fi
  echo "unknown"
}

gm_detect_cpu_flags_x86() {
  if command -v cpuid2cpuflags >/dev/null 2>&1; then
    cpuid2cpuflags | sed 's/^CPU_FLAGS_X86: //'
    return
  fi
  awk -F': ' '/^flags/{print $2; exit}' /proc/cpuinfo | tr ' ' '\n' | sort -u | tr '\n' ' '
}

gm_detect_gpu_vendor() {
  local v
  v="$(lspci 2>/dev/null | grep -Ei 'VGA|3D|Display' || true)"
  if echo "$v" | grep -qi "NVIDIA"; then echo "nvidia"; return; fi
  if echo "$v" | grep -qi "AMD|ATI"; then echo "amd"; return; fi
  if echo "$v" | grep -qi "Intel"; then echo "intel"; return; fi
  echo "unknown"
}

gm_guess_video_cards() {
  case "$(gm_detect_gpu_vendor)" in
    amd)   echo "amdgpu radeonsi" ;;
    intel) echo "i915 iris" ;;
    nvidia) echo "nvidia" ;;
    *)     echo "" ;;
  esac
}

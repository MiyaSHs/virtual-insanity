#!/usr/bin/env bash
set -euo pipefail

gm_ask() {
  local prompt="$1" default="${2:-}"
  local ans
  if [[ -n "$default" ]]; then
    read -r -p "${prompt} [${default}]: " ans
    echo "${ans:-$default}"
  else
    read -r -p "${prompt}: " ans
    echo "$ans"
  fi
}

gm_yesno() {
  local prompt="$1" default="${2:-y}"
  local ans
  while true; do
    read -r -p "${prompt} (y/n) [${default}]: " ans
    ans="${ans:-$default}"
    case "$ans" in
      y|Y) return 0 ;;
      n|N) return 1 ;;
      *) echo "Please answer y or n." ;;
    esac
  done
}

gm_menu() {
  local title="$1"; shift
  local -a items=("$@")
  echo
  echo "$title"
  local i=1
  for it in "${items[@]}"; do
    echo "  $i) $it"
    i=$((i+1))
  done
  local choice
  while true; do
    read -r -p "Select [1-${#items[@]}]: " choice
    [[ "$choice" =~ ^[0-9]+$ ]] || continue
    (( choice>=1 && choice<=${#items[@]} )) || continue
    echo "${items[$((choice-1))]}"
    return 0
  done
}

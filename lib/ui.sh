#!/usr/bin/env bash
set -euo pipefail

# Simple TUI helpers (whiptail if available, fallback to select).

have_whiptail() { command -v whiptail >/dev/null 2>&1; }

ui_menu() {
  local title="$1"; shift
  local prompt="$1"; shift
  local -a items=("$@") # pairs: key label key label ...

  if have_whiptail; then
    local choice
    choice=$(whiptail --title "$title" --menu "$prompt" 20 90 10 "${items[@]}" 3>&1 1>&2 2>&3) || return 1
    echo "$choice"
  else
    echo "$title"
    echo "$prompt"
    local -a keys=()
    local i=0
    while [[ $i -lt ${#items[@]} ]]; do
      keys+=("${items[$i]}")
      i=$((i+2))
    done
    PS3="Select: "
    select opt in "${keys[@]}"; do
      [[ -n "${opt:-}" ]] && { echo "$opt"; return 0; }
    done
  fi
}

ui_yesno() {
  local title="$1" prompt="$2" default="${3:-yes}"
  if have_whiptail; then
    local def=0
    [[ "$default" == "no" ]] && def=1
    if whiptail --title "$title" --yesno "$prompt" 12 80; then
      return 0
    else
      return 1
    fi
  else
    local ans
    read -r -p "$prompt [y/N]: " ans
    [[ "${ans,,}" =~ ^y(es)?$ ]]
  fi
}

ui_input() {
  local title="$1" prompt="$2" default="${3:-}"
  if have_whiptail; then
    whiptail --title "$title" --inputbox "$prompt" 12 80 "$default" 3>&1 1>&2 2>&3
  else
    read -r -p "$prompt [$default]: " ans
    echo "${ans:-$default}"
  fi
}

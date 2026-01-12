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
    local args=()
    [[ "$default" == "no" ]] && args+=(--defaultno)
    whiptail --title "$title" "${args[@]}" --yesno "$prompt" 12 80
  else
    local ans
    if [[ "$default" == "yes" ]]; then
      read -r -p "$prompt [Y/n]: " ans
      [[ -z "${ans:-}" || "${ans,,}" =~ ^y(es)?$ ]]
    else
      read -r -p "$prompt [y/N]: " ans
      [[ "${ans,,}" =~ ^y(es)?$ ]]
    fi
  fi
}

ui_input() {
  local title="$1" prompt="$2" default="${3:-}"
  if have_whiptail; then
    whiptail --title "$title" --inputbox "$prompt" 12 80 "$default" 3>&1 1>&2 2>&3
  else
    local ans
    read -r -p "$prompt [$default]: " ans
    echo "${ans:-$default}"
  fi
}

ui_checklist() {
  local title="$1"; shift
  local prompt="$1"; shift
  local height="${1:-20}"; shift || true
  local width="${1:-90}"; shift || true
  local list_height="${1:-12}"; shift || true
  local -a items=("$@") # triples: tag label on/off ...

  if have_whiptail; then
    local out
    out=$(whiptail --title "$title" --checklist "$prompt" "$height" "$width" "$list_height" "${items[@]}" 3>&1 1>&2 2>&3) || return 1
    # whiptail returns quoted items, e.g. "a" "b"
    echo "$out" | tr -d '"'
  else
    echo "$title"
    echo "$prompt"
    echo "Enter space-separated tags to enable (e.g. openjdk-bin rust-bin):"
    local ans
    read -r ans
    echo "$ans"
  fi
}

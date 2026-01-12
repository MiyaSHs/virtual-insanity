#!/usr/bin/env bash
set -euo pipefail

# Convenience wrapper if you want: curl -fsSL <raw>/bootstrap.sh | bash
REPO_URL_DEFAULT="https://github.com/YOU/golden-master.git"
REPO_URL="${REPO_URL:-$REPO_URL_DEFAULT}"
DIR="${DIR:-golden-master}"

if ! command -v git >/dev/null 2>&1; then
  echo "git not found. Install git in the live environment first."
  exit 1
fi

rm -rf "$DIR"
git clone "$REPO_URL" "$DIR"
cd "$DIR"
exec bash install.sh

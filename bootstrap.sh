#!/usr/bin/env bash
set -euo pipefail

# Minimal "curl | bash" bootstrap (optional).
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<you>/golden-master/main/bootstrap.sh | bash
#
# This script will clone the repo to /tmp and run install.sh.
# You can also just `git clone` and run `bash install.sh`.

REPO_URL="${REPO_URL:-https://github.com/<you>/golden-master.git}"
DEST="${DEST:-/tmp/golden-master}"

if ! command -v git >/dev/null 2>&1; then
  echo "git is required in the live environment. Install it first." >&2
  exit 1
fi

rm -rf "$DEST"
git clone --depth 1 "$REPO_URL" "$DEST"
cd "$DEST"
exec bash install.sh

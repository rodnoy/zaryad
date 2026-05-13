#!/usr/bin/env bash
# Usage: update-cask.sh <version> <sha256> <github_owner>
set -euo pipefail

VERSION="${1:?version required}"
SHA256="${2:?sha256 required}"
OWNER="${3:?github owner required}"

CASK_FILE="Casks/zaryad.rb"

if [ ! -f "$CASK_FILE" ]; then
  echo "Error: $CASK_FILE not found" >&2
  exit 1
fi

# macOS sed in-place
sed -i '' "s|version \".*\"|version \"${VERSION}\"|" "$CASK_FILE"
sed -i '' "s|sha256 \".*\"|sha256 \"${SHA256}\"|" "$CASK_FILE"
sed -i '' "s|url \".*\"|url \"https://github.com/${OWNER}/zaryad/releases/download/v${VERSION}/Zaryad-${VERSION}-universal.dmg\"|" "$CASK_FILE"

echo "Updated $CASK_FILE to version ${VERSION}"

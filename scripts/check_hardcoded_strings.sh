#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PATTERN='Text\("[^"]*[[:space:]][^"]*"\)|Text\("[^"]*[A-Z][^"]*"\)|Button\("[^"]*[[:space:]][^"]*"\)|Button\("[^"]*[A-Z][^"]*"\)|\.alert\("[^"]*[[:space:]][^"]*"|\.alert\("[^"]*[A-Z][^"]*"|TextField\("[^"]*[[:space:]][^"]*"\)|TextField\("[^"]*[A-Z][^"]*"\)|navigationTitle\("[^"]*[[:space:]][^"]*"\)|navigationTitle\("[^"]*[A-Z][^"]*"\)'

if ! command -v rg >/dev/null 2>&1; then
  echo "ripgrep (rg) is required" >&2
  exit 2
fi

set +e
matches=$(rg -n "$PATTERN" "$ROOT_DIR/Sources/Presentation" --glob '*.swift')
status=$?
set -e

if [[ $status -eq 0 ]]; then
  set +e
  filtered=$(printf '%s\n' "$matches" | rg -v 'Text\("⚡"\)|Text\("0"\)|Text\("\\\(.*"\)|Text\("-\\\(.*"\)|Text\("[a-z0-9]+([._][a-z0-9]+)*"\)|Button\("[a-z0-9]+([._][a-z0-9]+)*"\)|\.alert\("[a-z0-9]+([._][a-z0-9]+)*"|TextField\("[a-z0-9]+([._][a-z0-9]+)*"\)|navigationTitle\("[a-z0-9]+([._][a-z0-9]+)*"\)')
  set -e
  if [[ -n "${filtered}" ]]; then
    echo "Found likely hardcoded user-facing strings in Sources/Presentation:" >&2
    printf '%s\n' "$filtered" >&2
    exit 1
  fi
fi

echo "Hardcoded string check passed"

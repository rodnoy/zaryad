#!/usr/bin/env bash
set -euo pipefail

# Simple release packager for local use.
# Builds the Swift package in release configuration and produces a tar.gz from .build/release

echo "Building Swift package (release)..."
swift build -c release

TS=$(date +%Y%m%d%H%M%S)
OUT=charger-monitor-release-${TS}.tar.gz
if [ -d .build/release ]; then
  tar -czf "$OUT" .build/release
  echo "Packaged: $OUT"
else
  echo "Warning: .build/release not found. Packaging whole repo (not recommended)."
  tar -czf "$OUT" .
  echo "Packaged: $OUT"
fi

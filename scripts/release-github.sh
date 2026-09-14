#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
TAG="v$VERSION"
DMG_PATH="$ROOT_DIR/dist/PromptDock-$VERSION.dmg"

if [[ ! -f "$DMG_PATH" ]]; then
  "$ROOT_DIR/scripts/create-dmg.sh"
fi

gh release create "$TAG" "$DMG_PATH" \
  --repo sukeesh/promptdock \
  --title "PromptDock $VERSION" \
  --notes "Initial public release of PromptDock, a fast native macOS menu bar app for reusable AI prompts."

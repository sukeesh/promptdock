#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
APP_NAME="PromptDock"
RELEASE_DIR="$ROOT_DIR/dist"
APP_DIR="$RELEASE_DIR/$APP_NAME.app"
STAGING_DIR="$RELEASE_DIR/dmg"
DMG_PATH="$RELEASE_DIR/$APP_NAME-$VERSION.dmg"

if [[ ! -d "$APP_DIR" ]]; then
  "$ROOT_DIR/scripts/build-release.sh"
fi

rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR"

cp -R "$APP_DIR" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$STAGING_DIR"

echo "$DMG_PATH"

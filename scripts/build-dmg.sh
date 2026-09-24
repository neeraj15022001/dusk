#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)"
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  printf 'Expected a numeric X.Y.Z app version, got %s\n' "$VERSION" >&2
  exit 1
fi

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dusk-dmg.XXXXXX")"
MOUNT_PATH="$WORK_DIR/mounted"
MOUNTED=0
cleanup() {
  if [[ "$MOUNTED" == 1 ]]; then
    hdiutil detach "$MOUNT_PATH" || return
  fi
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

# Build each slice through the normal app builder, preserving its SDK options.
for ARCH in arm64 x86_64; do
  bash scripts/build-app.sh "$@" --arch "$ARCH"
  cp dist/Dusk.app/Contents/MacOS/Dusk "$WORK_DIR/Dusk-$ARCH"
done
lipo -create "$WORK_DIR/Dusk-arm64" "$WORK_DIR/Dusk-x86_64" -output dist/Dusk.app/Contents/MacOS/Dusk
for ARCH in arm64 x86_64; do
  lipo dist/Dusk.app/Contents/MacOS/Dusk -verify_arch "$ARCH"
done
codesign --force --sign - dist/Dusk.app
codesign --verify --deep --strict dist/Dusk.app

STAGING_PATH="$WORK_DIR/staging"
mkdir -p "$STAGING_PATH" "$MOUNT_PATH"
ditto dist/Dusk.app "$STAGING_PATH/Dusk.app"
ln -s /Applications "$STAGING_PATH/Applications"
cp docs/INSTALL.txt "$STAGING_PATH/Read Me.txt"

DMG_NAME="Dusk-$VERSION-universal.dmg"
DMG_PATH="$PWD/dist/$DMG_NAME"
hdiutil create -volname "Dusk $VERSION" -srcfolder "$STAGING_PATH" -fs HFS+ -format UDZO -ov "$DMG_PATH"
hdiutil verify "$DMG_PATH"

# Check the actual distributed bundle, not only the staging directory.
hdiutil attach "$DMG_PATH" -readonly -nobrowse -mountpoint "$MOUNT_PATH"
MOUNTED=1
codesign --verify --deep --strict "$MOUNT_PATH/Dusk.app"
for ARCH in arm64 x86_64; do
  lipo "$MOUNT_PATH/Dusk.app/Contents/MacOS/Dusk" -verify_arch "$ARCH"
done
cmp LICENSE "$MOUNT_PATH/Dusk.app/Contents/Resources/LICENSE"
cmp THIRD_PARTY_NOTICES.md "$MOUNT_PATH/Dusk.app/Contents/Resources/THIRD_PARTY_NOTICES.md"
cmp Resources/Info.plist "$MOUNT_PATH/Dusk.app/Contents/Info.plist"
[[ "$(readlink "$MOUNT_PATH/Applications")" == /Applications ]]
cmp docs/INSTALL.txt "$MOUNT_PATH/Read Me.txt"
hdiutil detach "$MOUNT_PATH"
MOUNTED=0

(cd dist && shasum -a 256 "$DMG_NAME" > "$DMG_NAME.sha256")
printf 'Verified %s and SHA-256 checksum\n' "$DMG_PATH"

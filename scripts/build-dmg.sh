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

# Compile each architecture once; reuse those exact slices for all three packages.
for ARCH in arm64 x86_64; do
  bash scripts/build-app.sh "$@" --arch "$ARCH"
  cp dist/Dusk.app/Contents/MacOS/Dusk "$WORK_DIR/Dusk-$ARCH"
done
lipo -create "$WORK_DIR/Dusk-arm64" "$WORK_DIR/Dusk-x86_64" -output "$WORK_DIR/Dusk-universal"

verify_architectures() {
  local binary="$1" flavor="$2" actual expected
  actual="$(lipo -archs "$binary" | tr ' ' '\n' | sort | xargs)"
  expected="$flavor"
  if [[ "$flavor" == universal ]]; then expected='arm64 x86_64'; fi
  if [[ "$actual" != "$expected" ]]; then
    printf 'Architecture mismatch: expected %s, found %s\n' "$expected" "$actual" >&2
    return 1
  fi
}

mkdir -p "$MOUNT_PATH"
for FLAVOR in arm64 x86_64 universal; do
  cp "$WORK_DIR/Dusk-$FLAVOR" dist/Dusk.app/Contents/MacOS/Dusk
  verify_architectures dist/Dusk.app/Contents/MacOS/Dusk "$FLAVOR"
  codesign --force --sign - dist/Dusk.app
  codesign --verify --deep --strict dist/Dusk.app

  STAGING_PATH="$WORK_DIR/staging-$FLAVOR"
  mkdir -p "$STAGING_PATH"
  ditto dist/Dusk.app "$STAGING_PATH/Dusk.app"
  ln -s /Applications "$STAGING_PATH/Applications"
  cp docs/INSTALL.txt "$STAGING_PATH/Read Me.txt"

  DMG_NAME="Dusk-$VERSION-$FLAVOR.dmg"
  DMG_PATH="$PWD/dist/$DMG_NAME"
  hdiutil create -volname "Dusk $VERSION $FLAVOR" -srcfolder "$STAGING_PATH" -fs HFS+ -format UDZO -ov "$DMG_PATH"
  hdiutil verify "$DMG_PATH"

  # Inspect the distributed bundle, including exact architecture and icon identity.
  hdiutil attach "$DMG_PATH" -readonly -nobrowse -mountpoint "$MOUNT_PATH"
  MOUNTED=1
  codesign --verify --deep --strict "$MOUNT_PATH/Dusk.app"
  verify_architectures "$MOUNT_PATH/Dusk.app/Contents/MacOS/Dusk" "$FLAVOR"
  cmp LICENSE "$MOUNT_PATH/Dusk.app/Contents/Resources/LICENSE"
  cmp THIRD_PARTY_NOTICES.md "$MOUNT_PATH/Dusk.app/Contents/Resources/THIRD_PARTY_NOTICES.md"
  cmp Resources/AppIcon.icns "$MOUNT_PATH/Dusk.app/Contents/Resources/AppIcon.icns"
  cmp Resources/Info.plist "$MOUNT_PATH/Dusk.app/Contents/Info.plist"
  [[ "$(readlink "$MOUNT_PATH/Applications")" == /Applications ]]
  cmp docs/INSTALL.txt "$MOUNT_PATH/Read Me.txt"
  hdiutil detach "$MOUNT_PATH"
  MOUNTED=0

  (cd dist && shasum -a 256 "$DMG_NAME" > "$DMG_NAME.sha256")
  printf 'Verified %s and SHA-256 checksum\n' "$DMG_PATH"
done

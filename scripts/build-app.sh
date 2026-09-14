#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
# Forward optional SwiftPM flags (for example, --sdk) consistently to both calls.
swift build -c release --product Dusk --scratch-path .build --disable-sandbox "$@"
BIN_DIR="$(swift build -c release --scratch-path .build --disable-sandbox --show-bin-path "$@")"
APP_PATH="$PWD/dist/Dusk.app"
mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"
cp "$BIN_DIR/Dusk" "$APP_PATH/Contents/MacOS/Dusk"
cp Resources/Info.plist "$APP_PATH/Contents/Info.plist"
cp LICENSE THIRD_PARTY_NOTICES.md "$APP_PATH/Contents/Resources/"
codesign --force --sign - "$APP_PATH"
printf 'Built %s\n' "$APP_PATH"

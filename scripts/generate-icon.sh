#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
ICONSET="$PWD/.build/icons/AppIcon.iconset"
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
swift scripts/draw-icon.swift "$ICONSET"
iconutil -c icns "$ICONSET" -o Resources/AppIcon.icns
cp "$ICONSET/icon_512x512@2x.png" Resources/AppIcon.png
printf 'Generated Resources/AppIcon.icns and preview PNG\n'

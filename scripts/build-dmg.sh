#!/usr/bin/env bash
# Builds a release .app bundle and packages it as a DMG.
# Usage: ./scripts/build-dmg.sh [version]
#   version defaults to the output of `git describe --tags --abbrev=0` or "dev"
set -euo pipefail

VERSION="${1:-$(git describe --tags --abbrev=0 2>/dev/null || echo "dev")}"
APP_NAME="MacSesh"
BUNDLE="${APP_NAME}.app"
DMG_NAME="mac-sesh-${VERSION}.dmg"
STAGING="$(mktemp -d)/dmg-staging"

echo "→ Building release binary…"
swift build -c release

echo "→ Assembling ${BUNDLE}…"
rm -rf "${BUNDLE}"
mkdir -p "${BUNDLE}/Contents/MacOS"
mkdir -p "${BUNDLE}/Contents/Resources"

cp ".build/release/${APP_NAME}" "${BUNDLE}/Contents/MacOS/"
cp "Resources/Info.plist"       "${BUNDLE}/Contents/"

echo "→ Ad-hoc code signing…"
codesign --force --deep --sign - "${BUNDLE}"

echo "→ Creating DMG…"
mkdir -p "${STAGING}"
cp -R "${BUNDLE}" "${STAGING}/"
# Symlink to /Applications so users can drag-install
ln -s /Applications "${STAGING}/Applications"

hdiutil create \
    -volname "mac-sesh ${VERSION}" \
    -srcfolder "${STAGING}" \
    -ov -format UDZO \
    "${DMG_NAME}"

rm -rf "${BUNDLE}" "${STAGING}"

echo "✓ ${DMG_NAME}"

#!/usr/bin/env bash
# Builds MacSesh and installs it to /Applications.
set -euo pipefail

APP_NAME="MacSesh"
BUNDLE="${APP_NAME}.app"
DEST="/Applications/${BUNDLE}"

echo "→ Building release binary…"
swift build -c release

echo "→ Assembling ${BUNDLE}…"
rm -rf "${BUNDLE}"
mkdir -p "${BUNDLE}/Contents/MacOS"
mkdir -p "${BUNDLE}/Contents/Resources"

cp ".build/release/${APP_NAME}" "${BUNDLE}/Contents/MacOS/"
cp "Resources/Info.plist"       "${BUNDLE}/Contents/"
[ -f "Resources/AppIcon.icns" ] && cp "Resources/AppIcon.icns" "${BUNDLE}/Contents/Resources/"

echo "→ Ad-hoc code signing…"
codesign --force --deep --sign - "${BUNDLE}"

echo "→ Installing to ${DEST}…"
if [ -w "/Applications" ]; then
    cp -R "${BUNDLE}" "${DEST}"
else
    sudo cp -R "${BUNDLE}" "${DEST}"
fi

rm -rf "${BUNDLE}"

echo "✓ MacSesh installed to ${DEST}"
echo ""
echo "Note: To launch at login, open MacSesh, click the menubar icon, and toggle"
echo "\"Launch at Login\". Or add it manually in System Settings → General → Login Items."

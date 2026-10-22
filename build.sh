#!/bin/bash
# Compila NotBar y genera build/NotBar.app.
# Uso: ./build.sh          -> solo compila
#      ./build.sh install  -> compila y copia a /Applications
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release
BIN="$(swift build -c release --show-bin-path)/NotBar"

APP="build/NotBar.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/NotBar"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

# Firma ad hoc por defecto; exporta SIGN_IDENTITY="Apple Development: ..." para usar tu certificado.
codesign --force --sign "${SIGN_IDENTITY:--}" "$APP"
echo "Listo: $APP"

rm -f build/NotBar.zip
ditto -c -k --keepParent "$APP" build/NotBar.zip
echo "Listo: build/NotBar.zip"

if [[ "${1:-}" == "install" ]]; then
    pkill -x NotBar 2>/dev/null || true
    rm -rf /Applications/NotBar.app
    cp -R "$APP" /Applications/
    echo "Instalado en /Applications/NotBar.app"
    open /Applications/NotBar.app
fi

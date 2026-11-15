#!/bin/bash
# Compila SbuSeasons in versione ottimizzata e la impacchetta come SbuSeasons.app.
set -euo pipefail
cd "$(dirname "$0")"

# 1. Compila per Apple Silicon e Intel insieme ("universal").
swift build -c release --arch arm64 --arch x86_64

# 2. Una .app è solo una cartella con questa struttura.
APP=SbuSeasons.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/SbuSeasons" "$APP/Contents/MacOS/"
cp Info.plist "$APP/Contents/"

# 3. Firma. Se c'è un certificato "Apple Development" (Xcode lo crea con il tuo Apple ID) usiamo quello:
#    la firma resta uguale tra un build e l'altro e macOS non dimentica il permesso Accessibilità.
#    Altrimenti firma "ad-hoc" (il trattino): funziona, ma il permesso va ridato dopo ogni build.
#    Se ce n'è più d'uno, prendiamo sempre lo stesso (ordinati): macOS non li elenca in ordine fisso,
#    e cambiare certificato farebbe perdere di nuovo il permesso.
IDENTITY=$(security find-identity -v -p codesigning | awk '/Apple Development/ {print $2}' | sort | head -1)
codesign --force --sign "${IDENTITY:--}" "$APP"
echo "Firmata con: ${IDENTITY:-ad-hoc}"

echo "Fatto: $APP  →  open $APP  (oppure trascinala in /Applicazioni)"

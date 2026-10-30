#!/usr/bin/env bash
# One-time setup: generates the native Android & iOS projects around the
# Dart code, then applies the Uttaranchal app name, icon and splash screen.
# Usage (macOS / Linux):   chmod +x setup.sh && ./setup.sh
set -euo pipefail
cd "$(dirname "$0")"

command -v flutter >/dev/null || { echo "Flutter is not installed or not on PATH. See README.md"; exit 1; }

echo "▸ Generating android/ and ios/ (existing Dart files are kept)…"
flutter create . --project-name uttaranchal_app --org com.uttaranchal.dairy --platforms=android,ios

echo "▸ Fetching packages…"
flutter pub get

echo "▸ Setting the display name to 'Uttaranchal'…"
MANIFEST=android/app/src/main/AndroidManifest.xml
PLIST=ios/Runner/Info.plist
if [[ "$OSTYPE" == darwin* ]]; then SED=(sed -i ''); else SED=(sed -i); fi
"${SED[@]}" 's/android:label="[^"]*"/android:label="Uttaranchal"/' "$MANIFEST"
"${SED[@]}" '/<key>CFBundleDisplayName<\/key>/{n;s/<string>.*<\/string>/<string>Uttaranchal<\/string>/;}' "$PLIST"

echo "▸ Generating launcher icons & splash screen…"
dart run flutter_launcher_icons
dart run flutter_native_splash:create

echo
echo "✔ Done. Plug in a phone (or start an emulator/simulator) and run:"
echo "     flutter run --release"

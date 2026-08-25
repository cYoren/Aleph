#!/usr/bin/env bash
# Capture Aleph store screenshots on an iOS simulator.
#
# No UI automation needed: lib/features/startup/startup_gate_screen.dart reads a
# START dart-define and routes straight to a screen in debug builds, the same
# escape hatch Cirdoku, Tessera and Binar.io use.
#
#   START=/reading    the interlinear reader
#   START=/search     search
#   START=/bookmarks  saved passages
#   START=/settings   settings
#   START=/language   the language picker (also the real first-run screen)
#
# Usage:  scripts/capture_store_screenshots.sh [UDID]
# Output: screenshots/aso-refresh/raw/*.png at the device's native size.
set -uo pipefail

FLUTTER_HOME="${FLUTTER_HOME:-$HOME/development/flutter}"
[ -x "$FLUTTER_HOME/bin/flutter" ] && export PATH="$FLUTTER_HOME/bin:$PATH"
echo "using flutter: $(command -v flutter)"

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE=com.originalbible.originalBible
APP="$APP_DIR/build/ios/iphonesimulator/Runner.app"
OUT="$APP_DIR/screenshots/aso-refresh/raw"
UDID="${1:-2F111968-E761-42EA-A17F-ADDD591E9E8B}"   # iPhone 17 Pro Max

mkdir -p "$OUT"
cd "$APP_DIR"

xcrun simctl boot "$UDID" >/dev/null 2>&1
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1
# Device locale drives the app's own language, not just the status bar.
xcrun simctl spawn "$UDID" defaults write "Apple Global Domain" AppleLanguages -array "en-US" >/dev/null 2>&1
xcrun simctl spawn "$UDID" defaults write "Apple Global Domain" AppleLocale -string "en_US" >/dev/null 2>&1

capture() {
  local route="$1" name="$2"
  echo "==> START=$route"
  flutter build ios --simulator --debug --no-codesign \
    --dart-define=START="$route" >/dev/null 2>&1 \
    || { echo "    BUILD FAILED"; return 1; }

  xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1
  # iOS bakes a "< AppName" back indicator into the status bar when one app
  # launches over another. Terminate the neighbours so it never appears.
  for b in com.medhub.cirdoku com.medhub.magisquare com.medhub.binario com.hexasweeper.hexasweeper; do
    xcrun simctl terminate "$UDID" "$b" >/dev/null 2>&1
  done
  xcrun simctl uninstall "$UDID" "$BUNDLE" >/dev/null 2>&1
  xcrun simctl install "$UDID" "$APP" >/dev/null 2>&1 || { echo "    INSTALL FAILED"; return 1; }
  xcrun simctl launch "$UDID" "$BUNDLE" >/dev/null 2>&1
  sleep 15
  xcrun simctl io "$UDID" screenshot "$OUT/$name.png" >/dev/null 2>&1 && echo "    -> $name.png"
}

capture /reading   01_reading
capture /search    02_search
capture /bookmarks 03_bookmarks
capture /language  04_language

echo
for f in "$OUT"/*.png; do
  [ -e "$f" ] || continue
  printf '  %s  %s\n' "$(sips -g pixelWidth -g pixelHeight "$f" 2>/dev/null | awk '/pixel/{printf "%sx",$2}' | sed 's/x$//')" "$(basename "$f")"
done
echo
echo "Then compose:  python3 scripts/compose_store_screenshots.py"

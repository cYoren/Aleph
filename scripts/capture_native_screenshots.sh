#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$REPO_ROOT"
BUNDLE_ID="com.originalbible.originalBible"
OUTPUT_DIR="$REPO_ROOT/store-screenshots"
APP_PATH="$APP_DIR/build/ios/iphonesimulator/Runner.app"
VALIDATOR="$REPO_ROOT/scripts/validate_native_screenshots.py"

cd "$APP_DIR"
if [ -f scripts/build_full_bible_db.py ] && [ ! -f assets/bible.db ]; then
  mkdir -p build
  python3 scripts/build_full_bible_db.py --output assets/bible.db --cache-dir /tmp/original_bible_db_cache --strict-coverage --fill-kjv-gaps --emit-coverage-report build/coverage_report.json
fi
flutter pub get
flutter build ios --simulator --debug --no-codesign

test -d "$APP_PATH"
test -f "$VALIDATOR"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
DEVICES_JSON="$(mktemp)"
trap 'rm -f "$DEVICES_JSON"' EXIT
xcrun simctl list devices available -j > "$DEVICES_JSON"

select_device() {
  python3 - "$DEVICES_JSON" "$1" <<'PY'
import json
import sys
kind = sys.argv[2]
payload = json.load(open(sys.argv[1]))
all_devices = [
    device
    for group in payload.get("devices", {}).values()
    for device in group
    if device.get("isAvailable")
]
if kind == "phone":
    preferred = ["iPhone 17 Pro Max", "iPhone 17 Pro", "iPhone 16 Pro Max", "iPhone 15 Pro Max", "iPhone 14 Pro Max"]
    candidates = [d for d in all_devices if d.get("name", "").startswith("iPhone")]
else:
    preferred = ["iPad Pro 13-inch (M5)", "iPad Pro 13-inch", "iPad Pro 12.9-inch (6th generation)", "iPad Pro 11-inch (M5)"]
    candidates = [d for d in all_devices if d.get("name", "").startswith("iPad")]
for name in preferred:
    matches = [d for d in candidates if d.get("name") == name]
    if matches:
        print(matches[-1]["udid"])
        raise SystemExit
if not candidates:
    raise SystemExit(f"No available {kind} simulator")
print(sorted(candidates, key=lambda d: d.get("name", ""))[-1]["udid"])
PY
}

capture() {
  local device_name="$1"
  local udid="$2"
  local filename="$3"
  local output="$OUTPUT_DIR/$filename"
  local baseline="$OUTPUT_DIR/.baseline-$filename"
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b
  xcrun simctl io "$udid" screenshot "$baseline"
  xcrun simctl install "$udid" "$APP_PATH"
  xcrun simctl launch "$udid" "$BUNDLE_ID"
  sleep 12
  xcrun simctl io "$udid" screenshot "$output"
  python3 "$VALIDATOR" "$output" --baseline "$baseline"
  rm -f "$baseline"
  xcrun simctl shutdown "$udid" || true
  printf 'Captured and validated %s -> %s\n' "$device_name" "$output"
}

capture "phone" "$(select_device phone)" "iphone-native.png"
capture "tablet" "$(select_device tablet)" "ipad-native.png"
file "$OUTPUT_DIR"/*.png
printf '\nNative screenshots passed the content gate. Review them before any composition or upload.\n'

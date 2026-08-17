#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$REPO_ROOT"
BUNDLE_ID="com.originalbible.originalBible"
OUTPUT_DIR="$REPO_ROOT/store-screenshots"
APP_PATH="$APP_DIR/build/ios/iphonesimulator/Runner.app"
cd "$APP_DIR"
if [ -f scripts/build_full_bible_db.py ] && [ ! -f assets/bible.db ]; then
  mkdir -p build
  python3 scripts/build_full_bible_db.py --output assets/bible.db --cache-dir /tmp/original_bible_db_cache --strict-coverage --fill-kjv-gaps --emit-coverage-report build/coverage_report.json
fi
flutter pub get
flutter build ios --simulator --debug --no-codesign
rm -rf "$OUTPUT_DIR"; mkdir -p "$OUTPUT_DIR"
DEVICES_JSON="$(xcrun simctl list devices available -j)"
read_device() {
  python3 - "$1" "$DEVICES_JSON" <<'PY'
import json, sys
wanted=sys.argv[1]; payload=json.loads(sys.argv[2])
ids=[d['udid'] for group in payload.get('devices',{}).values() for d in group if d.get('isAvailable') and d.get('name')==wanted]
if not ids: raise SystemExit(f'No available simulator named: {wanted}')
print(ids[-1])
PY
}
capture() {
  local name="$1"; local udid="$2"; local output="$OUTPUT_DIR/$3"
  xcrun simctl boot "$udid" 2>/dev/null || true; xcrun simctl bootstatus "$udid" -b
  xcrun simctl install "$udid" "$APP_PATH"; xcrun simctl launch "$udid" "$BUNDLE_ID"; sleep 12
  xcrun simctl io "$udid" screenshot "$output"; xcrun simctl shutdown "$udid" || true
  echo "Captured $name -> $output"
}
capture "iPhone 15 Pro Max" "$(read_device 'iPhone 15 Pro Max')" "iphone-67.png"
capture "iPhone 11 Pro Max" "$(read_device 'iPhone 11 Pro Max')" "iphone-65.png"
capture "iPad Pro (12.9-inch) (6th generation)" "$(read_device 'iPad Pro (12.9-inch) (6th generation)')" "ipad-129.png"
file "$OUTPUT_DIR"/*.png
printf '\nCommit temporarily and push:\n  git add store-screenshots && git commit -m "capture native Aleph screenshots" && git push origin main\n'

#!/usr/bin/env bash
# Push the store listings in fastlane/metadata to App Store Connect and Google
# Play. Dry run by default (plans the ASC change, validates the Play edit and
# throws it away); pass --apply to write.
#
#   ./scripts/push_store_listings.sh            # dry run
#   ./scripts/push_store_listings.sh --apply    # ASC draft + Play listing
#
# ASC writes into the given version's draft, so nothing is public until that
# version is submitted. Play listing text goes live once the edit commits.
set -euo pipefail

APP_ID="6758858816"                           # App Store Connect
PACKAGE="com.originalbible.original_bible"    # Google Play
VERSION="${VERSION:-$(grep -m1 '^version:' pubspec.yaml | sed -E 's/version: *([^+]+).*/\1/')}"
APPLY=false
[[ "${1:-}" == "--apply" ]] && APPLY=true
export GPLAY_NO_UPDATE=1

cd "$(dirname "$0")/.."
META=fastlane/metadata
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "== App Store Connect, version $VERSION"
python3 - "$META" "$WORK/asc" "$VERSION" <<'PY'
import json, pathlib, sys
meta, out, version = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]), sys.argv[3]
for loc_dir in sorted(p for p in meta.iterdir() if p.is_dir() and p.name not in ("android", "review_information")):
    r = lambda f: (loc_dir / f).read_text(encoding="utf-8").strip()
    (out / "app-info").mkdir(parents=True, exist_ok=True)
    (out / "version" / version).mkdir(parents=True, exist_ok=True)
    (out / "app-info" / f"{loc_dir.name}.json").write_text(json.dumps(
        {"name": r("name.txt"), "subtitle": r("subtitle.txt"), "privacyPolicyUrl": r("privacy_url.txt")},
        ensure_ascii=False))
    (out / "version" / version / f"{loc_dir.name}.json").write_text(json.dumps(
        {"description": r("description.txt"), "keywords": r("keywords.txt"),
         "promotionalText": r("promotional_text.txt"), "supportUrl": r("support_url.txt"),
         "whatsNew": r("release_notes.txt")},
        ensure_ascii=False))
PY
(
  cd "$WORK"
  asc metadata plan --app "$APP_ID" --version "$VERSION" --platform IOS --dir ./asc > plan.json
  python3 -c "import json;p=json.load(open('plan.json'))['plan'];print({k:len(v) for k,v in p.items() if isinstance(v,list)})"
  if $APPLY; then
    asc metadata approve --review-dir .asc/metadata/review --all > /dev/null
    asc metadata apply --app "$APP_ID" --version "$VERSION" --platform IOS \
      --dir ./asc --review-dir .asc/metadata/review --confirm > /dev/null
    echo "ASC: applied to the $VERSION draft"
  fi
)

echo "== Google Play"
EDIT="$(gplay edits create --package "$PACKAGE" --output json | python3 -c 'import json,sys;print(json.load(sys.stdin)["id"])')"
for dir in "$META"/android/*/; do
  locale="$(basename "$dir")"
  gplay listings update --package "$PACKAGE" --edit "$EDIT" --locale "$locale" \
    --title "$(cat "$dir/title.txt")" \
    --short-description "$(cat "$dir/short_description.txt")" \
    --full-description "$(cat "$dir/full_description.txt")" > /dev/null
  echo "  $locale"
done
gplay edits validate --package "$PACKAGE" --edit "$EDIT" > /dev/null
if $APPLY; then
  gplay edits commit --package "$PACKAGE" --edit "$EDIT" > /dev/null
  echo "Play: committed"
else
  gplay edits delete --package "$PACKAGE" --edit "$EDIT" --confirm > /dev/null
  echo "Play: validated, discarded (dry run)"
fi

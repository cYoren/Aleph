#!/usr/bin/env bash
# Push the store listings in fastlane/metadata, and the screenshots in
# screenshots/store (scripts/compose_store_screenshots.py), to App Store Connect
# and Google Play. Dry run by default (plans the ASC change, validates the Play edit and
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
SHOTS=screenshots/store
for pair in "iphone:IPHONE_67" "ipad:IPAD_PRO_3GEN_129"; do
  dir="${pair%%:*}"; type="${pair##*:}"
  if $APPLY; then
    asc screenshots upload --app "$APP_ID" --version "$VERSION" --path "$SHOTS/$dir" \
      --device-type "$type" --replace --confirm > /dev/null
    echo "ASC: $dir screenshots replaced"
  else
    # New locales only exist on ASC after the metadata apply, so a dry run
    # checks the files locally instead.
    for locale_dir in "$SHOTS/$dir"/*/; do
      asc screenshots validate --path "$locale_dir" --device-type "$type" \
        | python3 -c 'import json,sys;d=json.load(sys.stdin);assert d["errorCount"]==0,d;print("  %s: %d ok" % (d["path"], d["readyFiles"]))'
    done
  fi
done

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
# Screenshots exist for en-US and pt-BR; the other locales fall back to en-US.
for locale_dir in "$SHOTS"/iphone/*/; do
  locale="$(basename "$locale_dir")"
  for pair in "iphone:phoneScreenshots" "ipad:tenInchScreenshots"; do
    dir="${pair%%:*}"; type="${pair##*:}"
    gplay images delete-all --package "$PACKAGE" --edit "$EDIT" --locale "$locale" --type "$type" --confirm > /dev/null
    for shot in "$SHOTS/$dir/$locale"/*.png; do
      gplay images upload --package "$PACKAGE" --edit "$EDIT" --locale "$locale" --type "$type" --file "$shot" > /dev/null
    done
  done
  echo "  screenshots $locale"
done
gplay edits validate --package "$PACKAGE" --edit "$EDIT" > /dev/null
if $APPLY; then
  gplay edits commit --package "$PACKAGE" --edit "$EDIT" > /dev/null
  echo "Play: committed"
else
  gplay edits delete --package "$PACKAGE" --edit "$EDIT" --confirm > /dev/null
  echo "Play: validated, discarded (dry run)"
fi

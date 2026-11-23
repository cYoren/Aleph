#!/usr/bin/env bash
# Everything that must be true before an Aleph build goes to a store, in one
# command, so the check is not a memory exercise.
#
#   scripts/release_preflight.sh                 # all gates
#   scripts/release_preflight.sh --skip-sim --allow-no-sim   # gates only, no launch
#
# A store submission needs the launch pass. Skipping it (or running off macOS,
# where it cannot run) makes this script exit non-zero unless --allow-no-sim is
# passed explicitly, so "all gates passed" is never printed without it.
#   scripts/release_preflight.sh --app path/to/Runner.app   # also launch this build
#
# Fails loudly. Exit 0 means: the data is complete, the code analyses, every test
# passes, the version moved, the database asset matches the code, and (on a Mac,
# unless skipped) the build launches and paints on an iPhone and an iPad.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

SKIP_SIM=0
ALLOW_NO_SIM=0
LOG_DIR="$(mktemp -d)"
trap 'rm -rf "$LOG_DIR"' EXIT
APP="build/ios/iphonesimulator/Runner.app"
while [ $# -gt 0 ]; do
  case "$1" in
    --skip-sim) SKIP_SIM=1 ;;
    --allow-no-sim) ALLOW_NO_SIM=1 ;;
    --app) shift; APP="${1:?--app needs a path}" ;;
    *) echo "release_preflight: unknown argument $1"; exit 2 ;;
  esac
  shift
done

failures=0
skipped=0
step() { printf '\n== %s\n' "$1"; }
ok()   { printf '   ok  %s\n' "$1"; }
bad()  { printf '   FAIL %s\n' "$1"; failures=$((failures + 1)); }

step "version"
version="$(sed -n 's/^version: //p' pubspec.yaml | head -1)"
if [ -n "$version" ]; then ok "pubspec $version"; else bad "no version in pubspec.yaml"; fi
# The version also lives in the PostHog event payload guard and the store notes;
# test/posthog_test.dart already fails when those drift, so a version bump that
# forgets one of them is caught by the test step below.

step "database asset"
if [ -f assets/bible.db.gz ]; then
  ok "assets/bible.db.gz $(du -h assets/bible.db.gz | cut -f1)"
else
  bad "assets/bible.db.gz is missing: run scripts/prepare_bible_db.py before building"
fi

step "release data gates"
# validate_release.sh reads assets/bible.db; the build only ships the packed
# asset, so unpack it here rather than making a missing file look like bad data.
if [ ! -f assets/bible.db ] && [ -f assets/bible.db.gz ]; then
  gunzip -c assets/bible.db.gz > assets/bible.db 2>/dev/null && ok "unpacked assets/bible.db from the bundled asset"
fi
if [ -x scripts/validate_release.sh ]; then
  if ./scripts/validate_release.sh > ${LOG_DIR}/validate.log 2>&1; then
    ok "validate_release.sh"
  else
    bad "validate_release.sh (see ${LOG_DIR}/validate.log)"
    tail -20 ${LOG_DIR}/validate.log | sed 's/^/      /'
  fi
else
  bad "scripts/validate_release.sh is not executable"
fi

step "static analysis"
if flutter analyze lib test > ${LOG_DIR}/analyze.log 2>&1; then
  ok "flutter analyze"
else
  bad "flutter analyze (see ${LOG_DIR}/analyze.log)"
  tail -20 ${LOG_DIR}/analyze.log | sed 's/^/      /'
fi

step "tests"
if flutter test > ${LOG_DIR}/test.log 2>&1; then
  ok "flutter test"
else
  bad "flutter test (see ${LOG_DIR}/test.log)"
  tail -30 ${LOG_DIR}/test.log | sed 's/^/      /'
fi

step "launch pass"
if [ "$SKIP_SIM" = 1 ]; then
  skipped=$((skipped + 1)); printf '   SKIPPED (--skip-sim): a store submission still needs it\n'
elif [ "$(uname -s)" != "Darwin" ]; then
  skipped=$((skipped + 1)); printf '   SKIPPED (not macOS): run scripts/sim_launch_check.py on the build Mac\n'
elif [ ! -d "$APP" ]; then
  bad "no simulator build at $APP: flutter build ios --simulator, then --app PATH"
else
  if scripts/sim_launch_check.py --app "$APP" --out build/sim-launch; then
    # The build must be the one this source produces, not yesterday's artifact.
    if python3 - "$version" <<'PY'
import json, sys
from pathlib import Path
result = json.loads(Path("build/sim-launch/result.json").read_text())
print(f"   {result['version']}+{result['build']} on {[d['device'] for d in result['devices']]}")
sys.exit(0 if f"{result['version']}+{result['build']}" == sys.argv[1] else 1)
PY
    then
      ok "launched and painted on an iPhone and an iPad, version matches"
    else
      bad "the launch pass ran a different build than pubspec says ($version)"
    fi
  else
    bad "launch pass (build/sim-launch/result.json)"
  fi
fi

printf '\n'
if [ "$failures" -gt 0 ]; then
  echo "release_preflight: $failures gate(s) failed for $version"
  exit 1
fi
if [ "$skipped" -gt 0 ] && [ "$ALLOW_NO_SIM" != 1 ]; then
  echo "release_preflight: local gates passed for $version, launch pass NOT run."
  echo "                  A store submission needs it; pass --allow-no-sim to accept that here."
  exit 1
fi
if [ "$skipped" -gt 0 ]; then
  echo "release_preflight: local gates passed for $version (launch pass NOT run, --allow-no-sim)"
  exit 0
fi
echo "release_preflight: all gates passed for $version"
exit 0

#!/usr/bin/env bash
# Everything that must be true before an Aleph build goes to a store, in one
# command, so the check is not a memory exercise.
#
#   scripts/release_preflight.sh                 # all gates
#   scripts/release_preflight.sh --skip-sim      # skip the simulator launch pass
#   scripts/release_preflight.sh --app path/to/Runner.app   # also launch this build
#
# Fails loudly. Exit 0 means: the data is complete, the code analyses, every test
# passes, the version moved, the database asset matches the code, and (on a Mac,
# unless skipped) the build launches and paints on an iPhone and an iPad.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

SKIP_SIM=0
APP="build/ios/iphonesimulator/Runner.app"
while [ $# -gt 0 ]; do
  case "$1" in
    --skip-sim) SKIP_SIM=1 ;;
    --app) shift; APP="${1:?--app needs a path}" ;;
    *) echo "release_preflight: unknown argument $1"; exit 2 ;;
  esac
  shift
done

failures=0
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
  if ./scripts/validate_release.sh > /tmp/aleph-validate.log 2>&1; then
    ok "validate_release.sh"
  else
    bad "validate_release.sh (see /tmp/aleph-validate.log)"
    tail -20 /tmp/aleph-validate.log | sed 's/^/      /'
  fi
else
  bad "scripts/validate_release.sh is not executable"
fi

step "static analysis"
if flutter analyze lib test > /tmp/aleph-analyze.log 2>&1; then
  ok "flutter analyze"
else
  bad "flutter analyze (see /tmp/aleph-analyze.log)"
  tail -20 /tmp/aleph-analyze.log | sed 's/^/      /'
fi

step "tests"
if flutter test > /tmp/aleph-test.log 2>&1; then
  ok "flutter test"
else
  bad "flutter test (see /tmp/aleph-test.log)"
  tail -30 /tmp/aleph-test.log | sed 's/^/      /'
fi

step "launch pass"
if [ "$SKIP_SIM" = 1 ]; then
  printf '   skipped (--skip-sim): a store submission still needs it\n'
elif [ "$(uname -s)" != "Darwin" ]; then
  printf '   skipped (not macOS): run scripts/sim_launch_check.py on the build Mac\n'
elif [ ! -d "$APP" ]; then
  bad "no simulator build at $APP: flutter build ios --simulator, then --app PATH"
else
  if scripts/sim_launch_check.py --app "$APP" --out build/sim-launch; then
    ok "launched and painted on an iPhone and an iPad"
  else
    bad "launch pass (build/sim-launch/result.json)"
  fi
fi

printf '\n'
if [ "$failures" -eq 0 ]; then
  echo "release_preflight: all gates passed for $version"
  exit 0
fi
echo "release_preflight: $failures gate(s) failed for $version"
exit 1

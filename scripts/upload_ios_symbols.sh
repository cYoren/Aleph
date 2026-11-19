#!/usr/bin/env bash
#
# Upload the dSYMs from an iOS .xcarchive to Sentry.
#
# Why this exists: a native crash or app-hang report only points at app code
# when Sentry has the App.framework.dSYM for the build that produced it. Build
# 1.0.7+30 shipped without it, so Sentry issue ALEPH-1 (7856177326, "App Hang
# Fully Blocked") arrived with sixteen App.framework frames marked `missing`
# and `native_missing_dsym` on Runner: the Dart work that blocked the main
# thread for 3.5s cannot be named from that report. `xcodebuild archive`
# already writes the symbols (Release uses DEBUG_INFORMATION_FORMAT =
# dwarf-with-dsym); this script is the step that puts them in Sentry and fails
# loudly when they are not there.
#
# Usage:
#   scripts/upload_ios_symbols.sh --archive build/ios/archive/Runner.xcarchive
#   scripts/upload_ios_symbols.sh --archive ... --dry-run
#
# Environment:
#   SENTRY_AUTH_TOKEN  required unless --dry-run. Must be an org token with
#                      `project:releases`; the iOS workflow passes it from the
#                      repository secret of the same name.
#   SENTRY_ORG         default medhub-ba
#   SENTRY_PROJECT     default aleph
#
# Written for the bash 3.2 that ships with macOS: no mapfile, no associative
# arrays, no ${var,,}.
set -euo pipefail

ARCHIVE=""
DRY_RUN=0
ORG="${SENTRY_ORG:-medhub-ba}"
PROJECT="${SENTRY_PROJECT:-aleph}"

usage() {
  cat <<'EOF'
usage: upload_ios_symbols.sh --archive <path/to/Runner.xcarchive> [--dry-run]
                             [--org <org>] [--project <project>]

Exit codes:
  0  symbols uploaded (or, with --dry-run, present and usable)
  1  the archive has no usable symbols
  2  bad invocation or missing tooling
EOF
}

die() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --archive) ARCHIVE="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --org) ORG="${2:-}"; shift 2 ;;
    --project) PROJECT="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; printf 'error: unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

[[ -n "$ARCHIVE" ]] || { usage >&2; printf 'error: --archive is required\n' >&2; exit 2; }
[[ -d "$ARCHIVE" ]] || { printf 'error: archive not found: %s\n' "$ARCHIVE" >&2; exit 2; }

DSYM_DIR="$ARCHIVE/dSYMs"
if [[ ! -d "$DSYM_DIR" ]]; then
  die "$ARCHIVE has no dSYMs/ directory. The archive was built without debug
  information: Release must set DEBUG_INFORMATION_FORMAT = dwarf-with-dsym."
fi

# An app dSYM bundle is named after the bundle (Runner.app.dSYM) but its DWARF
# payload is named after the executable (Runner), so never derive one from the
# other: take whatever file is under Contents/Resources/DWARF.
dwarf_file() {
  local dir="$1" candidate
  for candidate in "$dir/Contents/Resources/DWARF"/*; do
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

APP_DSYM="$DSYM_DIR/App.framework.dSYM"
RUNNER_DSYM="$DSYM_DIR/Runner.app.dSYM"

# App.framework carries the Dart/AOT frames; Runner carries the native runner.
# Both are what Sentry reported missing for ALEPH-1, so neither is optional.
for required in "$APP_DSYM" "$RUNNER_DSYM"; do
  [[ -d "$required" ]] || die "missing $(basename "$required") in $DSYM_DIR.
  The dSYM set is what symbols are uploaded from; an archive without it cannot
  symbolicate this build."
  dwarf_file "$required" >/dev/null || die "$(basename "$required") holds no DWARF payload under Contents/Resources/DWARF."
done

count=0
echo "dSYM bundles in $DSYM_DIR:"
while IFS= read -r bundle; do
  [[ -n "$bundle" ]] || continue
  printf '  %s\n' "$(basename "$bundle")"
  count=$((count + 1))
done < <(find "$DSYM_DIR" -maxdepth 1 -type d -name '*.dSYM' | sort)

[[ "$count" -gt 0 ]] || die "no *.dSYM bundles in $DSYM_DIR"

if command -v sentry-cli >/dev/null 2>&1; then
  APP_DWARF="$(dwarf_file "$APP_DSYM")"
  echo "Checking App.framework dSYM with sentry-cli:"
  CHECK_OUTPUT="$(sentry-cli debug-files check "$APP_DWARF" 2>&1 || true)"
  printf '%s\n' "$CHECK_OUTPUT"
  # A dSYM can exist and still carry no symbols (stripped, or a Swift-only
  # stub). Sentry accepts the upload either way, so this is the only point
  # where a hollow bundle is caught.
  printf '%s\n' "$CHECK_OUTPUT" | grep -q 'Usable: yes' \
    || die "sentry-cli does not consider App.framework.dSYM usable; uploading it would not symbolicate anything."
else
  echo "sentry-cli not found on PATH: skipping the usability check."
  if [[ "$DRY_RUN" -eq 0 ]]; then
    die "sentry-cli is required to upload. Install it (brew install getsentry/tools/sentry-cli) or run with --dry-run."
  fi
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "dry run: would upload $count dSYM bundle(s) to $ORG/$PROJECT"
  exit 0
fi

: "${SENTRY_AUTH_TOKEN:?SENTRY_AUTH_TOKEN is not set. Add it as a repository secret (Sentry org medhub-ba, project aleph) or run with --dry-run.}"

echo "Uploading $count dSYM bundle(s) to $ORG/$PROJECT and waiting for analysis:"
sentry-cli debug-files upload --org "$ORG" --project "$PROJECT" --wait "$DSYM_DIR"

# Read the upload back. `debug-files find` queries the API by debug id, so this
# is proof the symbols exist server-side rather than proof the command exited 0.
APP_DWARF="${APP_DWARF:-$(dwarf_file "$APP_DSYM")}"
APP_ID="$(printf '%s\n' "$CHECK_OUTPUT" | sed -n 's/.*> \([0-9a-f-]\{36\}\).*/\1/p' | head -n 1)"
if [[ -n "$APP_ID" ]]; then
  echo "Confirming $APP_ID is registered in Sentry:"
  if FIND_OUTPUT="$(sentry-cli debug-files find "$APP_ID" 2>&1)"; then
    printf '%s\n' "$FIND_OUTPUT"
    printf '%s\n' "$FIND_OUTPUT" | grep -q 'Nothing found' \
      && die "Sentry still reports nothing for debug id $APP_ID after upload."
  else
    echo "warning: could not read the debug id back from Sentry; the upload exited 0."
  fi
else
  echo "warning: no debug id parsed from the dSYM check; skipping the read-back."
fi

echo "OK: uploaded $count dSYM bundle(s) from $ARCHIVE to $ORG/$PROJECT"

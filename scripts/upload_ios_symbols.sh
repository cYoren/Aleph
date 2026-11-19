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
#   SENTRY_AUTH_TOKEN  required unless --dry-run. Needs `project:releases` to
#                      upload and `project:read` to read the upload back; the
#                      iOS workflow passes it from the repository secret of the
#                      same name.
#   SENTRY_ORG         default medhub-ba
#   SENTRY_PROJECT     default aleph
#   SENTRY_URL         default https://sentry.io (self-hosted installs)
#
# Written for the bash 3.2 that ships with macOS: no mapfile, no associative
# arrays, no ${var,,}.
set -euo pipefail

ARCHIVE=""
DRY_RUN=0
ORG="${SENTRY_ORG:-medhub-ba}"
PROJECT="${SENTRY_PROJECT:-aleph}"
SENTRY_URL="${SENTRY_URL:-https://sentry.io}"

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

command -v curl >/dev/null 2>&1 \
  || { printf 'error: curl is required to read the upload back\n' >&2; exit 2; }

echo "Uploading $count dSYM bundle(s) to $ORG/$PROJECT and waiting for analysis:"
sentry-cli debug-files upload --org "$ORG" --project "$PROJECT" --wait "$DSYM_DIR"

# Read the upload back from the server. `sentry-cli debug-files find` is not a
# remote lookup: its own `--no-cwd` flag ("Do not look for debug symbols in the
# current working directory") says it searches local files, so it would confirm
# the archive we just checked and pass whatever the server holds. This asks the
# project's debug-file endpoint for each debug id instead, which is the only
# evidence that the symbols Sentry needs are actually there.
#
# A dSYM can hold several ids (arm64, arm64e) and Sentry only needs the one the
# crash reports carry, so one confirmed id is enough.
APP_DWARF="${APP_DWARF:-$(dwarf_file "$APP_DSYM")}"
# `debug-files check` prints one line per identifier as `> Debug ID: <uuid>`
# (sentry-cli src/commands/debug_files/check.rs).
APP_IDS="$(printf '%s\n' "${CHECK_OUTPUT:-}" | sed -n 's/.*> Debug ID: \([0-9a-f]\{8\}-[0-9a-f]\{4\}-[0-9a-f]\{4\}-[0-9a-f]\{4\}-[0-9a-f]\{12\}\).*/\1/p')"

# Is this debug id registered for the project? 0 = yes, 1 = no, 2 = could not ask.
debug_id_on_server() {
  local debug_id="$1" body
  if ! body="$(curl -fsS \
      -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" \
      "$SENTRY_URL/api/0/projects/$ORG/$PROJECT/files/dsyms/?query=$debug_id")"; then
    echo "warning: could not query $SENTRY_URL for debug id $debug_id (the token needs project:read)."
    return 2
  fi
  printf '%s\n' "$body" | grep -Eq "\"debugId\"[[:space:]]*:[[:space:]]*\"$debug_id\""
}

CONFIRMED=0
if [[ -z "$APP_IDS" ]]; then
  die "sentry-cli read no debug id from App.framework.dSYM, so the upload cannot be
  verified. Refusing to report success on an unverified symbol upload."
fi

while IFS= read -r debug_id; do
  [[ -n "$debug_id" ]] || continue
  echo "Confirming $debug_id is registered in $ORG/$PROJECT:"
  if debug_id_on_server "$debug_id"; then
    echo "  present"
    CONFIRMED=1
  else
    echo "  absent"
  fi
done <<< "$APP_IDS"

[[ "$CONFIRMED" -eq 1 ]] || die "the App.framework dSYM uploaded but none of its debug ids
  ($(printf '%s' "$APP_IDS" | tr '\n' ' ')) is registered in $ORG/$PROJECT. Sentry cannot
  symbolicate this build until it is: check that SENTRY_AUTH_TOKEN can read the project
  (project:read) and that the upload reached the same Sentry instance ($SENTRY_URL)."

echo "OK: uploaded $count dSYM bundle(s) from $ARCHIVE to $ORG/$PROJECT"

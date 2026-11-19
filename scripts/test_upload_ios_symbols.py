#!/usr/bin/env python3
"""Tests for the iOS dSYM upload step.

Run directly:

    python3 scripts/test_upload_ios_symbols.py

Covers the properties the symbol gate depends on:

* the iOS release workflow actually runs the upload against the archive it
  built (the step is what was missing when ALEPH-1 arrived unsymbolicated),
* an archive without dSYMs, without App.framework.dSYM, or with a hollow
  App.framework.dSYM is refused instead of uploading nothing useful,
* a real run with a token calls `sentry-cli debug-files upload --wait` for the
  configured org/project and then reads the debug id back from the project on
  the Sentry API, not from local files,
* the read-back fails the release when Sentry does not list the debug id, when
  the API cannot be queried, or when no debug id could be read from the dSYM,
* a missing token fails loudly rather than skipping the upload.

Both stubs mirror real tool output: `debug-files check` prints identifiers as
`> Debug ID: <uuid>` (sentry-cli src/commands/debug_files/check.rs) and the
debug-file endpoint answers with `[{"debugId": ...}]` objects. The fake archive
mirrors `xcodebuild archive` layout: dSYM bundles are named after the bundle
(Runner.app.dSYM) while the DWARF file inside is named after the executable
(Runner), which is the detail a naive implementation gets wrong.
"""

from __future__ import annotations

import os
import pathlib
import shutil
import subprocess
import tempfile
import unittest

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
SCRIPT = REPO_ROOT / "scripts" / "upload_ios_symbols.sh"
WORKFLOW = REPO_ROOT / ".github" / "workflows" / "ios-testflight.yml"
BASH = shutil.which("bash") or "/bin/bash"

# The debug ids Sentry reported missing for ALEPH-1 (7856177326).
APP_DEBUG_ID = "939fc33b-7f57-b2d1-7e91-df907fbe4e88"
ARM64E_DEBUG_ID = "0f9d0e2c-2c33-3d4e-8a51-6a6d1c58d0aa"

FAKE_SENTRY_CLI = """#!/usr/bin/env bash
set -u
printf '%s\\n' "$*" >> "$SENTRY_STUB_LOG"
case "${1:-}" in
  debug-files)
    case "${2:-}" in
      check)
        echo "Debug Info File Check"
        echo "  Type: macho"
        echo "  Contained debug identifiers:"
        for id in ${SENTRY_STUB_IDS-__APP_DEBUG_ID__}; do
          echo "    > Debug ID: $id"
          echo "      Arch:     arm64"
        done
        echo "  Contained debug information:"
        echo "    > symtab, debug"
        echo "  Usable: ${SENTRY_STUB_USABLE:-yes}"
        ;;
      upload)
        echo "Uploaded 3 missing debug information files"
        echo "File processing complete:"
        ;;
    esac
    ;;
esac
exit 0
""".replace("__APP_DEBUG_ID__", APP_DEBUG_ID)

# Sentry's project debug-file endpoint, stubbed at the HTTP boundary.
FAKE_CURL = """#!/usr/bin/env bash
set -u
printf '%s\\n' "$*" >> "$CURL_STUB_LOG"
url=""
for arg in "$@"; do
  case "$arg" in
    http*) url="$arg" ;;
  esac
done
id="${url##*query=}"
if [[ "${CURL_STUB_STATE:-ok}" == "error" ]]; then
  exit 22
fi
present_ids="${CURL_STUB_PRESENT_IDS:-}"
if [[ -z "$present_ids" || " $present_ids " == *" $id "* ]]; then
  printf '[{"id":"1","debugId":"%s","objectName":"App","cpuName":"arm64","symbolType":"macho"}]\\n' "$id"
else
  printf '[]\\n'
fi
exit 0
"""

DWARF_NAME = {
    "App.framework.dSYM": "App",
    "Runner.app.dSYM": "Runner",
    "Flutter.framework.dSYM": "Flutter",
}


class SymbolUploadTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.tmp = pathlib.Path(self._tmp.name)
        self.addCleanup(self._tmp.cleanup)

    # -- helpers ---------------------------------------------------------

    def make_archive(self, bundles=("App.framework.dSYM", "Runner.app.dSYM"), payloads=True):
        """Build an archive shaped like `xcodebuild archive` output."""
        archive = self.tmp / "Runner.xcarchive"
        dsyms = archive / "dSYMs"
        dsyms.mkdir(parents=True)
        for bundle in bundles:
            dwarf = dsyms / bundle / "Contents" / "Resources" / "DWARF" / DWARF_NAME[bundle]
            dwarf.parent.mkdir(parents=True)
            if payloads:
                dwarf.write_bytes(b"\xca\xfe\xba\xbe")
        return archive

    def stub_dir(self):
        directory = self.tmp / "bin"
        directory.mkdir(exist_ok=True)
        for name, body in (("sentry-cli", FAKE_SENTRY_CLI), ("curl", FAKE_CURL)):
            stub = directory / name
            stub.write_text(body)
            stub.chmod(0o755)
        return directory

    def run_script(self, *args, token=True, path=None, env_extra=None):
        env = dict(os.environ)
        env["SENTRY_STUB_LOG"] = str(self.tmp / "sentry-cli.log")
        env["CURL_STUB_LOG"] = str(self.tmp / "curl.log")
        env.pop("SENTRY_ORG", None)
        env.pop("SENTRY_PROJECT", None)
        env.pop("SENTRY_URL", None)
        env.pop("SENTRY_AUTH_TOKEN", None)
        env.pop("SENTRY_STUB_IDS", None)
        env.pop("SENTRY_STUB_USABLE", None)
        env.pop("CURL_STUB_STATE", None)
        env.pop("CURL_STUB_PRESENT_IDS", None)
        if token:
            env["SENTRY_AUTH_TOKEN"] = "test-token"
        env.update(env_extra or {})
        if path is None:
            env["PATH"] = f"{self.stub_dir()}:{env['PATH']}"
        else:
            env["PATH"] = path
        return subprocess.run(
            [BASH, str(SCRIPT), *args],
            capture_output=True,
            text=True,
            env=env,
            cwd=str(REPO_ROOT),
        )

    def calls(self):
        log = self.tmp / "sentry-cli.log"
        return log.read_text().splitlines() if log.exists() else []

    def curl_calls(self):
        log = self.tmp / "curl.log"
        return log.read_text().splitlines() if log.exists() else []

    # -- the workflow wiring ---------------------------------------------

    def test_ios_workflow_uploads_symbols_for_the_archive_it_built(self):
        workflow = WORKFLOW.read_text()
        self.assertIn("scripts/upload_ios_symbols.sh", workflow)
        self.assertIn(
            "--archive build/ios/archive/Runner.xcarchive", workflow,
            "the upload must target the archive this workflow produced",
        )
        self.assertIn(
            "SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}", workflow,
            "the upload needs the token; without it the step cannot run",
        )

    # -- archive validation ----------------------------------------------

    def test_dry_run_lists_the_symbol_bundles(self):
        archive = self.make_archive()
        result = self.run_script(
            "--archive", str(archive), "--dry-run", token=False, path="/usr/bin:/bin"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("App.framework.dSYM", result.stdout)
        self.assertIn("Runner.app.dSYM", result.stdout)
        self.assertIn("dry run", result.stdout)

    def test_archive_without_dsyms_is_refused(self):
        archive = self.tmp / "Runner.xcarchive"
        archive.mkdir()
        result = self.run_script("--archive", str(archive), "--dry-run")
        self.assertEqual(result.returncode, 1)
        self.assertIn("DEBUG_INFORMATION_FORMAT", result.stderr)

    def test_archive_without_app_framework_dsym_is_refused(self):
        archive = self.make_archive(bundles=("Runner.app.dSYM",))
        result = self.run_script("--archive", str(archive), "--dry-run")
        self.assertEqual(result.returncode, 1)
        self.assertIn("App.framework.dSYM", result.stderr)

    def test_hollow_dsym_is_refused(self):
        archive = self.make_archive(payloads=False)
        result = self.run_script("--archive", str(archive), "--dry-run")
        self.assertEqual(result.returncode, 1)
        self.assertIn("DWARF payload", result.stderr)

    def test_missing_archive_is_a_usage_error(self):
        result = self.run_script("--archive", str(self.tmp / "nope.xcarchive"))
        self.assertEqual(result.returncode, 2)
        self.assertIn("archive not found", result.stderr)

    # -- upload path -----------------------------------------------------

    def test_upload_is_read_back_from_the_project_api(self):
        archive = self.make_archive()
        result = self.run_script("--archive", str(archive))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(
            any("debug-files upload --org medhub-ba --project aleph --wait" in call for call in self.calls()),
            self.calls(),
        )
        read_back = self.curl_calls()
        self.assertTrue(
            any(
                f"/api/0/projects/medhub-ba/aleph/files/dsyms/?query={APP_DEBUG_ID}" in call
                for call in read_back
            ),
            f"the upload must be read back from the project API: {read_back}",
        )
        self.assertTrue(
            any("Authorization: Bearer test-token" in call for call in read_back),
            f"the read-back must authenticate: {read_back}",
        )

    def test_read_back_fails_when_sentry_does_not_list_the_debug_id(self):
        archive = self.make_archive()
        result = self.run_script("--archive", str(archive), env_extra={"CURL_STUB_STATE": "ok",
                                                                      "CURL_STUB_PRESENT_IDS": ARM64E_DEBUG_ID})
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn(APP_DEBUG_ID, result.stderr)
        self.assertIn("none of its debug ids", " ".join(result.stderr.split()))

    def test_read_back_fails_when_the_api_cannot_be_queried(self):
        archive = self.make_archive()
        result = self.run_script("--archive", str(archive), env_extra={"CURL_STUB_STATE": "error"})
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("could not query", result.stdout)
        self.assertIn("none of its debug ids", " ".join(result.stderr.split()))

    def test_second_debug_id_confirms_the_upload(self):
        """A multi-arch dSYM only needs one of its ids on the server."""
        archive = self.make_archive()
        result = self.run_script(
            "--archive", str(archive),
            env_extra={
                "SENTRY_STUB_IDS": f"{APP_DEBUG_ID} {ARM64E_DEBUG_ID}",
                "CURL_STUB_PRESENT_IDS": ARM64E_DEBUG_ID,
            },
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("present", result.stdout)

    def test_unreadable_debug_id_fails_instead_of_skipping_the_read_back(self):
        archive = self.make_archive()
        result = self.run_script("--archive", str(archive), env_extra={"SENTRY_STUB_IDS": ""})
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("cannot be", result.stderr)
        self.assertEqual(self.curl_calls(), [], "nothing can be confirmed without ids")

    def test_missing_token_fails_instead_of_skipping(self):
        archive = self.make_archive()
        result = self.run_script("--archive", str(archive), token=False)
        self.assertEqual(result.returncode, 1)
        self.assertIn("SENTRY_AUTH_TOKEN", result.stderr)


if __name__ == "__main__":
    unittest.main(verbosity=2)

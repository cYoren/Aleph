# Aleph completion checkpoint

Saved on `design/reading-activation-polish`, PR #8, against main.

Verified locally on the final source:

- 335 Flutter unit/widget tests pass; 2 opt-in live tests remain skipped.
- Static analysis has no issues; source diff has no whitespace errors.
- Release database checks pass. Actual decoded syntax covers all 31,152
  canonical verses, with no missing, duplicate or extra records.
- All 13,281 short-gloss IDs are covered in each of the seven translated
  languages. All eight Bible translations have complete canonical references.
- Greek assets have pinned per-file hashes and all 28,475 corpus forms have
  generated pronunciations. The runtime is sherpa-onnx 2.0.1; no eSpeak code or
  dictionary files ship. Linux native synthesis and the Linux debug build pass.
- 21 layout captures cover phone, tablet and desktop. Language chooser captures
  were refreshed after removing missing flag glyphs and correcting BSB labeling.
- Error recovery is localized and retryable across the reader/study screens;
  diagnostics statuses are localized and wrap at large text sizes.

Native Android verification on the Mac compiled and installed the app, then
captured language selection, first word, definition, tradition, reader, home,
bookmarks and search. Navigating from Search to Settings exposed a real
`Cannot use ref after the widget was disposed` error. The query now uses
provider-managed disposal; disposal no longer reads a dead widget reference,
and the debounce callback is guarded. A regression verifies safe navigation,
cancelled pending input and query reset. The final 335-test run includes it.

Remaining native verification, intentionally not claimed as complete:

- Re-run the Android integration test on the final source, including Settings,
  dark theme, native speech and playback completion after the navigation fix.
- Run iPhone/iPad and macOS native builds/checks. An iPhone simulator was created
  but no Apple build or interaction pass was completed.

The user requested wrap-up before these remaining native checks. No store
release or merge was performed. PR #8 remains draft until those checks finish.
Automated review exhausted its quota and produced no code review; changes were
self-reviewed and all paginated review sources were checked.

Evidence and reusable caches:

- Local: `/home/gustvmar/Work/aleph-readiness/` (reports, audio probes and
  `android-native-evidence.tar.gz`).
- Mac: `/Users/gustavomarcelino/builds/aleph-ready-20261104/` (isolated worktree,
  native build cache, APK, Android integration log and screenshots).
- Mac runner: `verify-android.sh`; it fetches the branch before running the test.
- iPhone simulator: `392AF755-02E9-4419-AE69-6B5B3B5056F4`.
- Mac access uses `ssh -F /home/gustvmar/.ssh/config gaius`, then the existing
  VPS-owned key to `gustavomarcelino@100.118.101.27`, with strict host checking.
  Supply multi-command scripts as files, since adb can consume stdin scripts.

The original two local translation commits remain on their original feature
branch. Missing long-form language caches are separate content work; the app
continues to label its English fallback honestly.

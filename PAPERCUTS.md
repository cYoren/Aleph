# Project friction log

## Open

- [ ] Verify the legacy Flutter repository is not used by CI, release jobs, or local automation before quarantine.
      Confirmed still live: a `flutter run` on 2026-08-11 emitted `Stale file ... /Users/<user>/Documents/Coding/Original bible/lib/l10n/generated/...` warnings, so the legacy checkout is still being referenced by the local build.
- [ ] Keep generated database assets and coverage reports outside source-oriented paths.
- [ ] `flutter build ios` on Xcode 26.6 auto-migrated `ios/Runner/AppDelegate.swift` and
      `ios/Flutter/AppFrameworkInfo.plist` to the UIScene plugin-registration lifecycle
      (`FlutterImplicitEngineDelegate`) as a side effect of a release-readiness build check.
      Left in, since reverting risks breaking the next `flutter build ios` on this toolchain,
      but it has not been verified on a physical device or in TestFlight — do that before
      the actual store release, not just the simulator build used here.

## Resolved

- [x] 2026-08-07: Added canonical workspace guidance and generated-asset rules.
- [x] 2026-08-11: Cross-reference entry point was an unlabeled icon among four, so it read as
      absent. Now badged with the reference count via `getCrossReferenceCountsForChapter`
      (one query per chapter, not per verse — no scroll jank).
- [x] 2026-08-11: Reader opened on Genesis 1 with no explanation for a first-time user.
      Onboarding now covers long-press-to-peek and recitation explicitly (new page), and a
      one-time dismissible hint appears in the reader itself for anyone who tapped Skip.
- [x] 2026-08-11: Recitation was silent on iOS with the Ring/Silent switch on, and stopped
      the instant the screen locked — the flagship feature looked broken for a large share of
      iPhone users. Fixed: `playback` audio session category (see ROADMAP Phase 2.3) and
      `UIBackgroundModes: audio` in Info.plist.
- [x] 2026-08-11: Six locales (de/fr/es/ru/zh/ko) carried English placeholders for the audio,
      readability, and phrase-spacing strings added this session, and all book names were
      English regardless of app language. Both closed — `find_untranslated.py` reports 0
      across all 8 locales.

## Rules

- Never claim a store release from a successful local build alone.

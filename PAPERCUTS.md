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

- [x] 2026-08-15: The app assumed every reader was Christian. Genesis was filed
      under "Old Testament", Malachi was followed by Matthew, and the verse of
      the day served John 3:16 to everyone. Onboarding now asks once which
      scriptures the reader came for; choosing Tanakh reorders the book picker
      into Torah / Nevi'im / Ketuvim, renames the Hebrew scriptures, and draws
      the daily verse from the Hebrew Bible. Neither choice hides any text —
      the Greek New Testament stays in the picker under its own name, because
      hiding it would break search and cross-references for no gain. Ordering
      is asserted in `test/reading_tradition_test.dart` (Daniel in Ketuvim,
      Chronicles closing the canon, the Megillot together).
- [x] 2026-08-15: Memorization sat on the home screen next to the alphabet
      guide, offering to hide words in a passage from a reader who could not
      yet sound out a letter. Moved to the end of Vocabulary, where someone who
      has started learning will find it.
- [x] 2026-08-15: Bookmarks listed references and timestamps but never the
      verse, so a favourites list asked you to remember why you saved each one.
      The card now leads with the text in the reader's translation, capped at
      four lines.

- [x] 2026-08-15: Learning mode told Portuguese readers "learning mode currently
      only supports English" instead of doing anything for them. It swaps a
      translated word for the original by matching the lexicon gloss against the
      verse — and the gloss now arrives localized through `BibleDAO.glossLanguage`,
      so the same matching works in any language. The English-only gate and its
      notice are gone; where a gloss is not yet translated, nothing matches and
      the verse renders plainly.
- [x] 2026-08-15: Removed three things that took space without earning it: the
      floating chapter pills painted over the bottom of every verse list (the
      chapter is in the app bar, and the arrows there navigate), the right-to-left
      arrow appended to every Hebrew verse (an icon on every OT verse forever,
      restating what the text shows), and `definition_modal.dart` (dead since
      `definition_sheet.dart` replaced it).
- [x] 2026-08-15: Settings had an "upgrade" row whose switch unlocked the paid AI
      model for free — a control that either lies about a purchase or gives the
      tier away. Removed; the daily allowance now sits on the AI switch itself,
      where it is actually useful. `aiProUnlocked` stays in state, waiting on a
      real StoreKit / Play Billing entitlement.

- [x] 2026-08-15: Cross-references looked unimplemented on any device that had
      installed an earlier build. `assets/bible.db` has 343,556 of them, but the
      on-device copy is written once and reused forever, and the freshness check
      only looked for tables that had existed since the first release. Fixed
      twice over: `cross_references` and `syntax_trees` joined the required-table
      set, and a `kBundledDatabaseVersion` stamp now forces a recopy whenever the
      bundled data moves ahead of the local one. **Bump that constant on every
      regenerated release database** — it is now the only thing that reaches
      existing installs.
- [x] 2026-08-15: Choosing Português gave a Portuguese interface and an English
      Bible. The language default was only applied during onboarding, so anyone
      who installed before it existed, or who changed language in Settings, kept
      the KJV. Settings now moves the translation with the language, and
      `_loadSettings` heals existing installs — both only when the reader has
      not picked a translation by hand.

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

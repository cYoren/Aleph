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

- [x] 2026-09-03: A UI/UX audit of the whole app, and the fixes for it.

      **Search returned the wrong 50 verses.** `bible_dao.search` ordered by
      `v.book_id` — the abbreviation, as a string — and then cut at 50, so the
      sort was alphabetical and the cap landed inside it. "shepherd" in the KJV
      matches 114 verses; the reader got 50 of them, 1 Chronicles to Isaiah,
      with Psalm 23:1 not among them. Now joins `books` and orders by
      `book_order`, returns up to 200, and the header says "showing 50 of 114"
      when there are more. Matched runs are marked in the result text.

      **Every jump to a verse landed at the top of the chapter.** Bookmarks,
      search hits, cross-references and the concordance all called
      `loadChapter(book, chapter)` and stopped; `ReadingState` had no verse.
      Tapping a bookmark on Psalm 119:105 opened Psalm 119:1. `ReadingState`
      now carries `targetVerse` and the reader scrolls to it and marks it,
      reusing the machinery that already followed the recitation voice.

      **Those jumps were also one-way.** All of them used `context.go`, which
      replaces the stack, so chasing a chain of cross-references stranded you
      at the end of it. `ReadingNotifier` keeps a bounded history of
      `(book, chapter, verse)` and the reader shows a back arrow when there is
      somewhere to go. Chapter paging deliberately does not record.

      **First launch copied 234 MB behind a bare spinner.** `rootBundle.load`
      then one `writeAsBytes`, with nothing on screen saying what was
      happening — and it repeats on every `kBundledDatabaseVersion` bump. The
      copy is now chunked, publishes progress through
      `databaseCopyProgress`, and the startup gate shows a screen that says
      this happens once and everything works offline afterwards. A failed copy
      explains itself and offers a retry; any other database failure lets the
      reader through to screens that now have their own error states.

      **Accessibility.** There was not one `Semantics` widget in 28,343 lines.
      Added to the word, the study tiles, the continue-reading row, the peek
      bubble and the mastery ring, plus the eight `IconButton`s that had no
      tooltip. The word tap target was about 26x24 pt against a 44 pt minimum
      and carries two gestures; padding went from 3x2 to 6x7.

      **Contrast.** In light mode the gold measured 4.38:1 on parchment,
      under the 4.5:1 AA floor — and since every word in the database carries a
      Strong's number, that was the colour of the entire Hebrew and Greek text.
      Now `0xFF7A6021`, which clears 4.5:1 against every light surface. The
      transliteration's 80% alpha (3.07:1) and the translation-missing note's
      60% (2.82:1) are gone, and the parsing quiz's `Colors.green.shade800`
      (2.67:1 on the night ground) is `tertiaryContainer`.

      **Book names were localized in three screens and English in nine.** A
      Korean reader saw the reader app bar in Korean and their bookmarks,
      search results, home screen, word study, cross-references, memorization
      and definition sheet in English. All nine now go through
      `localizedBookNameProvider`.

      **Two English strings shipped to all eight locales** — the example
      glosses under the Hebrew and Greek onboarding cards. They were Dart
      literals rather than `.arb` keys, so `find_untranslated.py` reported
      zero. Now keys, translated. 47 new strings in all eight languages.

      **Smaller things.** The Settings row for the recitation voice had no
      `onTap` and did nothing; it now opens the platform voice installer, and
      is hidden where there is none to open. The first Settings section was
      headed "Theme" and held ten rows including the reading tradition; the
      groups are now Reading, Learning, Audio, Appearance and About. Ten
      screens printed the raw Dart exception with no retry and now use
      `ErrorState`. The chapter grid filled the display with `primaryContainer`
      gold, against theme.dart's own first rule. Amber-for-OT and blue-for-NT
      survived in the syntax screen the cleanup that removed them elsewhere.
      There was no way to copy the Hebrew or Greek — "Copy verse" gives the
      translation — so the long-press menu gained Copy original and Copy both.
      Recitation gained pause, resume and verse skipping. The book picker
      gained a filter and a `PopScope` so the system back button steps back one
      level like the app bar does. Removing a bookmark is immediate with an
      undo rather than a swipe that snaps back into a confirmation dialog.
      `Share.share` now passes `sharePositionOrigin` so the iPad popover is
      anchored. Search no longer grabs the keyboard on every visit or discards
      the query on the way out. The nav bar labels all five destinations. The
      39-book Old Testament set is derived from `kTanakhOrder` instead of being
      written out as a literal in two screens. And there is an About screen:
      version, sources for the text, translations, lexicons, MACULA syntax
      (CC BY) and the SIL fonts, `showLicensePage`, and the responsible-entity
      rows moved down from Settings.

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

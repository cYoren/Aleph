# Original Bible — Roadmap

Status: current

## Mission

Help people get truly in depth with the Bible **in its original languages** — Hebrew and
Greek — and support them in what they need along the way (vocabulary, reading fluency,
memorizing psalms and passages), all offline-first and without clutter.

**Guiding principle for prioritization:** every feature should either
(a) deepen genuine engagement with the original text, or
(b) help the user *learn* so that engagement becomes easier over time.
Features that do neither (generic engagement mechanics, social feeds, devotional
aggregation) are explicitly de-prioritized.

**Current focus: beginner-friendliness.** The depth features largely exist. What
is missing is the on-ramp — someone who has never read Hebrew or Greek should be
able to open the app and know what to do. Anything that lowers that first barrier
outranks a new depth feature.

**Batched work lives in [queue.md](queue.md).** Bulk translation and other
token-heavy jobs are specified there as self-contained prompts for a scheduled
worker, rather than done inline. If you are an agent picking up this project,
read `queue.md` before starting anything that looks like mass content work.

---

## Phase 0 — The on-ramp (the current priority) — **shipped 2026-11-13**

What someone who has never read a Hebrew letter sees in the first ten minutes is
now a path, not a library: `/start`, reached automatically when onboarding ends
(and from a card at the top of the home screen until it is done).

1. **Three letters** — alef, bet, gimel (or alpha, beta, gamma) with the sound
   each makes and the example word the alphabet guide already teaches.
2. **One word** — those letters inside a real word, with its transliteration and
   meaning.
3. **One verse** — Genesis 1:1 (Hebrew) or John 1:1 (Greek): every single word
   carries its sound and its gloss, the translation sits underneath, and any word
   opens its full entry on tap.
4. **Five words** — the five worth keeping from that verse become real SM-2 cards
   through the same quiz sheet the vocabulary deck uses.

**It can say how long it took.** The clock starts at the first launch of the app
(`firstRunLaunchAt`), not at the reading screen, and the closing card prints the
number ("Your first verse in 7 minutes"). `test/first_run_test.dart` pins the
measurement, including the "under a minute" case and the fact that restarting the
steps never rewrites the first time. Completing each step records an opt-in
anonymous event (`first_verse_read`, `first_review_done`) with no text and no
timing.

Tests: `test/first_steps_widget_test.dart` (each step renders what it promises),
`test/first_run_test.dart` (the clock), plus the startup gate change covered by
`test/release_readiness_widget_test.dart` and
`test/onboarding_activation_test.dart`.

---

## Phase 1 — Make the depth claim true (data quality)

The foundation is right (word-level tokens, Strong's, morphology, offline SQLite), but two
things currently undercut the "in depth" promise:

### 1.1 Real lexicon definitions ⭐ — **shipped**
- [x] Replace the majority-vote gloss "definition" (`"{gloss}. Strong's {n}."`) with full
      Strong's dictionary entries (definition, derivation, KJV renderings) from
      Open Scriptures (CC BY-SA) in `scripts/build_full_bible_db.py`.
- [x] Fill missing transliteration/pronunciation from the Strong's data
      (the Greek NT tokens currently have none).
- [x] Scholarly lexicon layer shipped: **BDB** (Hebrew, `openscriptures/HebrewLexicon`)
      and **Abbott-Smith** (Greek, `translatable-exegetical-tools/Abbott-Smith`) entries
      attached to ~14k lexicon rows, shown as an expandable section in the definition
      sheet.
- [x] **Structured senses.** `lexicon_senses` holds numbered, nested sense rows
      parsed from BDB and Abbott-Smith (1,807 Hebrew + 5,249 Greek entries;
      42.6% of Hebrew and 86.8% of Greek tokens). The definition sheet renders the
      dictionary's own numbering, headings and indentation instead of one blob,
      and falls back to the flattened entry where the dictionary left prose only.
      Gates: `build_lexicon_senses` and `validate_database`.
      Tests: `scripts/test_build_depth_tables.py`, `test/lexicon_senses_test.dart`,
      `test/definition_depth_sheet_test.dart`, release-DB checks in
      `test/database_test.dart`.

### 1.2 Real syntax trees — **shipped**
- [x] Imported the **MACULA Greek** (SBLGNT lowfat) and **MACULA Hebrew** (WLC lowfat)
      treebanks (Clear Bible, CC BY 4.0): per-verse sentence trees in a `syntax_trees`
      table, 100% verse coverage (31,152/31,152).
- [x] The syntax screen renders the real trees as an indented outline with role/phrase
      labels; the POS-heuristic sketch remains only as a fallback for old DBs, still
      labeled as a sketch.
- [x] Tap a tree word to open its lexicon entry; collapsible nodes for long
      sentences. `onLeafTap` was already wired in `syntax_tree_view`; the
      behaviour is now pinned by `test/syntax_tree_view_widget_test.dart` (leaf
      tap reports the word, internal nodes fold, punctuation is inert).

### 1.3 Concordance / word study — **in progress**
- [x] "See all occurrences" of a word from the definition sheet: every verse containing a
      Strong's number / lemma, in canonical order, tappable to jump into the reader.
- [x] Occurrences grouped by book with headers (list capped at 300 with a count
      note; true pagination still open for hyper-frequent particles).
- [x] Word search: by Strong's id, lemma (pointing/accent-insensitive),
      transliteration, or English gloss — results open the concordance.
- [x] **True root (shoresh) search.** `lexicon_roots` maps Strong's ids onto
      TWOT roots, with BDB's own root letters and gloss. The definition sheet
      shows the root and opens `/root`, which lists every word built on it with
      counts and every verse the family appears in: searching בָּרַךְ finds
      בְּרָכָה too. Tests: `test/root_study_widget_test.dart`,
      `test_build_depth_tables.py`, release-DB checks.

---

## Phase 2 — The learning loop (unify depth + learning)

### 2.1 Proper spaced repetition — **shipped**
- [x] Replace the linear ±0.2 mastery bump with the SM-2 algorithm
      (easiness factor, expanding intervals) in `SrsDao`.
- [x] **FSRS replaced SM-2 (2026-11-13).** `fsrs` 2.x ships 21 pretrained
      weights, so it schedules correctly with no review history; the earlier
      "wait for volume" reason was wrong (volume is only needed to *personalise*
      the weights, which nothing does). Card state lives on `srs_progress`
      (`fsrs_stability`, `fsrs_difficulty`, `fsrs_state`, `fsrs_step`,
      `fsrs_reps`, `fsrs_lapses`); the due date stays `next_review_at`, and the
      SM-2 columns stay as readable history. The binary quiz maps to
      `Rating.good` / `Rating.again` — no four-button sheet. Migration v6 seeds
      stability from `interval_days`, keeps `last_reviewed_at`, and writes
      nothing else, so no mastery score can be lowered; the first post-migration
      review is floored at the interval SM-2 would have scheduled, so the
      upgrade never pulls a review forward. `srs_reviews` now logs the FSRS
      rating alongside the grade. Tests: `test/srs_fsrs_test.dart` (the 40-review
      replay gate, the migration, the in-place v5 → v6 upgrade),
      `test/srs_sm2_test.dart` (SM-2, still the memorization scheduler and the
      migration reference).
- [x] Frequency-ordered vocabulary decks with live text-coverage stats and an SRS
      review queue (`/vocabulary`).

### 2.2 Personalized Reader's Bible mode ⭐ the differentiator
- [x] v1 shipped: reading mode where mastered words render plain and rare words
      (below 30 whole-Bible occurrences) get an inline gloss — a printed Reader's
      Greek NT, but personalized and adaptive. Reading itself becomes the SRS loop.
- [x] **Adaptive per-user threshold.** The gloss bar starts at the printed-reader
      convention (30 occurrences) and rises to the most frequent word the reader
      has met in review but not mastered, capped at 500 — the help follows the
      reader rather than the average. `adaptiveReaderThreshold` in
      `lib/shared/utils/reader_mode.dart`, tested in `test/reader_mode_test.dart`.
- [x] **Marking words known from reading exposure.** The definition sheet has a
      "mark as known" action that records mastery above the reader-mode
      suppression threshold, schedules it 180 days out, and keeps whatever
      history the word already had (`SrsDao.markKnown`,
      `test/srs_mark_known_test.dart`).
- [x] **Readability map shipped** (`/readability`, `lib/features/readability/`):
      ranks every book by the share of its tokens the user has mastered, and
      recommends what to read next. Progress shown as capability rather than a
      streak — this is the sanctioned alternative to gamification.
- [x] **Vocabulary deck defect fixed**: MACULA splits Hebrew proclitics into
      their own tokens, so the raw frequency table is headed by ו, ה, ל, ב, מ —
      prefixes, not vocabulary. `lib/shared/utils/vocabulary_filter.dart` drops
      them by consonant count, and drops Strong's ids with no lexicon row.
      See queue.md Task 3: several *real* Greek words (ἐγώ, ἦν, σοῦ) are lost
      to that second rule because the lexicon is keyed by lemma number only.

### 2.3 Passage memorization (psalms, in Hebrew) ⭐
- [x] v1 shipped: pick any chapter (Psalms default) → progressive word hiding
      (warm-up/challenge/first-letters) → self-graded recall, scheduled by the shared
      SM-2 engine (`/memorization`).
- [x] Transliteration inside practice mode: a toggle in the app bar adds the
      verse as it sounds (`bə·rēʾ·ˈšîṯ`, stress from the accents, Greek folded the
      same way the reader folds it), so reciting from memory is not also an
      alphabet test.
- [x] **Audio recitation shipped** (`lib/features/audio/`): a bundled offline
      Greek voice, with the device voice for Hebrew. Synthesized audio avoids
      the recording-licensing question entirely. Continuous chapter
      playback with the spoken verse highlighted and scrolled into view; also
      word-level playback from the definition sheet.
      - Voices: the **Greek** New Testament is read by a voice bundled *inside*
        the app (Piper `el_GR/rapunzelina` via sherpa-onnx) — no install, no
        internet, works on a fresh install. **Hebrew** is read by the device
        voice; a suitable redistributable Hebrew model has not been validated
        for this project. See
        `docs/tasks/embedded-voices-findings.md`.
      - **Pronunciation is Modern Israeli / Modern Greek** — living traditions,
        not reconstructed ancient pronunciation, and not the Erasmian Greek
        most seminaries teach. This is stated in Settings rather than glossed
        over. No platform TTS can produce Erasmian.
      - Text prep is the real work, in `recitation_text.dart`: cantillation must
        be stripped (engines choke on it) while niqqud is kept, and polytonic
        Greek must be folded to monotonic or the engines cannot read it at all.
        The folding table is generated by `scripts/generate_greek_monotonic.py`.
      - The bundled Greek writes every comma tight against the next word
        (`λόγος,καὶ`) in all 5,414 NT verses that have one; a space is inserted
        before speaking or the voice runs straight through the phrase break.
      - [x] **iOS audio session fixed.** Without configuration, iOS applies the
        default `ambientSolo` session: recitation was silenced by the
        Ring/Silent switch and stopped the instant the screen locked — the
        flagship feature going silent for a large share of iPhone users. Fixed
        with `setIosAudioCategory(.playback, [.duckOthers], .spokenAudio)` in
        `recitation_service.dart` plus `UIBackgroundModes: audio` in
        `Info.plist`, so listening continues through both. Verified by a real
        `flutter build ios` (simulator) rather than analyze alone; not yet
        verified on a physical device — see PAPERCUTS.
- [ ] Bundled recordings remain an option later if a properly licensed set is
      found; the player interface would not need to change. Still deferred, for
      the same licensing reason.

### 2.4 Morphology as a learning tool
- [x] Parsing quizzes ("what form is this?") driven by the morphology decoder —
      from the vocabulary screen, Hebrew and Greek.
- [x] **Paradigms, as far as the data honestly goes.** The sheet lists every form
      of the word that actually occurs, grouped the way a paradigm is read —
      Hebrew by binyan, Greek by tense and voice — with counts and the same
      morphology decoding used elsewhere. It is labelled "forms in the text", not
      "paradigm", because a generated table would print forms nobody ever wrote.
      `lib/shared/utils/paradigm.dart`, `test/paradigm_test.dart`.

---

## Phase 3 — Reader depth features

### 3.0 Cantillation as a teaching layer ⭐ — **shipped**

Every OT verse already carried the full accentuation of the Leningrad Codex, and
the app was throwing it away. Two things come out of it that no other layer of
our data provides. Implemented in `lib/shared/utils/cantillation.dart`
(prose "21 books" hierarchy; poetic accents flagged but given nearest prose rank).

- [x] **Stress.** Most accents sit on the stressed syllable, so the text tells us
      where the tone falls. `hebrew_syllables.dart` syllabifies the pointing and
      marks it: `bə·rēʾ·ˈšîṯ`. Prepositive and postpositive accents (pashta,
      telisha gedola, segolta, zarqa) sit at a fixed word edge and say nothing
      about stress — those emit **no** mark rather than a guessed one.
- [x] **Phrase structure.** Disjunctive accents divide a verse into nested sense
      units. The reader spaces the text at those breaks (Settings → Phrase
      spacing), which is the step from decoding word-by-word to actually reading.
      Rank 1 on Gen 1:1 reproduces the traditional division exactly.
- Validated across all 23,213 OT verses: silluq falls on the final word in 99.9%
  (which is what lets us tell silluq from meteg — they share glyph U+05BD), and
  accent frequencies match the known Masoretic distribution.
- [ ] Next: use the same phrase structure to pace recitation, and let a learner
      tap a break to hear just that phrase. **Deferred** — it needs the recitation
      player to own a phrase queue, which is a design change to the audio bar.

- [x] Display controls for the Hebrew text: full / vowels-only / consonantal modes —
      reading unpointed text is itself a learning progression.
- [ ] Qere/Ketiv display. **Deferred** — no licence-clean qere/ketiv layer exists
      in the pipeline yet; see the deferred list.
- [x] Cross-references: OpenBible.info dataset (CC-BY, ~340k pairs), per-verse
      sheet in the reader with previews, best-voted first.
- [x] **Participant/referent data from MACULA.** Hebrew verbs carry their subject
      and Greek pronouns their referent, resolved to surface text and Strong's id
      at build time and shown in the sheet as "subject" / "refers to". Tests:
      `test/definition_depth_sheet_test.dart`; participant gate in
      `build_full_bible_db.py` and `scripts/validate_release.sh`.
- [ ] Textual variants (NT: NA/Byz differences) — long-term, **deferred**: the
      collation is the copyrighted work even where both texts are free.

---

## Engineering foundation

- [x] Test coverage for the data pipeline: versification mapping and the coverage
      gates (`scripts/test_pipeline_gates.py`), lexicon enrichment
      (`test_build_lexicon_enrichment.py`), structured senses and roots
      (`test_build_depth_tables.py`). `scripts/validate_release.sh` runs them and
      gates the release database on senses, roots and participants.
- [x] Widget test for the tap word → definition flow (gloss, Strong's definition,
      BDB expandable section, concordance entry point).
- [ ] Keep 100% offline as a hard constraint; any future sync must be opt-in and E2E
      encrypted. **One sanctioned exception has shipped**: the opt-in AI passage
      explainer in `lib/features/explain/`, off by default, which states plainly in
      Settings that the passage leaves the device. It is the only code in the app
      that touches the network — recitation uses the OS speech engine and sends
      nothing anywhere. With no API key compiled in, the feature is hidden
      entirely and the app is fully offline again. See queue.md Task 4 for the two
      model quirks (reasoning leakage, token budget) that will break it visibly if
      changed.

### Localization

- Interface strings live in `lib/l10n/*.arb` across 8 locales.
- **Book names are NOT in the database** — `books.name` and `books.name_en` are
  both English. Localized names live in `assets/book_names.json`, served by
  `lib/providers/book_names_provider.dart` with a per-book fallback to English.
  **All 8 app languages are filled**, 66 books each, in each language's
  standard edition convention (e.g. Luther-tradition German, Synodal Russian
  numbering for Samuel/Kings).
- `python3 scripts/find_untranslated.py` inventories what is still English:
  ARB values byte-identical to the English original, plus user-facing string
  literals hardcoded in Dart. **Run it before claiming a localization is done.**
- **Content**, not just the interface, is localised too: the short glosses, the
  long-form Strong's/BDB/Abbott-Smith definitions, and every grammar label
  `MorphologyDecoder` emits are served in the reader's language. Long-form
  content flows through `data/lexicon_translations/` and the
  `lexicon_definition_i18n` table; grammar labels through the `morph*` ARB keys
  and `lib/shared/utils/morphology_labels.dart`. Rows without a translation fall
  back to the labelled English original.
- When adding a UI string: add it to `app_en.arb`, translate `app_pt.arb`, and
  copy the English value into the remaining six so key parity holds and the app
  falls back rather than crashing. The script will then flag it for translation.

---

## Known findings (do not re-investigate)

- **Cross-references are not broken.** The data was always fine — 343,556
  pairs in `cross_references` (Gen 1:1 has 61) — the entry point just read as
  absent (unlabeled icon among four others). Fixed: badged with the count,
  loaded once per chapter via `getCrossReferenceCountsForChapter`.
- **~35 Greek Strong's ids have no lexicon row**, including common words a
  beginner needs (ἐγώ, ἦν, σοῦ, ὑμῶν). They appear to be inflected-form numbers
  while the lexicon is keyed by lemma number. queue.md Task 3.

## Explicitly de-prioritized

Reading plans, streaks/badges, devotional integrations, verse-image sharing, social
features. YouVersion wins that game; our niche is *actually engaging the original text*.
(Reading plans may return later as "reading-fluency plans" tied to vocabulary coverage.)

---

## Data sources & licenses

| Data | Source | License |
|---|---|---|
| Hebrew/Greek tokens, morphology, glosses | `themikejr/bible-mcp` (MACULA-derived) | CC BY 4.0 |
| Translations (KJV, Luther 1912, …) | `seven1m/open-bibles` | public domain / as listed |
| Strong's dictionaries (full definitions) | `openscriptures/strongs` | CC BY-SA |
| BDB Hebrew lexicon | `openscriptures/HebrewLexicon` | public domain |
| Abbott-Smith Greek lexicon | `translatable-exegetical-tools/Abbott-Smith` | public domain |
| MACULA treebanks (syntax trees) | Clear Bible | CC BY 4.0 |
| Cross-references | OpenBible.info (TSK-derived) | CC Attribution |
| Bundled TTS voice (Greek) | Piper `el_GR/rapunzelina` via sherpa-onnx | MIT weights / CC0 data / GPL-3.0 eSpeak NG |
| Long-form lexicon translations | machine-translated, cached in `data/lexicon_translations/` | derived from the CC BY-SA Strong's / public-domain BDB & Abbott-Smith originals |

---

## Deferred, and why

- **Fitting the FSRS weights to a reader.** FSRS ships pretrained defaults and
  schedules from them; fitting them to one reader needs a few hundred reviews
  each, and `srs_reviews` now records what a fit would need (rating, elapsed
  interval, pre-review state). Not a product gap — the defaults are the
  algorithm's own recommendation for a new user.
- **Qere/Ketiv display.** The shipped WLC text carries the ketiv consonants and
  the qere vowels in the standard convention, and nothing in the pipeline marks
  which verses even have a qere. A real display needs a dedicated qere/ketiv
  dataset (Tanach.us publishes one) added to `build_full_bible_db.py` with its
  licence recorded in `assets/attributions.txt`, plus a column per token. A
  "qere" toggle over unmarked data would be a guess presented as scholarship.
- **Textual variants (NA/Byz).** The Byzantine text is free; the *collation* is
  the copyrighted work (NA28 apparatus). Deferred until a licence-clean collation
  is verified.
- **Phrase-paced recitation** (tap a break to hear just that phrase). The data is
  there — `senseUnits` already splits the verse — but pacing the player means the
  recitation bar needs a phrase queue, highlighting, and a stop rule for a queue
  that changes under the user. That is an audio-bar redesign, worth doing on its
  own rather than bolted onto this pass.
- **Bundled Hebrew recitation voice.** Unchanged from the embedded-voice work: no
  redistributable Hebrew model has been validated.

---

## Report — 2026-11-13

| Item | Evidence |
|---|---|
| Structured senses (`lexicon_senses`) | 1,807 Hebrew + 5,249 Greek entries; gates in `build_lexicon_senses` + `validate_database`; `test/lexicon_senses_test.dart`, `test/definition_depth_sheet_test.dart`, `scripts/test_build_depth_tables.py` |
| Tree word → lexicon entry, collapsible nodes | `test/syntax_tree_view_widget_test.dart` |
| Root (shoresh) search | `lexicon_roots` + `/root`; `test/root_study_widget_test.dart`, release-DB root check in `test/database_test.dart` |
| Paradigm tables (attested forms) | `lib/shared/utils/paradigm.dart`; `test/paradigm_test.dart`; sheet pane in `test/definition_depth_sheet_test.dart` |
| Qere/Ketiv | deferred, why written above |
| MACULA participants ("who is he") | 53,097 subject + 12,859 referent links; `participant_links` gate; `test/definition_depth_sheet_test.dart` |
| Textual variants | deferred |
| Adaptive reader threshold | `adaptiveReaderThreshold`; `test/reader_mode_test.dart` |
| Marking words known from reading | `SrsDao.markKnown`; `test/srs_mark_known_test.dart` |
| FSRS | deferred; `srs_reviews` log ships (`test/srs_mark_known_test.dart`) |
| Transliteration in practice mode | `_transliterate` in `memorization_practice_screen.dart` |
| Pipeline tests | `scripts/test_pipeline_gates.py`, `scripts/test_build_depth_tables.py` |
| Beginner on-ramp + time to first verse | `/start`, `first_run.dart`, `test/first_steps_widget_test.dart`, `test/first_run_test.dart` |

`kBundledDatabaseVersion` 4 → 5 for the new layers.

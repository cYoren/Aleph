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
- [ ] Structured senses: parse the numbered sense hierarchy into a `lexicon_senses`
      table instead of one flattened text blob.

### 1.2 Real syntax trees — **shipped**
- [x] Imported the **MACULA Greek** (SBLGNT lowfat) and **MACULA Hebrew** (WLC lowfat)
      treebanks (Clear Bible, CC BY 4.0): per-verse sentence trees in a `syntax_trees`
      table, 100% verse coverage (31,152/31,152).
- [x] The syntax screen renders the real trees as an indented outline with role/phrase
      labels; the POS-heuristic sketch remains only as a fallback for old DBs, still
      labeled as a sketch.
- [ ] Tap a tree word to open its lexicon entry; collapsible nodes for long sentences.

### 1.3 Concordance / word study — **in progress**
- [x] "See all occurrences" of a word from the definition sheet: every verse containing a
      Strong's number / lemma, in canonical order, tappable to jump into the reader.
- [x] Occurrences grouped by book with headers (list capped at 300 with a count
      note; true pagination still open for hyper-frequent particles).
- [x] Word search: by Strong's id, lemma (pointing/accent-insensitive),
      transliteration, or English gloss — results open the concordance.
- [ ] True root (shoresh) search across binyanim.

---

## Phase 2 — The learning loop (unify depth + learning)

### 2.1 Proper spaced repetition — **in progress**
- [x] Replace the linear ±0.2 mastery bump with the SM-2 algorithm
      (easiness factor, expanding intervals) in `SrsDao`.
- [ ] Upgrade to FSRS once review volume justifies it.
- [x] Frequency-ordered vocabulary decks with live text-coverage stats and an SRS
      review queue (`/vocabulary`).

### 2.2 Personalized Reader's Bible mode ⭐ the differentiator
- [x] v1 shipped: reading mode where mastered words render plain and rare words
      (below 30 whole-Bible occurrences) get an inline gloss — a printed Reader's
      Greek NT, but personalized and adaptive. Reading itself becomes the SRS loop.
- [ ] Next: adaptive per-user threshold and marking words known from reading exposure.
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
- [ ] Add transliteration/pronunciation support inside practice mode (Hebrew niqqud
      display modes already apply).
- [x] **Audio recitation shipped via platform TTS** (`lib/features/audio/`), which
      avoids the recording-licensing question entirely. Continuous chapter
      playback with the spoken verse highlighted and scrolled into view; also
      word-level playback from the definition sheet.
      - Voices: `he-IL` and `el-GR` from the OS. **Pronunciation is Modern
        Israeli / Modern Greek** — living traditions, not reconstructed
        ancient pronunciation, and not the Erasmian Greek most seminaries
        teach. This is stated in Settings rather than glossed over. No
        platform TTS can produce Erasmian.
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
      found; the player interface would not need to change.

### 2.4 Morphology as a learning tool
- [x] Parsing quizzes ("what form is this?") driven by the morphology decoder —
      from the vocabulary screen, Hebrew and Greek.
- [ ] Paradigm tables (show the full conjugation/declension a form belongs to).

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
      tap a break to hear just that phrase.

- [x] Display controls for the Hebrew text: full / vowels-only / consonantal modes —
      reading unpointed text is itself a learning progression.
- [ ] Qere/Ketiv display.
- [x] Cross-references: OpenBible.info dataset (CC-BY, ~340k pairs), per-verse
      sheet in the reader with previews, best-voted first.
- [ ] Participant/referent data from MACULA (who is "he" in this verse?).
- [ ] Textual variants (NT: NA/Byz differences) — long-term.

---

## Engineering foundation

- [ ] Test coverage for the data pipeline first (versification mapping, coverage gates,
      lexicon enrichment) — every depth feature builds on that layer.
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

# Original Bible — Roadmap

## Mission

Help people get truly in depth with the Bible **in its original languages** — Hebrew and
Greek — and support them in what they need along the way (vocabulary, reading fluency,
memorizing psalms and passages), all offline-first and without clutter.

**Guiding principle for prioritization:** every feature should either
(a) deepen genuine engagement with the original text, or
(b) help the user *learn* so that engagement becomes easier over time.
Features that do neither (generic engagement mechanics, social feeds, devotional
aggregation) are explicitly de-prioritized.

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

### 2.3 Passage memorization (psalms, in Hebrew) ⭐
- [x] v1 shipped: pick any chapter (Psalms default) → progressive word hiding
      (warm-up/challenge/first-letters) → self-graded recall, scheduled by the shared
      SM-2 engine (`/memorization`).
- [ ] Add transliteration/pronunciation support inside practice mode (Hebrew niqqud
      display modes already apply).
- [ ] Audio recitation (verify licensing of the free Shmuelof Hebrew recordings before
      bundling).

### 2.4 Morphology as a learning tool
- [x] Parsing quizzes ("what form is this?") driven by the morphology decoder —
      from the vocabulary screen, Hebrew and Greek.
- [ ] Paradigm tables (show the full conjugation/declension a form belongs to).

---

## Phase 3 — Reader depth features

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
      encrypted.

---

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

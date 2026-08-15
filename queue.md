# Work queue for a scheduled worker

Batched, token-heavy jobs that are cheap to specify and expensive to do inline.
Each task below is self-contained: paste the **Prompt** block into a scheduled
worker, and it has everything it needs without this conversation.

Regenerate the untranslated inventory at any time with:

```bash
python3 scripts/find_untranslated.py
```

---

## Task 1 — Translate book names into 6 languages

**Status:** done. All 8 locales (`en`, `pt`, `de`, `fr`, `es`, `ru`, `zh`, `ko`)
are filled in `assets/book_names.json`, 66 books each, keys verified against
the `en` abbreviation set. Kept here as a reference for the naming
conventions used, in case a name needs correcting later.

### Prompt

> You are editing `assets/book_names.json` in a Bible reading app.
>
> The file maps a locale to a map of book abbreviation → book name. The `en`
> and `pt` locales are already complete; use `en` as the list of the 66
> abbreviations you must cover, and copy that key order exactly.
>
> Add six new top-level locale keys: `de`, `fr`, `es`, `ru`, `zh`, `ko`.
> For each, give the standard, conventional name of each book of the Bible as
> printed in a widely used Bible edition in that language — German (Luther
> tradition), French (Segond/Ostervald), Spanish (Reina-Valera), Russian
> (Synodal), Simplified Chinese (和合本), Korean (개역개정).
>
> Rules:
> - Keep every abbreviation key exactly as it appears in `en`. Do not invent,
>   rename, or omit any of the 66.
> - Numbered books keep their number in the local convention (e.g. German
>   `1. Mose`, `1. Korinther`; Chinese `哥林多前书`).
> - Do not translate the `_comment` key; update it to remove locales you have
>   completed from the "still to fill" list.
> - Output valid JSON, UTF-8, 2-space indent. Do not add trailing commas.
>
> When done, verify with:
> `python3 -c "import json;d=json.load(open('assets/book_names.json'));print({k:len(v) for k,v in d.items() if not k.startswith('_')})"`
> Every locale must report 66.

---

## Task 2 — Translate the remaining UI strings

**Status:** done. `python3 scripts/find_untranslated.py` reports 0 untranslated
ARB values across all 8 locales as of this writing. Re-run it after adding any
new user-facing string — the workflow below still applies to future additions.

### Prompt

> You are translating UI strings in a Flutter app's ARB files.
>
> Run `python3 scripts/find_untranslated.py` to list every key whose value is
> still byte-identical to English, per locale. Translate each of those values
> in `lib/l10n/app_<locale>.arb` for `de`, `fr`, `es`, `ru`, `zh`, `ko`.
>
> Context: this is a Bible reader for studying Hebrew and Greek in the
> original. Terminology to keep consistent and accurate:
> - "Masoretic accents" / te'amim — the Hebrew cantillation marks
> - "sense units" — phrases marked off by those accents
> - "recitation" — the app reading the text aloud
> - "vocabulary coverage" — the share of a book's words the user knows
>
> Rules:
> - Do NOT translate placeholder names inside braces. `{book}`, `{percent}`,
>   `{count}`, `{number}`, `{tradition}` must appear verbatim in the output,
>   though you may reorder them to suit the target grammar.
> - Do not add, remove, or rename keys. Do not touch `@`-prefixed metadata
>   entries or `@@locale`.
> - Keep the register plain and warm; the audience includes beginners who have
>   never read Hebrew or Greek.
> - `zh` is Simplified Chinese. `ko` uses 한글.
>
> After editing, verify:
> ```bash
> flutter gen-l10n && flutter analyze && flutter test test/l10n_parity_test.dart
> ```
> All three must pass. `find_untranslated.py` should then report far fewer
> remaining strings (a handful of legitimately identical ones may remain).

---

## Task 3 — Recover Greek lexicon entries for inflected Strong's ids

**Status:** open
**Size:** ~35 ids, plus a pipeline change
**File:** `scripts/build_full_bible_db.py`

The `words` table references Strong's ids that have no row in `lexicon`, so
those words are dropped from the vocabulary deck by
`lib/shared/utils/vocabulary_filter.dart`. Several are common, important words
a beginner needs.

Confirmed examples: `G1473` (ἐγώ, "I"), `G2258` (ἦν, "was"), `G4675` (σοῦ,
"your"), `G5216` (ὑμῶν), `G5209` (ὑμᾶς), `G2257` (ἡμῶν), `G1438` (ἑαυτοῦ),
`G5124` (τοῦτο).

These look like inflected-form Strong's numbers from the Textus Receptus
numbering, while the lexicon is keyed by lemma numbers only.

### Prompt

> In `scripts/build_full_bible_db.py`, Greek tokens carry Strong's ids that
> have no corresponding row in the `lexicon` table, so those words render with
> no definition and are filtered out of the vocabulary deck.
>
> First, quantify the gap:
> ```bash
> python3 - <<'EOF'
> import sqlite3
> db = sqlite3.connect('assets/bible.db')
> rows = db.execute("""
>   SELECT w.strongs, COUNT(*) n FROM words w
>   LEFT JOIN lexicon lx ON lx.strongs_id = w.strongs
>   WHERE w.language='grc' AND lx.strongs_id IS NULL
>   GROUP BY w.strongs ORDER BY n DESC""").fetchall()
> print(len(rows), 'ids;', sum(r[1] for r in rows), 'tokens')
> for r in rows[:40]: print(r)
> EOF
> ```
> Then do the same for `language='heb'`.
>
> Fix the pipeline so every Strong's id present in `words` resolves to a
> lexicon entry — most likely by mapping inflected-form ids onto their lemma
> entry, using the token's own `lemma` column as the join key when the
> Strong's id has no direct match.
>
> Constraints from AGENTS.md: this is a content-correctness change. Preserve
> attribution and license fields, and report the coverage delta before and
> after. Do not commit `assets/bible.db` — it is a generated artifact.
>
> Verify the gap is closed by re-running the query above, then rebuild and run
> `./scripts/validate_release.sh`, `flutter analyze`, `flutter test`.

---

## Task 4 — AI passage explanation

**Status:** done. Built against OpenRouter, opt-in and off by default. See
`lib/features/explain/`. The notes below are kept because several were found
only by testing the live model, and a regression in any of them is visible to
the reader.

**Model:** `nvidia/nemotron-3.5-lightning:free` via
`https://openrouter.ai/api/v1/chat/completions` (OpenAI-compatible).

### Two non-obvious things that will break the feature if changed

1. **It is a reasoning model, and it will print its own thinking as the
   answer.** Without `"reasoning": {"exclude": true}` in the request body, the
   reader sees `Here's a thinking process: 1. Analyze User Request...` instead
   of an explanation.
2. **It needs a large `max_tokens`.** It spends roughly 900 tokens reasoning
   before writing anything. At a few hundred it returns a truncated fragment
   with `finish_reason: length` — and note that `reasoning.exclude` hides the
   reasoning but does *not* stop it consuming the budget. 3000 is the shipped
   value; measured latency is about 5 seconds.

Both are asserted in `test/explain_service_test.dart`, and
`test/explain_live_smoke_test.dart` catches a regression against the real
endpoint (it skips unless a key is supplied).

### Key handling

The key is never committed. It is read with `String.fromEnvironment` and
supplied at build time:

```bash
flutter build ios --dart-define=OPENROUTER_API_KEY=sk-or-v1-...
```

With no key the feature is hidden entirely — no button, no settings switch —
so a source build with no key is a clean offline app rather than one with a
dead affordance.

**The accepted tradeoff:** a key compiled into the binary can be extracted by
anyone who downloads the app, and usage bills to the key owner. Put a spend
cap on it, and rotate it if the app gets popular. Rotate immediately if the
key was ever pasted into a chat, an issue, or a log.

### Possible follow-ups

- The free tier will rate-limit under real usage; `ExplainFailure.rateLimited`
  already surfaces a clear message, but a paid model id may be worth it.
- Explanations are re-fetched every time. Caching per verse would cut cost and
  latency, at the price of storing generated text on device.

---

## Done

- Localized book-name infrastructure (`assets/book_names.json`,
  `lib/providers/book_names_provider.dart`) with `en` + `pt` populated.
- `scripts/find_untranslated.py` to inventory untranslated ARB values and
  hardcoded Dart strings.

# STEPBible and SDBH — evaluated, not imported (2026-11-13)

Both datasets are licence-clean and both would add real depth. This is the decision, with the
numbers, before any code. Nothing here is imported.

Measured against the release database of 2026-11-13: `assets/bible.db` 222.6 MiB, 13,666 lexicon
entries, 607,217 tokens. Hebrew Strong's ids, two counts because the disambiguating letter suffix
matters: **7,938** distinct `lexicon.strongs_id` values starting with `H` (`H2050` and `H2050B` are
two), and **7,735** base ids once the suffix is dropped (`H2050B` → `H2050`). Every coverage number
below is against the 7,735 base ids, and says so.

---

## 1. STEPBible-Data (`STEPBible/STEPBible-Data`, CC BY 4.0)

Everything in the repository is CC BY 4.0, which permits redistribution and adaptation with
attribution. No share-alike obligation, so a derived table can ship under the app's own terms as
long as the source is credited. STEPBible's README asks for two things CC BY does not: that changes
be recorded and made available, and that the credit read "STEP Bible", linked to stepbible.org.
Neither is legally required; both are cheap, and the import should do them.

| Resource | Source size | What it is | Fit |
|---|---|---|---|
| **TIPNR** proper names | 8.0 MB | **12,728** tab-separated lines carry a `name@reference` tag, over **2,830** distinct name tags; every form of a name with Hebrew/Greek and every occurrence | **Yes — the strongest item in this list** |
| **TFLSJ** full LSJ | 22.7 MB + 8.0 MB extra | 5,523 distinct Greek lexemes, 5,709 rows, full LSJ with the Tyndale formatting | Partly |
| **TAHOT / TAGNT** word-level translations | ~95.6 MB (6 files) | gloss/translation per word, per edition | No, as-is |
| **TVTMS** versification | 5.5 MB | rule-based mapping between English/Hebrew/Latin/Greek traditions, with conditional tests | Not now |

### TIPNR — recommended

The app can already answer "what does this word mean". It cannot answer **which Herod**, **which
Mary**, **which Antioch** — and the definition sheet's participant pane ("subject: the Pharisees")
makes the gap visible: a name is shown and then nothing. TIPNR is exactly that layer: a unique id
per individual or place, every surface form, and an exhaustive reference list.

- **Size delta:** the useful projection is `(name_id, surface_form, strongs, category, every
  reference)` — roughly the 12,728 tagged lines above, ~1.5–2 MB in SQLite. **+1%** of the database.
- **How the count was taken:** every line of `TIPNR … .txt` whose first tab-separated field matches
  `name@reference` (12,728), and the distinct part before the `@` (2,830). TIPNR separates records
  with `$` and continues them on lines that start with a tab, so a "record" count depends on the
  parser; the tag count is what the projection needs and what this number is.
- **Licence obligation:** attribution in `assets/attributions.txt` and the ROADMAP source table.
- **One line:** import it; it is the only one of the four that answers a question a reader actually
  asks while reading, and it costs 1% of the database.

### TFLSJ — partly

Abbott-Smith already ships for Greek (5,249 entries with structured senses). LSJ is deeper but
much larger, and the app's Greek coverage is already 86.8% of tokens with a real dictionary. The
honest use is not "replace Abbott-Smith" but "offer LSJ where Abbott-Smith is thin", which needs a
per-entry decision and a UI that explains why one word has two dictionaries.

- **Size delta:** ~8–12 MB in SQLite for the full text, or ~3 MB if only the entries Abbott-Smith
  lacks are kept.
- **Licence obligation:** attribution, plus STEPBible's request that changes be recorded.
- **One line:** not now — it deepens a screen that is already deep, and the mission's next barrier
  is Hebrew-first reading, not Greek lexicography.

### TAHOT / TAGNT — no

~95 MB of per-word translation data. The app already ships eight full translations and a gloss
layer in seven languages. Importing this would double the database to buy a feature nobody has
asked for in the product's own terms.

- **One line:** no; the size is the whole argument.

### TVTMS — not now

It is a rule engine, not a table: each row is a mapping plus a **Tests** column
(`Gen.32:33=Last & Gen.32:1=Exist`) that has to be evaluated against the source edition before the
mapping applies. `scripts/versification_overrides.json` is a static offset table that works today.
TVTMS would replace it only by also implementing the evaluator, and the current file is not a
source of bugs.

- **One line:** keep the static overrides; revisit if versification becomes a bug source, because
  TVTMS is the right long-term source.

---

## 2. SDBH / UBS open licence (`ubsicap/ubs-open-license`, CC BY-SA 4.0)

The UBS Dictionary of Biblical Hebrew (SDBH) and of the Greek New Testament (SDGNT) carry
**semantic domains** per lexeme and per sense, in six languages (en, es, fr, pt, zh-hans,
zh-hant). This is the first layer that lets a reader look a word up **by concept** rather than by
root or by letter.

- **Source size:** Hebrew `UBSHebrewDic-v0.9.4-en.JSON` 24.1 MB; Greek `UBSGreekNTDic-v1.1-en.JSON`
  15.5 MB.
- **Coverage measured against our own data:** SDBH lists **7,957** Hebrew Strong's ids (every
  `StrongCodes` entry starting with `H`, normalized to `H` + four digits), of which **7,214 are base
  ids the app already has** — **93.3% of our 7,735**. Greek: 5,397 of 5,507 entries carry a
  Strong's id.
- **Size delta, measured by building the derived table:** Hebrew **3.2 MB** (20,567 rows),
  Greek **1.1 MB** (9,054 rows) — **4.3 MB, +2%** of the database, replacing 39 MB of JSON.
- **Licence obligation — the reason this is a decision and not a task:** **CC BY-SA 4.0 is
  share-alike.** A `semantic_domains` table derived from SDBH is a derivative work and must itself
  be licensed CC BY-SA 4.0. That is compatible with shipping it inside the app *as a data table*
  (the app's own code stays under its own licence), but it means:
  - the table and any export of it must carry the CC BY-SA notice and the SDBH attribution;
  - if a future sync or export feature ships this table to a user's own file, that file is
    share-alike too;
  - the ROADMAP's licence table must say so next to the row, not in a footnote.
- **One line:** import it, as a `semantic_domains` table with the share-alike notice stored beside
  the data — "look up by concept" is the one depth feature the app has no answer for at all, and it
  costs 2% of the database.

---

## Recommendation, in order

1. **SDBH semantic domains** — 4.3 MB, +2%, answers a question nothing else in the app answers.
   Blocked only on deciding how to carry the share-alike notice (a `licence` column on the table
   plus the attribution screen entry is enough).
2. **TIPNR proper names** — 1.5–2 MB, +1%, makes the participant pane finish its sentence.
3. **TFLSJ** — later, and only as a supplement to Abbott-Smith.
4. **TVTMS** — later, and only if versification becomes a bug source.
5. **TAHOT / TAGNT** — no.

Nothing in this report is imported in this pass.

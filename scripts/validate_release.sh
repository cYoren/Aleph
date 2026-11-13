#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DB_PATH="$ROOT_DIR/assets/bible.db"

echo "Running release validation..."

if [[ ! -f "$DB_PATH" ]]; then
  echo "ERROR: Missing database asset at $DB_PATH"
  exit 1
fi

required_tables=(
  books
  verses
  translations
  translation_verses
  translation_ref_map
  words
  lexicon
  cross_references
  syntax_trees
  lexicon_senses
  lexicon_roots
)

for table in "${required_tables[@]}"; do
  count="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='${table}';")"
  if [[ "$count" != "1" ]]; then
    echo "ERROR: Required table not found: $table"
    exit 1
  fi
done

books_count="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM books;")"
distinct_verse_books="$(sqlite3 "$DB_PATH" "SELECT COUNT(DISTINCT book_id) FROM verses;")"
verses_count="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM verses;")"
kjv_translation_verses="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM translation_verses WHERE translation_id='KJV';")"
words_count="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM words;")"
lexicon_count="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM lexicon;")"
enabled_translations="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM translations WHERE enabled=1;")"

required_enabled_translations=(
  KJV
  ALMEIDA
  LUTHER1912
  OSTERVALD
  SYNODAL
  VALERA1909
  CUVS
  KOREAN
)

if (( books_count != 66 )); then
  echo "ERROR: Expected 66 books, found $books_count"
  exit 1
fi

if (( distinct_verse_books != 66 )); then
  echo "ERROR: Expected verses for 66 books, found $distinct_verse_books"
  exit 1
fi

if (( verses_count < 31100 )); then
  echo "ERROR: Expected at least 31,100 verses, found $verses_count"
  exit 1
fi

if (( kjv_translation_verses < 31100 )); then
  echo "ERROR: Expected at least 31,100 KJV translation verses, found $kjv_translation_verses"
  exit 1
fi

if (( words_count < 600000 )); then
  echo "ERROR: Expected at least 600,000 words, found $words_count"
  exit 1
fi

if (( lexicon_count < 13000 )); then
  echo "ERROR: Expected at least 13,000 lexicon entries, found $lexicon_count"
  exit 1
fi

gloss_languages="$(sqlite3 "$DB_PATH" "SELECT COUNT(DISTINCT lang) FROM lexicon_gloss_i18n;" 2>/dev/null || echo 0)"
if (( gloss_languages < 7 )); then
  echo "ERROR: Expected translated glosses for 7 languages in lexicon_gloss_i18n, found $gloss_languages"
  exit 1
fi

# Counting languages alone would pass a language with a handful of rows, so
# check each one against the number of distinct Strong's ids that carry a gloss.
glossable_strongs="$(sqlite3 "$DB_PATH" "SELECT COUNT(DISTINCT strongs_id) FROM lexicon WHERE strongs_id IS NOT NULL AND strongs_id != '' AND gloss IS NOT NULL AND gloss != '';")"
for lang in pt es de fr ru zh ko; do
  lang_glosses="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM lexicon_gloss_i18n WHERE lang='${lang}';")"
  if (( glossable_strongs > 0 && lang_glosses * 100 < glossable_strongs * 95 )); then
    echo "ERROR: translated gloss coverage for '${lang}' is ${lang_glosses}/${glossable_strongs} (below 95%)"
    exit 1
  fi
done

if (( enabled_translations < 8 )); then
  echo "ERROR: Expected at least 8 enabled translations (KJV + DE/RU/PT/ES/FR + ZH + KO), found $enabled_translations"
  exit 1
fi

for translation_id in "${required_enabled_translations[@]}"; do
  is_enabled="$(sqlite3 "$DB_PATH" "SELECT COALESCE((SELECT enabled FROM translations WHERE id='${translation_id}' LIMIT 1), 0);")"
  if [[ "$is_enabled" != "1" ]]; then
    echo "ERROR: Required translation not enabled: $translation_id"
    exit 1
  fi
done

kougo_enabled="$(sqlite3 "$DB_PATH" "SELECT COALESCE((SELECT enabled FROM translations WHERE id='KOUGO' LIMIT 1), 0);")"
if [[ "$kougo_enabled" != "0" ]]; then
  echo "ERROR: KOUGO must remain disabled for this release."
  exit 1
fi

kjv_missing_refs="$(sqlite3 "$DB_PATH" "
    SELECT COUNT(*)
    FROM verses v
    LEFT JOIN translation_verses tv
      ON tv.translation_id = 'KJV'
     AND tv.book_id = v.book_id
     AND tv.chapter = v.chapter
     AND tv.verse_number = v.verse_number
    WHERE tv.id IS NULL;
  ")"

if (( kjv_missing_refs != 0 )); then
  echo "ERROR: Expected 0 missing KJV canonical refs, found $kjv_missing_refs"
  sqlite3 "$DB_PATH" "
    SELECT v.book_id || ' ' || v.chapter || ':' || v.verse_number
    FROM verses v
    LEFT JOIN translation_verses tv
      ON tv.translation_id = 'KJV'
     AND tv.book_id = v.book_id
     AND tv.chapter = v.chapter
     AND tv.verse_number = v.verse_number
    WHERE tv.id IS NULL
    ORDER BY v.book_id, v.chapter, v.verse_number
    LIMIT 20;
  "
  exit 1
fi

for translation_id in "${required_enabled_translations[@]}"; do
  missing_refs="$(sqlite3 "$DB_PATH" "
      SELECT COUNT(*)
      FROM verses v
      LEFT JOIN translation_verses tv
        ON tv.translation_id = '${translation_id}'
       AND tv.book_id = v.book_id
       AND tv.chapter = v.chapter
       AND tv.verse_number = v.verse_number
      WHERE tv.id IS NULL;
    ")"
  if (( missing_refs != 0 )); then
    echo "ERROR: Expected 0 missing canonical refs for ${translation_id}, found $missing_refs"
    sqlite3 "$DB_PATH" "
      SELECT v.book_id || ' ' || v.chapter || ':' || v.verse_number
      FROM verses v
      LEFT JOIN translation_verses tv
        ON tv.translation_id = '${translation_id}'
       AND tv.book_id = v.book_id
       AND tv.chapter = v.chapter
       AND tv.verse_number = v.verse_number
      WHERE tv.id IS NULL
      ORDER BY v.book_id, v.chapter, v.verse_number
      LIMIT 20;
    "
    exit 1
  fi
done

# Lexicon enrichment gate: full Strong's dictionary definitions must be
# present (not just the legacy one-line gloss fallback).
enriched_lexicon="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM lexicon WHERE definition LIKE '%KJV renderings:%' OR LENGTH(definition) > 80;")"
if (( enriched_lexicon < 10000 )); then
  echo "ERROR: Expected at least 10,000 enriched lexicon definitions, found $enriched_lexicon"
  echo "       (build with Strong's enrichment enabled — do not pass --no-strongs-enrichment for releases)"
  exit 1
fi

cross_references_count="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM cross_references;")"
if (( cross_references_count < 200000 )); then
  echo "ERROR: Expected at least 200,000 cross-references, found $cross_references_count"
  exit 1
fi

syntax_trees_count="$(sqlite3 "$DB_PATH" "SELECT COALESCE(SUM(verses), 0) FROM syntax_trees;")"
if (( syntax_trees_count < 30000 )); then
  echo "ERROR: Expected at least 30,000 verses with syntax trees, found $syntax_trees_count"
  exit 1
fi

# The trees ship as one gzip block per book and the app reads the packed asset,
# so a database that was never compacted (or an asset that does not decode back
# to it) must fail here rather than reach a store.
echo "Checking the compacted database and the packed asset..."
python3 "$ROOT_DIR/scripts/prepare_bible_db.py" --check --db "$DB_PATH"

extended_lexicon_count="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM lexicon WHERE extended_definition IS NOT NULL AND extended_definition != '';")"
if (( extended_lexicon_count < 8000 )); then
  echo "ERROR: Expected at least 8,000 BDB/Abbott-Smith extended entries, found $extended_lexicon_count"
  exit 1
fi

echo "Checking bundled Greek speech assets and corpus pronunciations..."
python3 "$ROOT_DIR/scripts/fetch_embedded_voices.py" --verify
python3 "$ROOT_DIR/scripts/build_greek_pronunciation_lexicon.py" --db "$DB_PATH" --check

# Structured senses: the definition sheet renders these instead of a flattened
# paragraph, so a release without them is a silent downgrade of the app's
# central screen.
lexicon_senses_count="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM lexicon_senses;")"
if (( lexicon_senses_count < 16000 )); then
  echo "ERROR: Expected at least 16,000 structured sense rows, found $lexicon_senses_count"
  exit 1
fi

# Hebrew roots (TWOT): the basis of root search across binyanim.
lexicon_roots_count="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM lexicon_roots;")"
if (( lexicon_roots_count < 4800 )); then
  echo "ERROR: Expected at least 4,800 Hebrew roots, found $lexicon_roots_count"
  exit 1
fi

# MACULA participant links: "who is he in this verse".
participant_links_count="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM words WHERE subject_text IS NOT NULL OR referent_text IS NOT NULL;")"
if (( participant_links_count < 40000 )); then
  echo "ERROR: Expected at least 40,000 participant links, found $participant_links_count"
  exit 1
fi

# Qere/Ketiv: the ~1.2k places where the scroll writes one thing and the
# tradition reads another. Both forms are stored per token; a build that skips
# the OSHB pass ships a reader that cannot show them.
qere_ketiv_count="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM words WHERE qere_text IS NOT NULL;")"
if (( qere_ketiv_count < 1180 )); then
  echo "ERROR: Expected at least 1,180 qere/ketiv tokens, found $qere_ketiv_count"
  exit 1
fi

# A marked row must be Hebrew and pointing only. This is the check that catches
# an OSHB editorial note (or a raw newline and its indentation) leaking into
# scripture, which the reader would render in the Hebrew font.
qere_dirty="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM words WHERE qere_text IS NOT NULL AND (qere_text GLOB '*[A-Za-z]*' OR ketiv_text GLOB '*[A-Za-z]*' OR qere_text LIKE '%' || char(10) || '%' OR ketiv_text LIKE '%' || char(10) || '%');")"
if (( qere_dirty != 0 )); then
  echo "ERROR: $qere_dirty qere/ketiv rows carry markup or editorial prose"
  exit 1
fi

qere_ketiv_pairs="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM words WHERE qere_text IS NOT NULL AND ketiv_text IS NOT NULL;")"
if (( qere_ketiv_pairs != qere_ketiv_count )); then
  echo "ERROR: $((qere_ketiv_count - qere_ketiv_pairs)) qere tokens have no written form"
  exit 1
fi

# Other editions: the reader's "other editions" pane. A text comparison, not
# an apparatus; a build that skips it ships a New Testament with no pane.
textual_variants_count="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM textual_variants;")"
if (( textual_variants_count < 8000 )); then
  echo "ERROR: Expected at least 8,000 readings from other editions, found $textual_variants_count"
  exit 1
fi

textual_variant_books="$(sqlite3 "$DB_PATH" "SELECT COUNT(DISTINCT book_id) FROM textual_variants;")"
if (( textual_variant_books != 27 )); then
  echo "ERROR: Expected other-edition readings in all 27 NT books, found $textual_variant_books"
  exit 1
fi

textual_variant_editions="$(sqlite3 "$DB_PATH" "SELECT COUNT(DISTINCT edition) FROM textual_variants;")"
if (( textual_variant_editions < 2 )); then
  echo "ERROR: Expected two other editions in textual_variants, found $textual_variant_editions"
  exit 1
fi

echo "Running lexicon enrichment unit tests..."
python3 "$ROOT_DIR/scripts/test_build_lexicon_enrichment.py" > /dev/null

echo "Running release-database compaction tests..."
python3 "$ROOT_DIR/scripts/test_prepare_bible_db.py" > /dev/null

echo "Running structured-sense and root-parsing tests..."
python3 "$ROOT_DIR/scripts/test_build_depth_tables.py" > /dev/null

echo "Running versification and coverage-gate tests..."
python3 "$ROOT_DIR/scripts/test_pipeline_gates.py" > /dev/null
echo "Running lexicon i18n pipeline tests..."
python3 "$ROOT_DIR/scripts/test_lexicon_i18n.py" > /dev/null
python3 "$ROOT_DIR/scripts/test_translation_delivery.py" > /dev/null

# Long-form translated content (definition + extended_definition). This reports
# per-language, per-field coverage and fails on genuine integrity problems
# (empty or stale rows). Missing translations are reported as a gap rather than
# a failure, because the content is delivered in batches; add --require-full on
# the validator once the batch is complete to make a gap fatal.
echo "Checking translated long-form lexicon coverage..."
python3 "$ROOT_DIR/scripts/validate_lexicon_i18n.py" --db "$DB_PATH"

# Once translated caches are supplied, require a complete validated delivery
# and its incorporation into the actual release database, not just cache files.
if compgen -G "$ROOT_DIR/data/lexicon_translations/[a-z][a-z].json" > /dev/null; then
  python3 "$ROOT_DIR/scripts/validate_translation_delivery.py" --db "$DB_PATH"
  python3 "$ROOT_DIR/scripts/validate_lexicon_i18n.py" --db "$DB_PATH" --require-full
fi

echo "Running structured-sense and root-parsing tests..."
python3 "$ROOT_DIR/scripts/test_build_depth_tables.py" > /dev/null

echo "Running versification and coverage-gate tests..."
python3 "$ROOT_DIR/scripts/test_pipeline_gates.py" > /dev/null

echo "OK: database asset and full-release integrity checks passed."
echo "  books=$books_count distinct_verse_books=$distinct_verse_books verses=$verses_count"
echo "  kjv_translation_verses=$kjv_translation_verses words=$words_count lexicon=$lexicon_count enabled_translations=$enabled_translations"
echo "  enriched_lexicon=$enriched_lexicon"
echo "  lexicon_senses=$lexicon_senses_count lexicon_roots=$lexicon_roots_count participant_links=$participant_links_count"
echo "  qere_ketiv=$qere_ketiv_count textual_variants=$textual_variants_count ($textual_variant_books books)"

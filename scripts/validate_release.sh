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

echo "Running lexicon enrichment unit tests..."
python3 "$ROOT_DIR/scripts/test_build_lexicon_enrichment.py" > /dev/null

echo "OK: database asset and full-release integrity checks passed."
echo "  books=$books_count distinct_verse_books=$distinct_verse_books verses=$verses_count"
echo "  kjv_translation_verses=$kjv_translation_verses words=$words_count lexicon=$lexicon_count enabled_translations=$enabled_translations"
echo "  enriched_lexicon=$enriched_lexicon"

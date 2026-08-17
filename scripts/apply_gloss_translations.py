#!/usr/bin/env python3
"""Fold the translated-gloss cache into the release database.

Reads every `data/gloss_translations/<lang>.json` produced by
`translate_glosses.py` and writes them into a `lexicon_gloss_i18n` table that
the app reads through `BibleDAO.glossLanguage`.

Run this after every `build_full_bible_db.py`, since that script rebuilds
`assets/bible.db` from scratch and the table would otherwise be missing. The
app treats a missing table as "no translations available" and shows English, so
forgetting this step degrades rather than breaks.

    python3 scripts/apply_gloss_translations.py
    python3 scripts/apply_gloss_translations.py --report
"""

from __future__ import annotations

import argparse
import json
import pathlib
import sqlite3
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
DEFAULT_DB = REPO / "assets" / "bible.db"
CACHE_DIR = REPO / "data" / "gloss_translations"

SCHEMA = """
CREATE TABLE IF NOT EXISTS lexicon_gloss_i18n (
    strongs_id TEXT NOT NULL,
    lang       TEXT NOT NULL,
    gloss      TEXT NOT NULL,
    PRIMARY KEY (strongs_id, lang)
)
"""

INDEX = (
    "CREATE INDEX IF NOT EXISTS idx_gloss_i18n_lang "
    "ON lexicon_gloss_i18n(lang, strongs_id)"
)


def load_cache(path: pathlib.Path) -> dict[str, str]:
    with path.open(encoding="utf-8") as handle:
        data = json.load(handle)
    return {
        key: value.strip()
        for key, value in data.items()
        if not key.startswith("_") and isinstance(value, str) and value.strip()
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=pathlib.Path, default=DEFAULT_DB)
    parser.add_argument("--cache-dir", type=pathlib.Path, default=CACHE_DIR)
    parser.add_argument(
        "--report",
        action="store_true",
        help="print per-language coverage and exit without writing",
    )
    args = parser.parse_args()

    if not args.db.exists():
        print(f"No database at {args.db}.", file=sys.stderr)
        return 2

    caches = sorted(args.cache_dir.glob("*.json")) if args.cache_dir.exists() else []
    if not caches:
        print(
            f"No translation caches in {args.cache_dir}. "
            "Run scripts/translate_glosses.py first.",
            file=sys.stderr,
        )
        return 1

    db = sqlite3.connect(args.db)
    try:
        total_glosses = db.execute(
            "SELECT COUNT(DISTINCT strongs_id) FROM lexicon "
            "WHERE strongs_id IS NOT NULL AND strongs_id != '' "
            "AND gloss IS NOT NULL AND gloss != ''"
        ).fetchone()[0]

        if args.report:
            for path in caches:
                entries = load_cache(path)
                pct = 100.0 * len(entries) / total_glosses if total_glosses else 0.0
                print(f"{path.stem}: {len(entries)}/{total_glosses} ({pct:.1f}%)")
            return 0

        db.execute(SCHEMA)
        db.execute(INDEX)

        written = 0
        for path in caches:
            lang = path.stem
            entries = load_cache(path)
            db.execute("DELETE FROM lexicon_gloss_i18n WHERE lang = ?", (lang,))
            db.executemany(
                "INSERT INTO lexicon_gloss_i18n (strongs_id, lang, gloss) "
                "VALUES (?, ?, ?)",
                [(sid, lang, gloss) for sid, gloss in entries.items()],
            )
            pct = 100.0 * len(entries) / total_glosses if total_glosses else 0.0
            print(f"{lang}: wrote {len(entries)} glosses ({pct:.1f}% coverage)")
            written += len(entries)

        db.commit()
        print(f"Total {written} translated glosses in {args.db}")
    finally:
        db.close()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

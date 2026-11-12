#!/usr/bin/env python3
"""Fold the translated long-form lexicon content into the release database.

Reads every `data/lexicon_translations/<lang>.json` produced by
`translate_lexicon_definitions.py` and writes them into the
`lexicon_definition_i18n` table that `BibleDAO` reads.

`build_full_bible_db.py` calls `write_lexicon_translations` itself, so a release
build that regenerates the database picks the content up automatically. Run this
script directly only to refresh an existing database, or with `--report` to see
coverage per language and field without writing anything.

    python3 scripts/apply_lexicon_translations.py
    python3 scripts/apply_lexicon_translations.py --report
"""

from __future__ import annotations

import argparse
import pathlib
import sqlite3
import sys

from lexicon_definitions_i18n import (
    CACHE_DIR,
    DEFAULT_DB,
    LANGUAGES,
    coverage_report,
    write_lexicon_translations,
)


def print_report(db: sqlite3.Connection) -> int:
    report = coverage_report(db)
    if not report["table_present"]:
        print(
            "lexicon_definition_i18n is absent: no translated long-form content "
            "is present in this database."
        )
        print(
            f"  source rows with definition: {report['total_definition']}, "
            f"with extended_definition: {report['total_extended_definition']}"
        )
        return 0

    print(
        f"Source rows — definition: {report['total_definition']}, "
        f"extended_definition: {report['total_extended_definition']}"
    )
    any_gap = False
    for lang, stats in sorted(report["languages"].items()):
        name = LANGUAGES.get(lang, lang)
        for field in ("definition", "extended_definition"):
            have = stats[field]["have"]
            total = stats[field]["total"]
            pct = 100.0 * have / total if total else 0.0
            flag = "" if total and have >= total else "  <-- gap"
            if flag:
                any_gap = True
            print(f"  {lang} ({name}) {field}: {have}/{total} ({pct:.1f}%){flag}")
    if any_gap:
        print(
            "\nGaps above are untranslated long-form content; the app falls "
            "back to the English original for those rows and labels the source."
        )
    return 0


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

    db = sqlite3.connect(args.db)
    try:
        if args.report:
            return print_report(db)

        caches = sorted(args.cache_dir.glob("*.json")) if args.cache_dir.exists() else []
        caches = [p for p in caches if p.stem in LANGUAGES]
        if not caches:
            print(
                f"No translation caches in {args.cache_dir}. "
                "Run scripts/translate_lexicon_definitions.py first.",
                file=sys.stderr,
            )
            return 1

        written = write_lexicon_translations(db, args.cache_dir)
        db.commit()
        print(f"Wrote {written} translated long-form values into {args.db}")
        print_report(db)
    finally:
        db.close()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

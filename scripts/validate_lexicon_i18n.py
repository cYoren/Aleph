#!/usr/bin/env python3
"""Measure real coverage of the translated long-form lexicon content.

`validate_release.sh` gates the release database on this. A gate that only
counted "are seven languages present?" would pass a language with a handful of
rows, so this checks each language against *each field* and reports the gaps
that actually matter:

* entries present in `lexicon` with English text but absent from the i18n table,
* translations stored as empty strings,
* translations whose stored source hash no longer matches the current English
  text (stale after the original changed),
* translations byte-identical to the English original (still untranslated).

Exit status: 0 when the data is structurally sound (gaps are reported but do not
fail), or non-zero when `--require-full` is given and any gap remains, or when a
genuine integrity problem is found.

    python3 scripts/validate_lexicon_i18n.py
    python3 scripts/validate_lexicon_i18n.py --require-full
"""

from __future__ import annotations

import argparse
import pathlib
import sqlite3
import sys

from lexicon_definitions_i18n import (
    DEFAULT_DB,
    LANGUAGES,
    sha256_text,
)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=pathlib.Path, default=DEFAULT_DB)
    parser.add_argument(
        "--require-full",
        action="store_true",
        help="fail unless every language covers every field completely",
    )
    args = parser.parse_args()

    if not args.db.exists():
        print(f"No database at {args.db}.", file=sys.stderr)
        return 2

    db = sqlite3.connect(args.db)
    try:
        has_table = db.execute(
            "SELECT COUNT(*) FROM sqlite_master "
            "WHERE type='table' AND name='lexicon_definition_i18n'"
        ).fetchone()[0]
        if not has_table:
            print(
                "lexicon_definition_i18n is absent — no translated long-form "
                "content has been generated yet."
            )
            print(
                "Run scripts/translate_lexicon_definitions.py --apply and "
                "scripts/apply_lexicon_translations.py to fill it."
            )
            return 1 if args.require_full else 0

        # Per lemma: current source text and hashes.
        source = {
            lemma: (definition, extended)
            for lemma, definition, extended in db.execute(
                "SELECT lemma, COALESCE(definition, ''), "
                "COALESCE(extended_definition, '') FROM lexicon"
            )
        }

        integrity_problems = 0
        total_gaps = 0
        languages = sorted(
            {row[0] for row in db.execute("SELECT DISTINCT lang FROM lexicon_definition_i18n")}
        )

        print(f"Languages with any translated content: {len(languages)}")
        for lang in languages:
            rows = {
                lemma: (definition, extended, sdef, sext, method, revision)
                for lemma, definition, extended, sdef, sext, method, revision in db.execute(
                    "SELECT lemma, definition, extended_definition, "
                    "source_definition_sha256, source_extended_sha256, method, revision "
                    "FROM lexicon_definition_i18n WHERE lang = ?",
                    (lang,),
                )
            }
            name = LANGUAGES.get(lang, lang)
            print(f"\n[{lang}] {name} — {len(rows)} rows cached")
            for field, index in (("definition", 0), ("extended_definition", 1)):
                have = 0
                empty = 0
                stale = 0
                identical = 0
                expected = 0
                for lemma, (definition, extended) in source.items():
                    english = definition if field == "definition" else extended
                    if not english:
                        continue
                    expected += 1
                    row = rows.get(lemma)
                    if row is None:
                        continue
                    translated = row[index]
                    if not translated:
                        empty += 1
                        continue
                    have += 1
                    stored_hash = row[2] if field == "definition" else row[3]
                    if stored_hash and stored_hash != sha256_text(english):
                        stale += 1
                    if translated.strip() == english.strip():
                        identical += 1
                missing = expected - have - empty
                gaps = missing + empty + stale + identical
                total_gaps += gaps
                if empty or stale or identical:
                    integrity_problems += empty + stale
                pct = 100.0 * have / expected if expected else 0.0
                status = "OK" if gaps == 0 else "GAP"
                print(
                    f"  {field}: {have}/{expected} ({pct:.1f}%) [{status}]"
                    + (f" missing={missing}" if missing else "")
                    + (f" empty={empty}" if empty else "")
                    + (f" stale={stale}" if stale else "")
                    + (f" still-english={identical}" if identical else "")
                )

        if total_gaps:
            print(
                "\nGaps reported above are untranslated or outdated rows. In the "
                "app every such row falls back to the labelled English original, "
                "so nothing is shown as a translation that is not one."
            )
        else:
            print("\nAll present languages cover every field completely.")

        if args.require_full and total_gaps:
            print("\n--require-full was set and gaps remain.", file=sys.stderr)
            return 1
        if integrity_problems:
            # Empty or stale rows are a real integrity problem, not just missing
            # work: fail regardless of --require-full.
            print(
                f"\nIntegrity problem: {integrity_problems} empty/stale rows.",
                file=sys.stderr,
            )
            return 1
    finally:
        db.close()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

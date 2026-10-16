#!/usr/bin/env python3
"""Export the real long-form lexicon content with stable identity and hashes.

The translated content is delivered offline, so before anything is translated
we need a faithful, reproducible picture of what the English originals are:

* every lexicon row keyed by `lemma` (the table's primary key — Strong's alone
  is *not* unique: H1121 has seven distinct lemma rows, and IDs like `H0430`
  and `H0871A` must keep their leading zeros and suffixes),
* a SHA-256 of the exact text of each of the two prose fields, which is the
  identity a translation is cached and invalidated on,
* the deduplication ratio, so the cost estimate reflects real repeat work.

Nothing is written into git by default beyond a small manifest: the full
English text already lives in the generated database and can be reproduced with

    python3 scripts/export_lexicon_definitions.py

Use `--bundle PATH` to emit the full source bundle for an external translation
worker, and `--estimate` to print the cost estimate for the seven languages.

    python3 scripts/export_lexicon_definitions.py --estimate
    python3 scripts/export_lexicon_definitions.py --bundle /tmp/lexicon_source.json
"""

from __future__ import annotations

import argparse
import json
import pathlib
import sqlite3
import sys

from lexicon_definitions_i18n import (
    CACHE_DIR,
    DEFAULT_DB,
    FIELDS,
    LANGUAGES,
    REPO,
    estimate,
    source_rows_with_hashes,
    unique_source_texts,
)

MANIFEST = CACHE_DIR / "_source_manifest.json"


def build_bundle(unique_texts: dict[str, dict[str, str]]) -> dict:
    bundle = {"schema": 1, "fields": {}, "texts": {field: {} for field in FIELDS}}
    for field in FIELDS:
        texts = unique_texts.get(field, {})
        bundle["fields"][field] = {
            "unique_texts": len(texts),
            "source_chars": sum(len(t) for t in texts.values()),
        }
        for digest, text in texts.items():
            bundle["texts"][field][digest] = text
    return bundle


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=pathlib.Path, default=DEFAULT_DB)
    parser.add_argument("--bundle", type=pathlib.Path, default=None)
    parser.add_argument("--estimate", action="store_true")
    parser.add_argument(
        "--write-manifest",
        action="store_true",
        help=f"write {MANIFEST.relative_to(REPO)} (small; safe to version)",
    )
    args = parser.parse_args()

    if not args.db.exists():
        print(f"No database at {args.db}.", file=sys.stderr)
        return 2

    db = sqlite3.connect(args.db)
    try:
        rows = source_rows_with_hashes(db)
        unique_texts = unique_source_texts(db)
    finally:
        db.close()

    row_count = len(rows)
    per_field = {}
    for field in FIELDS:
        distinct_on_rows = len({r[f"{field}_sha256"] for r in rows if r[f"{field}_sha256"]})
        unique = len(unique_texts.get(field, {}))
        chars = sum(len(r[field]) for r in rows if r[field])
        per_field[field] = {
            "rows_with_text": sum(1 for r in rows if r[field]),
            "distinct_row_hashes": distinct_on_rows,
            "unique_texts": unique,
            "total_chars": chars,
        }

    manifest = {
        "schema": 1,
        "identity": "lexicon.lemma (primary key)",
        "hash": "sha256 of the exact English text, per field",
        "db": args.db.name,
        "row_count": row_count,
        "languages": LANGUAGES,
        "fields": per_field,
    }

    print(f"Lexicon rows: {row_count}")
    for field, stats in per_field.items():
        dedup = 1 - (stats["unique_texts"] / stats["rows_with_text"] or 0)
        print(
            f"  {field}: {stats['rows_with_text']} rows, "
            f"{stats['unique_texts']} unique texts "
            f"({dedup * 100:.1f}% deduplicated), "
            f"{stats['total_chars']:,} chars"
        )

    estimate_data = estimate(unique_texts, LANGUAGES)
    print(
        f"\nTotal source characters (both fields): "
        f"{estimate_data['total_source_chars']:,}"
    )
    print(
        "Seven-language source volume: "
        f"{estimate_data['total_source_chars_all_languages']:,} chars"
    )

    if args.bundle:
        bundle = build_bundle(unique_texts)
        args.bundle.parent.mkdir(parents=True, exist_ok=True)
        with args.bundle.open("w", encoding="utf-8") as handle:
            json.dump(bundle, handle, ensure_ascii=False, indent=0)
        print(f"Wrote source bundle to {args.bundle}")

    if args.write_manifest:
        CACHE_DIR.mkdir(parents=True, exist_ok=True)
        with MANIFEST.open("w", encoding="utf-8") as handle:
            json.dump(manifest, handle, ensure_ascii=False, indent=2)
            handle.write("\n")
        print(f"Wrote manifest to {MANIFEST}")

    if args.estimate:
        print("\nCost estimate (translation only, no review):")
        for key, cost in estimate_data["cost_usd"].items():
            print(f"  {cost['label']}: ~US$ {cost['usd']:,.2f} for all seven languages")
        print(
            "  Basis: ~3.5 characters/token, output assumed ~1.25x the source "
            "length, public list prices. Confirm the model and budget before "
            "spending anything."
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

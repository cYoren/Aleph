#!/usr/bin/env python3
"""Validate an external worker's seven-language lexicon cache before import.

Read-only on the source database. Checks the exact source hashes, full coverage,
metadata, unchanged English, and preserved Hebrew/Greek/Strong's tokens. Checks
format and protected text, not translation quality; human review remains needed.
"""
from __future__ import annotations

import argparse
from collections import Counter
import json
import pathlib
import re
import sqlite3
import unicodedata

from lexicon_definitions_i18n import (
    CACHE_DIR, DEFAULT_DB, FIELDS, LANGUAGES, source_needs_translation,
    unique_source_texts,
)

STRONGS = re.compile(r"(?<![A-Za-z0-9_])[HG]\d+[A-Z]?(?![A-Za-z0-9_])")


def _unique_keys(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def protected_tokens(text: str) -> Counter:
    # Compare lexical identity, not orthography: the model re-points Hebrew and
    # normalises final letter forms, which does not change the word. Consonants
    # and Strong's numbers are what a citation must preserve.
    text = unicodedata.normalize("NFD", text)
    tokens = Counter(STRONGS.findall(text))
    run = []
    for char in text + " ":
        code = ord(char)
        if unicodedata.combining(char):
            # Vowel points and accents belong to the letter before them; the
            # comparison already excludes them.
            continue
        original_letter = (
            0x0590 <= code <= 0x05FF
            or 0x0370 <= code <= 0x03FF
            or 0x1F00 <= code <= 0x1FFF
        )
        if original_letter:
            run.append(char)
            continue
        if len(run) >= 2:
            tokens["".join(run)] += 1
        run = []
    return tokens


def validate_delivery(source: dict, cache_dir: pathlib.Path) -> list[str]:
    errors = []
    for lang in LANGUAGES:
        path = cache_dir / f"{lang}.json"
        try:
            cache = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=_unique_keys)
        except (OSError, ValueError) as error:
            errors.append(f"{lang}: {error}")
            continue
        if not isinstance(cache, dict):
            errors.append(f"{lang}: cache must be a JSON object")
            continue
        meta = cache.get("_meta")
        if not isinstance(meta, dict) or meta.get("lang") != lang:
            errors.append(f"{lang}: missing or mismatched _meta.lang")
        else:
            for key in ("method", "provider", "model"):
                if not isinstance(meta.get(key), str) or not meta[key].strip():
                    errors.append(f"{lang}: _meta.{key} must identify the actual translation method")
            revision = meta.get("revision")
            if type(revision) is not int or revision < 1:
                errors.append(f"{lang}: _meta.revision must be a positive integer")
        for field in FIELDS:
            values = cache.get(field)
            if not isinstance(values, dict):
                errors.append(f"{lang}/{field}: missing translation object")
                continue
            expected = source[field]
            missing = expected.keys() - values.keys()
            unknown = values.keys() - expected.keys()
            if missing:
                errors.append(f"{lang}/{field}: {len(missing)} missing source hashes")
            if unknown:
                errors.append(f"{lang}/{field}: {len(unknown)} unknown/outdated source hashes")
            for digest in expected.keys() & values.keys():
                original, translated = expected[digest], values[digest]
                label = f"{lang}/{field}/{digest}"
                if not isinstance(translated, str) or not translated.strip():
                    errors.append(f"{label}: empty or invalid translation")
                    continue
                if translated.strip() == original.strip() and source_needs_translation(original):
                    errors.append(f"{label}: English source was copied unchanged")
                if protected_tokens(original) != protected_tokens(translated):
                    errors.append(f"{label}: Hebrew, Greek or Strong's tokens were changed")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=pathlib.Path, default=DEFAULT_DB)
    parser.add_argument("--cache-dir", type=pathlib.Path, default=CACHE_DIR)
    args = parser.parse_args()
    try:
        with sqlite3.connect(args.db.resolve().as_uri() + "?mode=ro", uri=True) as db:
            source = unique_source_texts(db)
        errors = validate_delivery(source, args.cache_dir)
    except (OSError, ValueError, sqlite3.Error) as error:
        print(f"Delivery validation failed: {error}")
        return 1
    if errors:
        print(f"Delivery rejected: {len(errors)} issue(s). First 30:")
        for error in errors[:30]:
            print(f"  {error}")
        return 1
    print("OK: all seven caches match the current source, coverage and protected-token contract.")
    print("Human translation review is still required; this gate does not verify meaning.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

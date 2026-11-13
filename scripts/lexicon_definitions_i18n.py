#!/usr/bin/env python3
"""Shared machinery for the translated long-form lexicon content.

The app already ships machine-translated *short glosses* in
`lexicon_gloss_i18n` (see `apply_gloss_translations.py`). The long-form
fields — `lexicon.definition` (composed from Strong's) and
`lexicon.extended_definition` (BDB / Abbott-Smith) — were still English-only,
so a reader who tapped a word saw their own language for "Quick Meaning" and
English for "Full Definition" and the scholarly entry.

This module holds the pieces both the export and the apply/integration steps
need, so the translation pipeline can stay resumable and auditable:

* a stable identity for every source row (`lemma`, the lexicon primary key),
* a SHA-256 of the *exact* source text, so a translation can be detected as
  stale when the English original changes,
* deduplication of provably identical texts (translate each once, then fan the
  result back out to every entry that shares it),
* the `lexicon_definition_i18n` table the app reads, plus a coverage report.

Nothing here talks to the network: `translate_lexicon_definitions.py` does.
"""

from __future__ import annotations

import hashlib
import json
import pathlib
import re
import sqlite3
from typing import Iterable, Iterator

REPO = pathlib.Path(__file__).resolve().parent.parent
DEFAULT_DB = REPO / "assets" / "bible.db"
CACHE_DIR = REPO / "data" / "lexicon_translations"

#: The seven non-English interface languages the content is delivered in.
LANGUAGES: dict[str, str] = {
    "pt": "Brazilian Portuguese",
    "es": "Spanish",
    "de": "German",
    "fr": "French",
    "ru": "Russian",
    "zh": "Simplified Chinese",
    "ko": "Korean",
}

#: The lexicon fields that carry prose meant to be read by the learner.
FIELDS = ("definition", "extended_definition")

#: Bumped when the translation *method* changes (prompt, model family, ...).
#: Stored per row so the app and the validator can tell what produced a text.
TRANSLATION_REVISION = 1

SCHEMA = """
CREATE TABLE IF NOT EXISTS lexicon_definition_i18n (
    lemma                      TEXT NOT NULL,
    lang                       TEXT NOT NULL,
    definition                 TEXT,
    extended_definition        TEXT,
    source_definition_sha256   TEXT,
    source_extended_sha256     TEXT,
    method                     TEXT NOT NULL DEFAULT 'machine',
    revision                   INTEGER NOT NULL DEFAULT 1,
    PRIMARY KEY (lemma, lang)
)
"""

INDEX = (
    "CREATE INDEX IF NOT EXISTS idx_lexicon_definition_i18n_lang "
    "ON lexicon_definition_i18n(lang)"
)


def sha256_text(text: str) -> str:
    """Stable content hash of one field's English text."""
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


# Grammatical and bibliographic labels that appear in BDB and Abbott-Smith.
# They are not English prose, and counting them marked pure-notation entries as
# untranslated.
_SCHOLARLY_LABELS = {
    "adj", "adv", "al", "ant", "aram", "cf", "cl", "cod", "conj", "cp",
    "dem", "diod", "etc", "eur", "eus", "gent", "herod", "hom", "impf",
    "inf", "ins", "jos", "lat", "loc", "lxx", "mm", "ms", "mss", "mt",
    "part", "perf", "pl", "plat", "plut", "polyb", "prep", "pron", "qv",
    "rec", "sing", "sq", "subst", "suff", "sv", "syr", "targ", "thuc", "wh",
}


def source_needs_translation(text: str) -> bool:
    """English prose needs translation; labels and cross-entries do not.

    Scholarly entries are often nothing but original-language headwords,
    grammatical labels and references (``כִּידֹן n.pr.m. 1 Ch 13:9``,
    ``Πρίσκιλλα, v.s. Πρίσκα.``). Counting fragments such as ``Ch`` or ``adj``
    as English marked hundreds of those as untranslated and made a complete
    run impossible. Two ordinary Latin words is where a label turns into prose.
    """
    words = [
        word.lower()
        for word in re.findall(r"[A-Za-z]{3,}", text)
        if word.lower() not in _SCHOLARLY_LABELS
    ]
    return len(words) >= 2


def read_source_rows(db: sqlite3.Connection) -> Iterator[tuple]:
    """Yield (lemma, strongs_id, language, definition, extended_definition)."""
    cursor = db.execute(
        "SELECT lemma, COALESCE(strongs_id, ''), COALESCE(language, ''), "
        "       COALESCE(definition, ''), COALESCE(extended_definition, '') "
        "FROM lexicon ORDER BY lemma"
    )
    yield from cursor


def unique_source_texts(
    db: sqlite3.Connection,
) -> dict[str, dict[str, str]]:
    """Every distinct source text, keyed by field then SHA-256.

    Deduplication is by the exact text, so two entries that share a definition
    verbatim are translated once. The hash is the identity the cache is keyed
    on, which is what makes "already translated" verifiable rather than
    assumed.
    """
    unique: dict[str, dict[str, str]] = {field: {} for field in FIELDS}
    for _lemma, _strongs, _language, definition, extended in read_source_rows(db):
        for field, text in (("definition", definition), ("extended_definition", extended)):
            if not text:
                continue
            unique[field].setdefault(sha256_text(text), text)
    return unique


def source_rows_with_hashes(db: sqlite3.Connection) -> list[dict]:
    """Every lexicon row with per-field source hashes, for fan-out writes."""
    rows = []
    for lemma, strongs, language, definition, extended in read_source_rows(db):
        rows.append(
            {
                "lemma": lemma,
                "strongs_id": strongs,
                "language": language,
                "definition": definition,
                "extended_definition": extended,
                "definition_sha256": sha256_text(definition) if definition else "",
                "extended_definition_sha256": sha256_text(extended) if extended else "",
            }
        )
    return rows


# --------------------------------------------------------------------------
# Translation cache: data/lexicon_translations/<lang>.json
# --------------------------------------------------------------------------


def cache_path(lang: str, cache_dir: pathlib.Path = CACHE_DIR) -> pathlib.Path:
    return cache_dir / f"{lang}.json"


def empty_cache(lang: str) -> dict:
    return {
        "_meta": {
            "lang": lang,
            "language": LANGUAGES.get(lang, lang),
            "method": "machine-translation",
            "provider": "openrouter",
            "revision": TRANSLATION_REVISION,
            "note": (
                "Machine-translated long-form lexicon content, keyed by the "
                "SHA-256 of the exact English source text. The English original "
                "stays in assets/bible.db; these are translations of it."
            ),
        },
        "definition": {},
        "extended_definition": {},
    }


def load_cache(lang: str, cache_dir: pathlib.Path = CACHE_DIR) -> dict:
    path = cache_path(lang, cache_dir)
    if not path.exists():
        return empty_cache(lang)
    with path.open(encoding="utf-8") as handle:
        data = json.load(handle)
    cache = empty_cache(lang)
    cache["_meta"].update({k: v for k, v in data.get("_meta", {}).items() if v is not None})
    for field in FIELDS:
        raw = data.get(field, {})
        cache[field] = {
            key: value
            for key, value in raw.items()
            if isinstance(value, str) and value.strip()
        }
    return cache


def save_cache(lang: str, cache: dict, cache_dir: pathlib.Path = CACHE_DIR) -> None:
    cache_dir.mkdir(parents=True, exist_ok=True)
    path = cache_path(lang, cache_dir)
    ordered = {
        "_meta": cache["_meta"],
        **{
            field: dict(sorted(cache.get(field, {}).items()))
            for field in FIELDS
        },
    }
    tmp = path.with_suffix(".json.tmp")
    with tmp.open("w", encoding="utf-8") as handle:
        json.dump(ordered, handle, ensure_ascii=False, indent=0)
        handle.write("\n")
    tmp.replace(path)


# --------------------------------------------------------------------------
# Database integration: lexicon_definition_i18n
# --------------------------------------------------------------------------


def write_lexicon_translations(
    db: sqlite3.Connection,
    cache_dir: pathlib.Path = CACHE_DIR,
) -> int:
    """Fold every cached language into `lexicon_definition_i18n`.

    Mirrors `apply_gloss_translations.write_gloss_translations`: called by
    `build_full_bible_db.py` so a release database can never ship without the
    translated long-form content that is available, and usable on its own to
    refresh an existing database.

    Returns the number of (lemma, lang, translated-field) values written.
    """
    db.execute(SCHEMA)
    db.execute(INDEX)

    caches = sorted(cache_dir.glob("*.json")) if cache_dir.exists() else []
    caches = [p for p in caches if p.stem in LANGUAGES]
    if not caches:
        return 0

    rows = source_rows_with_hashes(db)
    _collapse_existing_columns(db)

    written = 0
    for path in caches:
        cache = load_cache(path.stem, cache_dir)
        definitions = cache.get("definition", {})
        extendeds = cache.get("extended_definition", {})
        revision = int(cache["_meta"].get("revision", TRANSLATION_REVISION))
        method = str(cache["_meta"].get("method", "machine"))

        payload = []
        for row in rows:
            translated_def = definitions.get(row["definition_sha256"]) if row["definition"] else None
            translated_ext = extendeds.get(row["extended_definition_sha256"]) if row["extended_definition"] else None
            if translated_def is None and translated_ext is None:
                continue
            payload.append(
                (
                    row["lemma"],
                    path.stem,
                    translated_def,
                    translated_ext,
                    row["definition_sha256"],
                    row["extended_definition_sha256"],
                    method,
                    revision,
                )
            )
            written += int(translated_def is not None) + int(translated_ext is not None)

        db.execute("DELETE FROM lexicon_definition_i18n WHERE lang = ?", (path.stem,))
        db.executemany(
            "INSERT INTO lexicon_definition_i18n "
            "(lemma, lang, definition, extended_definition, "
            " source_definition_sha256, source_extended_sha256, method, revision) "
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            payload,
        )
    return written


def _collapse_existing_columns(db: sqlite3.Connection) -> None:
    """No-op hook kept for symmetry; the schema above owns the columns."""
    return


def coverage_report(
    db: sqlite3.Connection,
) -> dict:
    """Per-language and per-field coverage of the translated long-form content.

    A language "covers" a field only when every source row that has English text
    for it also has a non-empty translation recorded for it. Counting rows in
    the i18n table alone would let a language with a handful of rows look done.
    """
    total_def = db.execute(
        "SELECT COUNT(*) FROM lexicon WHERE definition IS NOT NULL AND definition != ''"
    ).fetchone()[0]
    total_ext = db.execute(
        "SELECT COUNT(*) FROM lexicon "
        "WHERE extended_definition IS NOT NULL AND extended_definition != ''"
    ).fetchone()[0]

    has_table = db.execute(
        "SELECT COUNT(*) FROM sqlite_master "
        "WHERE type='table' AND name='lexicon_definition_i18n'"
    ).fetchone()[0]
    if not has_table:
        return {
            "table_present": False,
            "total_definition": total_def,
            "total_extended_definition": total_ext,
            "languages": {},
        }

    languages: dict[str, dict] = {}
    rows = db.execute(
        "SELECT lang, "
        "  SUM(CASE WHEN definition IS NOT NULL AND definition != '' THEN 1 ELSE 0 END), "
        "  SUM(CASE WHEN extended_definition IS NOT NULL AND extended_definition != '' THEN 1 ELSE 0 END) "
        "FROM lexicon_definition_i18n GROUP BY lang"
    ).fetchall()
    for lang, def_count, ext_count in rows:
        languages[lang] = {
            "rows": db.execute(
                "SELECT COUNT(*) FROM lexicon_definition_i18n WHERE lang = ?",
                (lang,),
            ).fetchone()[0],
            "definition": {"have": def_count or 0, "total": total_def},
            "extended_definition": {"have": ext_count or 0, "total": total_ext},
        }
    return {
        "table_present": True,
        "total_definition": total_def,
        "total_extended_definition": total_ext,
        "languages": languages,
    }


def estimate(unique_texts: dict[str, dict[str, str]], languages: Iterable[str]) -> dict:
    """Rough, transparent cost estimate from the *real* exported source.

    The numbers are deliberately conservative and stated as such: character
    counts come straight from the database, token counts use the common
    ~3.5 characters/token ratio for English, and cost is quoted for a
    mid-tier and a cheaper chat model so the reader can see the spread rather
    than a single authoritative figure.
    """
    langs = list(languages)
    per_field = {}
    total_source_chars = 0
    for field in FIELDS:
        chars = sum(len(text) for text in unique_texts.get(field, {}).values())
        per_field[field] = {
            "unique_texts": len(unique_texts.get(field, {})),
            "source_chars": chars,
            "approx_source_tokens": round(chars / 3.5),
        }
        total_source_chars += chars

    languages_detail = {}
    for lang in langs:
        out_chars = total_source_chars * 1.25  # translations run a little longer
        languages_detail[lang] = {
            "input_tokens": round(total_source_chars / 3.5),
            "output_tokens": round(out_chars / 3.5),
        }

    # USD per million tokens (input, output), public list prices, indicative.
    pricing = {
        "cheap": {"label": "cheap chat model (e.g. a light 7-8B-class API model)", "input": 0.10, "output": 0.30},
        "mid": {"label": "mid-tier model (e.g. a strong general chat model)", "input": 0.60, "output": 2.40},
    }
    costs = {}
    for key, price in pricing.items():
        total = 0.0
        for lang in langs:
            detail = languages_detail[lang]
            total += (
                detail["input_tokens"] / 1_000_000 * price["input"]
                + detail["output_tokens"] / 1_000_000 * price["output"]
            )
        costs[key] = {"label": price["label"], "usd": round(total, 2)}

    return {
        "languages": langs,
        "per_field": per_field,
        "total_source_chars": total_source_chars,
        "total_source_chars_all_languages": total_source_chars * len(langs),
        "languages_detail": languages_detail,
        "cost_usd": costs,
    }

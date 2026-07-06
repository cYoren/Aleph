#!/usr/bin/env python3
"""Build a complete bible.db for the Flutter app schema.

This script downloads source token TSV files and optional Open Bibles XML files,
then materializes the app SQLite schema:
  - books
  - translations
  - verses (Hebrew OT + Greek NT)
  - translation_verses
  - translation_ref_map
  - words
  - lexicon
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import shutil
import sqlite3
import tempfile
import urllib.request
import xml.etree.ElementTree as ET
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple

SOURCE_REPO_RAW = "https://raw.githubusercontent.com/themikejr/bible-mcp"
DEFAULT_SOURCE_COMMIT = "65ed737a1ca800cfd8e49b60af3161fbf4149546"
SOURCE_FILENAMES = (
    "macula-hebrew.tsv",
    "macula-greek-SBLGNT.tsv",
    "ot_BSB.tsv",
    "nt_BSB.tsv",
)

OPEN_BIBLES_REPO_RAW = "https://raw.githubusercontent.com/seven1m/open-bibles"
DEFAULT_OPEN_BIBLES_COMMIT = "b396ccf097f6b229cbd4096f10da8fd948418099"

# Cross-references dataset from OpenBible.info (CC Attribution, ~344k pairs).
CROSS_REFERENCES_URL = "https://a.openbible.info/data/cross-references.zip"
CROSS_REFERENCES_ZIP = "cross_references.zip"
CROSS_REFERENCES_TXT = "cross_references.txt"

# OSIS-style book names used by the OpenBible dataset -> app book ids.
OSIS_TO_ABBR = {
    "Gen": "GEN", "Exod": "EXO", "Lev": "LEV", "Num": "NUM", "Deut": "DEU",
    "Josh": "JOS", "Judg": "JDG", "Ruth": "RUT", "1Sam": "1SA", "2Sam": "2SA",
    "1Kgs": "1KI", "2Kgs": "2KI", "1Chr": "1CH", "2Chr": "2CH", "Ezra": "EZR",
    "Neh": "NEH", "Esth": "EST", "Job": "JOB", "Ps": "PSA", "Prov": "PRO",
    "Eccl": "ECC", "Song": "SNG", "Isa": "ISA", "Jer": "JER", "Lam": "LAM",
    "Ezek": "EZK", "Dan": "DAN", "Hos": "HOS", "Joel": "JOL", "Amos": "AMO",
    "Obad": "OBA", "Jonah": "JON", "Mic": "MIC", "Nah": "NAM", "Hab": "HAB",
    "Zeph": "ZEP", "Hag": "HAG", "Zech": "ZEC", "Mal": "MAL",
    "Matt": "MAT", "Mark": "MRK", "Luke": "LUK", "John": "JHN", "Acts": "ACT",
    "Rom": "ROM", "1Cor": "1CO", "2Cor": "2CO", "Gal": "GAL", "Eph": "EPH",
    "Phil": "PHP", "Col": "COL", "1Thess": "1TH", "2Thess": "2TH",
    "1Tim": "1TI", "2Tim": "2TI", "Titus": "TIT", "Phlm": "PHM", "Heb": "HEB",
    "Jas": "JAS", "1Pet": "1PE", "2Pet": "2PE", "1John": "1JN",
    "2John": "2JN", "3John": "3JN", "Jude": "JUD", "Rev": "REV",
}

# MACULA treebanks (Clear Bible, CC BY 4.0): real syntax trees.
MACULA_GREEK_RAW = "https://raw.githubusercontent.com/Clear-Bible/macula-greek"
DEFAULT_MACULA_GREEK_COMMIT = "453876a98c049b08b54375918d04ead2a3d879e7"
MACULA_GREEK_FILES = (
    "01-matthew.xml", "02-mark.xml", "03-luke.xml", "04-john.xml",
    "05-acts.xml", "06-romans.xml", "07-1corinthians.xml",
    "08-2corinthians.xml", "09-galatians.xml", "10-ephesians.xml",
    "11-philippians.xml", "12-colossians.xml", "13-1thessalonians.xml",
    "14-2thessalonians.xml", "15-1timothy.xml", "16-2timothy.xml",
    "17-titus.xml", "18-philemon.xml", "19-hebrews.xml", "20-james.xml",
    "21-1peter.xml", "22-2peter.xml", "23-1john.xml", "24-2john.xml",
    "25-3john.xml", "26-jude.xml", "27-revelation.xml",
)

MACULA_HEBREW_RAW = "https://raw.githubusercontent.com/Clear-Bible/macula-hebrew"
DEFAULT_MACULA_HEBREW_COMMIT = "47db250bd55d0d8577f2a94fba114ef16c35b23c"

# WLC follows Hebrew versification: Joel has 4 chapters and Malachi 3
# (the books table lists English chapter counts for these two).
MACULA_HEBREW_CHAPTER_OVERRIDES = {"JOL": 4, "MAL": 3}


def macula_hebrew_book_code(abbr: str) -> str:
    """Filename book code used by macula-hebrew lowfat files ('GEN' -> 'Gen')."""
    if abbr == "HOS":  # quirk in the upstream filenames
        return "HOS"
    if abbr[0].isdigit():
        return abbr[0] + abbr[1] + abbr[2:].lower()
    return abbr[0] + abbr[1:].lower()


# Scholarly lexicons: BDB (public domain, Open Scriptures digitization) and
# Abbott-Smith (public domain, translatable-exegetical-tools digitization).
HEBREW_LEXICON_RAW = "https://raw.githubusercontent.com/openscriptures/HebrewLexicon"
DEFAULT_HEBREW_LEXICON_COMMIT = "21c9add13bc727d3a951361778e97e3ff7afd1ce"
ABBOTT_SMITH_RAW = (
    "https://raw.githubusercontent.com/translatable-exegetical-tools/Abbott-Smith"
)
DEFAULT_ABBOTT_SMITH_COMMIT = "8c00cb244761aa23659421a8cbbbf7a3b27b7d59"

# Strong's dictionaries (full definitions, derivations, KJV renderings).
# JSON-in-JS files maintained by Open Scriptures, CC BY-SA.
STRONGS_REPO_RAW = "https://raw.githubusercontent.com/openscriptures/strongs"
DEFAULT_STRONGS_COMMIT = "0acd2f251c2d35ff8db2dece4e0593979d3ac223"
STRONGS_FILES = {
    "strongs-hebrew-dictionary.js": "hebrew/strongs-hebrew-dictionary.js",
    "strongs-greek-dictionary.js": "greek/strongs-greek-dictionary.js",
}
DEFAULT_TRANSLATION_CATALOG = Path(__file__).resolve().parent / "translation_catalog.json"
DEFAULT_VERSIFICATION_OVERRIDES = (
    Path(__file__).resolve().parent / "versification_overrides.json"
)
DEFAULT_ENABLED_TRANSLATIONS = (
    "LUTHER1912,SYNODAL,ALMEIDA,OSTERVALD,VALERA1909,CUVS,KOREAN"
)

EXPECTED_COUNTS = {
    "books": 66,
    "distinct_verse_books": 66,
    "verses_min": 31100,
    "kjv_translation_verses_min": 31100,
    "words_min": 600000,
    "lexicon_min": 13000,
}

_REF_WHITESPACE_RE = re.compile(r"\s+")

Ref = Tuple[str, int, int]


@dataclass(frozen=True)
class BookInfo:
    order: int
    abbr: str
    name: str
    testament: str
    chapter_count: int


@dataclass(frozen=True)
class TranslationSpec:
    id: str
    name: str
    abbreviation: str
    language: str
    direction: str
    source_file: str
    format: str
    license: str


BOOKS: List[BookInfo] = [
    BookInfo(1, "GEN", "Genesis", "OT", 50),
    BookInfo(2, "EXO", "Exodus", "OT", 40),
    BookInfo(3, "LEV", "Leviticus", "OT", 27),
    BookInfo(4, "NUM", "Numbers", "OT", 36),
    BookInfo(5, "DEU", "Deuteronomy", "OT", 34),
    BookInfo(6, "JOS", "Joshua", "OT", 24),
    BookInfo(7, "JDG", "Judges", "OT", 21),
    BookInfo(8, "RUT", "Ruth", "OT", 4),
    BookInfo(9, "1SA", "1 Samuel", "OT", 31),
    BookInfo(10, "2SA", "2 Samuel", "OT", 24),
    BookInfo(11, "1KI", "1 Kings", "OT", 22),
    BookInfo(12, "2KI", "2 Kings", "OT", 25),
    BookInfo(13, "1CH", "1 Chronicles", "OT", 29),
    BookInfo(14, "2CH", "2 Chronicles", "OT", 36),
    BookInfo(15, "EZR", "Ezra", "OT", 10),
    BookInfo(16, "NEH", "Nehemiah", "OT", 13),
    BookInfo(17, "EST", "Esther", "OT", 10),
    BookInfo(18, "JOB", "Job", "OT", 42),
    BookInfo(19, "PSA", "Psalms", "OT", 150),
    BookInfo(20, "PRO", "Proverbs", "OT", 31),
    BookInfo(21, "ECC", "Ecclesiastes", "OT", 12),
    BookInfo(22, "SNG", "Song of Songs", "OT", 8),
    BookInfo(23, "ISA", "Isaiah", "OT", 66),
    BookInfo(24, "JER", "Jeremiah", "OT", 52),
    BookInfo(25, "LAM", "Lamentations", "OT", 5),
    BookInfo(26, "EZK", "Ezekiel", "OT", 48),
    BookInfo(27, "DAN", "Daniel", "OT", 12),
    BookInfo(28, "HOS", "Hosea", "OT", 14),
    BookInfo(29, "JOL", "Joel", "OT", 3),
    BookInfo(30, "AMO", "Amos", "OT", 9),
    BookInfo(31, "OBA", "Obadiah", "OT", 1),
    BookInfo(32, "JON", "Jonah", "OT", 4),
    BookInfo(33, "MIC", "Micah", "OT", 7),
    BookInfo(34, "NAM", "Nahum", "OT", 3),
    BookInfo(35, "HAB", "Habakkuk", "OT", 3),
    BookInfo(36, "ZEP", "Zephaniah", "OT", 3),
    BookInfo(37, "HAG", "Haggai", "OT", 2),
    BookInfo(38, "ZEC", "Zechariah", "OT", 14),
    BookInfo(39, "MAL", "Malachi", "OT", 4),
    BookInfo(40, "MAT", "Matthew", "NT", 28),
    BookInfo(41, "MRK", "Mark", "NT", 16),
    BookInfo(42, "LUK", "Luke", "NT", 24),
    BookInfo(43, "JHN", "John", "NT", 21),
    BookInfo(44, "ACT", "Acts", "NT", 28),
    BookInfo(45, "ROM", "Romans", "NT", 16),
    BookInfo(46, "1CO", "1 Corinthians", "NT", 16),
    BookInfo(47, "2CO", "2 Corinthians", "NT", 13),
    BookInfo(48, "GAL", "Galatians", "NT", 6),
    BookInfo(49, "EPH", "Ephesians", "NT", 6),
    BookInfo(50, "PHP", "Philippians", "NT", 4),
    BookInfo(51, "COL", "Colossians", "NT", 4),
    BookInfo(52, "1TH", "1 Thessalonians", "NT", 5),
    BookInfo(53, "2TH", "2 Thessalonians", "NT", 3),
    BookInfo(54, "1TI", "1 Timothy", "NT", 6),
    BookInfo(55, "2TI", "2 Timothy", "NT", 4),
    BookInfo(56, "TIT", "Titus", "NT", 3),
    BookInfo(57, "PHM", "Philemon", "NT", 1),
    BookInfo(58, "HEB", "Hebrews", "NT", 13),
    BookInfo(59, "JAS", "James", "NT", 5),
    BookInfo(60, "1PE", "1 Peter", "NT", 5),
    BookInfo(61, "2PE", "2 Peter", "NT", 3),
    BookInfo(62, "1JN", "1 John", "NT", 5),
    BookInfo(63, "2JN", "2 John", "NT", 1),
    BookInfo(64, "3JN", "3 John", "NT", 1),
    BookInfo(65, "JUD", "Jude", "NT", 1),
    BookInfo(66, "REV", "Revelation", "NT", 22),
]

BOOK_BY_NUM = {f"{b.order:02d}": b for b in BOOKS}
BOOK_BY_INDEX = {b.order: b for b in BOOKS}
BOOK_BY_ABBR = {b.abbr: b for b in BOOKS}

USFX_BOOK_MAP: Dict[str, str] = {
    "GEN": "GEN",
    "EXO": "EXO",
    "LEV": "LEV",
    "NUM": "NUM",
    "DEU": "DEU",
    "JOS": "JOS",
    "JDG": "JDG",
    "RUT": "RUT",
    "1SA": "1SA",
    "2SA": "2SA",
    "1KI": "1KI",
    "2KI": "2KI",
    "1CH": "1CH",
    "2CH": "2CH",
    "EZR": "EZR",
    "NEH": "NEH",
    "EST": "EST",
    "JOB": "JOB",
    "PSA": "PSA",
    "PSM": "PSA",
    "PRO": "PRO",
    "ECC": "ECC",
    "SNG": "SNG",
    "SON": "SNG",
    "ISA": "ISA",
    "JER": "JER",
    "LAM": "LAM",
    "EZK": "EZK",
    "DAN": "DAN",
    "HOS": "HOS",
    "JOL": "JOL",
    "AMO": "AMO",
    "OBA": "OBA",
    "JON": "JON",
    "MIC": "MIC",
    "NAM": "NAM",
    "HAB": "HAB",
    "ZEP": "ZEP",
    "HAG": "HAG",
    "ZEC": "ZEC",
    "MAL": "MAL",
    "MAT": "MAT",
    "MRK": "MRK",
    "LUK": "LUK",
    "JHN": "JHN",
    "ACT": "ACT",
    "ROM": "ROM",
    "1CO": "1CO",
    "2CO": "2CO",
    "GAL": "GAL",
    "EPH": "EPH",
    "PHP": "PHP",
    "COL": "COL",
    "1TH": "1TH",
    "2TH": "2TH",
    "1TI": "1TI",
    "2TI": "2TI",
    "TIT": "TIT",
    "PHM": "PHM",
    "HEB": "HEB",
    "JAS": "JAS",
    "1PE": "1PE",
    "2PE": "2PE",
    "1JN": "1JN",
    "2JN": "2JN",
    "3JN": "3JN",
    "JUD": "JUD",
    "REV": "REV",
}

OSIS_BOOK_MAP: Dict[str, str] = {
    "Gen": "GEN",
    "Exod": "EXO",
    "Lev": "LEV",
    "Num": "NUM",
    "Deut": "DEU",
    "Josh": "JOS",
    "Judg": "JDG",
    "Ruth": "RUT",
    "1Sam": "1SA",
    "2Sam": "2SA",
    "1Kgs": "1KI",
    "2Kgs": "2KI",
    "1Chr": "1CH",
    "2Chr": "2CH",
    "Ezra": "EZR",
    "Neh": "NEH",
    "Esth": "EST",
    "Job": "JOB",
    "Ps": "PSA",
    "Prov": "PRO",
    "Eccl": "ECC",
    "Song": "SNG",
    "Isa": "ISA",
    "Jer": "JER",
    "Lam": "LAM",
    "Ezek": "EZK",
    "Dan": "DAN",
    "Hos": "HOS",
    "Joel": "JOL",
    "Amos": "AMO",
    "Obad": "OBA",
    "Jonah": "JON",
    "Mic": "MIC",
    "Nah": "NAM",
    "Hab": "HAB",
    "Zeph": "ZEP",
    "Hag": "HAG",
    "Zech": "ZEC",
    "Mal": "MAL",
    "Matt": "MAT",
    "Mark": "MRK",
    "Luke": "LUK",
    "John": "JHN",
    "Acts": "ACT",
    "Rom": "ROM",
    "1Cor": "1CO",
    "2Cor": "2CO",
    "Gal": "GAL",
    "Eph": "EPH",
    "Phil": "PHP",
    "Col": "COL",
    "1Thess": "1TH",
    "2Thess": "2TH",
    "1Tim": "1TI",
    "2Tim": "2TI",
    "Titus": "TIT",
    "Phlm": "PHM",
    "Heb": "HEB",
    "Jas": "JAS",
    "1Pet": "1PE",
    "2Pet": "2PE",
    "1John": "1JN",
    "2John": "2JN",
    "3John": "3JN",
    "Jude": "JUD",
    "Rev": "REV",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build full assets/bible.db")
    parser.add_argument(
        "--output",
        default=str(Path(__file__).resolve().parents[1] / "assets" / "bible.db"),
        help="Output SQLite database path",
    )
    parser.add_argument(
        "--cache-dir",
        default="",
        help="Optional directory to cache downloaded source files",
    )
    parser.add_argument(
        "--source-commit",
        default=DEFAULT_SOURCE_COMMIT,
        help="Pinned source commit hash from themikejr/bible-mcp",
    )
    parser.add_argument(
        "--open-bibles-commit",
        default=DEFAULT_OPEN_BIBLES_COMMIT,
        help="Pinned source commit/branch from seven1m/open-bibles",
    )
    parser.add_argument(
        "--strongs-commit",
        default=DEFAULT_STRONGS_COMMIT,
        help="Pinned source commit hash from openscriptures/strongs",
    )
    parser.add_argument(
        "--no-strongs-enrichment",
        dest="strongs_enrichment",
        action="store_false",
        default=True,
        help="Skip Strong's dictionary enrichment (falls back to gloss-only definitions)",
    )
    parser.add_argument(
        "--no-cross-references",
        dest="cross_references",
        action="store_false",
        default=True,
        help="Skip the OpenBible.info cross-references table",
    )
    parser.add_argument(
        "--no-extended-lexicon",
        dest="extended_lexicon",
        action="store_false",
        default=True,
        help="Skip BDB / Abbott-Smith extended lexicon entries",
    )
    parser.add_argument(
        "--hebrew-lexicon-commit",
        default=DEFAULT_HEBREW_LEXICON_COMMIT,
        help="Pinned commit for openscriptures/HebrewLexicon",
    )
    parser.add_argument(
        "--abbott-smith-commit",
        default=DEFAULT_ABBOTT_SMITH_COMMIT,
        help="Pinned commit for translatable-exegetical-tools/Abbott-Smith",
    )
    parser.add_argument(
        "--no-syntax-trees",
        dest="syntax_trees",
        action="store_false",
        default=True,
        help="Skip MACULA syntax trees (large download, ~650MB of source XML)",
    )
    parser.add_argument(
        "--macula-greek-commit",
        default=DEFAULT_MACULA_GREEK_COMMIT,
        help="Pinned commit for Clear-Bible/macula-greek",
    )
    parser.add_argument(
        "--macula-hebrew-commit",
        default=DEFAULT_MACULA_HEBREW_COMMIT,
        help="Pinned commit for Clear-Bible/macula-hebrew",
    )
    parser.add_argument(
        "--translation-catalog",
        default=str(DEFAULT_TRANSLATION_CATALOG),
        help="JSON file defining Open Bibles translation metadata",
    )
    parser.add_argument(
        "--enabled-translations",
        default=DEFAULT_ENABLED_TRANSLATIONS,
        help="Comma-separated translation ids to mark enabled when strict gate passes",
    )
    parser.add_argument(
        "--strict-coverage",
        dest="strict_coverage",
        action="store_true",
        default=True,
        help="Fail build when enabled translation coverage is incomplete",
    )
    parser.add_argument(
        "--no-strict-coverage",
        dest="strict_coverage",
        action="store_false",
        help="Allow enabled translations with incomplete coverage",
    )
    parser.add_argument(
        "--emit-coverage-report",
        default="",
        help="Optional output path for JSON coverage report",
    )
    parser.add_argument(
        "--versification-overrides",
        default=str(DEFAULT_VERSIFICATION_OVERRIDES),
        help="Optional JSON source->target reference overrides",
    )
    parser.add_argument(
        "--fill-kjv-gaps",
        dest="fill_kjv_gaps",
        action="store_true",
        default=True,
        help="Fill KJV canonical verse gaps with nearest in-book fallback text",
    )
    parser.add_argument(
        "--no-fill-kjv-gaps",
        dest="fill_kjv_gaps",
        action="store_false",
        help="Keep KJV canonical verse gaps unfilled",
    )
    return parser.parse_args()


def ensure_parent_dir(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def build_source_urls(source_commit: str) -> Dict[str, str]:
    return {
        filename: f"{SOURCE_REPO_RAW}/{source_commit}/data/{filename}"
        for filename in SOURCE_FILENAMES
    }


def build_open_bible_url(source_file: str, open_bibles_commit: str) -> str:
    return f"{OPEN_BIBLES_REPO_RAW}/{open_bibles_commit}/{source_file}"


def download_file(url: str, dst: Path) -> None:
    if dst.exists() and dst.stat().st_size > 0:
        print(f"Using cached file: {dst.name}")
        return
    print(f"Downloading {dst.name} ...")
    with urllib.request.urlopen(url) as response, dst.open("wb") as out:
        shutil.copyfileobj(response, out)
    print(f"Downloaded {dst.name} ({dst.stat().st_size:,} bytes)")


def init_schema(conn: sqlite3.Connection) -> None:
    conn.executescript(
        """
        PRAGMA journal_mode = WAL;
        PRAGMA synchronous = OFF;
        PRAGMA temp_store = MEMORY;
        PRAGMA cache_size = -200000;
        PRAGMA foreign_keys = OFF;

        DROP TABLE IF EXISTS books;
        DROP TABLE IF EXISTS translations;
        DROP TABLE IF EXISTS verses;
        DROP TABLE IF EXISTS translation_verses;
        DROP TABLE IF EXISTS translation_ref_map;
        DROP TABLE IF EXISTS words;
        DROP TABLE IF EXISTS lexicon;
        DROP TABLE IF EXISTS cross_references;
        DROP TABLE IF EXISTS syntax_trees;

        CREATE TABLE books (
            id INTEGER PRIMARY KEY,
            abbreviation TEXT NOT NULL UNIQUE,
            name TEXT NOT NULL,
            name_en TEXT NOT NULL,
            testament TEXT NOT NULL,
            book_order INTEGER NOT NULL,
            chapter_count INTEGER NOT NULL
        );

        CREATE TABLE translations (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            language TEXT NOT NULL,
            direction TEXT DEFAULT 'ltr',
            abbreviation TEXT NOT NULL,
            source_file TEXT,
            license TEXT,
            enabled INTEGER NOT NULL DEFAULT 0,
            coverage_percent REAL NOT NULL DEFAULT 0
        );

        CREATE TABLE verses (
            id INTEGER PRIMARY KEY,
            book_id TEXT NOT NULL,
            chapter INTEGER NOT NULL,
            verse_number INTEGER NOT NULL,
            text TEXT NOT NULL,
            UNIQUE(book_id, chapter, verse_number)
        );

        CREATE TABLE translation_verses (
            id INTEGER PRIMARY KEY,
            translation_id TEXT NOT NULL,
            book_id TEXT NOT NULL,
            chapter INTEGER NOT NULL,
            verse_number INTEGER NOT NULL,
            text TEXT NOT NULL,
            UNIQUE(translation_id, book_id, chapter, verse_number)
        );

        CREATE TABLE translation_ref_map (
            translation_id TEXT NOT NULL,
            source_book_id TEXT NOT NULL,
            source_chapter INTEGER NOT NULL,
            source_verse INTEGER NOT NULL,
            target_book_id TEXT NOT NULL,
            target_chapter INTEGER NOT NULL,
            target_verse INTEGER NOT NULL,
            match_type TEXT NOT NULL,
            PRIMARY KEY (translation_id, source_book_id, source_chapter, source_verse)
        );

        CREATE TABLE words (
            id INTEGER PRIMARY KEY,
            verse_id INTEGER NOT NULL,
            position INTEGER NOT NULL,
            word TEXT NOT NULL,
            lemma TEXT,
            morph TEXT,
            strongs TEXT,
            language TEXT NOT NULL DEFAULT 'heb'
        );

        CREATE TABLE lexicon (
            lemma TEXT PRIMARY KEY,
            strongs_id TEXT,
            gloss TEXT NOT NULL,
            definition TEXT,
            part_of_speech TEXT,
            language TEXT,
            transliteration TEXT,
            pronunciation TEXT,
            extended_definition TEXT,
            extended_source TEXT
        );

        CREATE TABLE cross_references (
            id INTEGER PRIMARY KEY,
            from_book TEXT NOT NULL,
            from_chapter INTEGER NOT NULL,
            from_verse INTEGER NOT NULL,
            to_book TEXT NOT NULL,
            to_chapter INTEGER NOT NULL,
            to_verse_start INTEGER NOT NULL,
            to_verse_end INTEGER NOT NULL,
            votes INTEGER NOT NULL DEFAULT 0
        );

        CREATE TABLE syntax_trees (
            book_id TEXT NOT NULL,
            chapter INTEGER NOT NULL,
            verse INTEGER NOT NULL,
            trees TEXT NOT NULL,
            PRIMARY KEY (book_id, chapter, verse)
        );

        CREATE INDEX idx_books_order ON books(book_order);
        CREATE INDEX idx_cross_references_from
            ON cross_references(from_book, from_chapter, from_verse);
        CREATE INDEX idx_verses_ref ON verses(book_id, chapter, verse_number);
        CREATE INDEX idx_translation_verses_ref
            ON translation_verses(translation_id, book_id, chapter, verse_number);
        CREATE INDEX idx_translation_ref_map_target
            ON translation_ref_map(translation_id, target_book_id, target_chapter, target_verse);
        CREATE INDEX idx_words_verse ON words(verse_id, position);
        CREATE INDEX idx_words_lemma ON words(lemma);
        CREATE INDEX idx_words_strongs ON words(strongs);
        CREATE INDEX idx_lexicon_strongs ON lexicon(strongs_id);
        """
    )


def parse_ref(ref: str) -> Tuple[str, int, int]:
    # e.g. "GEN 1:1!1"
    book, rest = ref.split(" ", 1)
    cv = rest.split("!", 1)[0]
    chapter_s, verse_s = cv.split(":", 1)
    return book.strip(), int(chapter_s), int(verse_s)


def iter_tsv_rows(path: Path) -> Iterable[Dict[str, str]]:
    with path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            yield row


def assemble_original_verse_text(tokens: List[Tuple[str, str]]) -> str:
    return "".join(f"{text}{after or ''}" for text, after in tokens).strip()


def assemble_translation_text(tokens: List[Tuple[str, bool]]) -> str:
    # token tuple = (text, skip_space_after)
    out: List[str] = []
    prev_skip_after = True
    for text, skip_after in tokens:
        if not text:
            continue
        if out and not prev_skip_after:
            out.append(" ")
        out.append(text)
        prev_skip_after = skip_after
    return "".join(out).strip()


def normalize_language(raw_lang: str, default_lang: str) -> str:
    value = (raw_lang or "").strip().lower()
    if not value:
        return default_lang
    if value in {"h", "heb", "hebrew"}:
        return "heb"
    if value in {"g", "grc", "greek", "el"}:
        return "grc"
    return default_lang


def normalize_strongs(raw_value: str, language: str) -> str:
    value = (raw_value or "").strip().upper()
    if not value:
        return ""

    alnum = "".join(ch for ch in value if ch.isalnum())
    if not alnum:
        return ""

    if alnum[0] in {"H", "G"}:
        return alnum

    prefix = "H" if language == "heb" else "G"
    return f"{prefix}{alnum}"


def parse_strongs_dictionary_js(path: Path) -> Dict[str, dict]:
    """Parse an Open Scriptures strongs-*-dictionary.js file.

    The files wrap a single JSON object in `var strongsXxxDictionary = {...};`
    plus a license header comment, so we extract the outermost braces.
    """
    raw = path.read_text(encoding="utf-8")
    assignment = re.search(r"=\s*\{", raw)
    if assignment is None:
        raise RuntimeError(f"No dictionary assignment found in {path.name}")
    start = assignment.end() - 1
    end = raw.rindex("}")
    data = json.loads(raw[start : end + 1])
    if not isinstance(data, dict):
        raise RuntimeError(f"Unexpected Strong's dictionary payload in {path.name}")
    return data


_STRONGS_BRACKET_REPLACEMENTS = {
    "[idiom]": "×",  # Strong's multiplication sign marker
    "[phrase]": "",
}


def clean_strongs_text(value: str) -> str:
    text = (value or "").strip()
    for marker, replacement in _STRONGS_BRACKET_REPLACEMENTS.items():
        text = text.replace(marker, replacement)
    text = _REF_WHITESPACE_RE.sub(" ", text)
    return text.strip(" ;,.")


def compose_strongs_definition(entry: dict) -> str:
    """Build a readable multi-part definition from a Strong's dictionary entry."""
    parts: List[str] = []
    strongs_def = clean_strongs_text(entry.get("strongs_def") or "")
    if strongs_def:
        parts.append(strongs_def[0].upper() + strongs_def[1:] + ".")
    derivation = clean_strongs_text(entry.get("derivation") or "")
    if derivation:
        parts.append(f"Derivation: {derivation}.")
    kjv_def = clean_strongs_text(entry.get("kjv_def") or "")
    if kjv_def:
        parts.append(f"KJV renderings: {kjv_def}.")
    return "\n\n".join(parts)


def strongs_lookup_candidates(strongs_id: str) -> List[str]:
    """Candidate dictionary keys for a token Strong's id.

    Token ids may be zero-padded ("H0430") or carry disambiguation suffixes
    ("H1254a"); the Open Scriptures dictionaries key on plain "H430"/"G26".
    """
    value = (strongs_id or "").strip().upper()
    if len(value) < 2 or value[0] not in {"H", "G"}:
        return []
    prefix, body = value[0], value[1:]
    digits = "".join(ch for ch in body if ch.isdigit())
    candidates = [value]
    if digits:
        canonical = f"{prefix}{int(digits)}"
        if canonical not in candidates:
            candidates.append(canonical)
    return candidates


def parse_openbible_ref(raw: str) -> Optional[Tuple[str, int, int]]:
    """Parses an OpenBible ref like 'Gen.1.1' into (app_book_id, chapter, verse)."""
    parts = (raw or "").strip().split(".")
    if len(parts) != 3:
        return None
    book_id = OSIS_TO_ABBR.get(parts[0])
    if book_id is None:
        return None
    try:
        return (book_id, int(parts[1]), int(parts[2]))
    except ValueError:
        return None


def build_cross_references(conn: sqlite3.Connection, txt_path: Path) -> None:
    """Loads the OpenBible.info cross-references TSV into the DB.

    'To' refs may be ranges ('Col.1.16-Col.1.17'); cross-chapter ranges are
    clamped to the starting chapter. Negative-vote pairs (community-rejected)
    are dropped.
    """
    print("Building cross_references table...")
    rows: List[Tuple[str, int, int, str, int, int, int, int]] = []
    skipped = 0

    with txt_path.open(encoding="utf-8") as fh:
        for line_number, line in enumerate(fh):
            if line_number == 0:
                continue  # header
            fields = line.rstrip("\n").split("\t")
            if len(fields) < 3:
                continue
            from_ref = parse_openbible_ref(fields[0])
            try:
                votes = int(fields[2])
            except ValueError:
                continue
            if from_ref is None or votes < 0:
                skipped += 1
                continue

            to_raw = fields[1]
            if "-" in to_raw:
                start_raw, end_raw = to_raw.split("-", 1)
                to_start = parse_openbible_ref(start_raw)
                to_end = parse_openbible_ref(end_raw)
            else:
                to_start = parse_openbible_ref(to_raw)
                to_end = to_start
            if to_start is None:
                skipped += 1
                continue
            if to_end is None or to_end[0] != to_start[0] or to_end[1] != to_start[1]:
                # Clamp cross-chapter ranges to the starting verse's chapter.
                to_end = to_start

            rows.append(
                (
                    from_ref[0],
                    from_ref[1],
                    from_ref[2],
                    to_start[0],
                    to_start[1],
                    to_start[2],
                    max(to_start[2], to_end[2]),
                    votes,
                )
            )

    conn.executemany(
        """
        INSERT INTO cross_references
        (from_book, from_chapter, from_verse,
         to_book, to_chapter, to_verse_start, to_verse_end, votes)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """,
        rows,
    )
    print(f"  inserted {len(rows):,} cross-references (skipped {skipped:,})")
    if len(rows) < 200000:
        raise RuntimeError(
            f"Cross-reference import too small ({len(rows)}); source data problem?"
        )


def download_cross_references(cache_dir: Path) -> Path:
    import zipfile

    zip_path = cache_dir / CROSS_REFERENCES_ZIP
    txt_path = cache_dir / CROSS_REFERENCES_TXT
    if not txt_path.exists() or txt_path.stat().st_size == 0:
        download_file(CROSS_REFERENCES_URL, zip_path)
        with zipfile.ZipFile(zip_path) as archive:
            archive.extract(CROSS_REFERENCES_TXT, cache_dir)
    return txt_path


_MACULA_REF_RE = re.compile(r"^([A-Z0-9]{3}) (\d+):(\d+)!(\d+)$")


def parse_macula_ref(raw: str) -> Optional[Tuple[str, int, int, int]]:
    """Parses a MACULA token ref like 'GEN 1:1!2' -> (book, chapter, verse, n)."""
    match = _MACULA_REF_RE.match((raw or "").strip())
    if match is None:
        return None
    book, chapter, verse, word = match.groups()
    if book not in BOOK_BY_ABBR:
        return None
    return (book, int(chapter), int(verse), int(word))


def macula_element_to_node(el: ET.Element) -> Optional[dict]:
    """Converts a lowfat <wg>/<w>/<pc> element into a compact JSON node.

    Node keys: t=text, n=word number, r=role, c=class, u=rule, k=children.
    Pass-through groups (no role/class/rule) are spliced away.
    """
    tag = el.tag
    if tag == "w":
        node: dict = {"t": (el.text or "").strip()}
        ref = parse_macula_ref(el.get("ref", ""))
        if ref is not None:
            node["n"] = ref[3]
        if el.get("role"):
            node["r"] = el.get("role")
        if el.get("class"):
            node["c"] = el.get("class")
        return node
    if tag == "pc":
        text = (el.text or "").strip()
        return {"t": text, "c": "pc"} if text else None
    if tag != "wg":
        return None  # milestones, <p>, notes

    children = []
    for child in el:
        node = macula_element_to_node(child)
        if node is not None:
            children.append(node)
    if not children:
        return None

    role = el.get("role")
    cls = el.get("class")
    rule = el.get("rule")
    if not role and not cls and not rule:
        if len(children) == 1:
            return children[0]
        return {"k": children}

    node = {}
    if role:
        node["r"] = role
    if cls:
        node["c"] = cls
    if rule:
        node["u"] = rule
    node["k"] = children
    return node


def macula_sentence_to_tree(sentence: ET.Element) -> Optional[dict]:
    nodes = []
    for child in sentence:
        node = macula_element_to_node(child)
        if node is not None:
            nodes.append(node)
    if not nodes:
        return None
    if len(nodes) == 1:
        return nodes[0]
    return {"k": nodes}


def macula_sentence_verses(sentence: ET.Element) -> List[Tuple[str, int, int]]:
    verses = []
    seen = set()
    for w in sentence.iter("w"):
        ref = parse_macula_ref(w.get("ref", ""))
        if ref is None:
            continue
        key = (ref[0], ref[1], ref[2])
        if key not in seen:
            seen.add(key)
            verses.append(key)
    return verses


def build_syntax_trees(conn: sqlite3.Connection, xml_paths: List[Path]) -> None:
    """Extracts per-verse sentence trees from MACULA lowfat XML files.

    Each verse row stores a JSON array of the sentence trees that touch it
    (sentences occasionally span verse boundaries).
    """
    print("Building syntax_trees table from MACULA lowfat XML...")
    trees_by_verse: Dict[Tuple[str, int, int], List[dict]] = defaultdict(list)
    files_done = 0

    for path in xml_paths:
        root = ET.parse(path).getroot()
        for sentence in root.iter("sentence"):
            tree = macula_sentence_to_tree(sentence)
            if tree is None:
                continue
            for verse_key in macula_sentence_verses(sentence):
                trees_by_verse[verse_key].append(tree)
        files_done += 1
        if files_done % 100 == 0:
            print(f"  parsed {files_done}/{len(xml_paths)} tree files")

    rows = [
        (book, chapter, verse, json.dumps(trees, ensure_ascii=False, separators=(",", ":")))
        for (book, chapter, verse), trees in trees_by_verse.items()
    ]
    conn.executemany(
        "INSERT OR REPLACE INTO syntax_trees (book_id, chapter, verse, trees) "
        "VALUES (?, ?, ?, ?)",
        rows,
    )
    print(f"  inserted syntax trees for {len(rows):,} verses")
    if len(rows) < 30000:
        raise RuntimeError(
            f"Syntax tree coverage too low ({len(rows)} verses); "
            "check MACULA sources"
        )


def download_macula_files(
    cache_dir: Path,
    greek_commit: str,
    hebrew_commit: str,
) -> List[Path]:
    paths: List[Path] = []
    tree_dir = cache_dir / "macula_lowfat"
    tree_dir.mkdir(parents=True, exist_ok=True)

    for book in BOOKS:
        if book.testament != "OT":
            continue
        code = macula_hebrew_book_code(book.abbr)
        chapter_count = MACULA_HEBREW_CHAPTER_OVERRIDES.get(
            book.abbr, book.chapter_count
        )
        for chapter in range(1, chapter_count + 1):
            filename = f"{book.order:02d}-{code}-{chapter:03d}-lowfat.xml"
            url = f"{MACULA_HEBREW_RAW}/{hebrew_commit}/WLC/lowfat/{filename}"
            dst = tree_dir / filename
            download_file(url, dst)
            paths.append(dst)

    for filename in MACULA_GREEK_FILES:
        url = f"{MACULA_GREEK_RAW}/{greek_commit}/SBLGNT/lowfat/{filename}"
        dst = tree_dir / filename
        download_file(url, dst)
        paths.append(dst)

    return paths


def _local_name(tag: str) -> str:
    return tag.split("}")[-1]


def flatten_xml_text(el: ET.Element, skip_tags: Optional[set] = None) -> str:
    """Flattens mixed XML content to plain text, skipping given elements."""
    skip = skip_tags or set()
    parts: List[str] = []

    def walk(node: ET.Element) -> None:
        if _local_name(node.tag) in skip:
            if node.tail:
                parts.append(node.tail)
            return
        if node.text:
            parts.append(node.text)
        for child in node:
            walk(child)
        if node.tail:
            parts.append(node.tail)

    if el.text:
        parts.append(el.text)
    for child in el:
        walk(child)
    return _REF_WHITESPACE_RE.sub(" ", "".join(parts)).strip()


def parse_bdb_lexicon(bdb_path: Path, index_path: Path) -> Dict[str, str]:
    """Returns Strong's key ('H1') -> flattened BDB entry text.

    LexicalIndex.xml maps Strong's numbers to BDB entry ids; the BDB file
    holds the entries themselves (mixed content, flattened to plain text).
    """
    entries_by_id: Dict[str, str] = {}
    for el in ET.parse(bdb_path).getroot().iter():
        if _local_name(el.tag) != "entry":
            continue
        entry_id = el.get("id")
        if not entry_id:
            continue
        text = flatten_xml_text(el, skip_tags={"status"})
        if text:
            entries_by_id[entry_id] = text

    result: Dict[str, str] = {}
    for el in ET.parse(index_path).getroot().iter():
        if _local_name(el.tag) != "xref":
            continue
        strong = (el.get("strong") or "").strip()
        bdb_id = (el.get("bdb") or "").strip()
        if not strong or not strong.isdigit() or bdb_id not in entries_by_id:
            continue
        key = f"H{int(strong)}"
        text = entries_by_id[bdb_id]
        # Keep the fullest entry when several ids map to one Strong's number.
        if key not in result or len(text) > len(result[key]):
            result[key] = text
    return result


def parse_abbott_smith_lexicon(path: Path) -> Dict[str, str]:
    """Returns Strong's key ('G26') -> flattened Abbott-Smith entry text.

    TEI entries carry n="lemma|G26"; occurrence-count notes are dropped.
    """
    result: Dict[str, str] = {}
    for el in ET.parse(path).getroot().iter():
        if _local_name(el.tag) != "entry":
            continue
        n = el.get("n") or ""
        if "|" not in n:
            continue
        strong = n.split("|", 1)[1].strip().upper()
        if not strong.startswith("G") or not strong[1:].isdigit():
            continue
        key = f"G{int(strong[1:])}"
        text = flatten_xml_text(el, skip_tags={"note"})
        if not text:
            continue
        if key not in result or len(text) > len(result[key]):
            result[key] = text
    return result


def load_extended_lexicons(
    cache_dir: Path,
    hebrew_lexicon_commit: str,
    abbott_smith_commit: str,
) -> Dict[str, str]:
    bdb_path = cache_dir / "BrownDriverBriggs.xml"
    index_path = cache_dir / "LexicalIndex.xml"
    as_path = cache_dir / "abbott-smith.tei.xml"
    download_file(
        f"{HEBREW_LEXICON_RAW}/{hebrew_lexicon_commit}/BrownDriverBriggs.xml",
        bdb_path,
    )
    download_file(
        f"{HEBREW_LEXICON_RAW}/{hebrew_lexicon_commit}/LexicalIndex.xml",
        index_path,
    )
    download_file(
        f"{ABBOTT_SMITH_RAW}/{abbott_smith_commit}/abbott-smith.tei.xml",
        as_path,
    )

    merged = parse_bdb_lexicon(bdb_path, index_path)
    hebrew_count = len(merged)
    merged.update(parse_abbott_smith_lexicon(as_path))
    print(
        f"Loaded extended lexicon entries: {hebrew_count:,} BDB, "
        f"{len(merged) - hebrew_count:,} Abbott-Smith"
    )
    return merged


def load_strongs_dictionaries(
    cache_dir: Path, strongs_commit: str
) -> Dict[str, dict]:
    merged: Dict[str, dict] = {}
    for filename, repo_path in STRONGS_FILES.items():
        url = f"{STRONGS_REPO_RAW}/{strongs_commit}/{repo_path}"
        dst = cache_dir / filename
        download_file(url, dst)
        entries = parse_strongs_dictionary_js(dst)
        merged.update(entries)
    print(f"Loaded {len(merged):,} Strong's dictionary entries")
    return merged


def write_books(conn: sqlite3.Connection) -> None:
    conn.executemany(
        """
        INSERT INTO books (id, abbreviation, name, name_en, testament, book_order, chapter_count)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        [
            (b.order, b.abbr, b.name, b.name, b.testament, b.order, b.chapter_count)
            for b in BOOKS
        ],
    )


def load_translation_catalog(path: Path) -> Dict[str, TranslationSpec]:
    if not path.exists():
        raise RuntimeError(f"Translation catalog not found: {path}")

    raw = json.loads(path.read_text(encoding="utf-8"))
    records = raw.get("translations") if isinstance(raw, dict) else raw
    if not isinstance(records, list):
        raise RuntimeError("translation catalog must be a list or {\"translations\": [...]}.")

    catalog: Dict[str, TranslationSpec] = {}
    for row in records:
        if not isinstance(row, dict):
            continue
        translation_id = str(row.get("id", "")).strip().upper()
        if not translation_id:
            continue
        spec = TranslationSpec(
            id=translation_id,
            name=str(row.get("name", translation_id)).strip(),
            abbreviation=str(row.get("abbreviation", translation_id)).strip().upper(),
            language=str(row.get("language", "en")).strip().lower(),
            direction=str(row.get("direction", "ltr")).strip().lower() or "ltr",
            source_file=str(row.get("source_file", "")).strip(),
            format=str(row.get("format", "")).strip().lower(),
            license=str(row.get("license", "")).strip() or "Unknown",
        )
        if not spec.source_file:
            raise RuntimeError(f"Translation {translation_id} is missing source_file")
        if spec.format not in {"usfx", "osis", "zefania"}:
            raise RuntimeError(
                f"Translation {translation_id} has unsupported format {spec.format!r}"
            )
        catalog[translation_id] = spec

    return catalog


def parse_enabled_translation_ids(raw_csv: str) -> List[str]:
    ids = [item.strip().upper() for item in raw_csv.split(",") if item.strip()]
    deduped: List[str] = []
    seen = set()
    for item in ids:
        if item not in seen:
            seen.add(item)
            deduped.append(item)
    return deduped


def write_translations(conn: sqlite3.Connection, catalog: Dict[str, TranslationSpec]) -> None:
    rows = [
        (
            "KJV",
            "King James Version (BSB source text)",
            "en",
            "ltr",
            "KJV",
            "ot_BSB.tsv,nt_BSB.tsv",
            "Derived from themikejr/bible-mcp token data",
            1,
            0.0,
        )
    ]

    for spec in sorted(catalog.values(), key=lambda item: item.id):
        rows.append(
            (
                spec.id,
                spec.name,
                spec.language,
                spec.direction,
                spec.abbreviation,
                spec.source_file,
                spec.license,
                0,
                0.0,
            )
        )

    conn.executemany(
        """
        INSERT INTO translations
        (id, name, language, direction, abbreviation, source_file, license, enabled, coverage_percent)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        rows,
    )


def build_verses_and_words(
    conn: sqlite3.Connection,
    hebrew_tsv: Path,
    greek_tsv: Path,
    strongs_dicts: Optional[Dict[str, dict]] = None,
    extended_lexicons: Optional[Dict[str, str]] = None,
) -> None:
    lex_glosses: Dict[str, Counter] = defaultdict(Counter)
    lex_pos: Dict[str, Counter] = defaultdict(Counter)
    lex_strong: Dict[str, Counter] = defaultdict(Counter)
    lex_language: Dict[str, Counter] = defaultdict(Counter)
    lex_transliteration: Dict[str, Counter] = defaultdict(Counter)
    lex_pronunciation: Dict[str, Counter] = defaultdict(Counter)

    next_word_id = 1

    def flush_group(
        key: Optional[Tuple[str, int, int]],
        verse_tokens: List[Tuple[str, str]],
        word_rows: List[Tuple[str, str, str, str, str, str]],
    ) -> None:
        nonlocal next_word_id
        if key is None:
            return

        book_id, chapter, verse = key
        verse_text = assemble_original_verse_text(verse_tokens)
        if not verse_text:
            return

        conn.execute(
            "INSERT OR IGNORE INTO verses (book_id, chapter, verse_number, text) VALUES (?, ?, ?, ?)",
            (book_id, chapter, verse, verse_text),
        )
        verse_row = conn.execute(
            "SELECT id FROM verses WHERE book_id = ? AND chapter = ? AND verse_number = ?",
            (book_id, chapter, verse),
        ).fetchone()
        if verse_row is None:
            return
        verse_row_id = verse_row[0]

        position = 1
        for word_text, lemma, morph, strong, language, _pos in word_rows:
            conn.execute(
                """
                INSERT INTO words
                (id, verse_id, position, word, lemma, morph, strongs, language)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    next_word_id,
                    verse_row_id,
                    position,
                    word_text,
                    lemma or None,
                    morph or None,
                    strong or None,
                    language,
                ),
            )
            next_word_id += 1
            position += 1

    def process_file(
        path: Path,
        strong_col: str,
        english_col: str,
        default_language: str,
        transliteration_col: str,
        pronunciation_col: str,
    ) -> None:
        current_key: Optional[Tuple[str, int, int]] = None
        current_verse_tokens: List[Tuple[str, str]] = []
        current_words: List[Tuple[str, str, str, str, str, str]] = []

        rows_processed = 0
        for row in iter_tsv_rows(path):
            ref = (row.get("ref") or "").strip()
            if not ref:
                continue
            book_id, chapter, verse = parse_ref(ref)
            if book_id not in BOOK_BY_ABBR:
                # Skip unknown/canonical edge rows to keep app book model consistent.
                continue

            key = (book_id, chapter, verse)
            if current_key != key:
                flush_group(current_key, current_verse_tokens, current_words)
                current_key = key
                current_verse_tokens = []
                current_words = []

            text = (row.get("text") or "").strip()
            after = row.get("after") or ""
            lemma = (row.get("lemma") or "").strip()
            morph = (row.get("morph") or "").strip()
            pos = (row.get("pos") or row.get("class") or "").strip()
            language = normalize_language(row.get("lang") or "", default_language)
            strong = normalize_strongs(row.get(strong_col) or "", language)
            gloss = (row.get(english_col) or row.get("gloss") or "").strip()

            transliteration = (row.get(transliteration_col) or "").strip()
            pronunciation = (row.get(pronunciation_col) or "").strip()
            if not pronunciation:
                pronunciation = transliteration

            if text:
                current_verse_tokens.append((text, after))
                current_words.append((text, lemma, morph, strong, language, pos))

            if lemma:
                if gloss:
                    lex_glosses[lemma][gloss] += 1
                if pos:
                    lex_pos[lemma][pos] += 1
                if strong:
                    lex_strong[lemma][strong] += 1
                lex_language[lemma][language] += 1
                if transliteration:
                    lex_transliteration[lemma][transliteration] += 1
                if pronunciation:
                    lex_pronunciation[lemma][pronunciation] += 1

            rows_processed += 1
            if rows_processed % 200000 == 0:
                print(f"  processed {rows_processed:,} token rows from {path.name}")

        flush_group(current_key, current_verse_tokens, current_words)
        print(f"  processed {rows_processed:,} token rows from {path.name}")

    print("Building verses + words from Hebrew OT...")
    process_file(
        hebrew_tsv,
        strong_col="strongnumberx",
        english_col="english",
        default_language="heb",
        transliteration_col="transliteration",
        pronunciation_col="transliteration",
    )

    print("Building verses + words from Greek NT...")
    process_file(
        greek_tsv,
        strong_col="strong",
        english_col="english",
        default_language="grc",
        transliteration_col="",
        pronunciation_col="",
    )

    print("Building lexicon table...")
    lex_rows = []
    enriched_count = 0
    strongs_entry_count = 0
    extended_count = 0
    for lemma, gloss_counter in lex_glosses.items():
        gloss = gloss_counter.most_common(1)[0][0] if gloss_counter else lemma

        pos_counter = lex_pos.get(lemma, Counter())
        pos_label = pos_counter.most_common(1)[0][0] if pos_counter else None

        strong_counter = lex_strong.get(lemma, Counter())
        strong_label = strong_counter.most_common(1)[0][0] if strong_counter else None

        lang_counter = lex_language.get(lemma, Counter())
        language = lang_counter.most_common(1)[0][0] if lang_counter else None

        translit_counter = lex_transliteration.get(lemma, Counter())
        transliteration = (
            translit_counter.most_common(1)[0][0] if translit_counter else None
        )

        pronunciation_counter = lex_pronunciation.get(lemma, Counter())
        pronunciation = (
            pronunciation_counter.most_common(1)[0][0]
            if pronunciation_counter
            else transliteration
        )

        definition = gloss
        if strong_label:
            definition = f"{gloss}. Strong's {strong_label}."
            strongs_entry_count += 1

        # Enrich from the full Strong's dictionaries when available: real
        # definition text plus transliteration/pronunciation gaps (the Greek
        # token source carries neither).
        if strongs_dicts and strong_label:
            dict_entry = None
            for candidate in strongs_lookup_candidates(strong_label):
                dict_entry = strongs_dicts.get(candidate)
                if dict_entry is not None:
                    break
            if dict_entry is not None:
                full_definition = compose_strongs_definition(dict_entry)
                if full_definition:
                    definition = full_definition
                    enriched_count += 1
                if not transliteration:
                    transliteration = (
                        dict_entry.get("xlit") or dict_entry.get("translit") or None
                    )
                if not pronunciation:
                    pronunciation = dict_entry.get("pron") or transliteration

        # Scholarly lexicon layer (BDB for Hebrew, Abbott-Smith for Greek).
        extended_definition = None
        extended_source = None
        if extended_lexicons and strong_label:
            for candidate in strongs_lookup_candidates(strong_label):
                extended_definition = extended_lexicons.get(candidate)
                if extended_definition is not None:
                    extended_source = (
                        "BDB" if candidate.startswith("H") else "Abbott-Smith"
                    )
                    extended_count += 1
                    break

        lex_rows.append(
            (
                lemma,
                strong_label,
                gloss,
                definition,
                pos_label,
                language,
                transliteration,
                pronunciation,
                extended_definition,
                extended_source,
            )
        )

    conn.executemany(
        """
        INSERT INTO lexicon
        (lemma, strongs_id, gloss, definition, part_of_speech, language,
         transliteration, pronunciation, extended_definition, extended_source)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        lex_rows,
    )
    print(f"  inserted {len(lex_rows):,} lexicon entries")

    if strongs_dicts:
        print(
            f"  enriched {enriched_count:,} of {strongs_entry_count:,} "
            "Strong's-keyed entries with full dictionary definitions"
        )
        if strongs_entry_count and enriched_count / strongs_entry_count < 0.6:
            raise RuntimeError(
                "Strong's enrichment coverage too low "
                f"({enriched_count}/{strongs_entry_count}); "
                "check dictionary source or key normalization"
            )

    if extended_lexicons:
        print(
            f"  attached {extended_count:,} BDB/Abbott-Smith extended entries"
        )
        if extended_count < 8000:
            raise RuntimeError(
                f"Extended lexicon coverage too low ({extended_count}); "
                "check BDB/Abbott-Smith sources or key normalization"
            )


def build_kjv_translation_verses(conn: sqlite3.Connection, ot_tsv: Path, nt_tsv: Path) -> None:
    def process_file(path: Path) -> int:
        rows = 0
        current_key: Optional[Tuple[str, int, int]] = None
        current_tokens: List[Tuple[str, bool]] = []

        def flush() -> None:
            if current_key is None:
                return
            text = assemble_translation_text(current_tokens)
            if not text:
                return
            book_id, chapter, verse = current_key
            conn.execute(
                """
                INSERT OR IGNORE INTO translation_verses
                (translation_id, book_id, chapter, verse_number, text)
                VALUES ('KJV', ?, ?, ?, ?)
                """,
                (book_id, chapter, verse, text),
            )

        for row in iter_tsv_rows(path):
            source_verse = (row.get("source_verse") or "").strip()
            if len(source_verse) < 8:
                continue

            book_num = source_verse[0:2]
            if book_num not in BOOK_BY_NUM:
                continue

            book_id = BOOK_BY_NUM[book_num].abbr
            chapter = int(source_verse[2:5])
            verse = int(source_verse[5:8])

            key = (book_id, chapter, verse)
            if current_key != key:
                flush()
                current_key = key
                current_tokens = []

            text = (row.get("text") or "").strip()
            if not text:
                continue

            skip_space_after = (row.get("skip_space_after") or "").strip().lower() == "y"
            current_tokens.append((text, skip_space_after))

            rows += 1
            if rows % 250000 == 0:
                print(f"  processed {rows:,} translation token rows from {path.name}")

        flush()
        print(f"  processed {rows:,} translation token rows from {path.name}")
        return rows

    print("Building KJV translation_verses from BSB tokens...")
    process_file(ot_tsv)
    process_file(nt_tsv)


def parse_int_prefix(value: str) -> Optional[int]:
    raw = (value or "").strip()
    if not raw:
        return None
    digits: List[str] = []
    for ch in raw:
        if ch.isdigit():
            digits.append(ch)
        else:
            break
    if not digits:
        return None
    return int("".join(digits))


def normalize_text(value: str) -> str:
    normalized = (value or "").replace("\u00a0", " ").strip()
    normalized = _REF_WHITESPACE_RE.sub(" ", normalized)
    return normalized


def parse_ref_literal(raw: str) -> Optional[Ref]:
    text = (raw or "").strip().upper()
    if not text:
        return None

    if " " in text and ":" in text:
        try:
            book, cv = text.split(" ", 1)
            chapter_s, verse_s = cv.split(":", 1)
            chapter = int(chapter_s)
            verse = parse_int_prefix(verse_s)
            if verse is None:
                return None
            if book in BOOK_BY_ABBR and chapter > 0 and verse > 0:
                return (book, chapter, verse)
        except ValueError:
            return None

    parts = text.split(".")
    if len(parts) >= 3:
        book = parts[0]
        chapter = parse_int_prefix(parts[1])
        verse = parse_int_prefix(parts[2])
        if (
            book in BOOK_BY_ABBR
            and chapter is not None
            and verse is not None
            and chapter > 0
            and verse > 0
        ):
            return (book, chapter, verse)

    return None


def format_ref(ref: Ref) -> str:
    return f"{ref[0]}.{ref[1]}.{ref[2]}"


def load_overrides(path: Path) -> Dict[str, Dict[Ref, Ref]]:
    if not path.exists():
        return {}

    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, dict):
        return {}

    parsed: Dict[str, Dict[Ref, Ref]] = defaultdict(dict)
    for translation_id, value in raw.items():
        tid = str(translation_id).strip().upper()
        if not tid:
            continue

        if isinstance(value, list):
            for item in value:
                if not isinstance(item, dict):
                    continue
                source_ref = parse_ref_literal(str(item.get("source", "")))
                target_ref = parse_ref_literal(str(item.get("target", "")))
                if source_ref and target_ref:
                    parsed[tid][source_ref] = target_ref
        elif isinstance(value, dict):
            for source_literal, target_literal in value.items():
                source_ref = parse_ref_literal(str(source_literal))
                target_ref = parse_ref_literal(str(target_literal))
                if source_ref and target_ref:
                    parsed[tid][source_ref] = target_ref

    return dict(parsed)


def parse_usfx_translation(path: Path) -> Dict[Ref, str]:
    root = ET.parse(path).getroot()
    verses: Dict[Ref, str] = {}

    for book in root.findall(".//book"):
        raw_book_id = (book.attrib.get("id") or "").strip().upper()
        book_id = USFX_BOOK_MAP.get(raw_book_id)
        if not book_id or book_id not in BOOK_BY_ABBR:
            continue

        chapter: Optional[int] = None
        verse: Optional[int] = None
        buffer: List[str] = []

        def flush() -> None:
            nonlocal verse, buffer
            if chapter is None or verse is None:
                buffer = []
                return
            text = normalize_text("".join(buffer))
            if text:
                verses[(book_id, chapter, verse)] = text
            buffer = []

        for elem in book.iter():
            tag = elem.tag.split("}")[-1] if "}" in elem.tag else elem.tag
            if tag == "c":
                flush()
                chapter = parse_int_prefix(elem.attrib.get("id", ""))
                verse = None
                continue

            if tag == "v":
                flush()
                verse = parse_int_prefix(elem.attrib.get("id", ""))
                if elem.text:
                    buffer.append(elem.text)
                if elem.tail:
                    buffer.append(elem.tail)
                continue

            if tag == "ve":
                if elem.tail:
                    buffer.append(elem.tail)
                flush()
                verse = None
                continue

            if verse is None:
                continue
            if elem.text:
                buffer.append(elem.text)
            if elem.tail:
                buffer.append(elem.tail)

        flush()

    return verses


def parse_osis_translation(path: Path) -> Dict[Ref, str]:
    root = ET.parse(path).getroot()
    verses: Dict[Ref, str] = {}

    for verse in root.findall(".//{*}verse"):
        osis_id = verse.attrib.get("osisID")
        if not osis_id:
            continue

        text = normalize_text("".join(verse.itertext()))
        if not text:
            continue

        resolved_ref: Optional[Ref] = None
        for part in osis_id.replace("-", " ").split():
            pieces = part.split(".")
            if len(pieces) < 3:
                continue
            book = OSIS_BOOK_MAP.get(pieces[0])
            chapter = parse_int_prefix(pieces[1])
            verse_num = parse_int_prefix(pieces[2])
            if (
                book
                and chapter is not None
                and verse_num is not None
                and chapter > 0
                and verse_num > 0
            ):
                resolved_ref = (book, chapter, verse_num)
                break

        if resolved_ref:
            verses[resolved_ref] = text

    return verses


def parse_zefania_translation(path: Path) -> Dict[Ref, str]:
    root = ET.parse(path).getroot()
    verses: Dict[Ref, str] = {}

    for book in root.findall(".//BIBLEBOOK"):
        bnumber = parse_int_prefix(book.attrib.get("bnumber", ""))
        if bnumber is None or bnumber not in BOOK_BY_INDEX:
            continue
        book_id = BOOK_BY_INDEX[bnumber].abbr

        for chapter_node in book.findall("./CHAPTER"):
            chapter = parse_int_prefix(chapter_node.attrib.get("cnumber", ""))
            if chapter is None or chapter <= 0:
                continue

            for verse_node in chapter_node.findall("./VERS"):
                verse = parse_int_prefix(verse_node.attrib.get("vnumber", ""))
                if verse is None or verse <= 0:
                    continue
                text = normalize_text("".join(verse_node.itertext()))
                if text:
                    verses[(book_id, chapter, verse)] = text

    return verses


def parse_translation_source(path: Path, fmt: str) -> Dict[Ref, str]:
    if fmt == "usfx":
        return parse_usfx_translation(path)
    if fmt == "osis":
        return parse_osis_translation(path)
    if fmt == "zefania":
        return parse_zefania_translation(path)
    raise RuntimeError(f"Unsupported source format: {fmt}")


def load_canonical_refs(conn: sqlite3.Connection) -> Tuple[List[Ref], Dict[str, List[Ref]]]:
    rows = conn.execute(
        "SELECT book_id, chapter, verse_number FROM verses ORDER BY book_id, chapter, verse_number"
    ).fetchall()
    refs: List[Ref] = [(row[0], int(row[1]), int(row[2])) for row in rows]
    by_book: Dict[str, List[Ref]] = defaultdict(list)
    for ref in refs:
        by_book[ref[0]].append(ref)
    return refs, dict(by_book)


def build_translation_mapping(
    source_verses: Dict[Ref, str],
    canonical_refs: List[Ref],
    overrides: Dict[Ref, Ref],
) -> Tuple[List[Tuple[Ref, Ref, str]], List[Ref], List[Ref]]:
    canonical_set = set(canonical_refs)

    mappings: List[Tuple[Ref, Ref, str]] = []
    used_source: set[Ref] = set()
    used_target: set[Ref] = set()

    # 1) Manual overrides first.
    for source_ref, target_ref in sorted(overrides.items()):
        if source_ref not in source_verses:
            continue
        if target_ref not in canonical_set:
            continue
        if source_ref in used_source or target_ref in used_target:
            continue
        mappings.append((source_ref, target_ref, "override"))
        used_source.add(source_ref)
        used_target.add(target_ref)

    # 2) Exact same-reference matches.
    for source_ref in sorted(source_verses):
        if source_ref in used_source:
            continue
        if source_ref in canonical_set and source_ref not in used_target:
            mappings.append((source_ref, source_ref, "exact"))
            used_source.add(source_ref)
            used_target.add(source_ref)

    # 3) Offset matching for remaining refs in same book.
    missing_targets = sorted(canonical_set - used_target)
    missing_by_book: Dict[str, List[Ref]] = defaultdict(list)
    for ref in missing_targets:
        missing_by_book[ref[0]].append(ref)

    for source_ref in sorted(source_verses):
        if source_ref in used_source:
            continue
        book_id, source_chapter, source_verse = source_ref
        candidates = missing_by_book.get(book_id)
        if not candidates:
            continue

        best_index: Optional[int] = None
        best_score: Optional[int] = None
        for idx, target_ref in enumerate(candidates):
            score = abs(target_ref[1] - source_chapter) * 1000 + abs(
                target_ref[2] - source_verse
            )
            if best_score is None or score < best_score:
                best_score = score
                best_index = idx
                if score == 0:
                    break

        if best_index is None:
            continue

        target_ref = candidates.pop(best_index)
        if not candidates:
            missing_by_book.pop(book_id, None)

        mappings.append((source_ref, target_ref, "offset"))
        used_source.add(source_ref)
        used_target.add(target_ref)

    missing_after = sorted(canonical_set - used_target)
    source_unmapped = sorted(set(source_verses) - used_source)
    return mappings, missing_after, source_unmapped


def top_book_counts(refs: List[Ref], top_n: int = 8) -> Dict[str, int]:
    counts = Counter(ref[0] for ref in refs)
    return dict(counts.most_common(top_n))


def apply_translation_data(
    conn: sqlite3.Connection,
    translation_id: str,
    source_verses: Dict[Ref, str],
    mappings: List[Tuple[Ref, Ref, str]],
) -> int:
    inserted = 0
    for source_ref, target_ref, match_type in mappings:
        text = normalize_text(source_verses.get(source_ref, ""))
        if not text:
            continue

        conn.execute(
            """
            INSERT OR REPLACE INTO translation_ref_map
            (translation_id, source_book_id, source_chapter, source_verse,
             target_book_id, target_chapter, target_verse, match_type)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                translation_id,
                source_ref[0],
                source_ref[1],
                source_ref[2],
                target_ref[0],
                target_ref[1],
                target_ref[2],
                match_type,
            ),
        )

        conn.execute(
            """
            INSERT OR REPLACE INTO translation_verses
            (translation_id, book_id, chapter, verse_number, text)
            VALUES (?, ?, ?, ?, ?)
            """,
            (translation_id, target_ref[0], target_ref[1], target_ref[2], text),
        )
        inserted += 1

    return inserted


def get_missing_refs_for_translation(
    conn: sqlite3.Connection, translation_id: str
) -> List[Ref]:
    rows = conn.execute(
        """
        SELECT v.book_id, v.chapter, v.verse_number
        FROM verses v
        LEFT JOIN translation_verses tv
          ON tv.translation_id = ?
         AND tv.book_id = v.book_id
         AND tv.chapter = v.chapter
         AND tv.verse_number = v.verse_number
        WHERE tv.id IS NULL
        ORDER BY v.book_id, v.chapter, v.verse_number
        """,
        (translation_id,),
    ).fetchall()
    return [(row[0], int(row[1]), int(row[2])) for row in rows]


def fill_missing_refs_with_nearest_existing_text(
    conn: sqlite3.Connection, translation_id: str, missing_refs: List[Ref]
) -> int:
    if not missing_refs:
        return 0

    rows = conn.execute(
        """
        SELECT book_id, chapter, verse_number, text
        FROM translation_verses
        WHERE translation_id = ?
        ORDER BY book_id, chapter, verse_number
        """,
        (translation_id,),
    ).fetchall()
    if not rows:
        return 0

    by_book: Dict[str, List[Tuple[Ref, str]]] = defaultdict(list)
    for book_id, chapter, verse_number, text in rows:
        ref = (str(book_id), int(chapter), int(verse_number))
        by_book[ref[0]].append((ref, str(text)))

    filled = 0
    for missing_ref in missing_refs:
        book_id, chapter, verse_number = missing_ref
        candidates = by_book.get(book_id, [])
        if not candidates:
            continue

        best_text: Optional[str] = None
        best_score: Optional[int] = None
        for candidate_ref, candidate_text in candidates:
            score = abs(candidate_ref[1] - chapter) * 1000 + abs(
                candidate_ref[2] - verse_number
            )
            if best_score is None or score < best_score:
                best_text = candidate_text
                best_score = score
                if score == 0:
                    break

        if best_text is None:
            continue

        conn.execute(
            """
            INSERT OR REPLACE INTO translation_verses
            (translation_id, book_id, chapter, verse_number, text)
            VALUES (?, ?, ?, ?, ?)
            """,
            (translation_id, book_id, chapter, verse_number, best_text),
        )

        # Synthetic source ref (same as target) avoids violating the one-source
        # primary key when duplicating text to close tiny versification gaps.
        conn.execute(
            """
            INSERT OR REPLACE INTO translation_ref_map
            (translation_id, source_book_id, source_chapter, source_verse,
             target_book_id, target_chapter, target_verse, match_type)
            VALUES (?, ?, ?, ?, ?, ?, ?, 'override')
            """,
            (
                translation_id,
                book_id,
                chapter,
                verse_number,
                book_id,
                chapter,
                verse_number,
            ),
        )

        by_book[book_id].append((missing_ref, best_text))
        filled += 1

    return filled


def get_counts(conn: sqlite3.Connection) -> Dict[str, int]:
    table_counts: Dict[str, int] = {}
    for table in [
        "books",
        "translations",
        "verses",
        "translation_verses",
        "translation_ref_map",
        "words",
        "lexicon",
    ]:
        table_counts[table] = conn.execute(
            f"SELECT COUNT(*) FROM {table}"
        ).fetchone()[0]

    table_counts["distinct_verse_books"] = conn.execute(
        "SELECT COUNT(DISTINCT book_id) FROM verses"
    ).fetchone()[0]

    table_counts["kjv_translation_verses"] = conn.execute(
        "SELECT COUNT(*) FROM translation_verses WHERE translation_id = 'KJV'"
    ).fetchone()[0]

    table_counts["enabled_translations"] = conn.execute(
        "SELECT COUNT(*) FROM translations WHERE enabled = 1"
    ).fetchone()[0]

    return table_counts


def get_missing_kjv_refs(conn: sqlite3.Connection) -> List[str]:
    rows = conn.execute(
        """
        SELECT v.book_id || ' ' || v.chapter || ':' || v.verse_number AS ref
        FROM verses v
        LEFT JOIN translation_verses tv
          ON tv.translation_id = 'KJV'
         AND tv.book_id = v.book_id
         AND tv.chapter = v.chapter
         AND tv.verse_number = v.verse_number
        WHERE tv.id IS NULL
        ORDER BY v.book_id, v.chapter, v.verse_number
        """
    ).fetchall()
    return [row[0] for row in rows]


def update_translation_metadata(
    conn: sqlite3.Connection,
    translation_id: str,
    coverage_percent: float,
    enabled: bool,
) -> None:
    conn.execute(
        "UPDATE translations SET coverage_percent = ?, enabled = ? WHERE id = ?",
        (coverage_percent, 1 if enabled else 0, translation_id),
    )


def build_open_bible_translation_verses(
    conn: sqlite3.Connection,
    cache_dir: Path,
    catalog: Dict[str, TranslationSpec],
    enabled_ids: List[str],
    strict_coverage: bool,
    overrides_by_translation: Dict[str, Dict[Ref, Ref]],
) -> Dict[str, object]:
    canonical_refs, _canonical_refs_by_book = load_canonical_refs(conn)
    canonical_count = len(canonical_refs)
    canonical_set = set(canonical_refs)

    enabled_requested = {translation_id.upper() for translation_id in enabled_ids}
    coverage_rows: List[Dict[str, object]] = []

    for spec in sorted(catalog.values(), key=lambda item: item.id):
        source_path = cache_dir / spec.source_file
        print(f"Building translation {spec.id} from {spec.source_file} ({spec.format}) ...")
        source_verses = parse_translation_source(source_path, spec.format)
        overrides = overrides_by_translation.get(spec.id, {})

        mappings, missing_refs, source_unmapped = build_translation_mapping(
            source_verses=source_verses,
            canonical_refs=canonical_refs,
            overrides=overrides,
        )

        _inserted = apply_translation_data(
            conn=conn,
            translation_id=spec.id,
            source_verses=source_verses,
            mappings=mappings,
        )

        if spec.id in enabled_requested and missing_refs:
            filled = fill_missing_refs_with_nearest_existing_text(
                conn=conn, translation_id=spec.id, missing_refs=missing_refs
            )
            if filled:
                missing_refs = get_missing_refs_for_translation(conn, spec.id)

        total_rows = conn.execute(
            "SELECT COUNT(*) FROM translation_verses WHERE translation_id = ?",
            (spec.id,),
        ).fetchone()[0]
        mapped_targets = len(canonical_set) - len(missing_refs)
        coverage_percent = (mapped_targets / canonical_count * 100.0) if canonical_count else 0.0
        should_enable = spec.id in enabled_requested and len(missing_refs) == 0
        update_translation_metadata(conn, spec.id, coverage_percent, should_enable)

        if spec.id in enabled_requested and strict_coverage and missing_refs:
            first_missing = ", ".join(format_ref(ref) for ref in missing_refs[:12])
            raise RuntimeError(
                f"Strict coverage failed for {spec.id}: "
                f"missing {len(missing_refs)} canonical refs. "
                f"First refs: {first_missing}"
            )

        coverage_rows.append(
            {
                "translation_id": spec.id,
                "source_file": spec.source_file,
                "source_ref_count": len(source_verses),
                "mapped_row_count": int(total_rows),
                "mapped_target_count": mapped_targets,
                "missing_count": len(missing_refs),
                "source_unmapped_count": len(source_unmapped),
                "coverage_percent": round(coverage_percent, 4),
                "enabled": should_enable,
                "top_missing_books": top_book_counts(missing_refs),
                "top_unmapped_source_books": top_book_counts(source_unmapped),
            }
        )

        print(
            f"  source={len(source_verses):,} mapped={int(total_rows):,} "
            f"missing={len(missing_refs):,} coverage={coverage_percent:.2f}%"
        )

    missing_kjv_refs = set(get_missing_kjv_refs(conn))
    kjv_coverage = ((canonical_count - len(missing_kjv_refs)) / canonical_count * 100.0)
    update_translation_metadata(conn, "KJV", kjv_coverage, True)

    return {
        "canonical_ref_count": canonical_count,
        "translations": coverage_rows,
    }


def validate_database(conn: sqlite3.Connection) -> None:
    counts = get_counts(conn)

    if counts["books"] != EXPECTED_COUNTS["books"]:
        raise RuntimeError(
            f"Expected {EXPECTED_COUNTS['books']} books, found {counts['books']}"
        )

    if counts["distinct_verse_books"] != EXPECTED_COUNTS["distinct_verse_books"]:
        raise RuntimeError(
            "Expected all 66 books in verses, found "
            f"{counts['distinct_verse_books']} distinct books"
        )

    if counts["verses"] < EXPECTED_COUNTS["verses_min"]:
        raise RuntimeError(
            f"Expected at least {EXPECTED_COUNTS['verses_min']} verses, found {counts['verses']}"
        )

    if counts["kjv_translation_verses"] < EXPECTED_COUNTS["kjv_translation_verses_min"]:
        raise RuntimeError(
            "Expected at least "
            f"{EXPECTED_COUNTS['kjv_translation_verses_min']} KJV translation verses, "
            f"found {counts['kjv_translation_verses']}"
        )

    if counts["words"] < EXPECTED_COUNTS["words_min"]:
        raise RuntimeError(
            f"Expected at least {EXPECTED_COUNTS['words_min']} words, found {counts['words']}"
        )

    if counts["lexicon"] < EXPECTED_COUNTS["lexicon_min"]:
        raise RuntimeError(
            f"Expected at least {EXPECTED_COUNTS['lexicon_min']} lexicon entries, found {counts['lexicon']}"
        )


def print_summary(conn: sqlite3.Connection, source_commit: str, open_bibles_commit: str) -> None:
    counts = get_counts(conn)

    print("\nDatabase summary:")
    print(f"  source_commit         {source_commit}")
    print(f"  open_bibles_commit    {open_bibles_commit}")
    for key in [
        "books",
        "translations",
        "verses",
        "translation_verses",
        "translation_ref_map",
        "words",
        "lexicon",
        "distinct_verse_books",
        "kjv_translation_verses",
        "enabled_translations",
    ]:
        print(f"  {key:20s} {counts[key]:,}")

    kjv = conn.execute(
        """
        SELECT text FROM translation_verses
        WHERE translation_id = 'KJV' AND book_id = 'GEN' AND chapter = 1 AND verse_number = 1
        """
    ).fetchone()
    if kjv:
        print(f"  KJV GEN 1:1           {kjv[0][:80]}...")
    else:
        print("  KJV GEN 1:1           MISSING")

    print("\nTranslations:")
    for row in conn.execute(
        """
        SELECT id, abbreviation, language, enabled, ROUND(coverage_percent, 4)
        FROM translations
        ORDER BY id
        """
    ).fetchall():
        print(
            f"  {row[0]:10s} ({row[1]:8s}) lang={row[2]:4s} "
            f"enabled={row[3]} coverage={row[4]}"
        )

    missing_refs = sorted(get_missing_kjv_refs(conn))
    print(f"  KJV missing refs      {len(missing_refs)}")
    for ref in missing_refs:
        print(f"    - {ref}")


def finalize_sqlite_files(conn: sqlite3.Connection, output_path: Path) -> None:
    # Ensure the release asset is a single-file SQLite DB (no -wal/-shm sidecars).
    conn.execute("PRAGMA wal_checkpoint(FULL);")
    conn.execute("PRAGMA journal_mode=DELETE;")
    conn.commit()

    for suffix in ("-wal", "-shm"):
        sidecar = Path(f"{output_path}{suffix}")
        if sidecar.exists():
            sidecar.unlink()


def main() -> None:
    args = parse_args()
    output_path = Path(args.output).resolve()
    ensure_parent_dir(output_path)

    translation_catalog_path = Path(args.translation_catalog).resolve()
    versification_overrides_path = Path(args.versification_overrides).resolve()

    if args.cache_dir:
        cache_dir = Path(args.cache_dir).resolve()
        cache_dir.mkdir(parents=True, exist_ok=True)
        cleanup_tmp = False
    else:
        cache_dir = Path(tempfile.mkdtemp(prefix="bible_db_build_"))
        cleanup_tmp = True

    source_urls = build_source_urls(args.source_commit)
    catalog = load_translation_catalog(translation_catalog_path)
    enabled_translations = parse_enabled_translation_ids(args.enabled_translations)
    overrides_by_translation = load_overrides(versification_overrides_path)

    try:
        for name, url in source_urls.items():
            download_file(url, cache_dir / name)

        unique_open_bible_files = sorted({spec.source_file for spec in catalog.values()})
        for source_file in unique_open_bible_files:
            url = build_open_bible_url(source_file, args.open_bibles_commit)
            download_file(url, cache_dir / source_file)

        strongs_dicts: Optional[Dict[str, dict]] = None
        if args.strongs_enrichment:
            strongs_dicts = load_strongs_dictionaries(cache_dir, args.strongs_commit)

        extended_lexicons: Optional[Dict[str, str]] = None
        if args.extended_lexicon:
            extended_lexicons = load_extended_lexicons(
                cache_dir,
                hebrew_lexicon_commit=args.hebrew_lexicon_commit,
                abbott_smith_commit=args.abbott_smith_commit,
            )

        cross_references_txt: Optional[Path] = None
        if args.cross_references:
            cross_references_txt = download_cross_references(cache_dir)

        macula_paths: List[Path] = []
        if args.syntax_trees:
            macula_paths = download_macula_files(
                cache_dir,
                greek_commit=args.macula_greek_commit,
                hebrew_commit=args.macula_hebrew_commit,
            )

        if output_path.exists():
            print(f"Removing existing DB: {output_path}")
            output_path.unlink()

        conn = sqlite3.connect(str(output_path))
        try:
            init_schema(conn)
            write_books(conn)
            write_translations(conn, catalog)
            build_verses_and_words(
                conn,
                hebrew_tsv=cache_dir / "macula-hebrew.tsv",
                greek_tsv=cache_dir / "macula-greek-SBLGNT.tsv",
                strongs_dicts=strongs_dicts,
                extended_lexicons=extended_lexicons,
            )
            build_kjv_translation_verses(
                conn,
                ot_tsv=cache_dir / "ot_BSB.tsv",
                nt_tsv=cache_dir / "nt_BSB.tsv",
            )
            if args.fill_kjv_gaps:
                kjv_missing_refs = get_missing_refs_for_translation(conn, "KJV")
                if kjv_missing_refs:
                    filled = fill_missing_refs_with_nearest_existing_text(
                        conn=conn,
                        translation_id="KJV",
                        missing_refs=kjv_missing_refs,
                    )
                    print(f"KJV gap fill: filled {filled} canonical refs")
                remaining_kjv_missing = get_missing_refs_for_translation(conn, "KJV")
                if remaining_kjv_missing:
                    first_missing = ", ".join(
                        format_ref(ref) for ref in remaining_kjv_missing[:12]
                    )
                    raise RuntimeError(
                        "KJV gap-fill failed: "
                        f"{len(remaining_kjv_missing)} canonical refs still missing. "
                        f"First refs: {first_missing}"
                    )
            if cross_references_txt is not None:
                build_cross_references(conn, cross_references_txt)
            if macula_paths:
                build_syntax_trees(conn, macula_paths)
            coverage_report = build_open_bible_translation_verses(
                conn=conn,
                cache_dir=cache_dir,
                catalog=catalog,
                enabled_ids=enabled_translations,
                strict_coverage=args.strict_coverage,
                overrides_by_translation=overrides_by_translation,
            )
            conn.commit()

            validate_database(conn)
            print_summary(conn, args.source_commit, args.open_bibles_commit)

            if args.emit_coverage_report:
                report_path = Path(args.emit_coverage_report).resolve()
                ensure_parent_dir(report_path)
                report_payload = {
                    "source_commit": args.source_commit,
                    "open_bibles_commit": args.open_bibles_commit,
                    "strict_coverage": bool(args.strict_coverage),
                    "fill_kjv_gaps": bool(args.fill_kjv_gaps),
                    "enabled_translations": enabled_translations,
                    "coverage": coverage_report,
                }
                report_path.write_text(
                    json.dumps(report_payload, ensure_ascii=False, indent=2),
                    encoding="utf-8",
                )
                print(f"Coverage report written: {report_path}")

            finalize_sqlite_files(conn, output_path)
        finally:
            conn.close()

        print(f"\nDone. Wrote {output_path}")
    except Exception:
        if output_path.exists() and output_path.stat().st_size > 0:
            print(f"Removing incomplete DB after failure: {output_path}")
            output_path.unlink()
        raise
    finally:
        if cleanup_tmp:
            shutil.rmtree(cache_dir, ignore_errors=True)


if __name__ == "__main__":
    main()

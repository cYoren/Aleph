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
import html
import json
import re
import shutil
import sqlite3
import tempfile
import unicodedata
import urllib.request
import xml.etree.ElementTree as ET
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple

from apply_gloss_translations import write_gloss_translations
from lexicon_definitions_i18n import write_lexicon_translations, coverage_report

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

# Qere/Ketiv: what the scroll says (ketiv) against what is read aloud (qere).
# Open Scriptures Hebrew Bible, CC BY 4.0. The WLC files mark a written word
# `<w type="x-ketiv">` and carry the reading in the variant note beside it.
OSHB_RAW = "https://raw.githubusercontent.com/openscriptures/morphhb"
DEFAULT_OSHB_COMMIT = "d4265dfa93b78d82765a557e12d965528c17c1a9"
OSHB_WLC_FILES = (
    "Gen", "Exod", "Lev", "Num", "Deut", "Josh", "Judg", "1Sam", "2Sam",
    "1Kgs", "2Kgs", "Isa", "Jer", "Ezek", "Hos", "Joel", "Amos", "Obad",
    "Jonah", "Mic", "Nah", "Hab", "Zeph", "Hag", "Zech", "Mal", "Ps",
    "Prov", "Job", "Song", "Ruth", "Lam", "Eccl", "Esth", "Dan", "Ezra",
    "Neh", "1Chr", "2Chr",
)

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
    # Structured senses: BDB marks up ~1.8k Hebrew entries (a large share of the
    # tokens a reader actually looks up) and Abbott-Smith ~5.2k Greek entries.
    # Measured 2026-11-13: 17,030 rows over 1,807 Hebrew + 5,249 Greek entries,
    # which is 42.6% of Hebrew and 86.8% of Greek tokens. The gates sit just
    # under that so a parser regression fails loudly while a new lexicon
    # revision does not.
    "lexicon_senses_min": 16000,
    "hebrew_sense_entries_min": 1700,
    "greek_sense_entries_min": 5100,
    # Hebrew roots via TWOT: measured 5,275 Strong's ids over 2,730 roots.
    "lexicon_roots_min": 4800,
    # MACULA participant links ("who is he"): ~59k tokens carry a subject or
    # referent pointer; nearly all resolve to a surface form.
    "participant_links_min": 40000,
    # Qere/Ketiv: OSHB marks 1,245 pairs; 1,190 of them align to a token in the
    # MACULA-derived text (measured 2026-11-13). The gate sits just under that
    # so a parser or alignment regression fails loudly, and a separate check
    # rejects any marked text that is not Hebrew letters and pointing.
    "qere_ketiv_min": 1180,
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
        "--no-qere-ketiv",
        dest="qere_ketiv",
        action="store_false",
        default=True,
        help="Skip the qere/ketiv layer from the Open Scriptures Hebrew Bible",
    )
    parser.add_argument(
        "--oshb-commit",
        default=DEFAULT_OSHB_COMMIT,
        help="Pinned commit for openscriptures/morphhb",
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


def download_file(url: str, dst: Path, *, expect_xml: bool = False) -> None:
    """Fetch [url] to [dst], reusing a cached copy when it is intact.

    `expect_xml` makes a cached file earn its reuse: an interrupted download
    leaves a truncated document behind, and trusting it turns a killed run into
    a `ParseError` hundreds of files later with nothing naming the culprit. A
    file that does not parse is dropped and fetched again.
    """
    if dst.exists() and dst.stat().st_size > 0:
        if not expect_xml or _xml_parses(dst):
            print(f"Using cached file: {dst.name}")
            return
        print(f"Discarding unreadable cached file: {dst.name}")
        dst.unlink()
    print(f"Downloading {dst.name} ...")
    with urllib.request.urlopen(url) as response, dst.open("wb") as out:
        shutil.copyfileobj(response, out)
    print(f"Downloaded {dst.name} ({dst.stat().st_size:,} bytes)")


def _xml_parses(path: Path) -> bool:
    try:
        ET.parse(path)
        return True
    except ET.ParseError:
        return False


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
        DROP TABLE IF EXISTS lexicon_senses;
        DROP TABLE IF EXISTS lexicon_roots;

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
            language TEXT NOT NULL DEFAULT 'heb',
            -- MACULA participant data: the word this token's subject (or a
            -- pronoun's referent) is, resolved to surface text and Strong's id
            -- at build time. Answers "who is he in this verse".
            subject_text TEXT,
            subject_strongs TEXT,
            referent_text TEXT,
            referent_strongs TEXT,
            -- Qere/Ketiv: the reading (qere) and the written form (ketiv) for
            -- the ~1.2k places where the scroll and the reading tradition
            -- differ. qere_lemma is the dictionary form of the reading when it
            -- is a different word from the one written. qere_anchor says which
            -- of the two the flowing text carries, and qere_span how many
            -- tokens the word occupies there — MACULA splits proclitics and
            -- suffixes into their own tokens, so a two-token word cannot be
            -- shown beside one of them without repeating the other.
            qere_text TEXT,
            ketiv_text TEXT,
            qere_lemma TEXT,
            qere_anchor TEXT,
            qere_span INTEGER
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

        CREATE TABLE lexicon_senses (
            id INTEGER PRIMARY KEY,
            strongs_id TEXT NOT NULL,
            source TEXT NOT NULL,
            level INTEGER NOT NULL,
            number TEXT,
            heading TEXT,
            summary TEXT
        );

        CREATE TABLE lexicon_roots (
            strongs_id TEXT PRIMARY KEY,
            root TEXT NOT NULL,
            root_gloss TEXT,
            twot TEXT NOT NULL
        );

        CREATE INDEX idx_books_order ON books(book_order);
        CREATE INDEX idx_cross_references_from
            ON cross_references(from_book, from_chapter, from_verse);
        CREATE INDEX idx_translation_ref_map_target
            ON translation_ref_map(translation_id, target_book_id, target_chapter, target_verse);
        CREATE INDEX idx_words_verse ON words(verse_id, position);
        CREATE INDEX idx_words_lemma ON words(lemma);
        CREATE INDEX idx_words_strongs ON words(strongs);
        CREATE INDEX idx_lexicon_strongs ON lexicon(strongs_id);
        CREATE INDEX idx_lexicon_senses_strongs ON lexicon_senses(strongs_id);
        CREATE INDEX idx_lexicon_roots_twot ON lexicon_roots(twot);
        """
    )


def macula_id(raw: str) -> str:
    """MACULA node id without its one-letter prefix ('o0100…' -> '0100…').

    Hebrew ids are prefixed `o`, Greek ones `n`; only the first character is a
    prefix, so it is dropped character by character rather than with lstrip.
    """
    value = (raw or "").strip()
    if value[:1].lower() in {"o", "n"}:
        return value[1:]
    return value


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
    text = "".join(f"{text}{after or ''}" for text, after in tokens).strip()
    # Greek tokens carry trailing punctuation with no space, which glued
    # 'λόγος,καὶ' together in most NT verses. Hebrew has none of these marks.
    return re.sub(r"([,.;·])(?=\S)", r"\1 ", text)


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


_STRIP_DIACRITICS_RE = re.compile(
    r"[\u0591-\u05BD\u05BF-\u05C7\u0300-\u036F\u1F00-\u1FFF]"
)


def select_canonical_strongs(
    lemma: str,
    strong_counter: Optional[Counter],
    strongs_dicts: Optional[Dict[str, dict]] = None,
) -> Optional[str]:
    """Select the canonical root Strong's ID for a lemma.

    When multiple Strong's numbers attach to a lemma in the source text (e.g.
    inflected forms of Greek pronouns or verbs like G1473 vs G3450 for ἐγώ,
    G4771 vs G5213 for σύ, G1510 vs G2076 for εἰμί), this resolves to the head
    dictionary entry rather than whichever inflected form happens to appear most
    frequently.
    """
    if not strong_counter:
        return None
    if len(strong_counter) == 1 or not strongs_dicts:
        return strong_counter.most_common(1)[0][0]

    clean_lem = _STRIP_DIACRITICS_RE.sub("", lemma).strip().lower()

    matching_candidates = []
    for candidate, _count in strong_counter.most_common():
        for lookup in strongs_lookup_candidates(candidate):
            entry = strongs_dicts.get(lookup)
            if entry:
                dict_lemma = entry.get("lemma") or ""
                clean_dict_lem = _STRIP_DIACRITICS_RE.sub(
                    "", dict_lemma
                ).strip().lower()
                if clean_dict_lem and (
                    clean_dict_lem == clean_lem
                    or clean_dict_lem in clean_lem
                    or clean_lem in clean_dict_lem
                ):
                    matching_candidates.append(candidate)
                    break

    if matching_candidates:
        # Prefer root lemma over derived / inflected entries
        for cand in matching_candidates:
            for lookup in strongs_lookup_candidates(cand):
                entry = strongs_dicts.get(lookup)
                if entry:
                    deriv = entry.get("derivation") or ""
                    # If derivation does not cite another candidate in the list, it's the root lemma
                    is_derived = any(
                        other != cand
                        and any(
                            c in deriv
                            for c in strongs_lookup_candidates(other)
                        )
                        for other in matching_candidates
                    )
                    if not is_derived:
                        return cand
        return matching_candidates[0]

    return strong_counter.most_common(1)[0][0]


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


def strip_greek_accents(text: str) -> str:
    """Strips polytonic diacritics and accents from Greek text for lemma matching."""
    if not text:
        return ""
    return "".join(
        ch
        for ch in unicodedata.normalize("NFD", text)
        if unicodedata.category(ch) != "Mn"
    ).lower().strip()


# Marks that belong to the verse or the phrase rather than to the word:
# cantillation (te'amim), meteg, rafe, paseq, and the maqaf that MACULA keeps
# on some lemmas (מִן־). They never distinguish one lexical form from another,
# so they must go before a token can be compared with its dictionary form.
_HEBREW_NON_LEXICAL_RE = re.compile(r"[\u0591-\u05AF\u05BD\u05BF\u05C0\u05BE]")


def hebrew_lexical_form(text: str) -> str:
    """Hebrew consonants and vowel points, without verse/phrase marks."""
    if not text:
        return ""
    return _HEBREW_NON_LEXICAL_RE.sub("", text).strip()


def select_canonical_strongs(
    lemma: str,
    strong_counter: Counter,
    strongs_dicts: Optional[Dict[str, dict]] = None,
) -> Optional[str]:
    """Select the canonical Strong's id for a lemma.

    Prefers dictionary headword entries (e.g. G1473 for ἐγώ, G4771 for σύ,
    G1510 for εἰμί, G3778 for οὗτος, G1438 for ἑαυτοῦ) over high-frequency
    inflected forms (G3450, G5213, G2076). Falls back to the most common
    candidate in the token stream.
    """
    if not strong_counter:
        return None

    if strongs_dicts and len(strong_counter) > 1:
        norm_lemma = strip_greek_accents(lemma)
        for strong_id in strong_counter.keys():
            for candidate in strongs_lookup_candidates(strong_id):
                dict_entry = strongs_dicts.get(candidate)
                if dict_entry:
                    dict_lemma = dict_entry.get("lemma") or ""
                    if dict_lemma and strip_greek_accents(dict_lemma) == norm_lemma:
                        return strong_id

    return strong_counter.most_common(1)[0][0]


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
            download_file(url, dst, expect_xml=True)
            paths.append(dst)

    for filename in MACULA_GREEK_FILES:
        url = f"{MACULA_GREEK_RAW}/{greek_commit}/SBLGNT/lowfat/{filename}"
        dst = tree_dir / filename
        download_file(url, dst, expect_xml=True)
        paths.append(dst)

    return paths


@dataclass(frozen=True)
class QereKetiv:
    """One place where the written text and the read text differ."""

    book_id: str
    chapter: int
    verse: int
    ketiv: str
    ketiv_strongs: Optional[str]
    qere: str
    qere_strongs: Optional[str]


# A ketiv is a *run* of `<w type="x-ketiv">` words, and the reading that follows
# it can be several words too (`מִן ׀ הַסְּעָרָה`). Editorial `<note n="M">`
# elements can sit inside the run, so the verse is walked in document order
# rather than matched with one pattern: matching `<w …ketiv…>` followed by
# `<note type="variant">` swallows everything between the first ketiv word and
# the last one, editorial prose included.
_OSHB_ELEMENT_RE = re.compile(
    r'<w\b(?P<wattr>[^>]*?)(?:/>|>(?P<wtext>.*?)</w>)'
    r'|<note\b(?P<nattr>[^>]*)>(?P<ntext>.*?)</note>',
    re.S,
)
_OSHB_QERE_RE = re.compile(
    r'<rdg\b[^>]*\btype="x-qere"[^>]*>(?P<body>.*?)</rdg>',
    re.S,
)
_OSHB_WORD_RE = re.compile(
    r'<w\b(?P<attr>[^>]*?)(?:/>|>(?P<text>.*?)</w>)',
    re.S,
)
_XML_COMMENT_RE = re.compile(r'<!--.*?-->', re.S)
_OSHB_VERSE_RE = re.compile(r'<verse\b[^>]*\bosisID="(?P<id>[^"]+)"[^>]*>(?P<body>.*?)</verse>', re.S)
_XML_ATTR_RE = re.compile(r'([\w:-]+)="([^"]*)"')


def _xml_attrs(raw: str) -> Dict[str, str]:
    return {key: value for key, value in _XML_ATTR_RE.findall(raw or "")}


def _oshb_strongs(lemma: str) -> Optional[str]:
    """The Strong's id out of an OSHB lemma ('c/269' -> 'H269').

    OSHB writes a compound lemma as slash-separated parts, so the reading's own
    number is the last part. Only a bare number is a Strong's id; anything else
    is a form the dictionary does not key on.
    """
    parts = [part.strip() for part in (lemma or "").split("/") if part.strip()]
    if not parts:
        return None
    last = parts[-1].split()[0] if parts[-1].split() else ""
    if not last.isdigit():
        return None
    return f"H{int(last):04d}"


def parse_oshb_qere_ketiv(path: Path) -> List[QereKetiv]:
    """Every qere/ketiv pair in one OSHB WLC book file."""
    text = path.read_text(encoding="utf-8")
    pairs: List[QereKetiv] = []

    for verse_match in _OSHB_VERSE_RE.finditer(text):
        osis_id = verse_match.group("id")
        parts = osis_id.split(".")
        if len(parts) != 3:
            continue
        book_id = OSIS_TO_ABBR.get(parts[0])
        if book_id is None:
            continue
        try:
            chapter, verse = int(parts[1]), int(parts[2])
        except ValueError:
            continue

        body = verse_match.group("body")
        # The ketiv words seen since the last real word, with their lemmas.
        pending: List[Tuple[str, str]] = []

        for element in _OSHB_ELEMENT_RE.finditer(body):
            if element.group("wattr") is not None:
                attrs = _xml_attrs(element.group("wattr"))
                word = _strip_xml_markup(element.group("wtext") or "")
                if attrs.get("type") == "x-ketiv":
                    if word:
                        pending.append((word, attrs.get("lemma", "")))
                else:
                    # A word that is not ketiv ends the run.
                    pending = []
                continue

            attrs = _xml_attrs(element.group("nattr") or "")
            if attrs.get("type") != "variant":
                # An editorial note (n="M") sits inside a ketiv run and says
                # nothing about the reading.
                continue

            qere_words = _qere_words(element.group("ntext") or "")
            if not qere_words or not pending:
                pending = []
                continue

            pairs.append(
                QereKetiv(
                    book_id=book_id,
                    chapter=chapter,
                    verse=verse,
                    ketiv=" ".join(word for word, _ in pending),
                    ketiv_strongs=_strongest_lemma_strongs(pending),
                    qere=" ".join(word for word, _ in qere_words),
                    qere_strongs=_strongest_lemma_strongs(qere_words),
                )
            )
            pending = []

    return pairs


def _qere_words(note_body: str) -> List[Tuple[str, str]]:
    """The words of a variant note's qere reading, with their lemmas."""
    reading = _OSHB_QERE_RE.search(note_body)
    if reading is None:
        return []
    words: List[Tuple[str, str]] = []
    for match in _OSHB_WORD_RE.finditer(reading.group("body")):
        text = _strip_xml_markup(match.group("text") or "")
        if not text:
            continue
        words.append((text, _xml_attrs(match.group("attr")).get("lemma", "")))
    return words


def _strongest_lemma_strongs(words: List[Tuple[str, str]]) -> Optional[str]:
    """The Strong's id of the longest word in a multi-word reading.

    A reading can be two words (`מִן ׀ הַסְּעָרָה`); the id that identifies it for
    alignment and for the dictionary is the one carrying the most consonants,
    which is the word the reader would look up.
    """
    if not words:
        return None
    longest = max(words, key=lambda item: len(hebrew_consonants(item[0])))
    return _oshb_strongs(longest[1])


def _strip_xml_markup(raw: str) -> str:
    """Inline text of a word, without nested tags, entities or morpheme marks.

    OSHB separates morphemes inside a word with a slash (וְ/אַחְיוֹתֵי/הֶ֖ם);
    the slash is markup, not part of what is written. Comments are removed
    before tags: dropping `<…>` alone leaves the comment body behind, which is
    how English editorial prose reached the reader's Hebrew line.
    """
    without_comments = _XML_COMMENT_RE.sub("", raw or "")
    text = html.unescape(re.sub(r"<[^>]+>", "", without_comments)).strip()
    return " ".join(text.replace("/", "").split())


def download_oshb_wlc_files(cache_dir: Path, commit: str) -> List[Path]:
    paths: List[Path] = []
    wlc_dir = cache_dir / "oshb_wlc"
    wlc_dir.mkdir(parents=True, exist_ok=True)
    for name in OSHB_WLC_FILES:
        dst = wlc_dir / f"{name}.xml"
        download_file(f"{OSHB_RAW}/{commit}/wlc/{name}.xml", dst, expect_xml=True)
        paths.append(dst)
    return paths


# Marks that belong to the verse or the phrase rather than to the word: see
# `hebrew_lexical_form`. Qere/ketiv alignment compares consonants only, because
# the two forms are pointed differently by definition.
_HEBREW_CONSONANT_RE = re.compile(r"[\u0591-\u05C7\u05BE\u05C0/]")


def hebrew_consonants(text: str) -> str:
    """Hebrew letters only, for aligning two traditions' spellings."""
    return _HEBREW_CONSONANT_RE.sub("", text or "").strip()


def find_token_span(
    token_texts: List[str],
    target: str,
    strongs: Optional[str] = None,
    token_strongs: Optional[List[Optional[str]]] = None,
) -> Optional[Tuple[int, int]]:
    """The contiguous run of tokens whose consonants spell [target].

    MACULA and OSHB split proclitics differently (ו/אחיותי/הם against
    ואחיותיהם), so a word is matched on the concatenated consonants of the
    verse, never on token index.

    When the same consonants occur more than once in a verse, [strongs] breaks
    the tie: the reading's own Strong's id says which occurrence is this word.
    A tie that still cannot be broken is refused — attaching a reading to the
    wrong word is worse than leaving it unmarked.
    """
    target = hebrew_consonants(target)
    if not target:
        return None

    letters: List[str] = []
    owners: List[int] = []
    for index, token in enumerate(token_texts):
        for letter in hebrew_consonants(token):
            letters.append(letter)
            owners.append(index)

    haystack = "".join(letters)
    spans: List[Tuple[int, int]] = []
    start = haystack.find(target)
    while start >= 0:
        spans.append((owners[start], owners[start + len(target) - 1]))
        start = haystack.find(target, start + 1)

    if not spans:
        return None
    if len(spans) == 1:
        return spans[0]

    if strongs and token_strongs:
        def matches(span: Tuple[int, int]) -> bool:
            return any(
                (token_strongs[index] or "").startswith(strongs)
                for index in range(span[0], span[1] + 1)
            )

        narrowed = [span for span in spans if matches(span)]
        if len(narrowed) == 1:
            return narrowed[0]

    return None


def build_qere_ketiv(conn: sqlite3.Connection, pairs: List[QereKetiv]) -> int:
    """Marks the tokens that carry a qere/ketiv difference.

    The pair is attached to the one token that holds most of the word: when the
    reading spans a proclitic and a suffix, the stem is where a reader looks it
    up. Both forms are stored, so the app can show what is written beside what
    is read without guessing which of the two the flowing text carries.
    """
    print("Building qere/ketiv layer from the Open Scriptures Hebrew Bible...")

    tokens_by_verse: Dict[Tuple[str, int, int], List[Tuple[int, str, Optional[str]]]] = {}
    for book_id, chapter, verse, word_id, text, strongs in conn.execute(
        """
        SELECT v.book_id, v.chapter, v.verse_number, w.id, w.word, w.strongs
        FROM words w JOIN verses v ON v.id = w.verse_id
        WHERE w.language = 'heb'
        ORDER BY v.book_id, v.chapter, v.verse_number, w.position
        """
    ):
        tokens_by_verse.setdefault((book_id, chapter, verse), []).append(
            (word_id, text, strongs)
        )

    lemma_by_strongs = {
        strongs: lemma
        for strongs, lemma in conn.execute(
            "SELECT strongs_id, lemma FROM lexicon WHERE strongs_id IS NOT NULL"
        )
        if strongs
    }

    updates: List[Tuple[str, str, Optional[str], int]] = []
    used_word_ids: set = set()
    unresolved = 0
    for pair in pairs:
        tokens = tokens_by_verse.get((pair.book_id, pair.chapter, pair.verse))
        if not tokens:
            unresolved += 1
            continue

        texts = [text for _, text, _ in tokens]
        strongs_ids = [strongs for _, _, strongs in tokens]
        # The flowing text follows the reading in almost every case, so the
        # reading is tried first; the written form is the fallback. Which one
        # matched is a fact about this verse and is stored, not re-derived.
        anchor = "qere"
        span = find_token_span(
            texts, pair.qere, pair.qere_strongs, strongs_ids
        )
        if span is None:
            anchor = "ketiv"
            span = find_token_span(
                texts, pair.ketiv, pair.ketiv_strongs, strongs_ids
            )
        if span is None:
            unresolved += 1
            continue

        start, end = span
        core = max(
            range(start, end + 1),
            key=lambda index: len(hebrew_consonants(texts[index])),
        )
        word_id, _, token_strongs = tokens[core]
        if word_id in used_word_ids:
            # A token carries one pair. EZK 16:53 has three with the same
            # consonants; the second one to land on a token is left unmarked
            # rather than overwriting the first, which would be a silent loss.
            unresolved += 1
            continue
        used_word_ids.add(word_id)

        qere_lemma = None
        if pair.qere_strongs and pair.qere_strongs != (token_strongs or ""):
            qere_lemma = lemma_by_strongs.get(pair.qere_strongs)

        updates.append(
            (
                pair.qere,
                pair.ketiv,
                qere_lemma,
                # Which form the flowing text carries, decided here because the
                # build is the only place that knows: the reader must not infer
                # it from the token, which is often one affix of the word.
                anchor,
                end - start + 1,
                word_id,
            )
        )

    conn.executemany(
        """
        UPDATE words
        SET qere_text = ?, ketiv_text = ?, qere_lemma = ?,
            qere_anchor = ?, qere_span = ?
        WHERE id = ?
        """,
        updates,
    )

    inline = sum(1 for row in updates if row[4] == 1)
    print(
        f"  marked {len(updates):,} tokens with a qere/ketiv pair "
        f"({unresolved:,} of {len(pairs):,} pairs could not be aligned); "
        f"{inline:,} are one token in the flowing text and can be shown beside it"
    )
    return len(updates)


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


# --- Structured senses ---------------------------------------------------
#
# BDB and Abbott-Smith both mark up a numbered sense hierarchy with nested
# <sense> elements. The lexicon table keeps only the flattened entry text, so a
# reader who wants "which of these meanings is this one" gets a paragraph. These
# rows keep the structure: level, the dictionary's own sense number, a short
# heading (the entry's <def>/<gloss> words), and the sense's own prose with
# scripture references stripped (they belong in the concordance, not here).

Sense = Tuple[int, str, str, str]  # level, number, heading, summary

_SENSE_HEADING_TAGS = {"def", "gloss", "stem", "asp"}
_SENSE_OWN_TEXT_SKIP = {"ref", "sense", "status", "note", "page"}
_MAX_SENSE_SUMMARY = 400


def _clean_sense_text(value: str) -> str:
    text = _REF_WHITESPACE_RE.sub(" ", value or "").strip()
    for bad, good in ((" ,", ","), (" ;", ";"), (" .", "."), ("( ", "("), (" )", ")")):
        text = text.replace(bad, good)
    return text.strip(" ;,.")


def _sense_heading(el: ET.Element) -> str:
    parts: List[str] = []
    for child in el:
        if _local_name(child.tag) not in _SENSE_HEADING_TAGS:
            continue
        text = _clean_sense_text("".join(child.itertext()))
        if text:
            parts.append(text)
    return _clean_sense_text(", ".join(parts))


def _sense_summary(el: ET.Element) -> str:
    text = _clean_sense_text(flatten_xml_text(el, skip_tags=_SENSE_OWN_TEXT_SKIP))
    if len(text) > _MAX_SENSE_SUMMARY:
        text = text[: _MAX_SENSE_SUMMARY - 1].rstrip() + "\u2026"
    return text


def _collect_senses(el: ET.Element, level: int = 0) -> List[Sense]:
    rows: List[Sense] = []
    for child in el:
        if _local_name(child.tag) != "sense":
            continue
        heading = _sense_heading(child)
        summary = _sense_summary(child)
        if heading or summary:
            rows.append((level, (child.get("n") or "").strip(), heading, summary))
        rows.extend(_collect_senses(child, level + 1))
    return rows


def parse_bdb_senses(bdb_path: Path, index_path: Path) -> Dict[str, List[Sense]]:
    """Strong's key ('H1') -> numbered BDB sense rows.

    Only entries whose editor marked up senses produce rows; BDB left many rare
    words as a single prose line. The definition sheet falls back to the entry
    text for those, so a gap here is a shallower pane, never a blank one.
    """
    entries = {}
    for el in ET.parse(bdb_path).getroot().iter():
        if _local_name(el.tag) != "entry":
            continue
        entry_id = el.get("id")
        if entry_id:
            entries[entry_id] = el

    best: Dict[str, List[Sense]] = {}
    for el in ET.parse(index_path).getroot().iter():
        if _local_name(el.tag) != "xref":
            continue
        strong = (el.get("strong") or "").strip()
        bdb_id = (el.get("bdb") or "").strip()
        if not strong.isdigit() or bdb_id not in entries:
            continue
        rows = _collect_senses(entries[bdb_id])
        if not rows:
            continue
        key = f"H{int(strong)}"
        # Several Strong's numbers can point at one BDB entry; keep the fullest.
        if key not in best or len(rows) > len(best[key]):
            best[key] = rows
    return best


def parse_abbott_smith_senses(path: Path) -> Dict[str, List[Sense]]:
    """Strong's key ('G26') -> numbered Abbott-Smith sense rows."""
    best: Dict[str, List[Sense]] = {}
    for el in ET.parse(path).getroot().iter():
        if _local_name(el.tag) != "entry":
            continue
        n = el.get("n") or ""
        if "|" not in n:
            continue
        strong = n.split("|", 1)[1].strip().upper()
        if not strong.startswith("G") or not strong[1:].isdigit():
            continue
        rows = _collect_senses(el)
        if not rows:
            continue
        key = f"G{int(strong[1:])}"
        if key not in best or len(rows) > len(best[key]):
            best[key] = rows
    return best


_STRONGS_SUFFIX_RE = re.compile(r"^([HG])0*(\d+)([A-Z].*)?$")


def normalize_lexicon_key(strongs_id: str) -> str:
    """Key form used by BDB/TWOT: 'H0430' -> 'H430', 'H1254a' -> 'H1254a'."""
    value = (strongs_id or "").strip().upper()
    match = _STRONGS_SUFFIX_RE.match(value)
    if match is None:
        return value
    prefix, digits, suffix = match.group(1), match.group(2), match.group(3) or ""
    return f"{prefix}{int(digits)}{suffix.lower()}"


def _lexicon_key_map(conn: sqlite3.Connection) -> Dict[str, str]:
    """Normalized Strong's id -> the id the lexicon actually stores.

    The lexicon keeps the padded form the token stream used ("H0430") while BDB
    and TWOT key on plain "H430". Sense and root rows have to be written under
    the lexicon's own id or the join in `BibleDAO` finds nothing.
    """
    mapping: Dict[str, str] = {}
    for (stored,) in conn.execute(
        "SELECT strongs_id FROM lexicon WHERE strongs_id IS NOT NULL AND strongs_id != ''"
    ):
        mapping.setdefault(normalize_lexicon_key(stored), stored)
    return mapping


def build_lexicon_senses(
    conn: sqlite3.Connection,
    hebrew: Dict[str, List[Sense]],
    greek: Dict[str, List[Sense]],
    minimums: Optional[Dict[str, int]] = None,
) -> Tuple[int, int, int]:
    """Writes sense rows for lexicon entries that exist, and gates coverage.

    Returns (rows, hebrew ids, greek ids) after writing.
    """
    limits = minimums if minimums is not None else EXPECTED_COUNTS
    key_map = _lexicon_key_map(conn)

    def rows_for(data: Dict[str, List[Sense]], source: str) -> List[Tuple]:
        out: List[Tuple] = []
        for key, senses in data.items():
            stored = key_map.get(normalize_lexicon_key(key))
            if stored is None:
                continue
            for level, number, heading, summary in senses:
                out.append((stored, source, level, number, heading, summary))
        return out

    payload = rows_for(hebrew, "BDB") + rows_for(greek, "Abbott-Smith")
    conn.executemany(
        """
        INSERT INTO lexicon_senses (strongs_id, source, level, number, heading, summary)
        VALUES (?, ?, ?, ?, ?, ?)
        """,
        payload,
    )

    hebrew_ids = len(
        {key for key in hebrew if normalize_lexicon_key(key) in key_map}
    )
    greek_ids = len({key for key in greek if normalize_lexicon_key(key) in key_map})
    print(
        f"  inserted {len(payload):,} sense rows "
        f"({hebrew_ids:,} Hebrew entries, {greek_ids:,} Greek)"
    )
    # What a reader actually meets: the share of tokens in each language whose
    # word has a numbered sense list behind it. Rows are one thing, this is the
    # number that decides whether the definition sheet feels structured.
    for language in ("heb", "grc"):
        covered, total = conn.execute(
            """
            SELECT
              COALESCE(SUM(CASE WHEN s.strongs_id IS NOT NULL THEN 1 ELSE 0 END), 0),
              COUNT(*)
            FROM words w
            LEFT JOIN (SELECT DISTINCT strongs_id FROM lexicon_senses) s
              ON s.strongs_id = w.strongs
            WHERE w.language = ? AND w.strongs IS NOT NULL AND w.strongs != ''
            """,
            (language,),
        ).fetchone()
        share = (100.0 * covered / total) if total else 0.0
        print(f"  {language} token coverage with senses: {share:.1f}%")

    if len(payload) < limits["lexicon_senses_min"]:
        raise RuntimeError(
            f"Lexicon senses coverage too low ({len(payload)} rows, need "
            f"{limits['lexicon_senses_min']}); check BDB/Abbott-Smith parsing"
        )
    if hebrew_ids < limits["hebrew_sense_entries_min"]:
        raise RuntimeError(
            f"Hebrew sense coverage too low ({hebrew_ids} entries, need "
            f"{limits['hebrew_sense_entries_min']})"
        )
    if greek_ids < limits["greek_sense_entries_min"]:
        raise RuntimeError(
            f"Greek sense coverage too low ({greek_ids} entries, need "
            f"{limits['greek_sense_entries_min']})"
        )
    return len(payload), hebrew_ids, greek_ids


@dataclass(frozen=True)
class RootInfo:
    """A Hebrew root, as BDB and TWOT name it.

    [twot] is the Theological Wordbook root number: words that share it are
    built on the same root, which is what makes a search across binyanim
    possible. BDB's entry ids group words by headword instead, so the TWOT
    number is the grouping key and BDB supplies the root's own letters.
    """

    root: str
    gloss: str
    twot: str


def _bdb_head_word(el: ET.Element) -> str:
    for child in el:
        if _local_name(child.tag) != "w":
            continue
        word = _REF_WHITESPACE_RE.sub(" ", "".join(child.itertext())).strip()
        return word.strip("[]()")
    return ""


def parse_bdb_roots(bdb_path: Path, index_path: Path) -> Dict[str, RootInfo]:
    """Strong's key ('H1288') -> root ('בָּרַךְ', 'kneel', TWOT 285)."""
    entries = {}
    bucket_root: Dict[str, str] = {}
    for el in ET.parse(bdb_path).getroot().iter():
        if _local_name(el.tag) != "entry":
            continue
        entry_id = el.get("id")
        if not entry_id:
            continue
        entries[entry_id] = el
        if el.get("type") == "root":
            bucket_root[".".join(entry_id.split(".")[:2])] = entry_id

    strong_to_twot: Dict[str, str] = {}
    strong_to_bdb: Dict[str, str] = {}
    for el in ET.parse(index_path).getroot().iter():
        if _local_name(el.tag) != "xref":
            continue
        strong = (el.get("strong") or "").strip()
        if not strong.isdigit():
            continue
        key = f"H{int(strong)}"
        twot = (el.get("twot") or "").strip()
        bdb_id = (el.get("bdb") or "").strip()
        if twot:
            strong_to_twot.setdefault(key, twot)
        if bdb_id:
            strong_to_bdb.setdefault(key, bdb_id)

    troot_for_strong: Dict[str, str] = {}
    for key, twot in strong_to_twot.items():
        match = re.match(r"^(\d+)", twot)
        if match:
            troot_for_strong[key] = match.group(1)

    members: Dict[str, List[str]] = defaultdict(list)
    for key, troot in troot_for_strong.items():
        members[troot].append(key)

    result: Dict[str, RootInfo] = {}
    for troot, keys in members.items():
        root_word = ""
        root_gloss = ""
        best_score = None
        for key in keys:
            bdb_id = strong_to_bdb.get(key)
            if not bdb_id:
                continue
            bucket = ".".join(bdb_id.split(".")[:2])
            root_id = bucket_root.get(bucket)
            if not root_id:
                continue
            word = _bdb_head_word(entries[root_id])
            if not word:
                continue
            # Prefer the bucket whose root entry is the one we are standing in,
            # then the shortest TWOT suffix (the root itself, not a derivative).
            score = (0 if bdb_id.startswith(bucket + ".") else 1, len(strong_to_twot.get(key, "")))
            if best_score is None or score < best_score:
                best_score = score
                root_word = word
                root_gloss = ""
                for child in entries[root_id]:
                    if _local_name(child.tag) == "def":
                        root_gloss = _clean_sense_text("".join(child.itertext()))
                        break
        if not root_word:
            continue
        for key in keys:
            result[key] = RootInfo(root=root_word, gloss=root_gloss, twot=troot)
    return result


def build_lexicon_roots(
    conn: sqlite3.Connection,
    roots: Dict[str, RootInfo],
    minimums: Optional[Dict[str, int]] = None,
) -> int:
    limits = minimums if minimums is not None else EXPECTED_COUNTS
    key_map = _lexicon_key_map(conn)
    payload = [
        (key_map[normalize_lexicon_key(key)], info.root, info.gloss, info.twot)
        for key, info in roots.items()
        if normalize_lexicon_key(key) in key_map
    ]
    conn.executemany(
        """
        INSERT OR REPLACE INTO lexicon_roots (strongs_id, root, root_gloss, twot)
        VALUES (?, ?, ?, ?)
        """,
        payload,
    )
    print(f"  inserted {len(payload):,} Hebrew roots ({len({p[3] for p in payload}):,} distinct)")
    if len(payload) < limits["lexicon_roots_min"]:
        raise RuntimeError(
            f"Lexicon root coverage too low ({len(payload)} entries, need "
            f"{limits['lexicon_roots_min']}); check TWOT/BDB parsing"
        )
    return len(payload)


def load_lexicon_senses(
    cache_dir: Path,
    hebrew_lexicon_commit: str,
    abbott_smith_commit: str,
) -> Tuple[Dict[str, List[Sense]], Dict[str, List[Sense]]]:
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
    hebrew = parse_bdb_senses(bdb_path, index_path)
    greek = parse_abbott_smith_senses(as_path)
    print(
        f"Loaded structured senses: {len(hebrew):,} Hebrew entries "
        f"({sum(len(v) for v in hebrew.values()):,} rows), "
        f"{len(greek):,} Greek ({sum(len(v) for v in greek.values()):,} rows)"
    )
    return hebrew, greek


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
            # Id stays "KJV" so saved reader settings keep working; the text
            # is the Berean Standard Bible and must be labelled as such.
            "KJV",
            "Berean Standard Bible",
            "en",
            "ltr",
            "BSB",
            "ot_BSB.tsv,nt_BSB.tsv",
            "Public domain (BSB, dedicated 2023); via themikejr/bible-mcp token data",
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
    # Transliteration of the token whose text *is* the lemma: the dictionary
    # form, as opposed to the most frequent inflected surface form.
    lex_lemma_form: Dict[str, Counter] = defaultdict(Counter)

    next_word_id = 1

    # MACULA points at other tokens by xml:id. The ids are collected as the
    # files stream past and resolved after both are read, because a subject can
    # sit in an earlier verse.
    surface_by_id: Dict[str, Tuple[str, str]] = {}
    pending_refs: List[Tuple[int, str, str]] = []  # (word id, ref, kind)

    def flush_group(
        key: Optional[Tuple[str, int, int]],
        verse_tokens: List[Tuple[str, str]],
        word_rows: List[Tuple[str, str, str, str, str, str, str, str]],
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
        for (
            word_text,
            lemma,
            morph,
            strong,
            language,
            _pos,
            subject_ref,
            referent_ref,
        ) in word_rows:
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
            if subject_ref:
                pending_refs.append((next_word_id, subject_ref, "subject"))
            if referent_ref:
                pending_refs.append((next_word_id, referent_ref, "referent"))
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
        current_words: List[Tuple[str, str, str, str, str, str, str, str]] = []

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

            token_id = (row.get("xml:id") or "").strip()
            subject_ref = macula_id(row.get("subjref") or "")
            referent_ref = macula_id(row.get("referent") or "")

            if text:
                current_verse_tokens.append((text, after))
                current_words.append(
                    (
                        text,
                        lemma,
                        morph,
                        strong,
                        language,
                        pos,
                        subject_ref,
                        referent_ref,
                    )
                )
                if token_id:
                    surface_by_id[macula_id(token_id)] = (text, strong)

            if lemma:
                if gloss:
                    lex_glosses[lemma][gloss] += 1
                else:
                    if lemma not in lex_glosses:
                        lex_glosses[lemma] = Counter()
                if pos:
                    lex_pos[lemma][pos] += 1
                if strong:
                    lex_strong[lemma][strong] += 1
                lex_language[lemma][language] += 1
                if transliteration:
                    lex_transliteration[lemma][transliteration] += 1
                    if hebrew_lexical_form(text) == hebrew_lexical_form(lemma):
                        lex_lemma_form[lemma][transliteration] += 1
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

    print("Resolving MACULA participant references...")
    subject_updates: List[Tuple[str, Optional[str], int]] = []
    referent_updates: List[Tuple[str, Optional[str], int]] = []
    for word_id, ref, kind in pending_refs:
        surface = surface_by_id.get(ref)
        if surface is None:
            continue
        text, strong = surface
        entry = (text, strong or None, word_id)
        if kind == "subject":
            subject_updates.append(entry)
        else:
            referent_updates.append(entry)

    conn.executemany(
        """
        UPDATE words SET subject_text = ?, subject_strongs = ?
        WHERE id = ?
        """,
        subject_updates,
    )
    conn.executemany(
        """
        UPDATE words SET referent_text = ?, referent_strongs = ?
        WHERE id = ?
        """,
        referent_updates,
    )
    print(
        f"  resolved {len(subject_updates):,} subject and "
        f"{len(referent_updates):,} referent links"
    )

    print("Building lexicon table...")
    lex_rows = []
    enriched_count = 0
    strongs_entry_count = 0
    extended_count = 0
    for lemma, gloss_counter in lex_glosses.items():
        pos_counter = lex_pos.get(lemma, Counter())
        pos_label = pos_counter.most_common(1)[0][0] if pos_counter else None

        strong_counter = lex_strong.get(lemma, Counter())
        strong_label = select_canonical_strongs(
            lemma, strong_counter, strongs_dicts
        )

        lang_counter = lex_language.get(lemma, Counter())
        language = lang_counter.most_common(1)[0][0] if lang_counter else None

        translit_counter = lex_transliteration.get(lemma, Counter())
        lemma_form_counter = lex_lemma_form.get(lemma, Counter())
        # The most frequent surface transliteration is the most frequent
        # *inflected* form, not the dictionary form: אָמַר was showing
        # "yyōʾmer" (imperfect) instead of "ʾāmar". Prefer tokens whose text is
        # the lemma itself, and keep the old majority vote as the fallback.
        if lemma_form_counter:
            transliteration = lemma_form_counter.most_common(1)[0][0]
        else:
            transliteration = (
                translit_counter.most_common(1)[0][0] if translit_counter else None
            )

        pronunciation_counter = lex_pronunciation.get(lemma, Counter())
        if lemma_form_counter:
            pronunciation = lemma_form_counter.most_common(1)[0][0]
        elif pronunciation_counter:
            pronunciation = pronunciation_counter.most_common(1)[0][0]
        else:
            pronunciation = transliteration

        if gloss_counter:
            gloss = gloss_counter.most_common(1)[0][0]
        else:
            # Fall back to Strong's dictionary definition/kjv_def, or lemma
            dict_entry = None
            if strongs_dicts and strong_label:
                for candidate in strongs_lookup_candidates(strong_label):
                    dict_entry = strongs_dicts.get(candidate)
                    if dict_entry:
                        break
            if dict_entry:
                raw_gloss = (
                    dict_entry.get("kjv_def")
                    or dict_entry.get("strongs_def")
                    or lemma
                )
                gloss = raw_gloss.split(",")[0].split(";")[0].strip() or lemma
            else:
                gloss = lemma

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

    print("Normalizing words table Strong's keys to lexicon entries...")
    conn.execute(
        """
        UPDATE words
        SET strongs = (SELECT lx.strongs_id FROM lexicon lx WHERE lx.lemma = words.lemma)
        WHERE lemma IS NOT NULL
          AND lemma != ''
          AND EXISTS (
              SELECT 1 FROM lexicon lx
              WHERE lx.lemma = words.lemma
                AND lx.strongs_id IS NOT NULL
                AND lx.strongs_id != ''
          )
        """
    )

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
        "lexicon_senses",
        "lexicon_roots",
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

    table_counts["participant_links"] = conn.execute(
        "SELECT COUNT(*) FROM words WHERE subject_text IS NOT NULL "
        "OR referent_text IS NOT NULL"
    ).fetchone()[0]

    table_counts["qere_ketiv"] = conn.execute(
        "SELECT COUNT(*) FROM words WHERE qere_text IS NOT NULL"
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

    if counts["lexicon_senses"] < EXPECTED_COUNTS["lexicon_senses_min"]:
        raise RuntimeError(
            "Expected at least "
            f"{EXPECTED_COUNTS['lexicon_senses_min']} structured sense rows, found "
            f"{counts['lexicon_senses']}"
        )

    if counts["lexicon_roots"] < EXPECTED_COUNTS["lexicon_roots_min"]:
        raise RuntimeError(
            "Expected at least "
            f"{EXPECTED_COUNTS['lexicon_roots_min']} Hebrew roots, found "
            f"{counts['lexicon_roots']}"
        )

    if counts["participant_links"] < EXPECTED_COUNTS["participant_links_min"]:
        raise RuntimeError(
            "Expected at least "
            f"{EXPECTED_COUNTS['participant_links_min']} participant links, found "
            f"{counts['participant_links']}"
        )

    if counts["qere_ketiv"] < EXPECTED_COUNTS["qere_ketiv_min"]:
        raise RuntimeError(
            "Expected at least "
            f"{EXPECTED_COUNTS['qere_ketiv_min']} qere/ketiv tokens, found "
            f"{counts['qere_ketiv']}"
        )

    dirty_qere = conn.execute(
        """
        SELECT COUNT(*) FROM words
        WHERE qere_text IS NOT NULL
          AND (qere_text GLOB '*[A-Za-z]*' OR ketiv_text GLOB '*[A-Za-z]*'
               OR qere_text LIKE '%' || char(10) || '%'
               OR ketiv_text LIKE '%' || char(10) || '%')
        """
    ).fetchone()[0]
    if dirty_qere:
        raise RuntimeError(
            f"{dirty_qere} qere/ketiv rows carry markup or editorial prose; "
            "the parser is leaking note text into scripture"
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
        "lexicon_senses",
        "lexicon_roots",
        "participant_links",
        "qere_ketiv",
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
    try:
        conn.commit()
        conn.isolation_level = None
        conn.execute("PRAGMA wal_checkpoint(TRUNCATE);")
        conn.execute("PRAGMA journal_mode=DELETE;")
        # Drops free pages left by the rebuild; this file ships inside every install.
        conn.execute("VACUUM;")
    except Exception as e:
        print(f"Note during sqlite finalize: {e}")

    for suffix in ("-wal", "-shm"):
        sidecar = Path(f"{output_path}{suffix}")
        if sidecar.exists():
            try:
                sidecar.unlink()
            except Exception:
                pass


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

        # Structured senses and Hebrew roots come from the same two lexicons and
        # are what turn a definition paragraph into a numbered meaning list and
        # a root search. Skipped with --no-extended-lexicon, same as the text.
        hebrew_senses: Dict[str, List[Sense]] = {}
        greek_senses: Dict[str, List[Sense]] = {}
        roots: Dict[str, RootInfo] = {}
        if args.extended_lexicon:
            hebrew_senses, greek_senses = load_lexicon_senses(
                cache_dir,
                hebrew_lexicon_commit=args.hebrew_lexicon_commit,
                abbott_smith_commit=args.abbott_smith_commit,
            )
            roots = parse_bdb_roots(
                cache_dir / "BrownDriverBriggs.xml",
                cache_dir / "LexicalIndex.xml",
            )
            print(f"Loaded Hebrew roots: {len(roots):,} Strong's ids")

        cross_references_txt: Optional[Path] = None
        if args.cross_references:
            cross_references_txt = download_cross_references(cache_dir)

        qere_ketiv_pairs: List[QereKetiv] = []
        if args.qere_ketiv:
            qere_paths = download_oshb_wlc_files(cache_dir, args.oshb_commit)
            for path in qere_paths:
                qere_ketiv_pairs.extend(parse_oshb_qere_ketiv(path))
            print(f"Parsed {len(qere_ketiv_pairs):,} qere/ketiv pairs from OSHB")

        macula_paths: List[Path] = []
        if args.syntax_trees:
            macula_paths = download_macula_files(
                cache_dir,
                greek_commit=args.macula_greek_commit,
                hebrew_commit=args.macula_hebrew_commit,
            )

        for p in (output_path, Path(f"{output_path}-wal"), Path(f"{output_path}-shm")):
            if p.exists():
                print(f"Removing existing file: {p}")
                p.unlink()

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
            if args.extended_lexicon:
                build_lexicon_senses(conn, hebrew_senses, greek_senses)
                build_lexicon_roots(conn, roots)
            if qere_ketiv_pairs:
                build_qere_ketiv(conn, qere_ketiv_pairs)
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
            translation_coverage = build_open_bible_translation_verses(
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
                    "coverage": translation_coverage,
                }
                report_path.write_text(
                    json.dumps(report_payload, ensure_ascii=False, indent=2),
                    encoding="utf-8",
                )
                print(f"Coverage report written: {report_path}")

            # Translated glosses live in data/gloss_translations; folding them in
            # here means no release path can forget the separate apply step.
            if write_gloss_translations(conn) == 0:
                raise RuntimeError("No translated glosses found in data/gloss_translations")

            # Long-form content (definition + extended_definition) lives in
            # data/lexicon_translations. Unlike the glosses this is allowed to be
            # partial: it is delivered in batches over time, and every row
            # without a translation falls back to its labelled English original.
            lexicon_i18n_values = write_lexicon_translations(conn)
            if lexicon_i18n_values == 0:
                print(
                    "NOTE: no translated long-form lexicon content found in "
                    "data/lexicon_translations — the app will show the labelled "
                    "English original for definitions. See "
                    "scripts/translate_lexicon_definitions.py --estimate."
                )
            else:
                i18n_report = coverage_report(conn)
                for i18n_lang, i18n_stats in sorted(i18n_report["languages"].items()):
                    print(
                        f"  lexicon i18n {i18n_lang}: definition "
                        f"{i18n_stats['definition']['have']}/{i18n_stats['definition']['total']}, "
                        f"extended {i18n_stats['extended_definition']['have']}/"
                        f"{i18n_stats['extended_definition']['total']}"
                    )
            conn.commit()

            finalize_sqlite_files(conn, output_path)
        finally:
            conn.close()

        print(f"\nDone. Wrote {output_path}")
    except Exception:
        for p in (output_path, Path(f"{output_path}-wal"), Path(f"{output_path}-shm")):
            if p.exists():
                print(f"Removing incomplete file after failure: {p}")
                try:
                    p.unlink()
                except Exception:
                    pass
        raise
    finally:
        if cleanup_tmp:
            shutil.rmtree(cache_dir, ignore_errors=True)


if __name__ == "__main__":
    main()

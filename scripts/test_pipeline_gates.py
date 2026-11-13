#!/usr/bin/env python3
"""Unit tests for versification mapping and the release coverage gates.

Every depth feature reads this layer: a translation mapped onto the wrong verse
is worse than a missing one, because it looks right. And the gates are what stop
a broken source from shipping silently — a gate nobody tests is a gate that can
be loosened by accident.

Run with: python3 scripts/test_pipeline_gates.py
"""

import importlib.util
import sqlite3
import sys
import unittest
from pathlib import Path

_SCRIPT_PATH = Path(__file__).resolve().parent / "build_full_bible_db.py"
_spec = importlib.util.spec_from_file_location("build_full_bible_db", _SCRIPT_PATH)
build_db = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = build_db
_spec.loader.exec_module(build_db)


class TranslationMappingTest(unittest.TestCase):
    """`build_translation_mapping`: source refs in, canonical targets out."""

    def setUp(self):
        self.canonical = [
            ("PSA", 3, 1),
            ("PSA", 3, 2),
            ("JOL", 3, 1),
            ("JOL", 3, 2),
            ("JOL", 4, 1),
        ]

    def test_exact_refs_match_themselves(self):
        source = {("PSA", 3, 1): "text", ("JOL", 3, 1): "text"}
        mappings, missing, unmapped = build_db.build_translation_mapping(
            source_verses=source,
            canonical_refs=self.canonical,
            overrides={},
        )

        kinds = {(s, t, kind) for s, t, kind in mappings}
        self.assertIn((("PSA", 3, 1), ("PSA", 3, 1), "exact"), kinds)
        self.assertEqual(unmapped, [])

    def test_manual_override_wins_over_offset_guessing(self):
        # A psalm title verse in the source that the canonical text numbers
        # differently: the override must be used, not the nearest guess.
        source = {("PSA", 3, 9): "title", ("PSA", 3, 1): "first"}
        mappings, _, _ = build_db.build_translation_mapping(
            source_verses=source,
            canonical_refs=self.canonical,
            overrides={("PSA", 3, 9): ("PSA", 3, 2)},
        )

        by_source = {source_ref: target for source_ref, target, _ in mappings}
        self.assertEqual(by_source[("PSA", 3, 9)], ("PSA", 3, 2))

    def test_joel_chapter_four_maps_without_losing_a_verse(self):
        # WLC (the Hebrew text) has four chapters in Joel; most translations
        # have three. A source verse that does not exist canonically must land
        # somewhere in the same book rather than being dropped.
        source = {("JOL", 2, 28): "a verse the canonical text numbers in ch. 3"}
        mappings, _, _ = build_db.build_translation_mapping(
            source_verses=source,
            canonical_refs=self.canonical,
            overrides={},
        )

        self.assertEqual(len(mappings), 1)
        self.assertEqual(mappings[0][0], ("JOL", 2, 28))
        self.assertEqual(mappings[0][2], "offset")
        self.assertEqual(mappings[0][1][0], "JOL")

    def test_unmapped_source_verses_are_reported_not_silently_dropped(self):
        source = {("RUT", 1, 1): "not in this canon"}
        mappings, missing, unmapped = build_db.build_translation_mapping(
            source_verses=source,
            canonical_refs=self.canonical,
            overrides={},
        )

        self.assertEqual(mappings, [])
        self.assertEqual(unmapped, [("RUT", 1, 1)])
        self.assertEqual(len(missing), len(self.canonical))

    def test_every_canonical_target_is_used_at_most_once(self):
        source = {
            ("PSA", 3, 1): "a",
            ("PSA", 3, 1): "a",  # same key, dict semantics
            ("PSA", 3, 5): "b",
            ("PSA", 3, 6): "c",
        }
        mappings, _, _ = build_db.build_translation_mapping(
            source_verses=source,
            canonical_refs=self.canonical,
            overrides={},
        )

        targets = [target for _, target, _ in mappings]
        self.assertEqual(len(targets), len(set(targets)))


class OverridesFileTest(unittest.TestCase):
    def test_the_shipped_overrides_file_parses(self):
        path = Path(__file__).resolve().parent / "versification_overrides.json"
        overrides = build_db.load_overrides(path)
        self.assertIsInstance(overrides, dict)
        # Every key must be a translation id the catalog knows about.
        catalog = build_db.load_translation_catalog(
            Path(__file__).resolve().parent / "translation_catalog.json"
        )
        for translation_id in overrides:
            self.assertIn(translation_id, catalog)

    def test_missing_file_means_no_overrides(self):
        self.assertEqual(build_db.load_overrides(Path("/nonexistent.json")), {})


class CoverageGateTest(unittest.TestCase):
    """`validate_database` fails loudly rather than shipping thin data."""

    def setUp(self):
        self.conn = sqlite3.connect(":memory:")
        self.conn.executescript(
            """
            CREATE TABLE books (id INTEGER, abbreviation TEXT, name TEXT,
                                name_en TEXT, testament TEXT, book_order INTEGER,
                                chapter_count INTEGER);
            CREATE TABLE translations (id TEXT, name TEXT, language TEXT,
                                       direction TEXT, abbreviation TEXT,
                                       source_file TEXT, license TEXT,
                                       enabled INTEGER, coverage_percent REAL);
            CREATE TABLE verses (id INTEGER PRIMARY KEY, book_id TEXT,
                                 chapter INTEGER, verse_number INTEGER, text TEXT);
            CREATE TABLE translation_verses (id INTEGER PRIMARY KEY,
                                             translation_id TEXT, book_id TEXT,
                                             chapter INTEGER, verse_number INTEGER,
                                             text TEXT);
            CREATE TABLE translation_ref_map (translation_id TEXT,
                                              source_book_id TEXT,
                                              source_chapter INTEGER,
                                              source_verse INTEGER,
                                              target_book_id TEXT,
                                              target_chapter INTEGER,
                                              target_verse INTEGER,
                                              match_type TEXT);
            CREATE TABLE words (id INTEGER PRIMARY KEY, verse_id INTEGER,
                                position INTEGER, word TEXT, lemma TEXT,
                                morph TEXT, strongs TEXT, language TEXT,
                                subject_text TEXT, subject_strongs TEXT,
                                referent_text TEXT, referent_strongs TEXT);
            CREATE TABLE lexicon (lemma TEXT PRIMARY KEY, strongs_id TEXT,
                                  gloss TEXT);
            CREATE TABLE lexicon_senses (id INTEGER PRIMARY KEY,
                                         strongs_id TEXT, source TEXT,
                                         level INTEGER, number TEXT,
                                         heading TEXT, summary TEXT);
            CREATE TABLE lexicon_roots (strongs_id TEXT PRIMARY KEY, root TEXT,
                                        root_gloss TEXT, twot TEXT);
            """
        )
        self.addCleanup(self.conn.close)
        self._fill(lexicon_senses=16000, lexicon_roots=4800)

    def _fill(self, *, lexicon_senses: int, lexicon_roots: int) -> None:
        books = build_db.BOOKS
        self.conn.executemany(
            "INSERT INTO books VALUES (?, ?, ?, ?, ?, ?, ?)",
            [
                (b.order, b.abbr, b.name, b.name, b.testament, b.order, b.chapter_count)
                for b in books
            ],
        )
        # One verse per book is enough for the shape checks; the count gates are
        # satisfied by the numbers below.
        self.conn.executemany(
            "INSERT INTO verses (book_id, chapter, verse_number, text) VALUES (?, 1, 1, 'x')",
            [(b.abbr,) for b in books],
        )
        for i in range(31100):
            self.conn.execute(
                "INSERT INTO verses (book_id, chapter, verse_number, text) "
                "VALUES ('GEN', ?, ?, 'x')",
                (2 + i // 1000, 1 + i % 1000),
            )
        self.conn.executemany(
            "INSERT INTO translation_verses (translation_id, book_id, chapter, "
            "verse_number, text) VALUES ('KJV', 'GEN', 1, ?, 'x')",
            [(i,) for i in range(1, 31101)],
        )
        self.conn.executemany(
            "INSERT INTO words (verse_id, position, word, language) "
            "VALUES (1, ?, 'w', 'heb')",
            [(i,) for i in range(600001)],
        )
        # Every tenth token carries a participant link, as MACULA's do.
        self.conn.execute(
            "UPDATE words SET subject_text = 'x', subject_strongs = 'H1' "
            "WHERE id % 10 = 0"
        )
        self.conn.executemany(
            "INSERT INTO lexicon (lemma, strongs_id, gloss) VALUES (?, ?, 'g')",
            [(f"l{i}", f"H{i}") for i in range(13001)],
        )
        self.conn.executemany(
            "INSERT INTO lexicon_senses (strongs_id, source, level, heading) "
            "VALUES (?, 'BDB', 0, 'h')",
            [(f"H{i}",) for i in range(lexicon_senses)],
        )
        self.conn.executemany(
            "INSERT INTO lexicon_roots (strongs_id, root, twot) VALUES (?, 'r', '1')",
            [(f"H{i}",) for i in range(lexicon_roots)],
        )
        self.conn.commit()

    def test_the_full_expected_shape_passes(self):
        build_db.validate_database(self.conn)

    def test_missing_vocabulary_aborts_the_build(self):
        self.conn.execute("DELETE FROM lexicon_senses WHERE rowid > 100")
        self.conn.commit()
        with self.assertRaises(RuntimeError) as ctx:
            build_db.validate_database(self.conn)
        self.assertIn("sense rows", str(ctx.exception))

    def test_missing_roots_abort_the_build(self):
        self.conn.execute("DELETE FROM lexicon_roots WHERE rowid > 100")
        self.conn.commit()
        with self.assertRaises(RuntimeError) as ctx:
            build_db.validate_database(self.conn)
        self.assertIn("Hebrew roots", str(ctx.exception))

    def test_a_thin_lexicon_aborts_the_build(self):
        self.conn.execute("DELETE FROM lexicon WHERE rowid > 100")
        self.conn.commit()
        with self.assertRaises(RuntimeError) as ctx:
            build_db.validate_database(self.conn)
        self.assertIn("lexicon entries", str(ctx.exception))


if __name__ == "__main__":
    unittest.main(verbosity=2)

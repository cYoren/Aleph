#!/usr/bin/env python3
"""Tests for the release-database compaction step.

Run directly:

    python3 scripts/test_prepare_bible_db.py

Covers the properties the shrink work depends on:

* every verse's syntax-tree JSON round-trips byte-for-byte,
* the stored record layout is pinned (`chapter:verse<TAB>json`, NUL separated),
  so the Dart decoder in `lib/data/database/daos/bible_dao.dart` can rely on it,
* the dead `idx_translation_ref_map_target` index is gone,
* compaction is idempotent (a second run changes nothing),
* `--check` accepts a correctly prepared pair and rejects a stale pack.
"""

from __future__ import annotations

import gzip
import pathlib
import sqlite3
import sys
import tempfile
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

import prepare_bible_db as prep  # noqa: E402

LEGACY_SCHEMA = """
    CREATE TABLE syntax_trees (
        book_id TEXT NOT NULL,
        chapter INTEGER NOT NULL,
        verse INTEGER NOT NULL,
        trees TEXT NOT NULL,
        PRIMARY KEY (book_id, chapter, verse)
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
    CREATE INDEX idx_translation_ref_map_target
        ON translation_ref_map(translation_id, target_book_id, target_chapter, target_verse);
"""


def _block(db: sqlite3.Connection, book_id: str) -> bytes:
    blob = db.execute(
        "SELECT blob FROM syntax_trees WHERE book_id = ?", (book_id,)
    ).fetchone()[0]
    return gzip.decompress(blob)


def _decode(block: bytes) -> dict[str, str]:
    """Independent decoder mirroring the Dart reader."""
    out: dict[str, str] = {}
    for record in block.split(b"\x00"):
        key, _, value = record.partition(b"\t")
        out[key.decode("utf-8")] = value.decode("utf-8")
    return out


class PrepareBibleDbTest(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.db_path = pathlib.Path(self._tmp.name) / "bible.db"
        db = sqlite3.connect(self.db_path)
        db.executescript(LEGACY_SCHEMA)
        self.rows = [
            ("GEN", 1, 1, '[{"c":"cl"}]'),
            ("GEN", 1, 2, '[{"c":"cl","u":"PP-V-S-O"}]'),
            ("GEN", 2, 1, '[{"t":"בָּרָ֣א"}]'),
            ("EXO", 1, 1, '[{"c":"np"}]'),
        ]
        db.executemany("INSERT INTO syntax_trees VALUES (?, ?, ?, ?)", self.rows)
        db.commit()
        db.close()

    def test_every_verse_round_trips(self) -> None:
        prep.compact(self.db_path)
        db = sqlite3.connect(self.db_path)
        try:
            expected = {(b, c, v): t for b, c, v, t in self.rows}
            got: dict[tuple[str, int, int], str] = {}
            for book_id, _, _ in db.execute("SELECT book_id, verses, blob FROM syntax_trees"):
                for key, value in _decode(_block(db, book_id)).items():
                    chapter, verse = key.split(":")
                    got[(book_id, int(chapter), int(verse))] = value
            self.assertEqual(got, expected)
        finally:
            db.close()

    def test_record_layout_is_pinned(self) -> None:
        prep.compact(self.db_path)
        db = sqlite3.connect(self.db_path)
        try:
            # One record per verse: `chapter:verse<TAB>json`, NUL separated, in
            # (chapter, verse) order. The Dart reader depends on exactly this.
            expected = b"\x00".join(
                f"{chapter}:{verse}".encode("utf-8") + b"\t" + trees.encode("utf-8")
                for book, chapter, verse, trees in self.rows
                if book == "GEN"
            )
            self.assertEqual(_block(db, "GEN"), expected)
            self.assertEqual(_block(db, "EXO"), b'1:1\t[{"c":"np"}]')
        finally:
            db.close()

    def test_verse_counts_are_stored(self) -> None:
        prep.compact(self.db_path)
        db = sqlite3.connect(self.db_path)
        try:
            counts = dict(db.execute("SELECT book_id, verses FROM syntax_trees"))
            self.assertEqual(counts, {"GEN": 3, "EXO": 1})
        finally:
            db.close()

    def test_dead_index_is_dropped(self) -> None:
        prep.compact(self.db_path)
        db = sqlite3.connect(self.db_path)
        try:
            remaining = db.execute(
                "SELECT COUNT(*) FROM sqlite_master "
                "WHERE type = 'index' AND name = 'idx_translation_ref_map_target'"
            ).fetchone()[0]
            self.assertEqual(remaining, 0)
        finally:
            db.close()

    def test_compaction_is_idempotent(self) -> None:
        self.assertTrue(prep.compact(self.db_path))
        digest_before = _block(sqlite3.connect(self.db_path), "GEN")
        self.assertFalse(prep.compact(self.db_path))
        digest_after = _block(sqlite3.connect(self.db_path), "GEN")
        self.assertEqual(digest_before, digest_after)

    def test_values_with_whitespace_survive_the_first_tab_split(self) -> None:
        # Parser robustness only: real MACULA JSON is minified, but a value
        # containing a tab or newline must still round-trip, because the reader
        # splits on the *first* tab and NUL can never appear in JSON.
        awkward = '[{"t":"a\tb\nc"}]'
        db = sqlite3.connect(self.db_path)
        db.execute(
            "INSERT INTO syntax_trees VALUES (?, ?, ?, ?)", ("EXO", 1, 2, awkward)
        )
        db.commit()
        db.close()
        prep.compact(self.db_path)
        db = sqlite3.connect(self.db_path)
        try:
            self.assertEqual(_decode(_block(db, "EXO"))["1:2"], awkward)
        finally:
            db.close()

    def test_check_accepts_prepared_pair_and_rejects_stale_pack(self) -> None:
        gz_path = self.db_path.with_name(self.db_path.name + ".gz")
        prep.compact(self.db_path)
        prep.pack(self.db_path, gz_path)
        self.assertEqual(prep.check(self.db_path, gz_path), [])

        # A pack that predates the database is a packaging bug the app would
        # ship silently, so it must fail loudly.
        gz_path.write_bytes(gzip.compress(b"not the database", mtime=0))
        problems = prep.check(self.db_path, gz_path)
        self.assertTrue(any("does not decode" in problem for problem in problems))

    def test_check_reports_an_uncompacted_database(self) -> None:
        gz_path = self.db_path.with_name(self.db_path.name + ".gz")
        prep.pack(self.db_path, gz_path)
        problems = prep.check(self.db_path, gz_path)
        self.assertTrue(any("not compacted" in problem for problem in problems))


class SyntaxCoverageTest(unittest.TestCase):
    def setUp(self):
        self.db = sqlite3.connect(':memory:')
        self.addCleanup(self.db.close)
        self.db.executescript('CREATE TABLE verses(book_id TEXT, chapter INTEGER, verse_number INTEGER); CREATE TABLE syntax_trees(book_id TEXT, verses INTEGER, blob BLOB);')
        self.db.execute("INSERT INTO verses VALUES ('GEN',1,1)")
        self.write('1:1\t[{"c":"cl"}]', 1)

    def write(self, text, count):
        self.db.execute('DELETE FROM syntax_trees')
        self.db.execute("INSERT INTO syntax_trees VALUES ('GEN',?,?)", (count, gzip.compress(text.encode())))

    def test_exact_coverage_passes(self):
        self.assertEqual(prep.check_syntax_blocks(self.db), [])

    def test_missing_canonical_verse_fails(self):
        self.db.execute("INSERT INTO verses VALUES ('GEN',1,2)")
        self.assertTrue(any('1 missing' in p for p in prep.check_syntax_blocks(self.db)))

    def test_declared_counts_cannot_hide_missing_records(self):
        self.write('1:1\t[{"c":"cl"}]', 31152)
        self.assertTrue(any('declared' in p for p in prep.check_syntax_blocks(self.db)))

    def test_duplicate_records_fail(self):
        self.write('1:1\t[{"c":"cl"}]\x001:1\t[{"c":"cl"}]', 2)
        self.assertTrue(any('duplicate' in p for p in prep.check_syntax_blocks(self.db)))

    def test_empty_or_invalid_tree_documents_fail(self):
        for document in ['[]', '{}', 'invalid json']:
            self.write('1:1\t' + document, 1)
            self.assertTrue(prep.check_syntax_blocks(self.db))

    def test_corrupt_compressed_data_fails(self):
        self.db.execute("UPDATE syntax_trees SET blob = X'000102'")
        self.assertTrue(prep.check_syntax_blocks(self.db))


if __name__ == "__main__":
    unittest.main(verbosity=2)

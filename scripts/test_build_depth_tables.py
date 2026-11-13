#!/usr/bin/env python3
"""Unit tests for the structured senses and Hebrew roots in the DB pipeline.

Both layers decide what the definition sheet shows, so a parsing regression is a
content regression: it must fail here rather than in the reader's hands.

Run with: python3 scripts/test_build_depth_tables.py
"""

import importlib.util
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path

_SCRIPT_PATH = Path(__file__).resolve().parent / "build_full_bible_db.py"
_spec = importlib.util.spec_from_file_location("build_full_bible_db", _SCRIPT_PATH)
build_db = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = build_db
_spec.loader.exec_module(build_db)

NS = 'xmlns="http://openscriptures.github.com/morphhb/namespace"'
BDB_XML = f"""<?xml version="1.0" encoding="UTF-8"?>
<lexicon {NS}>
  <entry id="b.dd.aa" type="root"><w>בָּרַךְ</w> <pos>vb</pos>. <def>kneel</def>
    <sense><stem>Qal</stem>
      <sense n="1"><def>kneel down</def> <ref r="Gen.24.11">Gn 24:11</ref></sense>
      <sense n="2"><def>bless</def>, <ref r="Gen.12.2">Gn 12:2</ref></sense>
    </sense>
    <sense><stem>Pi</stem>
      <sense n="1">to <def>bless</def> someone</sense>
    </sense>
    <status p="3">base</status>
  </entry>
  <entry id="a.ae.ab" type="root"><w>אָב</w> <pos>n.m</pos>. <def>father</def>
    <sense n="1"><def>father of individual</def></sense>
    <sense n="2">of God as <def>father of his people</def></sense>
  </entry>
  <entry id="plain.aa"><w>רֵיק</w> <def>empty</def>, no sense markup at all
    <status p="3">base</status>
  </entry>
</lexicon>
"""

LEXICAL_INDEX_XML = f"""<?xml version="1.0" encoding="UTF-8"?>
<index {NS}>
  <part xml:lang="heb">
    <entry id="aaa"><w>אָב</w><xref bdb="a.ae.ab" strong="1" twot="4a"/></entry>
    <entry id="bbb"><w>בָּרַךְ</w><xref bdb="b.dd.aa" strong="1288" twot="285"/></entry>
    <entry id="ccc"><w>בְּרָכָה</w><xref bdb="b.dd.ac" strong="1293" twot="285b"/></entry>
    <entry id="ddd"><w>רֵיק</w><xref bdb="plain.aa" strong="7386" twot="2159"/></entry>
  </part>
</index>
"""

ABBOTT_SMITH_XML = f"""<?xml version="1.0" encoding="UTF-8"?>
<TEI xmlns="http://www.crosswire.org/2013/TEIOSIS/namespace">
  <text><body>
    <entry n="λόγος|G3056">
      <sense n="I.">
        <sense n="1."><gloss>a word</gloss>, <ref osisRef="Matt.8.8">Mt 8:8</ref></sense>
        <sense n="2."><gloss>a saying</gloss>, <gloss>statement</gloss></sense>
      </sense>
    </entry>
    <entry n="ἀγάπη|G26">
      <sense><gloss>love</gloss>, goodwill, esteem</sense>
    </entry>
  </body></text>
</TEI>
"""


def _write(text: str, suffix: str) -> Path:
    fh = tempfile.NamedTemporaryFile("w", suffix=suffix, delete=False, encoding="utf-8")
    fh.write(text)
    fh.close()
    return Path(fh.name)


class ParseBdbSensesTest(unittest.TestCase):
    def setUp(self):
        self.bdb = _write(BDB_XML, ".xml")
        self.index = _write(LEXICAL_INDEX_XML, ".xml")
        self.addCleanup(self.bdb.unlink)
        self.addCleanup(self.index.unlink)

    def test_parses_nested_senses_with_numbers_and_headings(self):
        senses = build_db.parse_bdb_senses(self.bdb, self.index)

        self.assertEqual(sorted(senses), ["H1", "H1288"])
        rows = senses["H1288"]
        # Qal (level 0) with its two senses (level 1), then Pi and its one.
        self.assertEqual(len(rows), 5)
        self.assertEqual(rows[0][0], 0)
        self.assertEqual(rows[0][2], "Qal")
        self.assertEqual((rows[1][0], rows[1][1], rows[1][2]), (1, "1", "kneel down"))
        self.assertEqual((rows[2][0], rows[2][1], rows[2][2]), (1, "2", "bless"))
        self.assertEqual((rows[3][0], rows[3][2]), (0, "Pi"))
        self.assertEqual((rows[4][0], rows[4][1], rows[4][2]), (1, "1", "bless"))

    def test_strips_scripture_references_from_the_summary(self):
        senses = build_db.parse_bdb_senses(self.bdb, self.index)
        summary = senses["H1288"][1][3]
        self.assertIn("kneel down", summary)
        self.assertNotIn("Gn 24:11", summary)

    def test_entries_without_sense_markup_produce_no_rows(self):
        senses = build_db.parse_bdb_senses(self.bdb, self.index)
        self.assertNotIn("H7386", senses)

    def test_roots_group_by_twot_and_carry_bdb_letters(self):
        roots = build_db.parse_bdb_roots(self.bdb, self.index)

        # בָּרַךְ (verb) and בְּרָכָה (noun) share TWOT 285, so they share a root.
        self.assertEqual(roots["H1288"].twot, "285")
        self.assertEqual(roots["H1293"].twot, "285")
        self.assertEqual(roots["H1288"].root, roots["H1293"].root)
        self.assertTrue(roots["H1288"].root.startswith("ב"))
        self.assertEqual(roots["H1288"].gloss, "kneel")

        # No BDB bucket for H7386's bdb id, so it is left out rather than
        # guessed at.
        self.assertNotIn("H7386", roots)


class ParseAbbottSmithSensesTest(unittest.TestCase):
    def setUp(self):
        self.path = _write(ABBOTT_SMITH_XML, ".xml")
        self.addCleanup(self.path.unlink)

    def test_parses_greek_sense_hierarchy(self):
        senses = build_db.parse_abbott_smith_senses(self.path)

        self.assertEqual(sorted(senses), ["G26", "G3056"])
        rows = senses["G3056"]
        self.assertEqual(len(rows), 2)
        self.assertEqual((rows[0][0], rows[0][1]), (1, "1."))
        self.assertEqual(rows[0][2], "a word")
        self.assertEqual(rows[1][2], "a saying, statement")

    def test_single_sense_entries_survive(self):
        senses = build_db.parse_abbott_smith_senses(self.path)
        self.assertEqual(senses["G26"][0][2], "love")


class CachedDownloadTest(unittest.TestCase):
    """A truncated cached file must not poison the next build."""

    def test_an_intact_cached_xml_file_is_reused(self):
        path = _write("<a><b/></a>", ".xml")
        self.addCleanup(path.unlink)
        with _quiet():
            # No URL needed: a file that parses is never fetched again.
            build_db.download_file("http://invalid.invalid/x.xml", path, expect_xml=True)
        self.assertEqual(path.read_text(encoding="utf-8"), "<a><b/></a>")

    def test_a_truncated_cached_file_is_not_trusted(self):
        path = _write("<a><b", ".xml")
        self.addCleanup(lambda: path.unlink(missing_ok=True))
        with self.assertRaises(Exception):
            # It unlinks the broken file and then has to fetch, which fails
            # against an invalid URL -- the point is that it did not reuse it.
            with _quiet():
                build_db.download_file(
                    "http://invalid.invalid/x.xml", path, expect_xml=True
                )
        self.assertFalse(path.exists() and path.read_text(encoding="utf-8") == "<a><b")


class WriteSensesTest(unittest.TestCase):
    """The tables are written against lexicon rows, and the gate can fail."""

    def setUp(self):
        self.conn = sqlite3.connect(":memory:")
        self.conn.executescript(
            """
            CREATE TABLE lexicon (lemma TEXT PRIMARY KEY, strongs_id TEXT);
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
            INSERT INTO lexicon (lemma, strongs_id) VALUES ('בָּרַךְ', 'H1288');
            INSERT INTO lexicon (lemma, strongs_id) VALUES ('λόγος', 'G3056');
            INSERT INTO lexicon (lemma, strongs_id) VALUES ('אֱלֹהִים', 'H0430');
            CREATE TABLE words (
                id INTEGER PRIMARY KEY,
                strongs TEXT,
                language TEXT NOT NULL DEFAULT 'heb'
            );
            INSERT INTO words (strongs, language) VALUES ('H1288', 'heb');
            INSERT INTO words (strongs, language) VALUES ('H0430', 'heb');
            INSERT INTO words (strongs, language) VALUES ('G3056', 'grc');
            """
        )
        self.addCleanup(self.conn.close)

    def test_writes_only_senses_for_lexicon_entries(self):
        hebrew = {
            "H1288": [(0, "", "Qal", "kneel"), (1, "1", "kneel down", "")],
            # BDB keys on plain "H430"; the lexicon stores the padded "H0430",
            # so this only lands if the keys are normalized.
            "H430": [(0, "1", "rulers, judges", "")],
            "H9999": [(0, "1", "not in the lexicon", "")],
        }
        greek = {"G3056": [(0, "", "a word", "")], "G9999": [(0, "1", "nope", "")]}

        with _quiet():
            rows, heb_ids, grc_ids = build_db.build_lexicon_senses(
                self.conn, hebrew, greek, minimums=_no_minimums()
            )

        self.assertEqual((rows, heb_ids, grc_ids), (4, 2, 1))
        stored = self.conn.execute(
            "SELECT strongs_id, source FROM lexicon_senses ORDER BY strongs_id"
        ).fetchall()
        self.assertEqual(
            stored,
            [
                ("G3056", "Abbott-Smith"),
                ("H0430", "BDB"),
                ("H1288", "BDB"),
                ("H1288", "BDB"),
            ],
        )

    def test_coverage_gate_fails_on_a_thin_payload(self):
        with self.assertRaises(RuntimeError):
            with _quiet():
                build_db.build_lexicon_senses(
                    self.conn, {"H1288": [(0, "", "Qal", "")]}, {}
                )

    def test_roots_are_written_and_gated(self):
        roots = {
            "H1288": build_db.RootInfo(root="בָּרַךְ", gloss="kneel", twot="285"),
            "H9999": build_db.RootInfo(root="nope", gloss="", twot="1"),
        }
        with _quiet():
            written = build_db.build_lexicon_roots(self.conn, roots, minimums=_no_minimums())
        self.assertEqual(written, 1)
        row = self.conn.execute(
            "SELECT root, root_gloss, twot FROM lexicon_roots WHERE strongs_id = 'H1288'"
        ).fetchone()
        self.assertEqual(row, ("בָּרַךְ", "kneel", "285"))

        with self.assertRaises(RuntimeError):
            with _quiet():
                build_db.build_lexicon_roots(self.conn, roots)


def _no_minimums():
    """Gate thresholds relaxed to the fixture, so a write path can be tested."""
    return {
        "lexicon_senses_min": 1,
        "hebrew_sense_entries_min": 1,
        "greek_sense_entries_min": 0,
        "lexicon_roots_min": 1,
    }


class _quiet:
    """Silences the pipeline's own progress prints during a test."""

    def __enter__(self):
        import contextlib
        import io

        self._ctx = contextlib.redirect_stdout(io.StringIO())
        self._ctx.__enter__()
        return self

    def __exit__(self, *exc):
        return self._ctx.__exit__(*exc)


if __name__ == "__main__":
    unittest.main(verbosity=2)

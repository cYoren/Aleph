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


OSHB_VERSE = """<?xml version="1.0" encoding="UTF-8"?>
<osis xmlns="http://www.bibletechnologies.net/2003/OSIS/namespace">
<verse osisID="Gen.8.17">
  <w lemma="3605" morph="HNcmsc" id="01PUa">כָּל</w>
  <w type="x-ketiv" lemma="3318" morph="HVhv2ms" id="01Pdv">הוצא</w><note type="variant"><catchWord>הוצא</catchWord><rdg type="x-qere"><w lemma="3318" morph="HVhv2ms" id="01S7t">הַיְצֵ֣א</w></rdg></note>
  <w lemma="854" morph="HR/Sp2fs" id="018F2">אִתָּ֑/ךְ</w>
</verse>
<verse osisID="Gen.2.16">
  <w type="x-ketiv" lemma="c/269" id="01abc">ו/אחיתי/הם</w><note type="variant"><catchWord>ו/אחיתי/הם</catchWord><rdg type="x-qere"><w lemma="c/269" id="01def">וְ/אַחְיוֹתֵי/הֶ֖ם</w></rdg></note>
</verse>
<verse osisID="Gen.3.1">
  <w type="x-ketiv" lemma="3318" id="01ghi">הוצא</w><note type="variant"><catchWord>הוצא</catchWord></note>
</verse>
<verse osisID="Job.38.1">
  <w lemma="853" morph="HTo" id="01a">אֶת</w>
  <w type="x-ketiv" lemma="4480 a" morph="HR" id="01b">מנ</w>
  <note n="M">Marks a word with a final consonant that is a medial (not a final) form. </note>
  <w type="x-ketiv" lemma="d/5591 b" morph="HTd/Ncfsa" id="01c">ה/סערה</w><note type="variant"><catchWord>מנ ה/סערה</catchWord><rdg type="x-qere"><w lemma="4480 a" morph="HR" id="01d">מִ֥ן</w> <seg type="x-paseq">׀</seg><w lemma="d/5591 b" n="1" morph="HTd/Ncfsa" id="01e">הַ/סְּעָרָ֗ה</w></rdg></note>
  <w lemma="c/559" morph="HC/Vqw3ms" id="01f">וַ/יֹּאמַֽר</w>
</verse>
</osis>
"""


class QereKetivParseTest(unittest.TestCase):
    """The written form and the reading, out of the OSHB variant markup."""

    def setUp(self):
        self.path = _write(OSHB_VERSE, ".xml")
        self.addCleanup(self.path.unlink)

    def test_a_ketiv_word_yields_both_forms(self):
        pairs = build_db.parse_oshb_qere_ketiv(self.path)
        first = pairs[0]
        self.assertEqual((first.book_id, first.chapter, first.verse), ("GEN", 8, 17))
        self.assertEqual(first.ketiv, "הוצא")
        self.assertEqual(first.qere, "הַיְצֵ֣א")
        self.assertEqual(first.qere_strongs, "H3318")
        self.assertEqual(first.ketiv_strongs, "H3318")

    def test_morpheme_slashes_are_not_part_of_the_word(self):
        pairs = build_db.parse_oshb_qere_ketiv(self.path)
        second = pairs[1]
        self.assertEqual(second.ketiv, "ואחיתיהם")
        self.assertEqual(second.qere, "וְאַחְיוֹתֵיהֶ֖ם")

    def test_a_variant_note_without_a_reading_is_not_a_pair(self):
        pairs = build_db.parse_oshb_qere_ketiv(self.path)
        self.assertEqual(len(pairs), 3)

    def test_a_multi_word_ketiv_run_stays_one_pair(self):
        pairs = build_db.parse_oshb_qere_ketiv(self.path)
        job = [pair for pair in pairs if pair.book_id == "JOB"][0]
        self.assertEqual(job.ketiv, "מנ הסערה")
        # Two words, and the same consonants as the source: comparing pointing
        # codepoint by codepoint would be testing the fixture, not the parser.
        self.assertEqual(len(job.qere.split()), 2)
        self.assertEqual(build_db.hebrew_consonants(job.qere), "מןהסערה")
        # The id that identifies a two-word reading is the longer word's.
        self.assertEqual(job.qere_strongs, "H5591")

    def test_an_editorial_note_never_reaches_the_reading(self):
        # A `<note n="M">` inside a ketiv run is commentary, not scripture: it
        # used to be swallowed into ketiv_text by a backtracking match.
        pairs = build_db.parse_oshb_qere_ketiv(self.path)
        for pair in pairs:
            self.assertNotIn("Marks a word", pair.ketiv)
            self.assertNotIn("\n", pair.ketiv)
            self.assertNotIn("\n", pair.qere)

    def test_a_compound_lemma_keeps_its_own_number(self):
        self.assertEqual(build_db._oshb_strongs("c/269"), "H0269")
        self.assertEqual(build_db._oshb_strongs("l"), None)
        self.assertEqual(build_db._oshb_strongs(""), None)


class QereKetivAlignTest(unittest.TestCase):
    """Alignment by consonants, never by token index."""

    def test_a_word_split_by_proclitics_still_matches(self):
        tokens = ["וְ", "אַחְיוֹתֵי", "הֶ֖ם"]
        self.assertEqual(
            build_db.find_token_span(tokens, "וְ/אַחְיוֹתֵי/הֶ֖ם"), (0, 2)
        )

    def test_an_ambiguous_match_is_refused(self):
        tokens = ["דּוֹאֵ֣ג", "וַ", "יִּסֹּ֞ב", "דּוֹאֵ֣ג"]
        self.assertIsNone(build_db.find_token_span(tokens, "דואג"))

    def test_the_readings_strongs_id_breaks_the_tie(self):
        tokens = ["לְ", "דּוֹאֵ֔ג", "וַ", "יִּסֹּ֞ב", "דּוֹאֵ֣ג"]
        strongs = ["H3807A", "H1673", "H2050B", "H5437", "H1673"]
        # Both occurrences are the same word here, so the id cannot decide.
        self.assertIsNone(
            build_db.find_token_span(tokens, "דואג", "H1673", strongs)
        )
        # With only one of them carrying the reading's id, it decides.
        strongs[1] = "H0999"
        self.assertEqual(
            build_db.find_token_span(tokens, "דואג", "H1673", strongs), (4, 4)
        )

    def test_consonants_ignore_pointing_and_marks(self):
        self.assertEqual(build_db.hebrew_consonants("הַיְצֵ֣א"), "היצא")
        self.assertEqual(build_db.hebrew_consonants("בְּ/נֵי־"), "בני")


class WriteQereKetivTest(unittest.TestCase):
    """The words table gets both forms, and the gate can fail."""

    def setUp(self):
        self.conn = sqlite3.connect(":memory:")
        self.conn.executescript(
            """
            CREATE TABLE verses (
                id INTEGER PRIMARY KEY,
                book_id TEXT NOT NULL,
                chapter INTEGER NOT NULL,
                verse_number INTEGER NOT NULL
            );
            CREATE TABLE words (
                id INTEGER PRIMARY KEY,
                verse_id INTEGER NOT NULL,
                position INTEGER NOT NULL,
                word TEXT NOT NULL,
                strongs TEXT,
                language TEXT NOT NULL DEFAULT 'heb',
                qere_text TEXT,
                ketiv_text TEXT,
                qere_lemma TEXT,
                qere_anchor TEXT,
                qere_span INTEGER
            );
            CREATE TABLE lexicon (lemma TEXT PRIMARY KEY, strongs_id TEXT);
            INSERT INTO verses (id, book_id, chapter, verse_number)
                VALUES (1, 'GEN', 8, 17);
            INSERT INTO words (id, verse_id, position, word, strongs)
                VALUES (1, 1, 1, 'הָ', 'H1886A'),
                       (2, 1, 2, 'יְצֵ֣א', 'H3318');
            INSERT INTO lexicon (lemma, strongs_id) VALUES ('הוֹדַוְיָה', 'H1938');
            """
        )
        self.addCleanup(self.conn.close)

    def test_both_forms_land_on_the_stem_token(self):
        pairs = [
            build_db.QereKetiv(
                book_id="GEN",
                chapter=8,
                verse=17,
                ketiv="הוצא",
                ketiv_strongs="H3318",
                qere="הַיְצֵ֣א",
                qere_strongs="H3318",
            )
        ]
        with _quiet():
            written = build_db.build_qere_ketiv(self.conn, pairs)
        self.assertEqual(written, 1)
        row = self.conn.execute(
            "SELECT qere_text, ketiv_text, qere_lemma, qere_anchor, qere_span "
            "FROM words WHERE id = 2"
        ).fetchone()
        # The word is two tokens here (הָ + יְצֵ֣א), so the pair is stored but
        # cannot be shown beside one of them without repeating the other.
        self.assertEqual(row, ("הַיְצֵ֣א", "הוצא", None, "qere", 2))

    def test_a_word_split_across_tokens_is_marked_but_not_inline(self):
        # Three tokens spelling one word, the way MACULA splits a proclitic and
        # a suffix off the stem.
        self.conn.execute("DELETE FROM words")
        self.conn.executemany(
            "INSERT INTO words (id, verse_id, position, word, strongs) "
            "VALUES (?, 1, ?, ?, 'H3318')",
            [(1, 1, "הָ"), (2, 2, "יְצֵ"), (3, 3, "א")],
        )
        pairs = [
            build_db.QereKetiv(
                book_id="GEN",
                chapter=8,
                verse=17,
                ketiv="הוצא",
                ketiv_strongs="H3318",
                qere="הַיְצֵ֣א",
                qere_strongs="H3318",
            )
        ]
        with _quiet():
            build_db.build_qere_ketiv(self.conn, pairs)
        # Three tokens now spell the same word; the anchor is still the reading.
        row = self.conn.execute(
            "SELECT qere_span, qere_anchor FROM words WHERE qere_text IS NOT NULL"
        ).fetchone()
        self.assertEqual(row, (3, "qere"))

    def test_a_different_reading_carries_its_own_lemma(self):
        self.conn.execute(
            "UPDATE words SET word = 'הוֹדַוְיָ֡הוּ', strongs = 'H1939' WHERE id = 2"
        )
        pairs = [
            build_db.QereKetiv(
                book_id="GEN",
                chapter=8,
                verse=17,
                ketiv="הדיוהו",
                ketiv_strongs="H1939",
                qere="הוֹדַוְיָ֡הוּ",
                qere_strongs="H1938",
            )
        ]
        with _quiet():
            build_db.build_qere_ketiv(self.conn, pairs)
        row = self.conn.execute(
            "SELECT qere_lemma FROM words WHERE id = 2"
        ).fetchone()
        self.assertEqual(row, ("הוֹדַוְיָה",))

    def test_an_unaligned_pair_writes_nothing(self):
        pairs = [
            build_db.QereKetiv(
                book_id="GEN",
                chapter=8,
                verse=17,
                ketiv="שלום",
                ketiv_strongs=None,
                qere="שלום",
                qere_strongs=None,
            )
        ]
        with _quiet():
            written = build_db.build_qere_ketiv(self.conn, pairs)
        self.assertEqual(written, 0)
        self.assertEqual(
            self.conn.execute(
                "SELECT COUNT(*) FROM words WHERE qere_text IS NOT NULL"
            ).fetchone()[0],
            0,
        )


BYZANTINE_CSV = """chapter,verse,text
6,13,και μη εισενεγκης ημας εις πειρασμον αλλα ρυσαι ημας απο του πονηρου οτι σου εστιν η βασιλεια και η δυναμις και η δοξα εις τους αιωνας αμην
6,14,εαν γαρ αφητε
"""

CNTR_TSV = """Verse\tModern\tKoine\tLemma\tESN\tRole\tMorphology
40006013\t\u0318\u0398\u03b5\u1ff7,\t=θω\tθε\u03cc\u03c2\t23160\tN\t....DMS
40006013\t\u1f21\t=η\t\u1f41\t35880\tRA\t....NFS
40006013\t\u03b2\u03b1\u03c3\u03b9\u03bb\u03b5\u03af\u03b1\t=βασιλεια\t\u03b2\u03b1\u03c3\u03b9\u03bb\u03b5\u03af\u03b1\t9320\tN\t....NFS
"""


class OtherEditionsParseTest(unittest.TestCase):
    """The two other editions, as verse-keyed word lists."""

    def test_byzantine_csv_is_keyed_by_book_chapter_verse(self):
        directory = Path(tempfile.mkdtemp())
        self.addCleanup(lambda: __import__("shutil").rmtree(directory, ignore_errors=True))
        path = directory / "MAT.csv"
        path.write_text(BYZANTINE_CSV, encoding="utf-8")
        verses = build_db.parse_byzantine_edition([path])
        self.assertEqual(sorted(verses), [("MAT", 6, 13), ("MAT", 6, 14)])
        self.assertEqual(verses[("MAT", 6, 13)][:3], ["\u03ba\u03b1\u03b9", "\u03bc\u03b7", "\u03b5\u03b9\u03c3\u03b5\u03bd\u03b5\u03b3\u03ba\u03b7\u03c2"])

    def test_a_paragraph_mark_is_not_a_word(self):
        directory = Path(tempfile.mkdtemp())
        self.addCleanup(lambda: __import__("shutil").rmtree(directory, ignore_errors=True))
        path = directory / "MAT.csv"
        path.write_text(
            'chapter,verse,text\n1,1,"\u00b6\u0392\u03af\u03b2\u03bb\u03bf\u03c2 \u03b3\u03b5\u03bd\u03ad\u03c3\u03b5\u03c9\u03c2."\n',
            encoding="utf-8",
        )
        verses = build_db.parse_byzantine_edition([path])
        self.assertEqual(verses[("MAT", 1, 1)], ["\u0392\u03af\u03b2\u03bb\u03bf\u03c2", "\u03b3\u03b5\u03bd\u03ad\u03c3\u03b5\u03c9\u03c2."])

    def test_cntr_tsv_reads_the_eight_digit_verse_id(self):
        path = _write(CNTR_TSV, ".tsv")
        self.addCleanup(path.unlink)
        verses = build_db.parse_cntr_edition(path)
        self.assertEqual(list(verses), [("MAT", 6, 13)])
        self.assertEqual(verses[("MAT", 6, 13)], ["\u0318\u0398\u03b5\u1ff7,", "\u1f21", "\u03b2\u03b1\u03c3\u03b9\u03bb\u03b5\u03af\u03b1"])

    def test_a_verse_id_outside_the_new_testament_is_skipped(self):
        path = _write(
            "Verse\tModern\n19001001\t\u1f18\u03bd\n40006013\t\u03ba\u03b1\u03af\n",
            ".tsv",
        )
        self.addCleanup(path.unlink)
        verses = build_db.parse_cntr_edition(path)
        self.assertEqual(list(verses), [("MAT", 6, 13)])


class DiffVerseWordsTest(unittest.TestCase):
    """What counts as a different reading."""

    def test_pointing_and_punctuation_are_not_a_difference(self):
        self.assertEqual(
            build_db.diff_verse_words(
                ["\u03ba\u03b1\u1f76", "\u1f10\u03c3\u03c4\u03af\u03bd,"],
                ["\u03ba\u03b1\u03b9", "\u03b5\u03c3\u03c4\u03b9\u03bd"],
            ),
            [],
        )

    def test_final_sigma_is_not_a_difference(self):
        self.assertEqual(
            build_db.diff_verse_words(["\u03bb\u03cc\u03b3\u03bf\u03c2"], ["\u03bb\u03bf\u03b3\u03bf\u03c3"]),
            [],
        )

    def test_a_different_word_is_a_difference(self):
        self.assertEqual(
            build_db.diff_verse_words(
                ["\u03b5\u1f50\u03b4\u03bf\u03ba\u03af\u03b1\u03c2"],
                ["\u03b5\u03c5\u03b4\u03bf\u03ba\u03b9\u03b1"],
            ),
            [("\u03b5\u1f50\u03b4\u03bf\u03ba\u03af\u03b1\u03c2", "\u03b5\u03c5\u03b4\u03bf\u03ba\u03b9\u03b1")],
        )

    def test_an_addition_has_an_empty_base_side(self):
        self.assertEqual(
            build_db.diff_verse_words(
                ["\u03c0\u03bf\u03bd\u03b7\u03c1\u03bf\u1fe6"],
                ["\u03c0\u03bf\u03bd\u03b7\u03c1\u03bf\u03c5", "\u03b1\u03bc\u03b7\u03bd"],
            ),
            [("", "\u03b1\u03bc\u03b7\u03bd")],
        )

    def test_stored_readings_drop_the_editions_punctuation(self):
        # The comparison ignores punctuation, so the stored reading must too:
        # one side with a trailing full stop and the other without reads as a
        # difference that is not there.
        self.assertEqual(
            build_db.diff_verse_words(
                ["\u03c4\u03b7\u03c1\u03ae\u03c3\u03b1\u03c4\u03b5"],
                ["\u03c4\u03b7\u03c1\u03ae\u03c3\u03b1\u03c4\u03b5."],
            ),
            [],
        )
        self.assertEqual(
            build_db.diff_verse_words(
                ["\u03c0\u03bf\u03bd\u03b7\u03c1\u03bf\u1fe6"],
                ["\u03c0\u03bf\u03bd\u03b7\u03c1\u03bf\u03c5.", "\u1f00\u03bc\u03ae\u03bd."],
            ),
            [("", "\u1f00\u03bc\u03ae\u03bd")],
        )

    def test_an_omission_has_an_empty_other_side(self):
        self.assertEqual(
            build_db.diff_verse_words(
                ["\u03b1", "\u03b2", "\u03b3"],
                ["\u03b1", "\u03b3"],
            ),
            [("\u03b2", "")],
        )


class WriteTextualVariantsTest(unittest.TestCase):
    def setUp(self):
        self.conn = sqlite3.connect(":memory:")
        self.conn.executescript(
            """
            CREATE TABLE verses (id INTEGER PRIMARY KEY, book_id TEXT,
                                 chapter INTEGER, verse_number INTEGER);
            CREATE TABLE words (id INTEGER PRIMARY KEY, verse_id INTEGER,
                                position INTEGER, word TEXT,
                                language TEXT NOT NULL DEFAULT 'grc');
            CREATE TABLE textual_variants (
                id INTEGER PRIMARY KEY,
                book_id TEXT NOT NULL,
                chapter INTEGER NOT NULL,
                verse INTEGER NOT NULL,
                position INTEGER NOT NULL,
                edition TEXT NOT NULL,
                base_reading TEXT NOT NULL,
                other_reading TEXT NOT NULL
            );
            INSERT INTO verses (id, book_id, chapter, verse_number)
                VALUES (1, 'MAT', 6, 13);
            INSERT INTO words (verse_id, position, word) VALUES
                (1, 1, '\u03ba\u03b1\u1f76'),
                (1, 2, '\u03bc\u1f74'),
                (1, 3, '\u03c0\u03bf\u03bd\u03b7\u03c1\u03bf\u1fe6');
            """
        )
        self.addCleanup(self.conn.close)

    def test_differences_are_written_with_the_edition_named(self):
        editions = {
            "RP2018": {("MAT", 6, 13): ["\u03ba\u03b1\u03b9", "\u03bc\u03b7", "\u03c0\u03bf\u03bd\u03b7\u03c1\u03bf\u03c5", "\u03b1\u03bc\u03b7\u03bd"]}
        }
        with _quiet():
            written = build_db.build_textual_variants(self.conn, editions)
        self.assertEqual(written, 1)
        row = self.conn.execute(
            "SELECT book_id, chapter, verse, edition, base_reading, other_reading "
            "FROM textual_variants"
        ).fetchone()
        self.assertEqual(row, ("MAT", 6, 13, "RP2018", "", "\u03b1\u03bc\u03b7\u03bd"))

    def test_a_verse_the_base_text_lacks_writes_nothing(self):
        editions = {"SR": {("MAT", 9, 9): ["\u03ba\u03b1\u03b9"]}}
        with _quiet():
            written = build_db.build_textual_variants(self.conn, editions)
        self.assertEqual(written, 0)


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

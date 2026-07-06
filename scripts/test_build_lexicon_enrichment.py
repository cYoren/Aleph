#!/usr/bin/env python3
"""Unit tests for the Strong's lexicon enrichment in build_full_bible_db.py.

Run with: python3 scripts/test_build_lexicon_enrichment.py
"""

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path

_SCRIPT_PATH = Path(__file__).resolve().parent / "build_full_bible_db.py"
_spec = importlib.util.spec_from_file_location("build_full_bible_db", _SCRIPT_PATH)
build_db = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = build_db
_spec.loader.exec_module(build_db)


class ParseStrongsDictionaryJsTest(unittest.TestCase):
    def test_parses_js_wrapped_json(self):
        payload = (
            "/* license header with { braces } inside */\n"
            'var strongsHebrewDictionary = {"H1":{"lemma":"אָב",'
            '"xlit":"ʼâb","pron":"awb",'
            '"derivation":"a primitive word;",'
            '"strongs_def":"father",'
            '"kjv_def":"chief, father"}};\n'
        )
        with tempfile.NamedTemporaryFile(
            "w", suffix=".js", delete=False, encoding="utf-8"
        ) as fh:
            fh.write(payload)
            path = Path(fh.name)
        try:
            data = build_db.parse_strongs_dictionary_js(path)
        finally:
            path.unlink()
        self.assertEqual(list(data.keys()), ["H1"])
        self.assertEqual(data["H1"]["strongs_def"], "father")

    def test_header_brace_is_ignored(self):
        # The parser must anchor on the `= {` assignment, not on braces that
        # appear inside the license comment before the payload.
        payload = "/* {not json} */ var d = {\"G1\":{\"lemma\":\"A\"}};"
        with tempfile.NamedTemporaryFile(
            "w", suffix=".js", delete=False, encoding="utf-8"
        ) as fh:
            fh.write(payload)
            path = Path(fh.name)
        try:
            data = build_db.parse_strongs_dictionary_js(path)
        finally:
            path.unlink()
        self.assertEqual(data, {"G1": {"lemma": "A"}})


class StrongsLookupCandidatesTest(unittest.TestCase):
    def test_zero_padded_hebrew_id(self):
        self.assertEqual(
            build_db.strongs_lookup_candidates("H0430"), ["H0430", "H430"]
        )

    def test_disambiguation_suffix_falls_back_to_base_number(self):
        self.assertEqual(
            build_db.strongs_lookup_candidates("H1254A"), ["H1254A", "H1254"]
        )

    def test_canonical_id_produces_single_candidate(self):
        self.assertEqual(build_db.strongs_lookup_candidates("G26"), ["G26"])

    def test_lowercase_is_normalized(self):
        self.assertEqual(
            build_db.strongs_lookup_candidates("h0430"), ["H0430", "H430"]
        )

    def test_invalid_ids(self):
        self.assertEqual(build_db.strongs_lookup_candidates(""), [])
        self.assertEqual(build_db.strongs_lookup_candidates("430"), [])
        self.assertEqual(build_db.strongs_lookup_candidates("X430"), [])


class ComposeStrongsDefinitionTest(unittest.TestCase):
    def test_full_entry(self):
        entry = {
            "strongs_def": "gods in the ordinary sense",
            "derivation": "plural of H433;",
            "kjv_def": "angels, [idiom] exceeding, God (gods)",
        }
        text = build_db.compose_strongs_definition(entry)
        self.assertIn("Gods in the ordinary sense.", text)
        self.assertIn("Derivation: plural of H433.", text)
        self.assertIn("KJV renderings: angels, × exceeding, God (gods).", text)

    def test_idiom_marker_becomes_multiplication_sign(self):
        self.assertEqual(
            build_db.clean_strongs_text("[idiom] great; [phrase] many"),
            "× great; many",
        )

    def test_empty_entry_returns_empty_string(self):
        self.assertEqual(build_db.compose_strongs_definition({}), "")

    def test_whitespace_is_collapsed(self):
        entry = {"strongs_def": "  love,\n   i.e. affection  "}
        self.assertEqual(
            build_db.compose_strongs_definition(entry),
            "Love, i.e. affection.",
        )

    def test_no_double_period_when_source_ends_with_one(self):
        entry = {"kjv_def": "judges, [idiom] mighty."}
        self.assertEqual(
            build_db.compose_strongs_definition(entry),
            "KJV renderings: judges, × mighty.",
        )


class ParseOpenbibleRefTest(unittest.TestCase):
    def test_simple_ref(self):
        self.assertEqual(build_db.parse_openbible_ref("Gen.1.1"), ("GEN", 1, 1))

    def test_osis_names_map_to_app_ids(self):
        self.assertEqual(build_db.parse_openbible_ref("Ps.23.1"), ("PSA", 23, 1))
        self.assertEqual(build_db.parse_openbible_ref("1Kgs.2.3"), ("1KI", 2, 3))
        self.assertEqual(build_db.parse_openbible_ref("Phlm.1.5"), ("PHM", 1, 5))
        self.assertEqual(build_db.parse_openbible_ref("Song.2.1"), ("SNG", 2, 1))

    def test_unknown_book_returns_none(self):
        self.assertIsNone(build_db.parse_openbible_ref("Tob.1.1"))
        self.assertIsNone(build_db.parse_openbible_ref("Gen.1"))
        self.assertIsNone(build_db.parse_openbible_ref(""))

    def test_every_osis_book_maps_to_known_abbreviation(self):
        known = {b.abbr for b in build_db.BOOKS}
        for osis, abbr in build_db.OSIS_TO_ABBR.items():
            self.assertIn(abbr, known, f"{osis} maps to unknown {abbr}")
        self.assertEqual(len(set(build_db.OSIS_TO_ABBR.values())), 66)


class MaculaTreeExtractionTest(unittest.TestCase):
    SAMPLE = """
    <chapter>
      <sentence>
        <p><milestone unit="verse">GEN 1:1</milestone></p>
        <wg class="cl" rule="PP-V-S-O">
          <wg role="pp" class="pp" rule="PrepNp">
            <w ref="GEN 1:1!1" class="prep">be</w>
            <w ref="GEN 1:1!1" class="noun">reshit</w>
          </wg>
          <w role="v" ref="GEN 1:1!2" class="verb">bara</w>
          <wg>
            <w ref="GEN 1:1!3" class="noun">elohim</w>
          </wg>
        </wg>
      </sentence>
    </chapter>
    """

    def _sentence(self):
        import xml.etree.ElementTree as ET

        return next(ET.fromstring(self.SAMPLE).iter("sentence"))

    def test_tree_structure(self):
        tree = build_db.macula_sentence_to_tree(self._sentence())
        self.assertEqual(tree["c"], "cl")
        self.assertEqual(tree["u"], "PP-V-S-O")
        self.assertEqual(len(tree["k"]), 3)
        pp = tree["k"][0]
        self.assertEqual(pp["r"], "pp")
        self.assertEqual(pp["k"][0], {"t": "be", "n": 1, "c": "prep"})

    def test_passthrough_group_is_spliced(self):
        tree = build_db.macula_sentence_to_tree(self._sentence())
        # The attribute-less <wg> around 'elohim' must collapse to its leaf.
        self.assertEqual(tree["k"][2], {"t": "elohim", "n": 3, "c": "noun"})

    def test_verse_coverage(self):
        verses = build_db.macula_sentence_verses(self._sentence())
        self.assertEqual(verses, [("GEN", 1, 1)])

    def test_ref_parsing(self):
        self.assertEqual(
            build_db.parse_macula_ref("GEN 1:1!2"), ("GEN", 1, 1, 2)
        )
        self.assertEqual(
            build_db.parse_macula_ref("JUD 1:25!3"), ("JUD", 1, 25, 3)
        )
        self.assertIsNone(build_db.parse_macula_ref("XXX 1:1!1"))
        self.assertIsNone(build_db.parse_macula_ref("GEN 1:1"))

    def test_hebrew_filename_codes(self):
        self.assertEqual(build_db.macula_hebrew_book_code("GEN"), "Gen")
        self.assertEqual(build_db.macula_hebrew_book_code("1SA"), "1Sa")
        self.assertEqual(build_db.macula_hebrew_book_code("HOS"), "HOS")
        self.assertEqual(build_db.macula_hebrew_book_code("SNG"), "Sng")


if __name__ == "__main__":
    sys.exit(unittest.main(verbosity=2))

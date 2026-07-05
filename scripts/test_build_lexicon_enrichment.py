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


if __name__ == "__main__":
    sys.exit(unittest.main(verbosity=2))

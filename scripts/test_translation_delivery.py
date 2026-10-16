#!/usr/bin/env python3
"""Regression tests for the external translation delivery contract."""
from __future__ import annotations

import copy
import json
import pathlib
import tempfile
import unittest

from lexicon_definitions_i18n import LANGUAGES, sha256_text
from validate_translation_delivery import validate_delivery


class DeliveryTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.directory = pathlib.Path(self.tmp.name)
        self.english = "A word, λόγος, from G3056."
        self.greek = "Βοσόρ v. Βεώρ."
        self.source = {
            "definition": {sha256_text(self.english): self.english},
            "extended_definition": {sha256_text(self.greek): self.greek},
        }
        self.cache = {
            "_meta": {"lang": "pt", "method": "machine-translation",
                      "provider": "test", "model": "test-fixture", "revision": 1},
            "definition": {sha256_text(self.english): "Uma palavra, λόγος, de G3056."},
            "extended_definition": {sha256_text(self.greek): self.greek},
        }
        for lang in LANGUAGES:
            self.write(lang)

    def write(self, lang, cache=None):
        data = copy.deepcopy(cache or self.cache)
        data["_meta"]["lang"] = lang
        (self.directory / f"{lang}.json").write_text(json.dumps(data), encoding="utf-8")

    def test_preserves_original_language_only_cross_entries(self):
        self.assertEqual(validate_delivery(self.source, self.directory), [])

    def test_missing_language_is_rejected(self):
        (self.directory / "ko.json").unlink()
        self.assertTrue(validate_delivery(self.source, self.directory))

    def test_duplicate_json_hash_is_rejected(self):
        (self.directory / "pt.json").write_text('{"definition":{},"definition":{}}')
        self.assertTrue(any('duplicate JSON key' in e for e in validate_delivery(self.source, self.directory)))

    def test_changed_protected_word_is_rejected(self):
        self.cache["definition"][sha256_text(self.english)] = "Uma palavra, λογος, de G3056."
        self.write("pt")
        self.assertTrue(any('tokens were changed' in e for e in validate_delivery(self.source, self.directory)))

    def test_missing_strongs_reference_is_rejected(self):
        self.cache["definition"][sha256_text(self.english)] = "Uma palavra, λόγος."
        self.write("pt")
        self.assertTrue(any('tokens were changed' in e for e in validate_delivery(self.source, self.directory)))

    def test_unchanged_english_is_rejected(self):
        self.cache["definition"][sha256_text(self.english)] = self.english
        self.write("pt")
        self.assertTrue(any('copied unchanged' in e for e in validate_delivery(self.source, self.directory)))

    def test_unknown_or_missing_hash_is_rejected(self):
        self.cache["definition"] = {"0" * 64: "Tradução de outra origem."}
        self.write("pt")
        errors = validate_delivery(self.source, self.directory)
        self.assertTrue(any('missing source hashes' in e for e in errors))
        self.assertTrue(any('unknown/outdated source hashes' in e for e in errors))


if __name__ == "__main__":
    unittest.main(verbosity=2)

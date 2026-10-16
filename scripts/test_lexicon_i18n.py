#!/usr/bin/env python3
"""Tests for the long-form lexicon translation pipeline.

Run directly:

    python3 scripts/test_lexicon_i18n.py

Covers the properties the acceptance criteria call out, on a small synthetic
database where the originals and the translations are deliberately different:

* export keeps a stable identity (`lemma`) and a source hash per field,
* provably identical texts are deduplicated and fanned back out to every entry
  that shares them,
* entries that differ only by Strong's id are kept apart,
* entries with no cached translation are simply absent (the app falls back to
  English), not written as empty strings,
* a changed English original invalidates the cached translation (stale hash),
* coverage is counted per language and per field.
"""

from __future__ import annotations

import pathlib
import contextlib
import io
import sqlite3
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

import lexicon_definitions_i18n as i18n  # noqa: E402
import validate_lexicon_i18n as validator  # noqa: E402
import translate_lexicon_definitions as translator  # noqa: E402


def make_db() -> sqlite3.Connection:
    db = sqlite3.connect(":memory:")
    db.execute(
        "CREATE TABLE lexicon (lemma TEXT PRIMARY KEY, strongs_id TEXT, "
        "gloss TEXT NOT NULL, definition TEXT, extended_definition TEXT, language TEXT)"
    )
    rows = [
        # Two entries that share a Strong's id but differ in lemma and text.
        ("א", "H1", "g1", "First definition.", "First extended.", "heb"),
        ("ב", "H1", "g2", "First definition.", "Second extended.", "heb"),
        # An entry with a distinct definition and no extended text.
        ("λόγος", "G3056", "g3", "A word, speech.", None, "grc"),
        # A homonym pair sharing an identical extended text.
        ("נר", "H5216A", "g4", "A lamp.", "Shared scholarly note.", "heb"),
        ("נרה", "H5216B", "g5", "Another lamp sense.", "Shared scholarly note.", "heb"),
    ]
    db.executemany(
        "INSERT INTO lexicon (lemma, strongs_id, gloss, definition, extended_definition, language) "
        "VALUES (?, ?, ?, ?, ?, ?)",
        rows,
    )
    db.commit()
    return db


class ExportIdentityTest(unittest.TestCase):
    def test_lemma_is_the_identity_and_strongs_repeats(self):
        db = make_db()
        rows = i18n.source_rows_with_hashes(db)
        self.assertEqual(len(rows), 5)
        lemmas = {r["lemma"] for r in rows}
        self.assertEqual(len(lemmas), 5)
        # H1 appears twice: Strong's alone would have collapsed them.
        self.assertEqual(sum(1 for r in rows if r["strongs_id"] == "H1"), 2)

    def test_hash_is_stable_and_field_specific(self):
        db = make_db()
        rows = {r["lemma"]: r for r in i18n.source_rows_with_hashes(db)}
        self.assertEqual(rows["א"]["definition_sha256"], i18n.sha256_text("First definition."))
        self.assertNotEqual(
            rows["א"]["definition_sha256"], rows["א"]["extended_definition_sha256"]
        )
        # No extended text -> empty hash, not a hash of the empty string.
        self.assertEqual(rows["λόγος"]["extended_definition_sha256"], "")

    def test_identical_texts_deduplicate(self):
        db = make_db()
        unique = i18n.unique_source_texts(db)
        # "First definition." is shared by two entries -> one unique text.
        self.assertIn(i18n.sha256_text("First definition."), unique["definition"])
        self.assertEqual(len(unique["definition"]), 4)
        # "Shared scholarly note." is shared -> one unique extended text.
        self.assertEqual(len(unique["extended_definition"]), 3)


class CacheRoundTripTest(unittest.TestCase):
    def test_cache_keyed_by_source_hash_and_survives_reload(self):
        with tempfile.TemporaryDirectory() as tmp:
            cache_dir = pathlib.Path(tmp)
            cache = i18n.empty_cache("pt")
            cache["definition"][i18n.sha256_text("First definition.")] = "Primeira definição."
            i18n.save_cache("pt", cache, cache_dir)

            reloaded = i18n.load_cache("pt", cache_dir)
            self.assertEqual(
                reloaded["definition"][i18n.sha256_text("First definition.")],
                "Primeira definição.",
            )
            self.assertEqual(reloaded["_meta"]["lang"], "pt")


class ApplyTest(unittest.TestCase):
    def _cache(self, cache_dir: pathlib.Path) -> None:
        cache = i18n.empty_cache("pt")
        cache["definition"][i18n.sha256_text("First definition.")] = "Primeira definição."
        cache["extended_definition"][i18n.sha256_text("Shared scholarly note.")] = "Nota acadêmica."
        i18n.save_cache("pt", cache, cache_dir)

    def test_fanout_and_fallback(self):
        with tempfile.TemporaryDirectory() as tmp:
            db = make_db()
            self._cache(pathlib.Path(tmp))
            written = i18n.write_lexicon_translations(db, pathlib.Path(tmp))

            rows = {
                lemma: (definition, extended)
                for lemma, definition, extended in db.execute(
                    "SELECT lemma, definition, extended_definition "
                    "FROM lexicon_definition_i18n WHERE lang='pt'"
                )
            }
            # Deduplication: one cache entry each fanned out to two lemmas.
            self.assertEqual(rows["א"][0], "Primeira definição.")
            self.assertEqual(rows["ב"][0], "Primeira definição.")
            self.assertEqual(rows["נר"][1], "Nota acadêmica.")
            # No translation for the Greek entry -> absent, not empty.
            self.assertNotIn("λόγος", rows)
            # 2 definitions + 2 extended = 4 values.
            self.assertEqual(written, 4)

            # Existing English originals are untouched.
            english = db.execute(
                "SELECT definition FROM lexicon WHERE lemma='א'"
            ).fetchone()[0]
            self.assertEqual(english, "First definition.")

    def test_stale_hash_is_not_reused(self):
        with tempfile.TemporaryDirectory() as tmp:
            db = make_db()
            # Cache a translation for a *different* source text.
            cache = i18n.empty_cache("pt")
            cache["definition"][i18n.sha256_text("Some older wording.")] = "Tradução antiga."
            i18n.save_cache("pt", cache, pathlib.Path(tmp))

            i18n.write_lexicon_translations(db, pathlib.Path(tmp))
            count = db.execute(
                "SELECT COUNT(*) FROM lexicon_definition_i18n"
            ).fetchone()[0]
            # The changed original must not be served the stale translation.
            self.assertEqual(count, 0)

    def test_coverage_report_counts_per_field(self):
        with tempfile.TemporaryDirectory() as tmp:
            db = make_db()
            self._cache(pathlib.Path(tmp))
            i18n.write_lexicon_translations(db, pathlib.Path(tmp))
            report = i18n.coverage_report(db)

            self.assertTrue(report["table_present"])
            # coverage_report counts source *rows*, not unique texts:
            # 5 rows carry a definition, 4 carry an extended definition.
            self.assertEqual(report["total_definition"], 5)
            self.assertEqual(report["total_extended_definition"], 4)
            pt = report["languages"]["pt"]
            # "First definition." fanned out to two lemmas; "Shared scholarly
            # note." to two more.
            self.assertEqual(pt["definition"]["have"], 2)
            self.assertEqual(pt["extended_definition"]["have"], 2)


class EmptyTest(unittest.TestCase):
    def test_no_cache_writes_nothing(self):
        with tempfile.TemporaryDirectory() as tmp:
            db = make_db()
            self.assertEqual(i18n.write_lexicon_translations(db, pathlib.Path(tmp)), 0)
            count = db.execute(
                "SELECT COUNT(*) FROM lexicon_definition_i18n"
            ).fetchone()[0]
            self.assertEqual(count, 0)


class ValidationTest(unittest.TestCase):
    def _validate(self, db, *flags):
        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / 'fixture.db'
            db.commit()
            copy = sqlite3.connect(path)
            db.backup(copy)
            copy.close()
            with mock.patch.object(sys, 'argv', ['validate', '--db', str(path), *flags]), \
                    contextlib.redirect_stdout(io.StringIO()), \
                    contextlib.redirect_stderr(io.StringIO()):
                return validator.main()

    def test_full_coverage_requires_all_seven_languages(self):
        db = make_db()
        db.execute(i18n.SCHEMA)
        for row in i18n.source_rows_with_hashes(db):
            db.execute(
                'INSERT INTO lexicon_definition_i18n '
                '(lemma, lang, definition, extended_definition, '
                'source_definition_sha256, source_extended_sha256) VALUES (?, ?, ?, ?, ?, ?)',
                (row['lemma'], 'pt', 'Tradução.', 'Nota.' if row['extended_definition'] else None,
                 row['definition_sha256'], row['extended_definition_sha256']),
            )
        self.assertEqual(self._validate(db, '--require-full'), 1)

    def test_empty_table_does_not_satisfy_full_coverage(self):
        db = make_db()
        db.execute(i18n.SCHEMA)
        self.assertEqual(self._validate(db, '--require-full'), 1)

    def test_full_coverage_accepts_preserved_original_language_cross_entries(self):
        db = make_db()
        db.execute("UPDATE lexicon SET definition='Plain definition.', "
                   "extended_definition='Βοσόρ v. Βεώρ.'")
        db.execute(i18n.SCHEMA)
        for lang in i18n.LANGUAGES:
            for row in i18n.source_rows_with_hashes(db):
                db.execute('INSERT INTO lexicon_definition_i18n '
                           '(lemma, lang, definition, extended_definition, '
                           'source_definition_sha256, source_extended_sha256) '
                           'VALUES (?, ?, ?, ?, ?, ?)',
                           (row['lemma'], lang, 'Definição traduzida.',
                            row['extended_definition'], row['definition_sha256'],
                            row['extended_definition_sha256']))
        self.assertEqual(self._validate(db, '--require-full'), 0)

    def test_missing_source_hash_is_an_integrity_failure(self):
        db = make_db()
        db.execute(i18n.SCHEMA)
        db.execute("INSERT INTO lexicon_definition_i18n (lemma, lang, definition) "
                   "VALUES ('א', 'pt', 'Tradução sem origem verificada.')")
        self.assertEqual(self._validate(db), 1)

    def test_partial_field_translation_is_a_gap_not_corruption(self):
        db = make_db()
        db.execute(i18n.SCHEMA)
        db.execute('INSERT INTO lexicon_definition_i18n '
                   '(lemma, lang, definition, source_definition_sha256) VALUES (?, ?, ?, ?)',
                   ('א', 'pt', 'Primeira definição.', i18n.sha256_text('First definition.')))
        self.assertEqual(self._validate(db), 0)
        self.assertEqual(self._validate(db, '--require-full'), 1)


class TranslationResponseTest(unittest.TestCase):
    def test_partial_model_response_is_not_accepted_as_a_complete_batch(self):
        response = mock.MagicMock()
        response.read.return_value = b'{"choices":[{"message":{"content":"{\\"first\\":\\"Traduzido\\"}"}}]}'
        with mock.patch.object(translator.urllib.request, 'urlopen') as request:
            request.return_value.__enter__.return_value = response
            with self.assertRaises(ValueError):
                translator.request_batch('fake-test-key', 'test-model', 'pt',
                                         {'first': 'First text', 'second': 'Second text'}, 1, 100)


if __name__ == "__main__":
    unittest.main(verbosity=2)

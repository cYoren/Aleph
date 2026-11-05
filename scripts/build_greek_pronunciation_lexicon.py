#!/usr/bin/env python3
"""Generate a corpus-complete Greek pronunciation table for sherpa-onnx 2.

This is a build-time tool. eSpeak's code and dictionaries never enter the app;
only generated phoneme strings do. Reuses the verified voice's build data.
"""
from __future__ import annotations

import argparse
import ctypes
import hashlib
import json
import pathlib
import re
import sqlite3
import unicodedata

from generate_greek_monotonic import build_table

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUTPUT = ROOT / 'data' / 'greek_pronunciation_lexicon.txt'


def vocabulary(db: sqlite3.Connection) -> set[str]:
    table = build_table()
    words = set()
    queries = [
        "SELECT text FROM verses WHERE book_id IN (SELECT abbreviation FROM books WHERE testament='NT')",
        "SELECT word FROM words WHERE language='grc'",
        "SELECT lemma FROM lexicon WHERE strongs_id LIKE 'G%'",
    ]
    for query in queries:
        for (text,) in db.execute(query):
            folded = (text or '').translate(table)
            for word in re.findall(r'[^\W\d_]+', folded):
                if any('GREEK' in unicodedata.name(c, '') and c.isalpha() for c in word):
                    words.update((word, word.lower(), word.casefold()))
    # Typical word-level pronunciation examples used by the native smoke test.
    words.update(('λόγος', 'αγάπη'))
    return words


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--db', type=pathlib.Path, default=ROOT / 'assets' / 'bible.db')
    parser.add_argument('--voice-dir', type=pathlib.Path, default=ROOT / 'assets' / 'voices' / 'el_GR-rapunzelina-low')
    parser.add_argument('--espeak-library', type=pathlib.Path)
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--output', type=pathlib.Path, default=OUTPUT)
    args = parser.parse_args()
    with sqlite3.connect(args.db.resolve().as_uri() + '?mode=ro', uri=True) as db:
        words = vocabulary(db)
    if args.check:
        metadata = json.loads(args.output.with_suffix('.json').read_text())
        content = args.output.read_bytes()
        if hashlib.sha256(content).hexdigest() != metadata['sha256']:
            raise ValueError('Pronunciation table hash mismatch')
        keys = [line.split(' || ', 1)[0] for line in content.decode().splitlines()]
        if len(keys) != len(set(keys)) or not words.issubset(keys):
            raise ValueError(f'Pronunciation table has duplicate or missing words: {len(words - set(keys))} missing')
        print(f'OK: all {len(words)} Greek corpus/token/lemma forms have generated pronunciations')
        return 0
    if not args.espeak_library:
        parser.error('--espeak-library is required to regenerate the pronunciation table')
    engine = ctypes.CDLL(str(args.espeak_library.resolve()))
    engine.espeak_Info.argtypes = [ctypes.c_void_p]
    engine.espeak_Info.restype = ctypes.c_char_p
    version = engine.espeak_Info(None).decode()
    if not version.startswith('1.52.0'):
        raise ValueError(f'Expected pinned eSpeak NG 1.52.0; got {version}')
    engine.espeak_Initialize.argtypes = [ctypes.c_int, ctypes.c_int, ctypes.c_char_p, ctypes.c_int]
    if engine.espeak_Initialize(2, 0, str(args.voice_dir.resolve()).encode(), 0x8000) <= 0:
        raise RuntimeError('Could not initialize the build-time phonemizer')
    engine.espeak_SetVoiceByName.argtypes = [ctypes.c_char_p]
    if engine.espeak_SetVoiceByName(b'el') != 0:
        raise RuntimeError('Could not load the Greek build-time voice')
    engine.espeak_TextToPhonemes.argtypes = [ctypes.POINTER(ctypes.c_char_p), ctypes.c_int, ctypes.c_int]
    engine.espeak_TextToPhonemes.restype = ctypes.c_char_p
    tokens = {line.rsplit(' ', 1)[0] for line in (args.voice_dir / 'tokens.txt').read_text().splitlines()}
    lines = []
    for word in sorted(words):
        pointer = ctypes.c_char_p(word.encode())
        chunks = []
        while pointer.value:
            value = engine.espeak_TextToPhonemes(ctypes.byref(pointer), 1, 2)
            if value:
                chunks.extend(c for c in value.decode() if not c.isspace())
        if not chunks or set(chunks) - tokens:
            raise ValueError(f'{word}: unsupported phonemes: {set(chunks) - tokens}')
        lines.append(word + ' || ' + ' '.join(chunks))
    content = '\n'.join(lines) + '\n'
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(content, encoding='utf-8')
    metadata = {
        'generator': 'scripts/build_greek_pronunciation_lexicon.py',
        'espeak_version': version, 'voice': 'el', 'words': len(words),
        'sha256': hashlib.sha256(content.encode()).hexdigest(),
        'source': 'Bundled Greek New Testament text, token forms and lexicon lemmas',
        'note': 'Generated IPA output only; no eSpeak source code or dictionary data is distributed.',
    }
    args.output.with_suffix('.json').write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + '\n')
    print(f'Generated {len(lines)} corpus pronunciation entries: {args.output}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

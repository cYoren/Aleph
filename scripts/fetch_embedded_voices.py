#!/usr/bin/env python3
"""Prepare the verified Greek model and generated pronunciations, without GPL assets.

Uses sherpa-onnx 2 (Apache-2.0). The voice is MIT, its training dataset CC0.
The eSpeak tool may generate the lexicon during development, but neither its
code nor its dictionary data is included in a Flutter bundle.
Existing verified files and the original archive cache are reused.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import shutil
import sys
import tarfile
import urllib.request

REPO = pathlib.Path(__file__).resolve().parent.parent
DEST = REPO / 'assets' / 'voices'
VOICE = 'el_GR-rapunzelina-low'
URL = 'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-el_GR-rapunzelina-low.tar.bz2'
ARCHIVE_SHA = 'bb868070a9ba0d7220b3d7c9291a998c2f60accdb73525bd63b8751b86dd4839'
FILES = {
    'el_GR-rapunzelina-low.onnx': '7824cd5c9912e8aab9fce653f7af9d609c4e2e1d6e4c81d823699afa6d1b1537',
    'tokens.txt': '42d1a69ed2b91a51928a711aa228ed9f3dc021c6d359a3e9c4f37eb1d20f80bd',
}
LEXICON = REPO / 'data' / 'greek_pronunciation_lexicon.txt'


def sha256_of(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b''):
            digest.update(chunk)
    return digest.hexdigest()


def valid(path: pathlib.Path, expected: str) -> bool:
    return path.is_file() and sha256_of(path) == expected


def prepare(verify_only: bool) -> bool:
    target = DEST / VOICE
    metadata = json.loads(LEXICON.with_suffix('.json').read_text())
    expected = {**FILES, 'lexicon.txt': metadata['sha256']}
    if not valid(LEXICON, metadata['sha256']):
        raise ValueError('Generated pronunciation source does not match its pinned hash')
    missing = [name for name, digest in expected.items() if not valid(target / name, digest)]
    if verify_only:
        if missing:
            print(f'[FAIL] missing or altered assets: {missing}', file=sys.stderr)
            return False
        print(f'[ok] {VOICE}: all model, token and pronunciation hashes verified')
        return True
    target.mkdir(parents=True, exist_ok=True)
    model_missing = [name for name in missing if name in FILES]
    if model_missing:
        archive = DEST / '_archives' / URL.rsplit('/', 1)[1]
        if not archive.exists():
            archive.parent.mkdir(parents=True, exist_ok=True)
            partial = archive.with_suffix(archive.suffix + '.part')
            with urllib.request.urlopen(URL, timeout=60) as response, partial.open('wb') as output:
                shutil.copyfileobj(response, output)
            partial.replace(archive)
        if not valid(archive, ARCHIVE_SHA):
            raise ValueError('Voice archive hash does not match its pinned source')
        with tarfile.open(archive, 'r:bz2') as source:
            for member in source:
                name = pathlib.PurePosixPath(member.name).name
                if name in model_missing and member.isfile():
                    with source.extractfile(member) as incoming, (target / name).open('wb') as output:
                        shutil.copyfileobj(incoming, output)
    if 'lexicon.txt' in missing:
        shutil.copyfile(LEXICON, target / 'lexicon.txt')
    for name, digest in expected.items():
        if not valid(target / name, digest):
            raise ValueError(f'Prepared asset hash mismatch: {name}')
    manifest = {
        'generated_by': 'scripts/fetch_embedded_voices.py',
        'engine': {'name': 'sherpa-onnx', 'version': '2.0.1', 'license': 'Apache-2.0'},
        'voices': {VOICE: {'url': URL, 'archive_sha256': ARCHIVE_SHA, 'files': expected,
            'license': 'MIT weights / CC0 training data / generated IPA output',
            'pronunciation_entries': metadata['words']}},
        'not_shipped': {'he_IL': 'Hebrew uses the device voice; no bundled candidate has been validated.'},
        'notes': 'eSpeak code and dictionary data are build tools only and are not bundled.',
    }
    (DEST / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    print(f'[ok] {VOICE}: prepared {len(expected)} verified assets; reused unchanged model files')
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--list', action='store_true')
    parser.add_argument('--verify', action='store_true')
    args = parser.parse_args()
    if args.list:
        print(f'{VOICE}: available; MIT weights, CC0 data, generated IPA pronunciations')
        print('Hebrew: device voice; no bundled model is validated')
        return 0
    try:
        return 0 if prepare(args.verify) else 1
    except (OSError, ValueError, tarfile.TarError) as error:
        print(f'[FAIL] {error}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())

#!/usr/bin/env python3
"""Fetch and verify the offline TTS voices the app ships.

The voices are large (tens of MB) and are **not** committed to git. This script
is the reproducible preparation step: it downloads each voice from a pinned URL,
verifies its SHA-256, extracts it into `assets/voices/`, and writes a manifest.
`pubspec.yaml` lists `assets/voices/` so an app built without running this fails
loudly rather than shipping silent.

    python3 scripts/fetch_embedded_voices.py --list
    python3 scripts/fetch_embedded_voices.py            # fetch everything available
    python3 scripts/fetch_embedded_voices.py --verify   # re-check hashes only

What can and cannot be shipped
------------------------------
The engine is `sherpa-onnx` (Apache-2.0). The voices are Piper VITS models.

* **Greek (`el_GR`)** — `piper-el_GR-rapunzelina-low`. The weights come from the
  `rhasspy/piper-voices` repository (MIT); the training data is the Rapunzelina
  single-speaker Greek corpus, released CC0. Redistributable.

* **Hebrew (`he_IL`)** — **not shippable, and therefore not fetched.** The only
  Piper Hebrew voice (`he_IL/saspeech/medium`) was trained on the SASPEECH
  corpus (OpenSLR 134), whose licence is *"Custom non-commercial"*. It cannot be
  redistributed in an app distributed through the App Store or Play Store. No
  permissively licensed, mobile-sized Hebrew TTS model is known to exist as of
  this writing (see docs/tasks/embedded-voices-findings.md for the survey).
  Hebrew therefore keeps the device voice as its path.

* **Phonemizer data (`espeak-ng-data`)** — Piper models are phonemized with
  eSpeak NG, whose data is GPL-3.0. Attribution alone does not establish
  distribution compliance. Verify the exact components, corresponding-source
  requirements and distribution terms before shipping a store build. See
  docs/tasks/embedded-voices-findings.md. The generated manifest is build
  metadata, not a substitute for licenses or app credits.

Trimming the phonemizer data
----------------------------
The upstream Piper bundle ships eSpeak NG's dictionary for roughly a hundred
languages (~17 MB). A single-language voice reads exactly one of them, so the
other dictionaries are dead weight in the app bundle. After extraction each
voice keeps only the dictionaries named in its `espeak_dicts` entry; every
shared file the phonemizer needs (`phondata`, `phontab`, `phonindex`,
`intonations`, and the `lang/` and `voices/` trees) is left untouched. For the
Greek voice this drops ~17 MB to ~0.8 MB with no change to the phonemes
produced. Set `espeak_dicts` to `"all"` if a voice genuinely needs the full set.
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
DEST = REPO / "assets" / "voices"
MANIFEST = DEST / "manifest.json"

RELEASE = "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models"

VOICES = {
    # The Piper bundle already contains the espeak-ng-data directory the model
    # needs, so there is no separate phonemizer download.
    "el_GR-rapunzelina-low": {
        "url": f"{RELEASE}/vits-piper-el_GR-rapunzelina-low.tar.bz2",
        "sha256": "bb868070a9ba0d7220b3d7c9291a998c2f60accdb73525bd63b8751b86dd4839",
        "size": 67105521,
        "license": "MIT (engine weights) + CC0 (training data) + GPL-3.0 (espeak-ng-data)",
        "attribution": (
            "Piper el_GR/rapunzelina, converted by sherpa-onnx "
            "(https://huggingface.co/rhasspy/piper-voices). Training data: the "
            "Rapunzelina Greek single-speaker corpus (CC0). Phonemizer data: "
            "eSpeak NG (GPL-3.0) — verify license and source obligations before distribution."
        ),
        # Greek only: `el` is Modern Greek, `grc` is the Ancient Greek rules
        # the model also reaches for. Everything else in the bundle is unused.
        "espeak_dicts": ("el", "grc"),
    },
    "he_IL-saspeech-medium": {
        "url": f"{RELEASE}/vits-piper-he_IL-saspeech-medium.tar.bz2",
        "sha256": "",  # not fetched; see disabled reason
        "size": 0,
        "license": "NON-COMMERCIAL — must not ship",
        "attribution": "Piper he_IL/saspeech, trained on SASPEECH (OpenSLR 134)",
        "disabled": (
            "Not fetched: the SASPEECH training data is non-commercial, so this "
            "voice cannot be redistributed in the store app. Kept here as a "
            "record of why Hebrew has no bundled voice."
        ),
    },
}


def sha256_of(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def download(url: str, target: pathlib.Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    tmp = target.with_suffix(target.suffix + ".part")
    with urllib.request.urlopen(url) as response, tmp.open("wb") as out:
        shutil.copyfileobj(response, out)
    tmp.replace(target)


def fetch(name: str, spec: dict, verify_only: bool) -> bool:
    if spec.get("disabled"):
        print(f"[skip] {name}: disabled — {spec['disabled']}")
        return True

    archive = DEST / "_archives" / pathlib.Path(spec["url"]).name
    target_dir = DEST / name

    if not archive.exists():
        if verify_only:
            print(f"[fail] {name}: archive not present (run without --verify)")
            return False
        print(f"[get ] {name}: {spec['url']}")
        download(spec["url"], archive)

    got = sha256_of(archive)
    if got != spec["sha256"]:
        print(f"[FAIL] {name}: sha256 {got} != expected {spec['sha256']}", file=sys.stderr)
        return False
    print(f"[ok  ] {name}: sha256 verified")

    if verify_only:
        return True

    if target_dir.exists():
        shutil.rmtree(target_dir)
    target_dir.mkdir(parents=True, exist_ok=True)
    with tarfile.open(archive, "r:bz2") as tar:
        tar.extractall(target_dir)
    _flatten(target_dir)
    removed = prune_espeak_dicts(target_dir, spec.get("espeak_dicts"))
    print(f"[ok  ] {name}: extracted to {target_dir.relative_to(REPO)}")
    if removed:
        print(f"[ok  ] {name}: pruned {removed / 1048576:.1f} MB of unused eSpeak dictionaries")
    return True


def prune_espeak_dicts(directory: pathlib.Path, keep_langs) -> int:
    """Delete eSpeak NG dictionaries the voice never phonemizes with.

    eSpeak NG ships a dictionary per language (~17 MB in total). A voice that
    speaks one language reads one of them, so the rest is dead weight. Only
    `*_dict` files are considered; the shared tables and the `lang/` and
    `voices/` trees the phonemizer also loads are always kept.

    `keep_langs` is the voice's `espeak_dicts` entry: a tuple of language codes,
    or `"all"`/None to leave the extracted data untouched. Returns the number of
    bytes removed.
    """
    if not keep_langs or keep_langs == "all":
        return 0

    data = directory / "espeak-ng-data"
    if not data.is_dir():
        return 0

    keep = {f"{lang}_dict" for lang in keep_langs}
    removed = 0
    for path in sorted(data.glob("*_dict")):
        if path.name in keep:
            continue
        removed += path.stat().st_size
        path.unlink()
    return removed


def _flatten(directory: pathlib.Path) -> None:
    """Lift a single nested top-level directory up one level.

    The release tarballs wrap everything in a directory named after the voice;
    flattening gives stable asset paths (`<voice>/<voice>.onnx`, `tokens.txt`).
    """
    entries = [p for p in directory.iterdir()]
    if len(entries) == 1 and entries[0].is_dir():
        inner = entries[0]
        for child in list(inner.iterdir()):
            child.rename(directory / child.name)
        inner.rmdir()


def write_manifest() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    payload = {
        "generated_by": "scripts/fetch_embedded_voices.py",
        "engine": {"name": "sherpa-onnx", "license": "Apache-2.0"},
        "voices": {
            name: {
                k: (list(v) if isinstance(v, tuple) else v)
                for k, v in spec.items()
                if k
                in (
                    "url",
                    "sha256",
                    "size",
                    "license",
                    "attribution",
                    "disabled",
                    "espeak_dicts",
                )
            }
            for name, spec in VOICES.items()
        },
        "not_shipped": {
            "he_IL": (
                "No redistributable Hebrew TTS model is known to exist. The only "
                "Piper Hebrew voice uses the non-commercial SASPEECH dataset."
            ),
        },
        "notes": (
            "espeak_dicts lists the eSpeak NG language dictionaries kept in each "
            "voice's espeak-ng-data after extraction; every other language's "
            "dictionary is pruned to keep the bundle small. Shared phonemizer "
            "files are never pruned."
        ),
    }
    MANIFEST.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {MANIFEST.relative_to(REPO)}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--list", action="store_true", help="show what would be fetched")
    parser.add_argument("--verify", action="store_true", help="verify hashes without downloading")
    args = parser.parse_args()

    if args.list:
        for name, spec in VOICES.items():
            state = "disabled" if spec.get("disabled") else "available"
            print(f"{name:26} {spec['license']:32} {state}")
        return 0

    ok = True
    for name, spec in VOICES.items():
        ok &= fetch(name, spec, args.verify)
    if not ok:
        print("One or more voices could not be prepared.", file=sys.stderr)
        return 1
    if not args.verify:
        write_manifest()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

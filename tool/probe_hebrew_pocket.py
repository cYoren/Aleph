#!/usr/bin/env python3
"""Evaluate a pinned Hebrew ONNX candidate, outside the mobile application.

No paid API calls. Optional public model download at build/evaluation time only.
This is a CPU integration probe, not evidence of mobile or pronunciation quality.
Run using an isolated environment containing the upstream pocket-tts-onnx code.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import re
import resource
import socket
import sqlite3
import time
import urllib.request
import wave

REPO = pathlib.Path(__file__).resolve().parent.parent
MODEL_REVISION = "110f5251188e9407b4f724acdd8b0dfd0b20692a"
MODEL_SHA256 = "4c4592b7c5aadab2235ddc1409a0209aa164161a060543bf96a984298dfc6529"
MODEL_URL = (
    "https://huggingface.co/thewh1teagle/pocket-tts-onnx/resolve/"
    f"{MODEL_REVISION}/pocket-tts-english-ipa.onnx"
)


def digest(path):
    result = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            result.update(chunk)
    return result.hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=pathlib.Path, default=REPO / "assets/bible.db")
    parser.add_argument("--model", type=pathlib.Path,
                        default=pathlib.Path("/tmp/aleph-hebrew-evaluation/model.onnx"))
    parser.add_argument("--output", type=pathlib.Path,
                        default=pathlib.Path("/tmp/aleph-hebrew-evaluation/samples"))
    parser.add_argument("--voice")
    parser.add_argument("--fetch", action="store_true")
    parser.add_argument("--offline", action="store_true",
                        help="block Python network connections during the local inference probe")
    args = parser.parse_args()
    if args.offline and args.fetch:
        parser.error("--offline cannot be combined with --fetch")
    if args.offline:
        def no_network(*_args, **_kwargs):
            raise RuntimeError("Network connection attempted during offline inference")
        socket.create_connection = no_network
        socket.socket.connect = no_network
    if not args.model.exists() and args.fetch:
        args.model.parent.mkdir(parents=True, exist_ok=True)
        temporary = args.model.with_suffix(".onnx.part")
        with urllib.request.urlopen(MODEL_URL, timeout=60) as response, temporary.open("wb") as target:
            for chunk in iter(lambda: response.read(1024 * 1024), b""):
                target.write(chunk)
        if digest(temporary) != MODEL_SHA256:
            raise ValueError("Downloaded candidate failed SHA-256 verification")
        temporary.replace(args.model)
    if not args.model.exists() or digest(args.model) != MODEL_SHA256:
        raise ValueError("A verified candidate model is required; use --fetch to download it")

    import numpy as np
    import onnxruntime as ort
    from pocket_tts_onnx import PocketTTS

    before = time.perf_counter()
    tts = PocketTTS(args.model, num_threads=2)
    loaded_seconds = time.perf_counter() - before
    voices = tts.voices()
    voice = args.voice or next((name for name in ("omer", "male1") if name in voices), None)
    if voice is None or voice not in voices:
        raise ValueError(f"Specify a verified Hebrew voice with --voice. Available: {voices}")
    with sqlite3.connect(args.db.resolve().as_uri() + "?mode=ro", uri=True) as db:
        row = db.execute("SELECT text FROM verses WHERE book_id='GEN' AND chapter=1 "
                         "AND verse_number=1").fetchone()
    if not row:
        raise ValueError("Genesis 1:1 is absent from the source database")
    # Match the existing reader's speech preparation: retain niqqud, remove
    # cantillation and separate word/verse punctuation. No re-vocalization.
    prepared = re.sub(r"[\u0591-\u05AF]", "", row[0])
    prepared = prepared.replace("־", " ").replace("׀", " ").replace("׃", ".")
    prepared = " ".join(prepared.split())
    phrases = {"he-genesis-1-1": prepared, "he-word-bereshit": "בְּרֵאשִׁית"}
    args.output.mkdir(parents=True, exist_ok=True)
    results = []
    for name, text in phrases.items():
        before = time.perf_counter()
        # The Hebrew adapter accepts pointed text directly. Do not call the
        # upstream generic phonemizer (which can invoke eSpeak or a G2P model).
        samples, rate = tts.create(text, voice=voice, phonemes=True,
                                   temperature=0.3, decode_steps=2, seed=42)
        seconds = time.perf_counter() - before
        samples = np.asarray(samples, dtype=np.float32)
        if not len(samples) or not np.isfinite(samples).all():
            raise ValueError("Candidate generated empty or non-finite audio")
        duration = len(samples) / rate
        rms = float(np.sqrt(np.mean(samples ** 2)))
        if rms < 0.0001:
            raise ValueError("Candidate generated near-silent audio")
        path = args.output / f"{name}.wav"
        with wave.open(str(path), "wb") as audio:
            audio.setnchannels(1)
            audio.setsampwidth(2)
            audio.setframerate(rate)
            audio.writeframes((np.clip(samples, -1, 1) * 32767).astype("<i2").tobytes())
        results.append({"name": name, "text": text, "path": str(path),
                        "sample_rate": rate, "duration_seconds": duration,
                        "synthesis_seconds": seconds, "rms": rms,
                        "real_time_factor": seconds / duration})
        print(f"{name}: {duration:.2f}s audio; {seconds:.2f}s CPU wall time; RMS {rms:.4f}", flush=True)
    report = {"candidate_only": True, "model_revision": MODEL_REVISION,
              "model_sha256": MODEL_SHA256, "model_bytes": args.model.stat().st_size,
              "voice": voice, "available_voices": voices,
              "onnxruntime_version": ort.__version__,
              "load_seconds": loaded_seconds,
              "peak_rss_platform_units": resource.getrusage(resource.RUSAGE_SELF).ru_maxrss,
              "pronunciation_reviewed": False, "mobile_tested": False,
              "python_network_blocked": args.offline,
              "espeak_library_loaded": (
                  "libespeak" in pathlib.Path('/proc/self/maps').read_text()
                  if pathlib.Path('/proc/self/maps').exists() else None
              ),
              "samples": results}
    (args.output / "report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

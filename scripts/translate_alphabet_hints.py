#!/usr/bin/env python3
"""Translate the alphabet guide's sound hints into the app's other languages.

`assets/alphabet_hints.json` holds one short line per Hebrew and Greek letter
("b as in boy; without the dot inside, v as in vine"). English is authored by
hand; this fills the rest. It is about 54 lines per language — one request each,
so this is seconds of work and costs nothing on a free model.

The hints are the only part of the guide that needs translating: letter names
(Alef, Alpha) and transliterations are the same in every language, and the
example words take their meaning from the lexicon gloss instead.

    export OPENROUTER_API_KEY=sk-or-v1-...   # or put it in a gitignored .env
    python3 scripts/translate_alphabet_hints.py

Existing locale entries are never overwritten, so a hand-corrected line
survives a re-run. The app falls back to English for anything missing.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import sys
import urllib.request

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from _secrets import MISSING_MESSAGE, openrouter_api_key  # noqa: E402

REPO = pathlib.Path(__file__).resolve().parent.parent
HINTS = REPO / "assets" / "alphabet_hints.json"

ENDPOINT = "https://openrouter.ai/api/v1/chat/completions"
DEFAULT_MODEL = "nvidia/nemotron-3.5-lightning:free"

LANGUAGE_NAMES = {
    "pt": "Brazilian Portuguese",
    "de": "German",
    "fr": "French",
    "es": "Spanish",
    "ru": "Russian",
    "zh": "Simplified Chinese",
    "ko": "Korean",
}

SYSTEM_PROMPT = """You translate pronunciation hints for a Bible app that
teaches the Hebrew and Greek alphabets to complete beginners.

Each line describes the sound one letter makes, using an English keyword as the
example ("b as in boy").

Translate each line into {language}, and — this is the important part —
**replace the English example words with words in {language} that actually
contain the sound being described**. A Portuguese reader learning bet needs a
Portuguese word, not "boy". If {language} has no word with that sound, say so
briefly rather than inventing one.

Keep each line to one short sentence. Keep the register plain and warm; the
reader has never seen these letters before. Do not add commentary.

Return ONLY a JSON object mapping each input id to its translated line. No
prose, no code fence."""


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--languages", default=",".join(LANGUAGE_NAMES))
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--timeout", type=int, default=240)
    args = parser.parse_args()

    api_key = openrouter_api_key()
    if not api_key:
        print(MISSING_MESSAGE, file=sys.stderr)
        return 2

    with HINTS.open(encoding="utf-8") as handle:
        data = json.load(handle)

    english = data.get("en")
    if not english:
        print("assets/alphabet_hints.json has no `en` block.", file=sys.stderr)
        return 2

    for lang in (item.strip() for item in args.languages.split(",")):
        if not lang:
            continue
        if lang not in LANGUAGE_NAMES:
            print(f"Unknown language: {lang}", file=sys.stderr)
            return 2

        existing = data.get(lang, {})
        pending = {k: v for k, v in english.items() if k not in existing}
        if not pending:
            print(f"[{lang}] already complete")
            continue

        items = list(pending.items())
        batch_size = 6
        translated: dict[str, str] = {}

        for start in range(0, len(items), batch_size):
            batch = dict(items[start : start + batch_size])
            body = {
                "model": args.model,
                "reasoning": {"exclude": True},
                "max_tokens": 8192,
                "temperature": 0.2,
                "messages": [
                    {
                        "role": "system",
                        "content": SYSTEM_PROMPT.format(
                            language=LANGUAGE_NAMES[lang]
                        ),
                    },
                    {"role": "user", "content": json.dumps(batch, ensure_ascii=False)},
                ],
            }

            request = urllib.request.Request(
                ENDPOINT,
                data=json.dumps(body).encode("utf-8"),
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json",
                },
            )

            batch_res = {}
            for attempt in range(1, 4):
                try:
                    with urllib.request.urlopen(request, timeout=args.timeout) as response:
                        payload = json.loads(response.read().decode("utf-8"))

                    content = payload["choices"][0]["message"]["content"].strip()
                    if content.startswith("```"):
                        content = content.split("\n", 1)[1].rsplit("```", 1)[0]

                    parsed = json.loads(content)
                    if isinstance(parsed, dict):
                        batch_res = {
                            key: value.strip()
                            for key, value in parsed.items()
                            if key in batch and isinstance(value, str) and value.strip()
                        }
                    if batch_res:
                        break
                except Exception as e:
                    print(f"[{lang}] hint batch at {start} error ({e}), retry {attempt}/3", file=sys.stderr)

            translated.update(batch_res)
            data[lang] = {**existing, **translated}
            with HINTS.open("w", encoding="utf-8") as handle:
                json.dump(data, handle, ensure_ascii=False, indent=2)
                handle.write("\n")

        print(f"[{lang}] +{len(translated)} of {len(pending)}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

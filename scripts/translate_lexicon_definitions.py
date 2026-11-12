#!/usr/bin/env python3
"""Translate the long-form lexicon content (definition + extended_definition).

This is the expensive half of the localisation, and the one the short-gloss job
deliberately left alone: `lexicon.definition` (composed from Strong's) and
`lexicon.extended_definition` (BDB / Abbott-Smith). Together they are about
3.6 million characters of English across the seven target languages' worth of
output — far too much to do inline, and worth paying for exactly once.

Design, in the same shape as `translate_glosses.py`:

* **Resumable.** The cache under `data/lexicon_translations/<lang>.json` is keyed
  by the SHA-256 of the exact source text. A run can be interrupted and
  restarted for free, and a rebuilt database costs nothing.
* **Deduplicating.** Provably identical source texts are translated once and
  fanned back out to every entry that shares them
  (`lexicon_definitions_i18n.write_lexicon_translations`).
* **Safe by default.** Without `--apply` it only reports what it *would* send
  and the estimated cost. A paid run is an explicit, deliberate act.
* **Online at build time only.** Nothing here ships in the app; the app reads
  the frozen cache out of the local database.

Usage
-----
    # what would run, and roughly what it costs — no key needed
    python3 scripts/translate_lexicon_definitions.py --estimate

    # the real thing, one language at a time, resumable
    export OPENROUTER_API_KEY=sk-or-v1-...
    python3 scripts/translate_lexicon_definitions.py --apply --languages pt

    # fold the result into the release database
    python3 scripts/apply_lexicon_translations.py

The database is generated and not committed; the cache under
`data/lexicon_translations/` is the durable output and should be.
"""

from __future__ import annotations

import argparse
import json
import os
import pathlib
import sqlite3
import sys
import time
import urllib.error
import urllib.request

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from _secrets import MISSING_MESSAGE, openrouter_api_key  # noqa: E402
from lexicon_definitions_i18n import (  # noqa: E402
    CACHE_DIR,
    DEFAULT_DB,
    FIELDS,
    LANGUAGES,
    TRANSLATION_REVISION,
    empty_cache,
    estimate,
    load_cache,
    save_cache,
    unique_source_texts,
)

ENDPOINT = os.environ.get(
    "TRANSLATION_ENDPOINT", "https://openrouter.ai/api/v1/chat/completions"
)
DEFAULT_MODEL = "openai/gpt-4o-mini"

SYSTEM_PROMPT = """You translate dictionary entries for an offline Hebrew and \
Greek Bible reader. You translate English lexicon content into {language}.

Each input is one English entry: either a Strong's dictionary definition or a \
scholarly lexicon entry (Brown-Driver-Briggs for Hebrew, Abbott-Smith for \
Greek). Translate the whole entry, faithfully and completely.

Absolute rules:
- Keep every Hebrew and Greek word exactly as it is, including vowel points and \
accents. Do not transliterate them and do not translate them.
- Keep every biblical reference exactly as written (e.g. "Gen 1:1", "Matt 5:3", \
"Ps 23").
- Keep every Strong's number exactly as written (e.g. H0430, G26, H0871A).
- Keep the edition and work labels verbatim: KJV, BDB, LXX, MT, Targ, q.v., cf.
  Never replace KJV with a translation of the target language (not RVR, not
  LUT, not ARC, not 和合本): it names the source the renderings come from.
- Keep scholarly abbreviations that a reader would look up (e.g. BDB, LXX, MT, \
Targ, cf., q.v., Aram, cf. Syr) recognisable; translate only ordinary prose.
- Keep all numbered or lettered senses in the same order and keep the \
distinctions between them. Do not merge senses and do not add senses that are \
not there.
- Keep parenthetical markers such as "(et)" or "(as)" exactly where they are.
- Do not add commentary, exegesis, transliteration, or alternative readings \
that the original does not contain. If a phrase is ambiguous, translate it \
literally rather than guessing.

Return ONLY a JSON object mapping each input id to its translated entry, with \
no prose and no code fence."""


def read_pending(lang: str, db_path: pathlib.Path, args: argparse.Namespace) -> dict:
    """Unique source texts per field that are not yet in this language's cache."""
    db = sqlite3.connect(db_path)
    try:
        unique = unique_source_texts(db)
    finally:
        db.close()

    cache = load_cache(lang)
    pending: dict[str, dict[str, str]] = {}
    for field in FIELDS:
        todo = {
            digest: text
            for digest, text in unique.get(field, {}).items()
            if digest not in cache.get(field, {})
        }
        if args.limit:
            todo = dict(list(todo.items())[: args.limit])
        pending[field] = todo
    return pending


def request_batch(
    api_key: str,
    model: str,
    language: str,
    batch: dict[str, str],
    timeout: int,
    max_tokens: int,
) -> dict[str, str]:
    body = {
        "model": model,
        "max_tokens": max_tokens,
        "temperature": 0,
        "messages": [
            {
                "role": "system",
                "content": SYSTEM_PROMPT.format(language=LANGUAGES[language]),
            },
            {"role": "user", "content": json.dumps(batch, ensure_ascii=False)},
        ],
    }
    # OpenRouter only: ask it not to spend output on chain-of-thought. The
    # OpenCode relay ignores the flag and returns an empty content field when
    # it is present, so it is sent only to the endpoint that understands it.
    if "openrouter.ai" in ENDPOINT:
        body["reasoning"] = {"exclude": True}
    else:
        # The OpenCode relay honours the OpenAI-style switch. Without it the
        # model spends most of the wall clock on chain-of-thought: five short
        # entries took about a minute per batch.
        body["reasoning_effort"] = "none"

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        # Cloudflare in front of the OpenCode relay rejects the default
        # urllib User-Agent with error 1010.
        "User-Agent": "AlephLexiconTranslate/1.0",
    }
    session = os.environ.get("OPENCODE_SESSION")
    if session:
        headers["x-opencode-session"] = session

    request = urllib.request.Request(
        ENDPOINT,
        data=json.dumps(body).encode("utf-8"),
        headers=headers,
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        payload = json.loads(response.read().decode("utf-8"))

    content = payload["choices"][0]["message"]["content"].strip()
    if content.startswith("```"):
        content = content.split("\n", 1)[1].rsplit("```", 1)[0]
    parsed = json.loads(content)
    if not isinstance(parsed, dict):
        raise ValueError("model did not return a JSON object")
    result = {
        key: value.strip()
        for key, value in parsed.items()
        if key in batch and isinstance(value, str) and value.strip()
    }
    if set(result) != set(batch):
        raise ValueError('model response omitted entries or returned empty translations')
    return result


def translate_language(
    lang: str,
    db_path: pathlib.Path,
    api_key: str,
    args: argparse.Namespace,
) -> bool:
    pending = read_pending(lang, db_path, args)
    total = sum(len(batch) for batch in pending.values())
    if total == 0:
        cache = load_cache(lang)
        cached = sum(len(cache.get(f, {})) for f in FIELDS)
        print(f"[{lang}] nothing to do ({cached} unique texts cached)")
        return True

    cache = load_cache(lang)
    print(
        f"[{lang}] {pending['definition'].__len__()} definitions + "
        f"{pending['extended_definition'].__len__()} extended to translate "
        f"({total} unique texts)"
    )

    succeeded = True
    for field in FIELDS:
        items = list(pending[field].items())
        if not items:
            continue
        for start in range(0, len(items), args.batch_size):
            batch = dict(items[start : start + args.batch_size])
            for attempt in range(1, args.retries + 1):
                try:
                    result = request_batch(
                        api_key, args.model, lang, batch, args.timeout, args.max_tokens
                    )
                    cache[field].update(result)
                    save_cache(lang, cache)
                    print(
                        f"[{lang}/{field}] {start + len(batch)}/{len(items)} "
                        f"(+{len(result)})"
                    )
                    break
                except (urllib.error.HTTPError, urllib.error.URLError) as exc:
                    status = getattr(exc, "code", None)
                    if status in (401, 403):
                        print(
                            f"[{lang}] the API key was rejected ({status}). "
                            "Nothing translated so far is lost; re-run after "
                            "fixing OPENROUTER_API_KEY.",
                            file=sys.stderr,
                        )
                        return False
                    wait = args.backoff * attempt
                    print(
                        f"[{lang}/{field}] batch at {start} failed "
                        f"({status or exc}); retry {attempt}/{args.retries} "
                        f"in {wait}s",
                        file=sys.stderr,
                    )
                    time.sleep(wait)
                except (ValueError, KeyError, json.JSONDecodeError) as exc:
                    print(
                        f"[{lang}/{field}] batch at {start} returned unusable "
                        f"output ({exc}); retry {attempt}/{args.retries}",
                        file=sys.stderr,
                    )
                    time.sleep(args.backoff)
            else:
                succeeded = False
                print(f"[{lang}/{field}] giving up on batch at {start}", file=sys.stderr)
            time.sleep(args.delay)

    cached = sum(len(cache.get(f, {})) for f in FIELDS)
    print(f"[{lang}] done: {cached} unique texts cached")
    return succeeded


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=pathlib.Path, default=DEFAULT_DB)
    parser.add_argument(
        "--languages",
        default=",".join(LANGUAGES),
        help="comma-separated locales to fill (default: all seven)",
    )
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--batch-size", type=int, default=5)
    parser.add_argument("--max-tokens", type=int, default=16000)
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--timeout", type=int, default=240)
    parser.add_argument("--retries", type=int, default=4)
    parser.add_argument("--delay", type=float, default=1.5)
    parser.add_argument("--backoff", type=float, default=8.0)
    parser.add_argument(
        "--estimate",
        action="store_true",
        help="print what would be sent and the estimated cost, then exit",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="actually call the API and spend budget; without this it is a dry run",
    )
    args = parser.parse_args()

    if not args.db.exists():
        print(f"No database at {args.db}. Build it first.", file=sys.stderr)
        return 2

    languages = [lang.strip() for lang in args.languages.split(",") if lang.strip()]
    unknown = [lang for lang in languages if lang not in LANGUAGES]
    if not languages or unknown:
        print(f"Unknown language(s): {', '.join(unknown)}", file=sys.stderr)
        return 2
    if args.batch_size < 1 or args.retries < 1 or args.limit < 0:
        print('Batch size and retries must be positive; limit cannot be negative.', file=sys.stderr)
        return 2

    db = sqlite3.connect(args.db)
    try:
        unique = unique_source_texts(db)
    finally:
        db.close()

    plan = estimate(unique, languages)
    print("Long-form lexicon translation plan")
    for field, stats in plan["per_field"].items():
        print(
            f"  {field}: {stats['unique_texts']} unique texts, "
            f"{stats['source_chars']:,} chars (~{stats['approx_source_tokens']:,} tokens)"
        )
    print(f"  languages: {', '.join(languages)}")
    for key, cost in plan["cost_usd"].items():
        print(f"  ~US$ {cost['usd']:,.2f} — {cost['label']}")

    if not args.apply:
        print(
            "\nDry run. Nothing was sent and nothing was spent. Re-run with "
            "--apply once the model and budget are confirmed."
            if not args.estimate
            else "\nEstimate only."
        )
        return 0

    api_key = os.environ.get("TRANSLATION_API_KEY") or openrouter_api_key()
    if not api_key:
        print(MISSING_MESSAGE, file=sys.stderr)
        return 2

    for lang in languages:
        cache = load_cache(lang)
        cache["_meta"].update(
            {
                "provider": os.environ.get("TRANSLATION_PROVIDER", "openrouter"),
                "model": args.model,
                "revision": TRANSLATION_REVISION,
            }
        )
        save_cache(lang, {**empty_cache(lang), **cache})
        if not translate_language(lang, args.db, api_key, args):
            return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

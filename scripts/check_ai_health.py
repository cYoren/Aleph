#!/usr/bin/env python3
"""Check whether an explanation model is still fit to ship.

The failure this catches is the quiet one. A hosted model can degrade without
anything in our code changing — the provider swaps weights behind an id, or a
reasoning model starts leaking its chain of thought — and every request still
returns HTTP 200. Nothing throws; the answers just get worse.

So this runs a fixed set of passages through a model and grades the output on
the things that actually break:

  * leaked reasoning ("Here's a thinking process: ...")
  * truncation (cut off mid-sentence, usually a max_tokens problem)
  * an outline where prose was asked for
  * an answer too short to be an explanation
  * latency

Run it before a release, and whenever answers "feel worse". Compare two models
to decide what to switch to.

    export OPENROUTER_API_KEY=sk-or-v1-...
    python3 scripts/check_ai_health.py
    python3 scripts/check_ai_health.py --model deepseek/deepseek-v4.1-flash-1017
    python3 scripts/check_ai_health.py --compare

Exits non-zero if a model fails the bar, so it can gate a release in CI.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import statistics
import sys
import time
import urllib.error
import urllib.request

ENDPOINT = "https://openrouter.ai/api/v1/chat/completions"

FREE_MODEL = "nvidia/nemotron-3.5-lightning:free"
PRO_MODEL = "deepseek/deepseek-v4.1-flash-1017"

# Mirrors lib/features/explain/explain_model.dart. The two models want opposite
# treatment: deepseek honours reasoning effort (low roughly halves latency and
# cost), the free nemotron ignores it and needs a bigger budget instead.
MODEL_SETTINGS = {
    FREE_MODEL: {"max_tokens": 4000, "effort": None},
    PRO_MODEL: {"max_tokens": 3000, "effort": "low"},
}
DEFAULT_SETTINGS = {"max_tokens": 4000, "effort": None}

# Kept in step with buildExplainSystemPrompt() in
# lib/features/explain/explain_model.dart. If you change one, change both —
# grading against a different prompt than the app ships tells you nothing.
SYSTEM_PROMPT = """\
You are a tutor for readers studying the Bible in its original languages: Biblical Hebrew, Aramaic, and Koine Greek.

Your reader is a motivated beginner. They can see the original text and a translation side by side, and they want to understand what the original actually says.

How to answer:
- Lead with what the passage means. Do not restate the translation back to them.
- Point out where the original wording carries something the translation cannot.
- Quote the original word, then give it in Latin letters, then say what it means.
- Explain any grammatical term the first time you use it, in a few words.
- Be accurate above all. If you are unsure, say you are unsure.
- Do not preach, moralize, or give devotional application.

Format:
- 150 words maximum.
- Plain prose. You may use **bold** for original-language words.
- Reply with the explanation only.

Write your answer in English."""

# A spread of Hebrew and Greek, easy and hard. Each carries a term the answer
# should plausibly mention, used as a weak relevance signal.
CASES = [
    {
        "ref": "Genesis 1:1",
        "lang": "Hebrew",
        "text": "בְּרֵאשִׁית בָּרָא אֱלֹהִים אֵת הַשָּׁמַיִם וְאֵת הָאָרֶץ׃",
        "translation": "In the beginning God created the heaven and the earth.",
        "expect_any": ["bara", "בָּרָא", "elohim", "אֱלֹהִים", "beginning"],
    },
    {
        "ref": "Psalm 23:1",
        "lang": "Hebrew",
        "text": "יְהוָה רֹעִי לֹא אֶחְסָר׃",
        "translation": "The LORD is my shepherd; I shall not want.",
        "expect_any": ["shepherd", "רֹעִי", "roi", "YHWH", "יְהוָה"],
    },
    {
        "ref": "John 1:1",
        "lang": "Greek",
        "text": "Ἐν ἀρχῇ ἦν ὁ λόγος, καὶ ὁ λόγος ἦν πρὸς τὸν θεόν.",
        "translation": "In the beginning was the Word, and the Word was with God.",
        "expect_any": ["logos", "λόγος", "pros", "πρὸς", "word"],
    },
    {
        "ref": "Romans 3:23",
        "lang": "Greek",
        "text": "πάντες γὰρ ἥμαρτον καὶ ὑστεροῦνται τῆς δόξης τοῦ θεοῦ.",
        "translation": "For all have sinned, and come short of the glory of God.",
        "expect_any": ["hamartano", "ἥμαρτον", "doxa", "δόξης", "glory", "sin"],
    },
]

REASONING_TELLS = [
    "here's a thinking process",
    "here is a thinking process",
    "thinking process:",
    "let me analyze the request",
    "<think>",
    "step 1:",
]


def grade(text: str, expect_any: list[str]) -> list[str]:
    """Return the problems with an answer; empty means it passed."""
    problems: list[str] = []
    stripped = text.strip()
    lower = stripped.lower()

    if not stripped:
        return ["empty"]

    if any(tell in lower for tell in REASONING_TELLS):
        problems.append("leaked reasoning")

    if re.match(r"^\s*\d+\.\s", stripped):
        problems.append("outline not prose")

    if len(stripped) < 80:
        problems.append("too short")

    if not re.search(r"""[.!?"'”’)\]]\s*$""", stripped):
        problems.append("truncated")

    if not any(term.lower() in lower for term in expect_any):
        problems.append("did not engage the passage")

    return problems


def call(model: str, case: dict, api_key: str, max_tokens: int | None) -> tuple[str, float, float]:
    settings = MODEL_SETTINGS.get(model, DEFAULT_SETTINGS)
    reasoning: dict = {"exclude": True}
    if settings["effort"]:
        reasoning["effort"] = settings["effort"]

    body = json.dumps(
        {
            "model": model,
            "max_tokens": max_tokens or settings["max_tokens"],
            "temperature": 0.3,
            "reasoning": reasoning,
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {
                    "role": "user",
                    "content": (
                        f"Reference: {case['ref']}\n"
                        f"Original ({case['lang']}): {case['text']}\n"
                        f"Translation: {case['translation']}\n\n"
                        "Explain this passage."
                    ),
                },
            ],
        }
    ).encode()

    request = urllib.request.Request(
        ENDPOINT,
        data=body,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "X-Title": "Aleph health check",
        },
    )

    started = time.time()
    with urllib.request.urlopen(request, timeout=120) as response:
        payload = json.load(response)
    elapsed = time.time() - started

    if "error" in payload:
        raise RuntimeError(payload["error"])

    text = payload["choices"][0]["message"].get("content") or ""
    cost = (payload.get("usage") or {}).get("cost") or 0.0
    return text, elapsed, cost


def check(model: str, api_key: str, max_tokens: int | None, verbose: bool) -> bool:
    print(f"\n=== {model} ===")
    latencies: list[float] = []
    total_cost = 0.0
    failures = 0

    for case in CASES:
        try:
            text, elapsed, cost = call(model, case, api_key, max_tokens)
        except (urllib.error.URLError, RuntimeError, TimeoutError) as error:
            print(f"  {case['ref']:<14} REQUEST FAILED: {error}")
            failures += 1
            continue

        latencies.append(elapsed)
        total_cost += cost
        problems = grade(text, case["expect_any"])

        if problems:
            failures += 1
            print(f"  {case['ref']:<14} {elapsed:5.1f}s  FAIL: {', '.join(problems)}")
        else:
            print(f"  {case['ref']:<14} {elapsed:5.1f}s  ok")

        if verbose:
            print(f"      {text.strip()[:300]}")

    passed = len(CASES) - failures
    median = statistics.median(latencies) if latencies else 0.0

    print(f"  ---")
    print(f"  passed:  {passed}/{len(CASES)}")
    print(f"  median:  {median:.1f}s")
    print(f"  cost:    ${total_cost:.4f} for {len(CASES)} explanations")

    healthy = failures == 0 and median < 25
    if not healthy:
        print(f"  VERDICT: NOT HEALTHY — consider switching model")
    else:
        print(f"  VERDICT: healthy")
    return healthy


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model", help="model id to check")
    parser.add_argument(
        "--compare",
        action="store_true",
        help="check both the free and pro models",
    )
    parser.add_argument(
        "--max-tokens",
        type=int,
        default=None,
        help="override the per-model budget",
    )
    parser.add_argument("--verbose", action="store_true", help="print answers")
    args = parser.parse_args()

    api_key = os.environ.get("OPENROUTER_API_KEY", "").strip()
    if not api_key:
        print("Set OPENROUTER_API_KEY first.", file=sys.stderr)
        raise SystemExit(2)

    if args.compare:
        models = [FREE_MODEL, PRO_MODEL]
    elif args.model:
        models = [args.model]
    else:
        models = [FREE_MODEL]

    results = [check(m, api_key, args.max_tokens, args.verbose) for m in models]
    raise SystemExit(0 if all(results) else 1)


if __name__ == "__main__":
    main()

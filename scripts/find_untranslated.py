#!/usr/bin/env python3
"""Report UI strings that are still English in a non-English locale.

Two ways a string ends up untranslated:

1. It was added to `app_en.arb` and copied verbatim into the other locales so
   that key parity holds and the app falls back to English instead of crashing.
2. It is hardcoded in Dart and never went through the ARB files at all.

This finds the first kind by comparing each locale's value against English, and
the second by scanning Dart widgets for user-facing string literals. Both feed
`queue.md`, so a scheduled worker can translate a precise batch instead of
re-deriving what is missing.

Usage:
    python3 scripts/find_untranslated.py
    python3 scripts/find_untranslated.py --format queue   # markdown for queue.md
    python3 scripts/find_untranslated.py --locale de
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re

L10N_DIR = pathlib.Path("lib/l10n")
LIB_DIR = pathlib.Path("lib")
LOCALES = ["pt", "de", "fr", "es", "ru", "zh", "ko"]

# Strings that are legitimately identical across languages: fixed acronyms, or
# short/abbreviated forms that happen to converge between cognate languages.
# Verified by hand against every locale before being added here - do not add a
# key just because it is failing the check.
ALLOWED_IDENTICAL = {
    "appTitle",
    "KJV",
    "cnpjLabel",  # "CNPJ" - a Brazilian tax-ID acronym, not a translatable word
    "themeSystem",  # "System" is also correct German
    "posVerb",  # "Verb" is also correct German
    "posAdjectiveShort",  # "Adj." converges across en/pt/de/fr/es
    "posPrepositionShort",  # "Prep." converges across en/pt/es
    "posConjunctionShort",  # "Conj." converges across en/pt/es
    "error",  # "Error" is also correct Spanish
}

# Same idea, but the convergence holds for one locale only. A grammar label
# such as "singular" is genuinely a cognate in Portuguese and Spanish while
# still needing a translation in, say, Chinese; a global allow-list would hide
# a real gap in the other five languages.
ALLOWED_IDENTICAL_BY_LOCALE = {
    "pt": {
        "alphabetFinalForm",  # "final" is also correct Portuguese
        "traditionJewish",  # "Tanakh" is the standard Portuguese spelling
        "morphSingular",
        "morphPlural",
        "morphDual",
        "morphPronominal",
    },
    "es": {
        "alphabetFinalForm",  # "final" is also correct Spanish
        "morphSingular",
        "morphPlural",
        "morphDual",
        "morphPersonal",
        "morphPronominal",
    },
    "de": {
        "morphAdverb",
        "morphSuffix",
        "morphVerb",
        "morphPersonal",
        "morphPronominal",
        "morphAorist",
    },
    "fr": {
        "alphabetFinalForm",  # "final" is also correct French
        "traditionJewish",  # "Tanakh" is the standard French spelling
        "tanakhTorah",  # "Torah" is the standard French spelling
        "morphArticle",
        "morphInterjection",
        "morphPronominal",
    },
}


def load(locale: str) -> dict:
    path = L10N_DIR / f"app_{locale}.arb"
    if not path.exists():
        return {}
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def untranslated(locale: str) -> list[tuple[str, str]]:
    """Keys whose value is byte-identical to English."""
    english = load("en")
    target = load(locale)

    result = []
    allowed = ALLOWED_IDENTICAL | ALLOWED_IDENTICAL_BY_LOCALE.get(locale, set())
    for key, value in english.items():
        if key.startswith("@") or key.startswith("@@"):
            continue
        if key in allowed:
            continue
        if not isinstance(value, str):
            continue
        if target.get(key) == value:
            result.append((key, value))
    return result


# Widget constructors whose string arguments reach the screen.
_USER_FACING = re.compile(
    r"""(?:Text|SnackBar|tooltip:|title:|subtitle:|label:|hintText:|helperText:)"""
)
_LITERAL = re.compile(r"""(['"])((?:(?!\1)[^\\]|\\.){4,}?)\1""")
_LOOKS_TECHNICAL = re.compile(
    r"^(?:[a-z0-9_]+|assets/|package:|https?://|[A-Z_]+)$"
)


def hardcoded_strings() -> list[tuple[str, int, str]]:
    """User-facing literals in Dart that never went through the ARB files."""
    findings = []
    for path in sorted(LIB_DIR.rglob("*.dart")):
        if "l10n/generated" in str(path):
            continue
        for number, line in enumerate(
            path.read_text(encoding="utf-8").splitlines(), start=1
        ):
            stripped = line.strip()
            if stripped.startswith("//") or stripped.startswith("///"):
                continue
            if not _USER_FACING.search(line):
                continue
            for _, literal in _LITERAL.findall(line):
                if _LOOKS_TECHNICAL.match(literal):
                    continue
                if not re.search(r"[A-Za-z]{2,}\s", literal + " "):
                    continue
                findings.append((str(path), number, literal))
    return findings


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--locale", help="check one locale only")
    parser.add_argument(
        "--format", choices=["text", "queue"], default="text"
    )
    args = parser.parse_args()

    locales = [args.locale] if args.locale else LOCALES

    if args.format == "queue":
        print("<!-- generated by scripts/find_untranslated.py -->")

    total = 0
    for locale in locales:
        missing = untranslated(locale)
        total += len(missing)
        if not missing:
            print(f"{locale}: fully translated")
            continue

        print(f"\n{locale}: {len(missing)} strings still in English")
        for key, value in missing:
            print(f"  {key}: {value}" if args.format == "text" else f"- `{key}`: {value}")

    hardcoded = hardcoded_strings()
    if hardcoded:
        print(f"\nHardcoded in Dart, never localized: {len(hardcoded)}")
        for path, number, literal in hardcoded:
            print(f"  {path}:{number}  {literal}")

    print(f"\ntotal untranslated ARB values: {total}")


if __name__ == "__main__":
    main()

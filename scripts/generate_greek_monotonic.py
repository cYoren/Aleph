#!/usr/bin/env python3
"""Generate the polytonic -> monotonic Greek mapping used by the TTS layer.

Platform speech engines speak modern (monotonic) Greek and do not know the
Greek Extended block, so the polytonic text of the SBLGNT has to be folded down
before it can be spoken. Monotonic Greek keeps the acute and the diaeresis and
drops everything else, so for each polytonic character we keep the base letter,
keep any diaeresis, collapse acute/grave/circumflex to a single acute, and drop
the breathings and the iota subscript.

Dart has no Unicode normalisation in its core library, hence this table.

Usage:
    python3 scripts/generate_greek_monotonic.py \
        --output lib/shared/utils/greek_monotonic.dart
"""

from __future__ import annotations

import argparse
import unicodedata

# Combining marks, by role.
ACUTE = "́"
GRAVE = "̀"
CIRCUMFLEX = "͂"
SMOOTH = "̓"
ROUGH = "̔"
DIAERESIS = "̈"
IOTA_SUBSCRIPT = "ͅ"
MACRON = "̄"
BREVE = "̆"

ACCENTS = {ACUTE, GRAVE, CIRCUMFLEX}
DROPPED = {SMOOTH, ROUGH, IOTA_SUBSCRIPT, MACRON, BREVE}

# Ranges that can carry polytonic marks.
RANGES = [
    (0x0370, 0x03FF),  # Greek and Coptic
    (0x1F00, 0x1FFF),  # Greek Extended
]


def to_monotonic(ch: str) -> str:
    """Fold one character to its monotonic equivalent."""
    decomposed = unicodedata.normalize("NFD", ch)
    if len(decomposed) == 1:
        return ch

    base = decomposed[0]
    marks = decomposed[1:]

    has_accent = any(m in ACCENTS for m in marks)
    has_diaeresis = DIAERESIS in marks

    rebuilt = base
    if has_diaeresis:
        rebuilt += DIAERESIS
    if has_accent:
        rebuilt += ACUTE

    return unicodedata.normalize("NFC", rebuilt)


def build_table() -> dict[int, str]:
    table: dict[int, str] = {}
    for start, end in RANGES:
        for cp in range(start, end + 1):
            ch = chr(cp)
            if not unicodedata.name(ch, ""):
                continue
            folded = to_monotonic(ch)
            if folded != ch:
                table[cp] = folded
    return table


def render_dart(table: dict[int, str]) -> str:
    lines = [
        "// GENERATED FILE - DO NOT EDIT BY HAND.",
        "// Regenerate with:",
        "//   python3 scripts/generate_greek_monotonic.py \\",
        "//       --output lib/shared/utils/greek_monotonic.dart",
        "//",
        "// Polytonic -> monotonic Greek. Platform speech engines speak modern",
        "// Greek and do not know the Greek Extended block, so the polytonic",
        "// text has to be folded down before it can be spoken. The acute and",
        "// the diaeresis survive; breathings, the iota subscript, and the",
        "// grave/circumflex distinction do not.",
        "library;",
        "",
        "/// Code unit -> replacement string for every polytonic character.",
        "const Map<int, String> kGreekMonotonicFolding = {",
    ]

    for cp in sorted(table):
        replacement = table[cp]
        escaped = "".join(f"\\u{ord(c):04X}" for c in replacement)
        name = unicodedata.name(chr(cp), "?")
        lines.append(f"  0x{cp:04X}: '{escaped}', // {name}")

    lines.append("};")
    lines.append("")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    table = build_table()
    with open(args.output, "w", encoding="utf-8") as handle:
        handle.write(render_dart(table))

    print(f"wrote {len(table)} mappings to {args.output}")


if __name__ == "__main__":
    main()

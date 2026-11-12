#!/usr/bin/env python3
"""Compact the release database and pack the asset the app ships.

Run this after `build_full_bible_db.py` (and after the gloss / lexicon
post-steps it documents) and before `scripts/validate_release.sh`. It changes
nothing a reader can observe; it only changes how the same data is stored.

Two transformations, both lossless:

1. **Compact `assets/bible.db` in place.** MACULA stores one JSON syntax-tree
   document per verse, which costs ~52 MB of the file. Re-storing them as one
   gzip block per book returns byte-identical JSON for every verse while
   shrinking that to ~5 MB. The now-dead `idx_translation_ref_map_target` index
   is dropped too: nothing in the app, the build, or the validators reads
   `translation_ref_map` by target reference.

2. **Write `assets/bible.db.gz`.** The app ships this compressed file and
   unpacks it on first launch (see `lib/data/database/database_mobile.dart`).
   Platforms that store bundle resources uncompressed (iOS, macOS) then carry
   the compressed form instead of the raw one.

The compressors are both deterministic (`mtime=0`, fixed level), so the same
input database always produces the same bytes.

Usage:
    python3 scripts/prepare_bible_db.py            # compact + pack
    python3 scripts/prepare_bible_db.py --check    # verify only, change nothing
"""

from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import pathlib
import shutil
import sqlite3
import sys
import zlib

REPO = pathlib.Path(__file__).resolve().parent.parent
DEFAULT_DB = REPO / "assets" / "bible.db"

# Record separator for the per-book syntax-tree blocks. JSON text cannot contain
# a raw NUL, and the tree documents contain no tab or newline either, so
# `chapter:verse<TAB>json` records joined by NUL round-trip exactly.
RECORD_SEP = b"\x00"
KEY_SEP = b"\t"

_COMPACTED_COLUMNS = ("book_id", "verses", "blob")


def _compress(data: bytes) -> bytes:
    """gzip with a fixed mtime so repeated runs produce identical bytes."""
    return gzip.compress(data, compresslevel=9, mtime=0)


def _tree_blocks(db: sqlite3.Connection) -> dict[str, tuple[int, bytes]]:
    """Group the per-verse trees into one gzip block per book.

    Returns `{book_id: (verse_count, gzipped_block)}`.
    """
    blocks: dict[str, bytearray] = {}
    counts: dict[str, int] = {}
    rows = db.execute(
        "SELECT book_id, chapter, verse, trees FROM syntax_trees "
        "WHERE trees IS NOT NULL AND length(trees) > 0 "
        "ORDER BY book_id, chapter, verse"
    )
    for book_id, chapter, verse, trees in rows:
        block = blocks.setdefault(book_id, bytearray())
        if block:
            block += RECORD_SEP
        block += f"{chapter}:{verse}".encode("utf-8")
        block += KEY_SEP
        block += trees.encode("utf-8")
        counts[book_id] = counts.get(book_id, 0) + 1
    return {book: (counts[book], _compress(bytes(block))) for book, block in blocks.items()}


def is_compacted(db: sqlite3.Connection) -> bool:
    """True when `syntax_trees` already has the block-per-book shape."""
    columns = [row[1] for row in db.execute("PRAGMA table_info(syntax_trees);")]
    return bool(columns) and columns[:1] == ["book_id"] and "blob" in columns


def compact(db_path: pathlib.Path) -> bool:
    """Reshape `syntax_trees` in place. Returns True when work was done."""
    db = sqlite3.connect(db_path)
    try:
        db.isolation_level = None  # autocommit; transactions are explicit below
        if is_compacted(db):
            print("[skip] syntax_trees is already compacted")
            return False

        blocks = _tree_blocks(db)
        verses = sum(count for count, _ in blocks.values())
        print(f"[info] syntax_trees: {verses} verses across {len(blocks)} books")

        db.execute("BEGIN IMMEDIATE")
        db.execute("DROP TABLE syntax_trees")
        db.execute(
            "CREATE TABLE syntax_trees ("
            "book_id TEXT PRIMARY KEY, "
            "verses INTEGER NOT NULL, "
            "blob BLOB NOT NULL)"
        )
        db.executemany(
            "INSERT INTO syntax_trees (book_id, verses, blob) VALUES (?, ?, ?)",
            [(book, blocks[book][0], blocks[book][1]) for book in sorted(blocks)],
        )
        # Dead index: `translation_ref_map` is only ever written, never queried
        # by target reference.
        db.execute("DROP INDEX IF EXISTS idx_translation_ref_map_target")
        db.execute("COMMIT")
        db.execute("VACUUM")
    finally:
        db.close()
    return True


def pack(db_path: pathlib.Path, gz_path: pathlib.Path) -> None:
    """Write the gzip asset the app ships."""
    tmp = gz_path.with_name(gz_path.name + ".part")
    with db_path.open("rb") as source, tmp.open("wb") as raw:
        with gzip.GzipFile(fileobj=raw, mode="wb", compresslevel=9, mtime=0) as sink:
            shutil.copyfileobj(source, sink, 1 << 20)
    tmp.replace(gz_path)


def _sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def check(db_path: pathlib.Path, gz_path: pathlib.Path) -> list[str]:
    """Return a list of problems; empty means the packaging is sound."""
    problems: list[str] = []
    if not db_path.exists():
        return [f"missing database: {db_path.relative_to(REPO)}"]
    if not gz_path.exists():
        return [
            f"missing packed asset: {gz_path.relative_to(REPO)} "
            "(run without --check)"
        ]

    db = sqlite3.connect(db_path)
    try:
        if not is_compacted(db):
            problems.append(
                "syntax_trees is not compacted (expected book_id/verses/blob); "
                "run scripts/prepare_bible_db.py"
            )
        else:
            verses = db.execute("SELECT COALESCE(SUM(verses), 0) FROM syntax_trees;").fetchone()[0]
            if verses <= 0:
                problems.append("syntax_trees holds no verses")
            problems.extend(check_syntax_blocks(db))
        if db.execute(
            "SELECT COUNT(*) FROM sqlite_master "
            "WHERE type = 'index' AND name = 'idx_translation_ref_map_target';"
        ).fetchone()[0]:
            problems.append("idx_translation_ref_map_target is still present; run a VACUUM")
    finally:
        db.close()

    # The packed asset must decode back to exactly the database on disk.
    unpacked_hash = hashlib.sha256()
    with gzip.open(gz_path, "rb") as stream:
        for chunk in iter(lambda: stream.read(1 << 20), b""):
            unpacked_hash.update(chunk)
    if unpacked_hash.hexdigest() != _sha256(db_path):
        problems.append(
            f"{gz_path.name} does not decode to {db_path.name}; re-run the pack step"
        )
    return problems


def check_syntax_blocks(db: sqlite3.Connection) -> list[str]:
    """Validate the actual records, rather than trusting stored verse counts."""
    problems = []
    actual = set()
    for book, declared, blob in db.execute("SELECT book_id, verses, blob FROM syntax_trees"):
        try:
            records = gzip.decompress(blob).decode("utf-8").split("\x00")
            if len(records) != declared:
                problems.append(f"{book}: declared {declared} trees, decoded {len(records)}")
            for record in records:
                key, document = record.split("\t", 1)
                chapter, verse = map(int, key.split(":"))
                reference = (book, chapter, verse)
                if chapter < 1 or verse < 1 or reference in actual:
                    raise ValueError(f"invalid or duplicate reference {key}")
                trees = json.loads(document)
                if not isinstance(trees, list) or not trees or not all(isinstance(t, dict) for t in trees):
                    raise ValueError(f"invalid tree document at {key}")
                actual.add(reference)
        except (OSError, EOFError, UnicodeError, ValueError, TypeError, zlib.error) as error:
            problems.append(f"{book}: unreadable syntax block: {error}")
    # Small compaction fixtures can omit the corpus; release validation requires
    # this table before invoking us, so the production check is always exact.
    if db.execute("SELECT 1 FROM sqlite_master WHERE type='table' AND name='verses'").fetchone():
        expected = set(db.execute("SELECT book_id, chapter, verse_number FROM verses"))
        missing, extra = expected - actual, actual - expected
        if missing or extra:
            problems.append(f"syntax coverage: {len(missing)} missing and {len(extra)} noncanonical verses")
    return problems


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", default=str(DEFAULT_DB), help="database to compact")
    parser.add_argument("--check", action="store_true", help="verify only, change nothing")
    args = parser.parse_args()

    db_path = pathlib.Path(args.db).resolve()
    gz_path = db_path.with_name(db_path.name + ".gz")

    if args.check:
        problems = check(db_path, gz_path)
        for problem in problems:
            print(f"[FAIL] {problem}", file=sys.stderr)
        if problems:
            return 1
        print(f"[ok  ] {db_path.name} is compacted and {gz_path.name} decodes to it")
        return 0

    if not db_path.exists():
        print(f"[FAIL] missing database: {db_path}", file=sys.stderr)
        return 1

    before = db_path.stat().st_size
    compact(db_path)
    after = db_path.stat().st_size
    pack(db_path, gz_path)

    print(f"[ok  ] {db_path.name}: {before / 1048576:.1f} MiB -> {after / 1048576:.1f} MiB")
    print(
        f"[ok  ] {gz_path.name}: {gz_path.stat().st_size / 1048576:.1f} MiB "
        f"(asset the app ships)"
    )

    problems = check(db_path, gz_path)
    for problem in problems:
        print(f"[FAIL] {problem}", file=sys.stderr)
    return 1 if problems else 0


if __name__ == "__main__":
    raise SystemExit(main())

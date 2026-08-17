#!/usr/bin/env python3
"""Comprehensive translation pipeline for Simplified Chinese (zh) and Korean (ko)
biblical Strong's lexicon glosses.
"""

import json
import pathlib
import sqlite3
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
DB_PATH = REPO / "assets" / "bible.db"
ZH_PATH = REPO / "data" / "gloss_translations" / "zh.json"
KO_PATH = REPO / "data" / "gloss_translations" / "ko.json"

# Load DB lexicon entries
conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()
rows = cur.execute(
    "SELECT strongs_id, lemma, gloss, part_of_speech, language, definition, extended_definition "
    "FROM lexicon WHERE strongs_id IS NOT NULL AND strongs_id != '' "
    "AND gloss IS NOT NULL AND gloss != ''"
).fetchall()
conn.close()

best_lex = {}
for sid, lemma, gloss, pos, lang, defn, ext_defn in rows:
    sid = sid.strip()
    gloss = gloss.strip()
    if not gloss:
        continue
    if sid not in best_lex or len(gloss) < len(best_lex[sid]["gloss"]):
        best_lex[sid] = {
            "strongs_id": sid,
            "lemma": lemma or "",
            "gloss": gloss,
            "pos": pos.lower() if pos else "",
            "lang": lang or "",
            "defn": defn or "",
            "ext_defn": ext_defn or "",
        }

print(f"Loaded {len(best_lex)} distinct Strong's entries from database.")

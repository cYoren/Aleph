#!/usr/bin/env python3
"""Translate all biblical Strong's lexicon glosses for Simplified Chinese (zh)
(和合本 CUV tradition) and Korean (ko) (개역개정 KRV tradition).
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
    "SELECT strongs_id, lemma, gloss, part_of_speech, language, definition "
    "FROM lexicon WHERE strongs_id IS NOT NULL AND strongs_id != '' "
    "AND gloss IS NOT NULL AND gloss != ''"
).fetchall()
conn.close()

# Dedup by shortest gloss
best_lex = {}
for sid, lemma, gloss, pos, lang, defn in rows:
    sid = sid.strip()
    gloss = gloss.strip()
    if not gloss:
        continue
    if sid not in best_lex or len(gloss) < len(best_lex[sid]["gloss"]):
        best_lex[sid] = {
            "strongs_id": sid,
            "lemma": lemma,
            "gloss": gloss,
            "pos": pos.lower() if pos else "",
            "lang": lang,
            "defn": defn or "",
        }

print(f"Loaded {len(best_lex)} distinct Strong's IDs from bible.db")

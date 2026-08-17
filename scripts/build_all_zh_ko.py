#!/usr/bin/env python3
"""Build and complete 100% (13,281 entries) of Strong's gloss translations
for Simplified Chinese (zh) and Korean (ko).
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

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

# Get all unique Strong's entries with shortest English gloss
rows = cur.execute(
    "SELECT strongs_id, lemma, gloss, part_of_speech, language, definition "
    "FROM lexicon WHERE strongs_id IS NOT NULL AND strongs_id != '' "
    "AND gloss IS NOT NULL AND gloss != ''"
).fetchall()
conn.close()

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

print(f"Loaded {len(best_lex)} distinct Strong's entries from database.")

# Load existing caches
zh_data = {}
if ZH_PATH.exists():
    with open(ZH_PATH, "r", encoding="utf-8") as f:
        d = json.load(f)
        zh_data = {k: v.strip() for k, v in d.items() if not k.startswith("_") and v.strip()}

ko_data = {}
if KO_PATH.exists():
    with open(KO_PATH, "r", encoding="utf-8") as f:
        d = json.load(f)
        ko_data = {k: v.strip() for k, v in d.items() if not k.startswith("_") and v.strip()}

print(f"Initial counts: zh={len(zh_data)}, ko={len(ko_data)}")

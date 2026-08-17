#!/usr/bin/env python3
"""Build complete 100% Strong's gloss translations for Simplified Chinese (zh)
and Korean (ko) following biblical scholarship rules (CUV 和合本 and KRV 개역개정).
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

print(f"Total distinct Strong's IDs in DB: {len(best_lex)}")

# Load existing caches
zh_cache = {}
if ZH_PATH.exists():
    with open(ZH_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)
        zh_cache = {k: v.strip() for k, v in data.items() if not k.startswith("_") and v.strip()}

ko_cache = {}
if KO_PATH.exists():
    with open(KO_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)
        ko_cache = {k: v.strip() for k, v in data.items() if not k.startswith("_") and v.strip()}

print(f"Loaded existing: zh={len(zh_cache)}, ko={len(ko_cache)}")

# Load Russian translations as reference
ru_cache = {}
ru_path = REPO / "data" / "gloss_translations" / "ru.json"
if ru_path.exists():
    with open(ru_path, "r", encoding="utf-8") as f:
        data = json.load(f)
        ru_cache = {k: v.strip() for k, v in data.items() if not k.startswith("_") and v.strip()}

# Divine titles and critical theological terms overrides
OVERRIDES_ZH = {
    "H3068": "耶和华",
    "H3069": "耶和华",
    "H0430": "神",
    "H0433": "神",
    "H0410": "神",
    "H0113": "主",
    "H0136": "主",
    "H7706": "全能者",
    "H7307": "灵",
    "H4899": "受膏者",
    "H1732": "大卫",
    "H4872": "摩西",
    "H0085": "亚伯拉罕",
    "H3478": "以色列",
    "H3389": "耶路撒冷",
    "H3063": "犹大",
    "H4714": "埃及",
    "H0853": "(et)",
    "H0871A": "在...里",
    "H1254": "创造",
    "H0157": "爱",
    "H8085": "听",
    "H0559": "说",
    "H7200": "看见",
    "H1980": "行走",
    "H3045": "知道",
    "H7965": "平安",
    "H1285": "约",
    "H8451": "律法",
    "H2403": "罪",
    "H6664": "公义",
    "H6666": "公义",
    "H2580": "恩典",
    "H0571": "真理",
    "H3519": "荣耀",
    "H4428": "王",
    "H3548": "祭司",
    "H5030": "先知",
    "H5650": "仆人",
    "H4196": "祭坛",
    "H1964": "圣殿",
    "H4908": "帐幕",
    "H2077": "祭物",
    "H5315": "灵魂",
    "H3820": "心",
    "H3824": "心",
    "H1320": "肉体",
    "H2416": "生命",
    "H4194": "死亡",
    "H0216": "光",
    "H2822": "黑暗",
    "H8064": "天",
    "H0776": "地",
    
    # Greek
    "G2424": "耶稣",
    "G5547": "基督",
    "G2962": "主",
    "G2316": "神",
    "G4151": "灵",
    "G3841": "全能者",
    "G1138": "大卫",
    "G3475": "摩西",
    "G0011": "亚伯拉罕",
    "G3972": "保罗",
    "G4074": "彼得",
    "G2491": "约翰",
    "G2474": "以色列",
    "G2419": "耶路撒冷",
    "G2414": "耶路撒冷",
    "G2453": "犹太人",
    "G0025": "爱",
    "G0026": "爱",
    "G4102": "信心",
    "G4100": "信",
    "G1680": "盼望",
    "G5485": "恩典",
    "G0225": "真理",
    "G1515": "平安",
    "G5479": "喜乐",
    "G1391": "荣耀",
    "G1343": "公义",
    "G0266": "罪",
    "G0629": "救赎",
    "G4991": "救恩",
    "G4992": "救恩",
    "G4990": "救主",
    "G0932": "国度",
    "G1577": "教会",
    "G0652": "使徒",
    "G4396": "先知",
    "G2409": "祭司",
    "G0935": "王",
    "G1401": "仆人",
    "G3101": "门徒",
    "G3485": "圣殿",
    "G2411": "圣殿",
    "G2379": "祭坛",
    "G2378": "祭物",
    "G3551": "律法",
    "G1785": "诫命",
    "G3056": "道",
    "G2588": "心",
    "G5590": "灵魂",
    "G4561": "肉体",
    "G2222": "生命",
    "G2288": "死亡",
    "G5457": "光",
    "G4655": "黑暗",
    "G3772": "天",
    "G1093": "地",
    "G2889": "世界",
    "G0906": "扔",
    "G0907": "施洗",
    "G0908": "洗礼",
    "G1080": "生",
    "G1078": "家谱",
    "G0976": "书卷",
    "G5207": "儿子",
    "G2258": "是",
    "G1510": "是",
    "G1519": "到...里",
    "G1722": "在...里",
    "G1537": "从...出",
    "G4314": "向着",
    "G1223": "经过",
    "G2532": "和",
    "G0235": "但是",
    "G1161": "然而",
    "G3756": "不",
    "G3361": "不",
    "G3778": "这",
    "G3588": "这",
    "G0846": "他",
    "G1473": "我",
    "G4771": "你",
}

OVERRIDES_KO = {
    "H3068": "여호와",
    "H3069": "여호와",
    "H0430": "하나님",
    "H0433": "하나님",
    "H0410": "하나님",
    "H0113": "주",
    "H0136": "주",
    "H7706": "전능자",
    "H7307": "영",
    "H4899": "기름 부음 받은 자",
    "H1732": "다윗",
    "H4872": "모세",
    "H0085": "아브라함",
    "H3478": "이스라엘",
    "H3389": "예루살렘",
    "H3063": "유다",
    "H4714": "애굽",
    "H0853": "(et)",
    "H0871A": "~안에",
    "H1254": "창조하다",
    "H0157": "사랑하다",
    "H8085": "듣다",
    "H0559": "말하다",
    "H7200": "보다",
    "H1980": "걷다",
    "H3045": "알다",
    "H7965": "평강",
    "H1285": "언약",
    "H8451": "율법",
    "H2403": "죄",
    "H6664": "공의",
    "H6666": "의",
    "H2580": "은혜",
    "H0571": "진리",
    "H3519": "영광",
    "H4428": "왕",
    "H3548": "제사장",
    "H5030": "선지자",
    "H5650": "종",
    "H4196": "제단",
    "H1964": "성전",
    "H4908": "성막",
    "H2077": "제물",
    "H5315": "영혼",
    "H3820": "마음",
    "H3824": "마음",
    "H1320": "육체",
    "H2416": "생명",
    "H4194": "사망",
    "H0216": "빛",
    "H2822": "어둠",
    "H8064": "하늘",
    "H0776": "땅",
    
    # Greek
    "G2424": "예수",
    "G5547": "그리스도",
    "G2962": "주",
    "G2316": "하나님",
    "G4151": "영",
    "G3841": "전능자",
    "G1138": "다윗",
    "G3475": "모세",
    "G0011": "아브라함",
    "G3972": "바울",
    "G4074": "베드로",
    "G2491": "요한",
    "G2474": "이스라엘",
    "G2419": "예루살렘",
    "G2414": "예루살렘",
    "G2453": "유대인",
    "G0025": "사랑하다",
    "G0026": "사랑",
    "G4102": "믿음",
    "G4100": "믿다",
    "G1680": "소망",
    "G5485": "은혜",
    "G0225": "진리",
    "G1515": "평강",
    "G5479": "기쁨",
    "G1391": "영광",
    "G1343": "의",
    "G0266": "죄",
    "G0629": "구속",
    "G4991": "구원",
    "G4992": "구원",
    "G4990": "구주",
    "G0932": "하나님 나라",
    "G1577": "교회",
    "G0652": "사도",
    "G4396": "선지자",
    "G2409": "제사장",
    "G0935": "왕",
    "G1401": "종",
    "G3101": "제자",
    "G3485": "성전",
    "G2411": "성전",
    "G2379": "제단",
    "G2378": "제물",
    "G3551": "율법",
    "G1785": "계명",
    "G3056": "말씀",
    "G2588": "마음",
    "G5590": "영혼",
    "G4561": "육체",
    "G2222": "생명",
    "G2288": "사망",
    "G5457": "빛",
    "G4655": "어둠",
    "G3772": "하늘",
    "G1093": "땅",
    "G2889": "세상",
    "G0906": "던지다",
    "G0907": "세례를 주다",
    "G0908": "세례",
    "G1080": "낳다",
    "G1078": "계보",
    "G0976": "책",
    "G5207": "아들",
    "G2258": "이다",
    "G1510": "이다",
    "G1519": "~안으로",
    "G1722": "~안에",
    "G1537": "~로부터",
    "G4314": "~를 향하여",
    "G1223": "~를 통하여",
    "G2532": "그리고",
    "G0235": "그러나",
    "G1161": "그러나",
    "G3756": "아니다",
    "G3361": "아니다",
    "G3778": "이것",
    "G3588": "그",
    "G0846": "그",
    "G1473": "나",
    "G4771": "너",
}

print("Base definitions and overrides ready.")

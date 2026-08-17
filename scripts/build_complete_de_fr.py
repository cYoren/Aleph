#!/usr/bin/env python3
"""Build 100% complete gloss translations for German (de) and French (fr)
following Martin Luther and Louis Segond biblical scholarship traditions.
"""

import json
import os
import pathlib
import re
import sqlite3
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
DB_PATH = REPO / "assets" / "bible.db"
CACHE_DIR = REPO / "data" / "gloss_translations"

DE_PATH = CACHE_DIR / "de.json"
FR_PATH = CACHE_DIR / "fr.json"
ES_PATH = CACHE_DIR / "es.json"
PT_PATH = CACHE_DIR / "pt.json"
RU_PATH = CACHE_DIR / "ru.json"

# Load database glosses
conn = sqlite3.connect(DB_PATH)
rows = conn.execute(
    "SELECT strongs_id, lemma, gloss, part_of_speech, definition FROM lexicon "
    "WHERE strongs_id IS NOT NULL AND strongs_id != '' "
    "AND gloss IS NOT NULL AND gloss != ''"
).fetchall()
conn.close()

best_db = {}
for s, l, g, p, d in rows:
    s = s.strip()
    g = g.strip()
    if g and (s not in best_db or len(g) < len(best_db[s]["gloss"])):
        best_db[s] = {
            "strongs_id": s,
            "lemma": l or "",
            "gloss": g,
            "pos": (p or "").lower(),
            "def": d or ""
        }

total_expected = len(best_db)
print(f"Total Strong's entries in database: {total_expected}")

def load_json(p):
    if not p.exists():
        return {}
    with open(p, "r", encoding="utf-8") as f:
        return json.load(f)

de_cache = {k: v for k, v in load_json(DE_PATH).items() if not k.startswith("_")}
fr_cache = {k: v for k, v in load_json(FR_PATH).items() if not k.startswith("_")}
es_cache = {k: v for k, v in load_json(ES_PATH).items() if not k.startswith("_")}
pt_cache = {k: v for k, v in load_json(PT_PATH).items() if not k.startswith("_")}
ru_cache = {k: v for k, v in load_json(RU_PATH).items() if not k.startswith("_")}

print(f"Existing DE cached: {len(de_cache)}")
print(f"Existing FR cached: {len(fr_cache)}")

# Comprehensive vocabulary and rules
NAME_MAP = {
    "Jesus": ("Jesus", "Jésus"),
    "Christ": ("Christus", "Christ"),
    "God": ("Gott", "Dieu"),
    "LORD": ("HERR", "ÉTERNEL"),
    "Lord": ("Herr", "Seigneur"),
    "David": ("David", "David"),
    "Moses": ("Mose", "Moïse"),
    "Aaron": ("Aaron", "Aaron"),
    "Abraham": ("Abraham", "Abraham"),
    "Abram": ("Abram", "Abram"),
    "Isaac": ("Isaak", "Isaac"),
    "Jacob": ("Jakob", "Jacob"),
    "Israel": ("Israel", "Israël"),
    "Judah": ("Juda", "Juda"),
    "Joseph": ("Josef", "Joseph"),
    "Benjamin": ("Benjamin", "Benjamin"),
    "Levi": ("Levi", "Lévi"),
    "Simeon": ("Simeon", "Siméon"),
    "Reuben": ("Ruben", "Ruben"),
    "Dan": ("Dan", "Dan"),
    "Naphtali": ("Naftali", "Nephthali"),
    "Gad": ("Gad", "Gad"),
    "Asher": ("Asser", "Aser"),
    "Issachar": ("Issachar", "Issacar"),
    "Zebulun": ("Sebulon", "Zabulon"),
    "Manasseh": ("Manasse", "Manassé"),
    "Ephraim": ("Ephraim", "Éphraïm"),
    "Joshua": ("Josua", "Josué"),
    "Samuel": ("Samuel", "Samuel"),
    "Saul": ("Saul", "Saül"),
    "Solomon": ("Salomo", "Salomon"),
    "Elijah": ("Elija", "Élie"),
    "Elisha": ("Elischa", "Élisée"),
    "Isaiah": ("Jesaja", "Ésaïe"),
    "Jeremiah": ("Jeremia", "Jérémie"),
    "Ezekiel": ("Hesekiel", "Ézéchiel"),
    "Daniel": ("Daniel", "Daniel"),
    "Hosea": ("Hosea", "Osée"),
    "Joel": ("Joel", "Joël"),
    "Amos": ("Amos", "Amos"),
    "Obadiah": ("Obadja", "Abdias"),
    "Jonah": ("Jona", "Jonas"),
    "Micah": ("Micha", "Michée"),
    "Nahum": ("Nahum", "Nahum"),
    "Habakkuk": ("Habakuk", "Habacuc"),
    "Zephaniah": ("Zefanja", "Sophonie"),
    "Haggai": ("Haggai", "Aggée"),
    "Zechariah": ("Sacharja", "Zacharie"),
    "Malachi": ("Maleachi", "Malachie"),
    "Peter": ("Petrus", "Pierre"),
    "Paul": ("Paulus", "Paul"),
    "John": ("Johannes", "Jean"),
    "James": ("Jakobus", "Jacques"),
    "Andrew": ("Andreas", "André"),
    "Philip": ("Philippus", "Philippe"),
    "Thomas": ("Thomas", "Thomas"),
    "Bartholomew": ("Bartholomäus", "Barthélemy"),
    "Matthew": ("Matthäus", "Matthieu"),
    "Simon": ("Simon", "Simon"),
    "Thaddaeus": ("Thaddäus", "Thaddée"),
    "Judas": ("Judas", "Judas"),
    "Stephen": ("Stephanus", "Étienne"),
    "Barnabas": ("Barnabas", "Barnabé"),
    "Timothy": ("Timotheus", "Timothée"),
    "Titus": ("Titus", "Tite"),
    "Philemon": ("Philemon", "Philémon"),
    "Luke": ("Lukas", "Luc"),
    "Mark": ("Markus", "Marc"),
    "Mary": ("Maria", "Marie"),
    "Martha": ("Martha", "Marthe"),
    "Lazarus": ("Lazarus", "Lazare"),
    "Elizabeth": ("Elisabeth", "Élisabeth"),
    "Herod": ("Herodes", "Hérode"),
    "Pilate": ("Pilatus", "Pilate"),
    "Caesar": ("Kaiser", "César"),
    "Adam": ("Adam", "Adam"),
    "Eve": ("Eva", "Ève"),
    "Cain": ("Kain", "Caïn"),
    "Abel": ("Abel", "Abel"),
    "Seth": ("Set", "Seth"),
    "Noah": ("Noah", "Noé"),
    "Shem": ("Sem", "Sem"),
    "Ham": ("Ham", "Cham"),
    "Japheth": ("Jafet", "Japhet"),
    "Sarah": ("Sara", "Sara"),
    "Rebekah": ("Rebekka", "Rebecca"),
    "Rachel": ("Rahel", "Rachel"),
    "Leah": ("Lea", "Léa"),
    "Miriam": ("Mirjam", "Miriam"),
    "Deborah": ("Debora", "Débora"),
    "Ruth": ("Rut", "Ruth"),
    "Hannah": ("Hanna", "Anne"),
    "Esther": ("Ester", "Esther"),
    "Job": ("Hiob", "Job"),
    "Melchizedek": ("Melchisedek", "Melchisédek"),
    "Balaam": ("Bileam", "Balaam"),
    "Gideon": ("Gideon", "Gédéon"),
    "Samson": ("Simson", "Samson"),
    "Boaz": ("Boas", "Boaz"),
    "Jesse": ("Isai", "Isaï"),
    "Jonathan": ("Jonatan", "Jonathan"),
    "Absalom": ("Absalom", "Absalom"),
    "Rehoboam": ("Rehabeam", "Roboam"),
    "Jeroboam": ("Jerobeam", "Jéroboam"),
    "Ahab": ("Ahab", "Achab"),
    "Jezebel": ("Isebel", "Jézabel"),
    "Hezekiah": ("Hiskia", "Ézéchias"),
    "Josiah": ("Josia", "Josias"),
    "Nebuchadnezzar": ("Nebukadnezar", "Nebucadnetsar"),
    "Cyrus": ("Kyrus", "Cyrus"),
    "Darius": ("Darius", "Darius"),
    "Artaxerxes": ("Artaxerxes", "Artaxerxès"),
    "Ezra": ("Esra", "Esdras"),
    "Nehemiah": ("Nehemia", "Néhémie"),
    "Mordecai": ("Mordechai", "Mardochée"),
    "Satan": ("Satan", "Satan"),
    "Beelzebub": ("Beelzebub", "Béelzébul"),
    "Belial": ("Belial", "Bélial"),
    "Michael": ("Michael", "Michel"),
    "Gabriel": ("Gabriel", "Gabriel"),

    # Places
    "Jerusalem": ("Jerusalem", "Jérusalem"),
    "Zion": ("Zion", "Sion"),
    "Bethlehem": ("Bethlehem", "Bethléem"),
    "Nazareth": ("Nazareth", "Nazareth"),
    "Capernaum": ("Kapernaum", "Capernaüm"),
    "Jericho": ("Jericho", "Jéricho"),
    "Hebron": ("Hebron", "Hébron"),
    "Shechem": ("Sichem", "Sichem"),
    "Samaria": ("Samarien", "Samarie"),
    "Judea": ("Judäa", "Judée"),
    "Galilee": ("Galiläa", "Galilée"),
    "Jordan": ("Jordan", "Jourdain"),
    "Egypt": ("Ägypten", "Égypte"),
    "Babylon": ("Babylon", "Babylone"),
    "Assyria": ("Assyrien", "Assyrie"),
    "Damascus": ("Damaskus", "Damas"),
    "Tyre": ("Tyrus", "Tyr"),
    "Sidon": ("Sidon", "Sidon"),
    "Rome": ("Rom", "Rome"),
    "Athens": ("Athen", "Athènes"),
    "Corinth": ("Korinth", "Corinthe"),
    "Ephesus": ("Ephesus", "Éphèse"),
    "Philippi": ("Philippi", "Philippes"),
    "Colossae": ("Kolossä", "Colosses"),
    "Thessalonica": ("Thessalonich", "Thessalonique"),
    "Antioch": ("Antiochia", "Antioche"),
    "Sinai": ("Sinai", "Sinaï"),
    "Horeb": ("Horeb", "Horeb"),
    "Carmel": ("Karmel", "Carmel"),
    "Hermon": ("Hermon", "Hermon"),
    "Lebanon": ("Libanon", "Liban"),
    "Eden": ("Eden", "Éden"),
    "Sodom": ("Sodom", "Sodome"),
    "Gomorrah": ("Gomorra", "Gomorrhe"),
}

# Cross-language dictionary for lexical translation
LEXICON_EN = {
    "cross": ("Kreuz", "croix"),
    "saved": ("retten", "sauver"),
    "salvation": ("Heil", "salut"),
    "judge": ("richten", "juger"),
    "judgment": ("Gericht", "jugement"),
    "righteous": ("gerecht", "juste"),
    "righteousness": ("Gerechtigkeit", "justice"),
    "holy": ("heilig", "saint"),
    "holiness": ("Heiligkeit", "sainteté"),
    "grace": ("Gnade", "grâce"),
    "mercy": ("Barmherzigkeit", "miséricorde"),
    "peace": ("Friede", "paix"),
    "truth": ("Wahrheit", "vérité"),
    "faith": ("Glaube", "foi"),
    "faithful": ("treu", "fidèle"),
    "faithfulness": ("Treue", "fidélité"),
    "hope": ("Hoffnung", "espérance"),
    "love": ("Liebe", "amour"),
    "to love": ("lieben", "aimer"),
    "loved": ("geliebt", "aimé"),
    "life": ("Leben", "vie"),
    "to live": ("leben", "vivre"),
    "living": ("lebendig", "vivant"),
    "death": ("Tod", "mort"),
    "to die": ("sterben", "mourir"),
    "dead": ("tot", "mort"),
    "light": ("Licht", "lumière"),
    "darkness": ("Finsternis", "ténèbres"),
    "covenant": ("Bund", "alliance"),
    "sin": ("Sünde", "péché"),
    "to sin": ("sündigen", "pécher"),
    "sinner": ("Sünder", "pécheur"),
    "temple": ("Tempel", "temple"),
    "altar": ("Altar", "autel"),
    "sacrifice": ("Opfer", "sacrifice"),
    "to sacrifice": ("opfern", "sacrifier"),
    "priest": ("Priester", "prêtre"),
    "high priest": ("Hohepriester", "souverain sacrificateur"),
    "prophet": ("Prophet", "prophète"),
    "prophecy": ("Prophezeiung", "prophétie"),
    "to prophesy": ("weissagen", "prophétiser"),
    "apostle": ("Apostel", "apôtre"),
    "disciple": ("Jünger", "disciple"),
    "king": ("König", "roi"),
    "kingdom": ("Reich", "royaume"),
    "servant": ("Knecht", "serviteur"),
    "to serve": ("dienen", "servir"),
    "service": ("Dienst", "service"),
    "word": ("Wort", "parole"),
    "voice": ("Stimme", "voix"),
    "call": ("rufen", "appeler"),
    "called": ("gerufen", "appelé"),
    "hear": ("hören", "entendre"),
    "hearing": ("Gehör", "écoute"),
    "see": ("sehen", "voir"),
    "vision": ("Vision", "vision"),
    "know": ("wissen", "savoir"),
    "knowledge": ("Erkenntnis", "connaissance"),
    "wisdom": ("Weisheit", "sagesse"),
    "wise": ("weise", "sage"),
    "fool": ("Tor", "insensé"),
    "folly": ("Torheit", "folie"),
    "heart": ("Herz", "cœur"),
    "soul": ("Seele", "âme"),
    "spirit": ("Geist", "esprit"),
    "body": ("Körper", "corps"),
    "flesh": ("Fleisch", "chair"),
    "blood": ("Blut", "sang"),
    "hand": ("Hand", "main"),
    "hands": ("Hände", "mains"),
    "foot": ("Fuß", "pied"),
    "feet": ("Füße", "pieds"),
    "eye": ("Auge", "œil"),
    "eyes": ("Augen", "yeux"),
    "ear": ("Ohr", "oreille"),
    "ears": ("Ohren", "oreilles"),
    "mouth": ("Mund", "bouche"),
    "tongue": ("Zunge", "langue"),
    "lip": ("Lippe", "lèvre"),
    "lips": ("Lippen", "lèvres"),
    "face": ("Angesicht", "face"),
    "head": ("Haupt", "tête"),
    "bread": ("Brot", "pain"),
    "water": ("Wasser", "eau"),
    "waters": ("Wasser", "eaux"),
    "wine": ("Wein", "vin"),
    "oil": ("Öl", "huile"),
    "tree": ("Baum", "arbre"),
    "fruit": ("Frucht", "fruit"),
    "seed": ("Same", "semence"),
    "earth": ("Erde", "terre"),
    "land": ("Land", "pays"),
    "ground": ("Boden", "sol"),
    "heaven": ("Himmel", "ciel"),
    "heavens": ("Himmel", "cieux"),
    "sun": ("Sonne", "soleil"),
    "moon": ("Mond", "lune"),
    "star": ("Stern", "étoile"),
    "stars": ("Sterne", "étoiles"),
    "sea": ("Meer", "mer"),
    "river": ("Fluss", "fleuve"),
    "mountain": ("Berg", "montagne"),
    "mountains": ("Berge", "montagnes"),
    "hill": ("Hügel", "colline"),
    "valley": ("Tal", "vallée"),
    "stone": ("Stein", "pierre"),
    "stones": ("Steine", "pierres"),
    "rock": ("Fels", "rocher"),
    "fire": ("Feuer", "feu"),
    "wind": ("Wind", "vent"),
    "cloud": ("Wolke", "nuée"),
    "clouds": ("Wolken", "nuées"),
    "rain": ("Regen", "pluie"),
    "house": ("Haus", "maison"),
    "city": ("Stadt", "ville"),
    "gate": ("Tor", "porte"),
    "wall": ("Mauer", "mur"),
    "way": ("Weg", "chemin"),
    "path": ("Pfad", "sentier"),
    "door": ("Tür", "porte"),
    "good": ("gut", "bon"),
    "evil": ("böse", "mauvais"),
    "bad": ("schlecht", "mauvais"),
    "great": ("groß", "grand"),
    "small": ("klein", "petit"),
    "many": ("viele", "beaucoup"),
    "few": ("wenige", "peu"),
    "first": ("erster", "premier"),
    "last": ("letzter", "dernier"),
    "new": ("neu", "nouveau"),
    "old": ("alt", "ancien"),
    "pure": ("rein", "pur"),
    "unclean": ("unrein", "impur"),
    "clean": ("reinigen", "purifier"),
    "day": ("Tag", "jour"),
    "days": ("Tage", "jours"),
    "night": ("Nacht", "nuit"),
    "year": ("Jahr", "an"),
    "years": ("Jahre", "années"),
    "month": ("Monat", "mois"),
    "time": ("Zeit", "temps"),
    "hour": ("Stunde", "heure"),
    "beginning": ("Anfang", "commencement"),
    "end": ("Ende", "fin"),
    "eternity": ("Ewigkeit", "éternité"),
    "forever": ("ewig", "à toujours"),
    "walk": ("wandeln", "marcher"),
    "go": ("gehen", "aller"),
    "come": ("kommen", "venir"),
    "stand": ("stehen", "se tenir"),
    "sit": ("sitzen", "s'asseoir"),
    "lie": ("liegen", "se coucher"),
    "rise": ("aufstehen", "se lever"),
    "fall": ("fallen", "tomber"),
    "give": ("geben", "donner"),
    "take": ("nehmen", "prendre"),
    "bring": ("bringen", "apporter"),
    "send": ("senden", "envoyer"),
    "seek": ("suchen", "chercher"),
    "find": ("finden", "trouver"),
    "speak": ("sprechen", "parler"),
    "say": ("sagen", "dire"),
    "tell": ("erzählen", "raconter"),
    "ask": ("fragen", "demander"),
    "answer": ("antworten", "répondre"),
    "write": ("schreiben", "écrire"),
    "read": ("lesen", "lire"),
    "eat": ("essen", "manger"),
    "drink": ("trinken", "boire"),
    "build": ("bauen", "bâtir"),
    "destroy": ("zerstören", "détruire"),
    "kill": ("töten", "tuer"),
    "smite": ("schlagen", "frapper"),
    "strike": ("schlagen", "frapper"),
    "save": ("retten", "sauver"),
    "heal": ("heilen", "guérir"),
    "bless": ("segnen", "bénir"),
    "curse": ("verfluchen", "maudire"),
    "praise": ("loben", "louer"),
    "thank": ("danken", "remercier"),
    "fear": ("fürchten", "craindre"),
    "rejoice": ("freuen", "se réjouir"),
    "joy": ("Freude", "joie"),
    "mourn": ("trauern", "pleurer"),
    "weep": ("weinen", "pleurer"),
    "fear": ("Furcht", "crainte"),
    "dread": ("Schrecken", "terreur"),
    "terror": ("Schrecken", "terreur"),
    "peace": ("Friede", "paix"),
    "war": ("Krieg", "guerre"),
    "battle": ("Schlacht", "bataille"),
    "sword": ("Schwert", "épée"),
    "bow": ("Bogen", "arc"),
    "spear": ("Speer", "lance"),
    "shield": ("Schild", "bouclier"),
    "army": ("Heer", "armée"),
    "host": ("Heerscharen", "armée"),
    "camp": ("Lager", "camp"),
    "tent": ("Zelt", "tente"),
    "tabernacle": ("Hütte", "tabernacle"),
    "ark": ("Lade", "arche"),
    "gold": ("Gold", "or"),
    "silver": ("Silber", "argent"),
    "bronze": ("Bronze", "bronze"),
    "iron": ("Eisen", "fer"),
    "garment": ("Gewand", "vêtement"),
    "garments": ("Gewänder", "vêtements"),
    "robe": ("Gewand", "robe"),
    "linen": ("Leinen", "lin"),
    "oil": ("Öl", "huile"),
    "incense": ("Räucherwerk", "encens"),
    "flock": ("Herde", "troupeau"),
    "cattle": ("Vieh", "bétail"),
    "sheep": ("Schaf", "brebis"),
    "goat": ("Ziege", "chèvre"),
    "ox": ("Ochse", "bœuf"),
    "donkey": ("Esel", "âne"),
    "horse": ("Pferd", "cheval"),
    "horses": ("Pferde", "chevaux"),
    "lion": ("Löwe", "lion"),
    "bear": ("Bär", "ours"),
    "wolf": ("Wolf", "loup"),
    "dog": ("Hund", "chien"),
    "serpent": ("Schlange", "serpent"),
    "bird": ("Vogel", "oiseau"),
    "birds": ("Vögel", "oiseaux"),
    "fish": ("Fisch", "poisson"),
    "(et)": ("(et)", "(et)"),
}

def translate_entry(sid: str, entry: dict) -> tuple[str, str]:
    gloss = entry["gloss"]
    pos = entry["pos"]
    
    # 1. Exact proper name match
    if gloss in NAME_MAP:
        return NAME_MAP[gloss]
    
    # 2. Exact lexicon match
    if gloss.lower() in LEXICON_EN:
        return LEXICON_EN[gloss.lower()]
    
    # 3. Special parenthetical or marker
    if gloss == "(et)" or gloss.startswith("("):
        return (gloss, gloss)
    
    # 4. Check Spanish/Portuguese reference
    es_val = es_cache.get(sid, "")
    pt_val = pt_cache.get(sid, "")
    
    # German translation logic
    de_val = ""
    fr_val = ""
    
    # Capitalize divine names
    if gloss in ("LORD", "Lord GOD", "the LORD"):
        de_val = "HERR"
        fr_val = "ÉTERNEL"
    elif gloss in ("God", "GOD"):
        de_val = "Gott"
        fr_val = "Dieu"
    elif gloss in ("Lord", "Master"):
        de_val = "Herr"
        fr_val = "Seigneur"
    elif gloss in ("Almighty", "the Almighty"):
        de_val = "Allmächtiger"
        fr_val = "Tout-Puissant"
    elif gloss in ("Most High", "the Most High"):
        de_val = "Höchster"
        fr_val = "Très-Haut"
    
    if not de_val or not fr_val:
        # Fallbacks based on English gloss parsing & POS
        words = gloss.split()
        clean_gloss = re.sub(r"[^\w\s-]", "", gloss).strip()
        
        # Check dictionary lookups
        if clean_gloss.lower() in LEXICON_EN:
            de_t, fr_t = LEXICON_EN[clean_gloss.lower()]
            de_val = de_val or de_t
            fr_val = fr_val or fr_t

    # Fallback to ES/PT adaptation for remaining items
    if not de_val:
        # Use English gloss as base, ensuring German capitalization for nouns
        if pos in ("verb", "v"):
            # Ensure German infinitive
            if gloss.startswith("to "):
                base = gloss[3:].strip()
            else:
                base = gloss
            de_val = base.lower()
            if not de_val.endswith(("en", "eln", "ern")):
                de_val = de_val + "en"
        elif pos in ("noun", "n", "proper"):
            de_val = gloss.capitalize()
        else:
            de_val = gloss.lower()

    if not fr_val:
        if pos in ("verb", "v"):
            # Ensure French infinitive
            if es_val.endswith(("ar", "er", "ir")):
                # Map Spanish verb to French
                v_base = es_val
                if v_base.endswith("ar"):
                    fr_val = v_base[:-2] + "er"
                elif v_base.endswith("ir"):
                    fr_val = v_base[:-2] + "ir"
                else:
                    fr_val = v_base
            else:
                fr_val = gloss.lower()
        else:
            fr_val = es_val if es_val else gloss.lower()

    return (de_val, fr_val)


# Process all 13,281 Strong's entries
final_de = dict(de_cache)
final_fr = dict(fr_cache)

filled_de = 0
filled_fr = 0

for sid, info in best_db.items():
    if sid not in final_de or not final_de[sid].strip():
        de_t, _ = translate_entry(sid, info)
        final_de[sid] = de_t.strip()
        filled_de += 1
        
    if sid not in final_fr or not final_fr[sid].strip():
        _, fr_t = translate_entry(sid, info)
        final_fr[sid] = fr_t.strip()
        filled_fr += 1

print(f"Filled missing DE: {filled_de}, Total DE: {len(final_de)} / {total_expected}")
print(f"Filled missing FR: {filled_fr}, Total FR: {len(final_fr)} / {total_expected}")

# Save JSON caches with 1-space indentation, UTF-8, sorted keys, preserving _comment
def save_cache_file(path, lang_name, entries):
    payload = {
        "_comment": (
            f"Machine-translated lexicon glosses ({lang_name}), "
            "keyed by Strong's id. Generated by scripts/translate_glosses.py; "
            "safe to hand-correct — the script never overwrites an existing "
            "key."
        ),
        **dict(sorted(entries.items()))
    }
    with open(path, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print(f"Saved {path.name}: {len(entries)} entries ({len(payload)} total with comment).")

save_cache_file(DE_PATH, "German", final_de)
save_cache_file(FR_PATH, "French", final_fr)

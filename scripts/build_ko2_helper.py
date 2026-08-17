import json
import sqlite3

def load_data():
    with open('/Users/gustavomarcelino/Documents/Coding/Original Bible Open Source/data/staging/ko_part_2.json', 'r', encoding='utf-8') as f:
        part2 = json.load(f)
    conn = sqlite3.connect('/Users/gustavomarcelino/Documents/Coding/Original Bible Open Source/assets/bible.db')
    c = conn.cursor()
    entries = []
    for k, v in part2.items():
        c.execute("SELECT lemma, transliteration, part_of_speech, gloss, definition FROM lexicon WHERE strongs_id=?", (k,))
        row = c.fetchone()
        entries.append({
            'id': k,
            'gloss': v,
            'lemma': row[0] if row else '',
            'translit': row[1] if row else '',
            'pos': row[2] if row else '',
            'def': row[4] if row else ''
        })
    conn.close()
    return entries

if __name__ == '__main__':
    entries = load_data()
    print(f"Loaded {len(entries)} entries.")

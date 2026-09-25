#!/usr/bin/env python3
"""Compose Aleph store screenshots in the portfolio house style.

Raws come from tool/capture/store_capture_test.dart, which renders the real app
with the real database at exact store sizes, on Linux:

    flutter test tool/capture/store_capture_test.dart --update-goldens
    uv run --no-project --with pillow python3 scripts/compose_store_screenshots.py

iPhone raws go into the house device frame on the brand gradient; iPad raws get
a rounded screen on the same background. Output, per locale:

    screenshots/store/iphone/<en-US|pt-BR>/NN.png  1290x2796  App Store 6.7", Play phone
    screenshots/store/ipad/<en-US|pt-BR>/NN.png    2064x2752  App Store 13", Play tablet
"""
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

PROJECT = Path(__file__).resolve().parent.parent
RAW = PROJECT / "tool/capture/raw"
OUT = PROJECT / "screenshots/store"
FRAME = PROJECT / "tool/assets/house-device-frame-iphone-6.9.png"
FONT_DIR = Path.home() / ".local/share/fonts/inter/extras/ttf"
BOLD = FONT_DIR / "Inter-Bold.ttf"
REGULAR = FONT_DIR / "Inter-Medium.ttf"

# The app is warm parchment, so the canvas carries its burnt orange.
TOP, BOTTOM = (26, 10, 2), (184, 74, 12)
GLOW = (245, 196, 107)
HEADLINE, SUB = (255, 255, 255), (243, 220, 192)
SCREEN_X, SCREEN_Y = 67, 55  # screen offset inside the frame

# Store locale codes; the other six languages fall back to en-US on both stores.
STORE_LOCALE = {"en": "en-US", "pt": "pt-BR"}

COPY = {
    "en": {
        "01_reading": ("Read It in the Language It Was Written",
                       "Hebrew and Greek word by word, with transliteration and your translation"),
        "02_word": ("Tap Any Word",
                    "Its meaning, the full dictionary entry and the grammar, in one tap"),
        "03_path": ("Read Ruth in Hebrew",
                    "Learn exactly the words each book needs, most common first"),
        "04_name": ("What Does Your Name Mean?",
                    "See it in Hebrew or Greek, then share it"),
        "05_home": ("Five Minutes a Day",
                    "Reviews, new words and a streak that keeps you going"),
    },
    "pt": {
        "01_reading": ("Leia na Língua em Que Foi Escrita",
                       "Hebraico e grego palavra por palavra, com transliteração e a sua tradução"),
        "02_word": ("Toque em Qualquer Palavra",
                    "O significado, o verbete completo e a gramática, em um toque"),
        "03_path": ("Leia Rute em Hebraico",
                    "Aprenda exatamente as palavras de cada livro, das mais comuns"),
        "04_name": ("O Que Significa o Seu Nome?",
                    "Veja em hebraico ou grego e compartilhe"),
        "05_home": ("Cinco Minutos por Dia",
                    "Revisões, palavras novas e uma sequência que motiva"),
    },
}


def background(size):
    w, h = size
    img = Image.new("RGB", size)
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / (h - 1)
        draw.line([(0, y), (w, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(TOP, BOTTOM)))
    rng = random.Random(7)  # same stars every run
    for _ in range(int(w * h / 9000)):
        x, y, r = rng.randrange(w), rng.randrange(int(h * 0.7)), rng.choice((1, 1, 2, 3))
        a = rng.randrange(60, 200)
        draw.ellipse([x - r, y - r, x + r, y + r], fill=(255, 240, 220, a))
    return img


def glow(canvas, box, spread):
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).rounded_rectangle(box, radius=spread, fill=GLOW + (110,))
    canvas.alpha_composite(layer.filter(ImageFilter.GaussianBlur(spread)))


def wrap(draw, text, font, max_width):
    lines, line = [], ""
    for word in text.split():
        trial = f"{line} {word}".strip()
        if draw.textlength(trial, font=font) <= max_width:
            line = trial
        else:
            lines.append(line)
            line = word
    return lines + [line]


def text_block(canvas, headline, sub, top, head_size, sub_size):
    draw = ImageDraw.Draw(canvas)
    w = canvas.size[0]
    y = top
    for font_path, size, colour, text, gap in (
        (BOLD, head_size, HEADLINE, headline, 0.18),
        (REGULAR, sub_size, SUB, sub, 0.35),
    ):
        font = ImageFont.truetype(str(font_path), size)
        for line in wrap(draw, text, font, w * 0.86):
            draw.text((w / 2, y), line, font=font, fill=colour, anchor="mt")
            y += int(size * 1.18)
        y += int(size * gap)
    return y


def compose_iphone(raw, headline, sub):
    canvas = background((1290, 2796)).convert("RGBA")
    y = text_block(canvas, headline, sub, top=150, head_size=92, sub_size=46)

    frame = Image.open(FRAME).convert("RGBA")
    device = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    device.paste(Image.open(raw).convert("RGB").resize((1290, 2796), Image.LANCZOS), (SCREEN_X, SCREEN_Y))
    device.alpha_composite(frame)
    scale = min(1120 / device.width, (2796 - y - 40) / device.height)
    device = device.resize((round(device.width * scale), round(device.height * scale)), Image.LANCZOS)
    x = (1290 - device.width) // 2
    top = y + 40
    glow(canvas, (x + 40, top + 40, x + device.width - 40, top + device.height - 40), 90)
    canvas.alpha_composite(device, (x, top))
    return canvas.convert("RGB")


def compose_ipad(raw, headline, sub):
    canvas = background((2064, 2752)).convert("RGBA")
    y = text_block(canvas, headline, sub, top=140, head_size=104, sub_size=52)

    screen = Image.open(raw).convert("RGB")
    scale = min(1560 / screen.width, (2752 - y - 60) / screen.height)
    screen = screen.resize((round(screen.width * scale), round(screen.height * scale)), Image.LANCZOS)
    bezel = 22
    body = Image.new("RGBA", (screen.width + 2 * bezel, screen.height + 2 * bezel), (0, 0, 0, 0))
    ImageDraw.Draw(body).rounded_rectangle([0, 0, *body.size], radius=70, fill=(18, 12, 8, 255))
    mask = Image.new("L", screen.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, *screen.size], radius=50, fill=255)
    body.paste(screen, (bezel, bezel), mask)
    x = (2064 - body.width) // 2
    top = y + 60
    glow(canvas, (x + 40, top + 40, x + body.width - 40, top + body.height - 40), 110)
    canvas.alpha_composite(body, (x, top))
    return canvas.convert("RGB")


def main():
    made = 0
    for device, compose in (("iphone", compose_iphone), ("ipad", compose_ipad)):
        for locale, shots in COPY.items():
            out_dir = OUT / device / STORE_LOCALE[locale]
            out_dir.mkdir(parents=True, exist_ok=True)
            for name, (headline, sub) in shots.items():
                raw = RAW / device / locale / f"{name}.png"
                if not raw.exists():
                    raise SystemExit(f"missing raw {raw}; run tool/capture first")
                compose(raw, headline, sub).save(out_dir / f"{name}.png", optimize=True)
                made += 1
    print(f"{made} screenshots in {OUT}")


if __name__ == "__main__":
    main()

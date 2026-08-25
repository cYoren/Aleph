#!/usr/bin/env python3
"""
Compose Aleph store screenshots in the shared portfolio house style.

Produces the same look as the Cirdoku, Tessera and medhub listings, so the
portfolio reads as one family:

    raw capture -> resize to 1290x2796 -> paste into the house device frame
    -> compose.py (gradient background, starfield, device glow, headline + sub)

The raws come from scripts/capture_store_screenshots.sh, which routes straight
to a screen via the START dart-define and pins the simulator to en-US. That
locale step matters: device locale drives the app's own language, and Aleph
ships five interface languages.

Usage:
    python3 scripts/compose_store_screenshots.py
"""
import argparse
import subprocess
import sys
from pathlib import Path

from PIL import Image

PROJECT = Path(__file__).resolve().parent.parent
FRAME = PROJECT / "tool/assets/house-device-frame-iphone-6.9.png"
COMPOSE = Path.home() / ".claude/skills/appstore-screenshots/scripts/compose.py"

SCREEN_W, SCREEN_H = 1290, 2796
SCREEN_X, SCREEN_Y = 67, 55

# Aleph palette: the app is warm parchment, so the canvas carries the burnt
# orange the listing already leans on rather than fighting it with a cool tone.
BG_COLOR = "#1A0A02"
BG_GRADIENT = "#B84A0C"
DEVICE_GLOW = "#F5C46B"
HEADLINE_COLOR = "#FFFFFF"
SUB_COLOR = "#F3DCC0"

SHOTS = [
    ("01_reading", "Read It in the Language It Was Written",
     "Hebrew and Greek line by line, with transliteration and English underneath"),
    ("02_search", "Find Any Verse, Then Go Deeper",
     "Search the text and open the dictionary entry behind every word"),
    ("03_language", "Five Interface Languages, One Original Text",
     "English, Portuguese, German, French and Spanish, each with its own Bible"),
]


def frame_one(raw_path: Path, framed_path: Path) -> None:
    frame = Image.open(FRAME).convert("RGBA")
    shot = Image.open(raw_path).convert("RGB").resize((SCREEN_W, SCREEN_H), Image.LANCZOS)
    canvas = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    canvas.paste(shot, (SCREEN_X, SCREEN_Y))
    Image.alpha_composite(canvas, frame).save(framed_path)


def compose_one(framed_path: Path, out_path: Path, headline: str, sub: str) -> None:
    subprocess.run([
        sys.executable, str(COMPOSE),
        "--screenshot", str(framed_path),
        "--output", str(out_path),
        "--size", f"{SCREEN_W}x{SCREEN_H}",
        "--bg-color", BG_COLOR,
        "--bg-gradient", BG_GRADIENT,
        "--headline", headline,
        "--subheadline", sub,
        "--headline-color", HEADLINE_COLOR,
        "--subheadline-color", SUB_COLOR,
        "--device-glow", DEVICE_GLOW,
        "--particles", "60",
        "--device-scale", "0.78",
    ], check=True)


# The iPadOS pointer arc bakes into the framebuffer when the mouse hovers the
# simulator window. Patch ONLY the arc; a larger corner patch destroys UI.
ARC_X0, ARC_Y0 = 2000, 2688

# iPad ships three boards. The copy is deliberately generic: all three captures
# show a medium board, so a rule-specific headline would be describing a rule
# the image does not actually demonstrate.
IPAD_SHOTS = [
    ("01_ipad", "Minesweeper, Rebuilt in Hex",
     "Six neighbours instead of eight — every deduction changes"),
    ("02_ipad", "Read Six Neighbours at Once",
     "The hex grid gives every clue more to say"),
    ("03_ipad", "Pure Logic, No Timer Pressure",
     "Play at your own pace — deduction, not reflexes"),
]


def compose_ipad(raw_path: Path, out_path: Path, headline: str, sub: str) -> None:
    """iPad has no device frame in the house style — round the corners instead."""
    subprocess.run([
        sys.executable, str(COMPOSE),
        "--screenshot", str(raw_path),
        "--output", str(out_path),
        "--size", "2064x2752",
        "--bg-color", BG_COLOR,
        "--bg-gradient", BG_GRADIENT,
        "--headline", headline,
        "--subheadline", sub,
        "--headline-color", HEADLINE_COLOR,
        "--subheadline-color", SUB_COLOR,
        "--device-glow", DEVICE_GLOW,
        "--particles", "60",
        "--device-scale", "0.80",
        "--corner-radius", "48",
        "--headline-px", "104",
        "--sub-px", "52",
    ], check=True)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw-dir", default="screenshots/aso-refresh/raw")
    ap.add_argument("--out-dir", default="screenshots/aso-refresh")
    args = ap.parse_args()

    raw_dir = (PROJECT / args.raw_dir).resolve()
    out_root = (PROJECT / args.out_dir).resolve()
    framed_dir = out_root / "framed"
    ios_dir = out_root / "final/ios/iphone"
    play_dir = out_root / "final/android/phone"
    for d in (framed_dir, ios_dir, play_dir):
        d.mkdir(parents=True, exist_ok=True)

    if not FRAME.exists():
        print(f"missing frame: {FRAME}", file=sys.stderr)
        return 1

    # Clear stale output. Without this a shot dropped from SHOTS survives in
    # final/ and gets re-uploaded — that bug shipped once on Tessera already.
    for d in (framed_dir, ios_dir, play_dir):
        for f in d.glob("*.png"):
            f.unlink()

    present = [(s, h, sub) for s, h, sub in SHOTS if (raw_dir / f"{s}.png").exists()]
    if not present:
        print(f"no raws in {raw_dir} — run scripts/capture_store_screenshots.sh", file=sys.stderr)
        return 1
    for stem, _, _ in SHOTS:
        if not (raw_dir / f"{stem}.png").exists():
            print(f"  (skipping {stem}: no raw)")

    for idx, (stem, headline, sub) in enumerate(present, start=1):
        raw = raw_dir / f"{stem}.png"
        framed = framed_dir / f"{stem}_framed.png"
        name = f"{idx:02d}_{stem.split('_', 1)[1]}.png"
        frame_one(raw, framed)
        compose_one(framed, ios_dir / name, headline, sub)
        Image.open(ios_dir / name).save(play_dir / name)
        print(f"  [{idx}/{len(present)}] {name}")

    # --- iPad: frameless, corner-rounded, pointer arc patched out ---
    ipad_raw = out_root / "ipad/raw"
    ipad_dir = out_root / "ipad/final"
    ipad_dir.mkdir(parents=True, exist_ok=True)
    for f in ipad_dir.glob("*.png"):
        f.unlink()
    for stem, headline, sub in IPAD_SHOTS:
        src = ipad_raw / f"{stem}.png"
        if not src.exists():
            print(f"  (skipping iPad {stem}: no raw)")
            continue
        im = Image.open(src).convert("RGB")
        w, h = im.size
        px = im.load()
        bg = px[w - 300, h - 300]
        for y in range(ARC_Y0, h):
            for x in range(ARC_X0, w):
                px[x, y] = bg
        tmp = ipad_dir / f".{stem}.png"
        im.save(tmp)
        compose_ipad(tmp, ipad_dir / f"{stem}.png", headline, sub)
        tmp.unlink()
        print(f"  iPad {stem}.png")

    print(f"\niOS  : {ios_dir}")
    print(f"iPad : {ipad_dir}")
    print(f"Play : {play_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

# Store screenshots

`screenshots/aso-refresh/final/` holds the **finished, upload-ready** assets.

```
aso-refresh/
  raw/                  native iPhone captures, 1320x2868
  framed/               raw pasted into the shared house device frame
  final/ios/iphone/     1290x2796  -> App Store APP_IPHONE_67
  final/android/phone/  1290x2796  -> Play phoneScreenshots (same renders)
```

## Regenerating

```bash
scripts/capture_store_screenshots.sh      # one build per screen
python3 scripts/compose_store_screenshots.py
```

`lib/features/startup/startup_gate_screen.dart` reads a `START` dart-define and routes straight
to a screen in debug builds — `/reading`, `/search`, `/bookmarks`, `/language` — the same escape
hatch Cirdoku, Tessera, Binar.io and Dual N-Back use. The capture script also pins the simulator
to en-US before launching, because device locale drives the app's own interface language and
Aleph ships five of them.

## What ships

Three shots: the interlinear reader (the product), search, and the language picker. `/bookmarks`
is captured by the script but **held back** — on a fresh install it is an empty state that sells
nothing.

The reader shot is the committed native capture under `store-screenshots/native/`, not a fresh
one, because a fresh install shows the "Three ways in" hint banner across the top third. Seeding
`flutter.hasSeenReadingHint` into the simulator's preference plist does **not** clear it — the
value is written but the app still renders the banner — so the clean capture is reused until
someone adds a dart-define to suppress it.

## Superseded

The App Store previously led with two unframed simulator captures of the language picker, and
before that with a flat orange set whose device screen still read **"Original Bible"** while the
listing was named "Aleph: Hebrew & Greek Bible" — the Guideline 2.3.8 mismatch pattern. The app
itself now says **Aleph** on its first screen, so that risk is gone.

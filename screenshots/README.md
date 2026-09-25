# Store screenshots

`screenshots/store/` holds the finished, upload-ready sets:

```
store/
  iphone/<en-US|pt-BR>/NN.png   1290x2796  App Store IPHONE_67, Play phoneScreenshots
  ipad/<en-US|pt-BR>/NN.png     2064x2752  App Store IPAD_PRO_3GEN_129, Play tenInchScreenshots
```

The other six languages fall back to the en-US set on both stores.

## Regenerating (Linux, no simulator)

```bash
flutter test tool/capture/store_capture_test.dart --update-goldens   # raws, real app + real bible.db
uv run --no-project --with pillow python3 scripts/compose_store_screenshots.py
./scripts/push_store_listings.sh            # dry run: validates everything
./scripts/push_store_listings.sh --apply    # ASC draft + Play listing
```

The capture renders the actual widgets with the bundled fonts and database at
the store's exact pixel sizes, seeds a learner (30 Ruth words mastered, 15 in
progress) so the path and home screens show real progress, and resets the
local user database first. Headlines live in `COPY` in the compose script; add
a locale there and in `_locales` in the capture test.

## Shots

1. Interlinear reader: the product.
2. A tapped word: meaning, full entry, grammar.
3. Book path (Ruth): the learning loop.
4. Name meaning (Daniel): the share hook.
5. Home: streak and today's five minutes.

`store-screenshots/` keeps the earlier native simulator captures as provenance.

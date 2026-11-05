# Aleph

Original-language Bible reader for **iOS**, **Android**, and **macOS**, with:
- Hebrew and Greek source text
- Word-level lexicon and morphology
- Translation layer with strict-coverage multilingual rollout
- Offline SQLite data

Enabled translations in current release DB:
- `KJV` (en; Berean Standard Bible text, shown as BSB)
- `LUTHER1912` (de)
- `SYNODAL` (ru)
- `ALMEIDA` (pt)
- `OSTERVALD` (fr)
- `VALERA1909` (es)
- `CUVS` (zh)
- `KOREAN` (ko)

Supported interface languages:
- English (`en`)
- Portuguese (`pt`)
- German (`de`)
- French (`fr`)
- Spanish (`es`)
- Russian (`ru`)
- Chinese Simplified (`zh`)
- Korean (`ko`)

## Platform Scope

Current release target:
- iOS
- Android
- macOS

Web is intentionally disabled for now because the local database workflow is offline-first.

## Prerequisites

- Flutter SDK (stable)
- Dart SDK (from Flutter)
- Python 3.9+
- SQLite CLI (`sqlite3`)
- Xcode (for iOS/macOS)
- Android Studio + Android SDK (for Android)

## Local Setup

1. Install dependencies:
```bash
flutter pub get
```

2. Build the production database asset:
```bash
python3 scripts/build_full_bible_db.py \
  --output assets/bible.db \
  --cache-dir /tmp/original_bible_db_cache \
  --strict-coverage \
  --fill-kjv-gaps \
  --emit-coverage-report build/coverage_report.json
```

3. Fold the translated lexicon glosses into it. The build script recreates
   `assets/bible.db` from scratch, so this has to run after it every time:
```bash
python3 scripts/apply_gloss_translations.py
```
   Skipping this is not fatal — the app falls back to English glosses — but
   readers on the other seven languages lose their word meanings.

4. Compact the database and pack the asset the app bundles. This reshapes the
   syntax trees into compressed per-book blocks and writes `assets/bible.db.gz`,
   which is what `pubspec.yaml` ships; the app unpacks it on first launch. Run it
   after every database build, or the build fails on a missing asset:
```bash
python3 scripts/prepare_bible_db.py
```

5. Fetch the bundled recitation voice(s), reusing the verified local cache:
```bash
python3 scripts/fetch_embedded_voices.py
```

6. Run the app:
```bash
flutter run
```

## Release Checklist

1. Build `assets/bible.db`:
```bash
python3 scripts/build_full_bible_db.py \
  --output assets/bible.db \
  --cache-dir /tmp/original_bible_db_cache \
  --strict-coverage \
  --fill-kjv-gaps \
  --emit-coverage-report build/coverage_report.json
python3 scripts/apply_gloss_translations.py
```

   Then bump `kBundledDatabaseVersion` in
   `lib/data/database/database_mobile.dart`. Installed copies of the database
   are reused forever unless that number changes, so a release that ships new
   data without bumping it reaches nobody who already has the app.

   Also incorporate translated content before packing, then prepare the bundled voice:
```bash
python3 scripts/apply_lexicon_translations.py       # when translation caches exist
python3 scripts/prepare_bible_db.py
python3 scripts/fetch_embedded_voices.py
python3 scripts/fetch_embedded_voices.py --verify
```

2. Run quality gates:
```bash
./scripts/validate_release.sh
flutter analyze
flutter test
```

3. Build release artifacts:
```bash
# Android
flutter build appbundle

# iOS
flutter build ipa

# macOS
flutter build macos
```

## Notes

- `assets/bible.db` is intentionally not tracked in git.
- Release validation enforces full-corpus thresholds, strict multilingual gates, zero missing canonical refs for every enabled release translation, and lexicon enrichment coverage.
- `KOUGO` (ja) remains intentionally disabled and hidden from release UI.

## Roadmap

See [ROADMAP.md](ROADMAP.md) for direction and priorities (real lexicons, real syntax
trees, the personalized reader mode, passage memorization in Hebrew).

## Data Sources & Attribution

- Hebrew/Greek token data with morphology: [`themikejr/bible-mcp`](https://github.com/themikejr/bible-mcp) (MACULA-derived, CC BY 4.0)
- Translations: [`seven1m/open-bibles`](https://github.com/seven1m/open-bibles) (public domain / per-file licenses)
- Strong's dictionary definitions: [`openscriptures/strongs`](https://github.com/openscriptures/strongs) (CC BY-SA, © Open Scriptures)
- Cross-references: [OpenBible.info](https://www.openbible.info/labs/cross-references/) (CC Attribution)
- Syntax trees: [MACULA Hebrew](https://github.com/Clear-Bible/macula-hebrew) & [MACULA Greek](https://github.com/Clear-Bible/macula-greek) (Clear Bible, CC BY 4.0)
- Scholarly lexicons: [BDB](https://github.com/openscriptures/HebrewLexicon) and [Abbott-Smith](https://github.com/translatable-exegetical-tools/Abbott-Smith) (public domain digitizations)
- Bundled recitation voice: [Piper](https://huggingface.co/rhasspy/piper-voices) `el_GR/rapunzelina` (voice MIT, dataset CC0), run by [sherpa-onnx 2.0.1](https://github.com/k2-fsa/sherpa-onnx) (Apache-2.0) with generated corpus pronunciations. eSpeak code and dictionary data are excluded from the bundle; see [the runtime migration](docs/tasks/greek-speech-2.md). No suitable Hebrew model has been validated for this project (see `docs/tasks/embedded-voices-findings.md`).
- Long-form lexicon translations: the offline pipeline is implemented, but the seven-language translation cache has not been generated. English originals remain visible with a localized notice until translated content is incorporated.

## Android Signing

- Copy `android/key.properties.example` to `android/key.properties`.
- Fill in real keystore values.
- Keep signing files out of version control.

## Contributing

Contributions are welcome! Please check out [CONTRIBUTING.md](CONTRIBUTING.md) for local development setup, code generation, and verification guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

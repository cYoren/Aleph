# Original Bible

Original-language Bible reader for **iOS**, **Android**, and **macOS**, with:
- Hebrew and Greek source text
- Word-level lexicon and morphology
- Translation layer with strict-coverage multilingual rollout
- Offline SQLite data

Enabled translations in current release DB:
- `KJV` (en)
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

3. Run the app:
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

## Android Signing

- Copy `android/key.properties.example` to `android/key.properties`.
- Fill in real keystore values.
- Keep signing files out of version control.

## Contributing

Contributions are welcome! Please check out [CONTRIBUTING.md](CONTRIBUTING.md) for local development setup, code generation, and verification guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

# Original Bible Agent Contract

## Mission and canonical location

Offline-first original-language Bible reader for iOS, Android, and macOS with Hebrew and Greek text, morphology, lexicons, translations, and SQLite data. Canonical VPS working copy: `/root/projects/original-bible-open-source`. GitHub: `https://github.com/cYoren/original-bible-open-source`.

## Start here

1. Check `git remote -v`, `git status --short --branch`, and the current branch.
2. Read `README.md`, `CONTRIBUTING.md`, and `ROADMAP.md`.
3. Keep `assets/bible.db` untracked and generated from the documented source pipeline.
4. Preserve attribution, license compatibility, translation provenance, and strict coverage thresholds.

## Setup and verification

```bash
flutter pub get
python3 scripts/build_full_bible_db.py --output assets/bible.db --cache-dir /tmp/original_bible_db_cache --strict-coverage --fill-kjv-gaps --emit-coverage-report build/coverage_report.json
./scripts/validate_release.sh
flutter analyze
flutter test
```

Release artifacts require separate verification for Android, iOS, and macOS. Do not claim a store release from a successful local build alone. Never commit keystores, provisioning files, credentials, generated databases, or private exports.

## Data and product safety

Treat translation, morphology, lexicon, and attribution changes as content correctness changes. Read the relevant source and coverage report before changing generated data. Keep the product positioned as an offline Bible reader, not a clinical or general-purpose app.

Use Git-backed branches and PRs. Include the exact database command, coverage result, platform checks, and attribution impact in PRs.

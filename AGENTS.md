# Original Bible Agent Contract

## Mission and canonical location

Offline-first original-language Bible reader for iOS, Android, and macOS with Hebrew and Greek text, morphology, lexicons, translations, and SQLite data. Canonical VPS working copy: `/root/projects/original-bible-open-source`. GitHub: `https://github.com/cYoren/Aleph`.

## Start here

1. Check `git remote -v`, `git status --short --branch`, and the current branch.
2. Read `README.md`, `CONTRIBUTING.md`, and `ROADMAP.md`.
3. Keep `assets/bible.db` untracked and generated from the documented source pipeline.
4. Preserve attribution, license compatibility, translation provenance, and strict coverage thresholds.

## Setup and verification

```bash
flutter pub get
python3 scripts/build_full_bible_db.py --output assets/bible.db --cache-dir /tmp/original_bible_db_cache --strict-coverage --fill-kjv-gaps --emit-coverage-report build/coverage_report.json
python3 scripts/prepare_bible_db.py         # compacts bible.db and writes bible.db.gz
./scripts/validate_release.sh               # data gates + the python pipeline tests
flutter analyze
flutter test
```

The release database carries five layers the definition sheet reads directly:
`lexicon` (flattened entry text), `lexicon_senses` (numbered senses from BDB and
Abbott-Smith), `lexicon_roots` (TWOT root per Strong's id), the participant
columns on `words` (`subject_text`/`referent_text`), and `syntax_trees`.
`validate_release.sh` fails if senses, roots or participant links are thin, so a
build that skips the extended lexicon (or a source that moved) stops there rather
than shipping a sheet with nothing in it.

Before any store build, run `scripts/release_preflight.sh`: release data
gates, `flutter analyze`, `flutter test`, the bundled-database asset, and (on a
Mac) a simulator launch pass that fails unless the app actually paints on an
iPhone and an iPad. `scripts/sim_launch_check.py` is the launch pass on its own.

Telemetry is release-only by construction (`lib/core/telemetry_gate.dart` and
`lib/core/telemetry_startup.dart`): a release build reports, every other build is
silent. A build that must stay silent skips `SentryFlutter.init` entirely, because
the SDK throws on a null DSN rather than ignoring it.

Release artifacts require separate verification for Android, iOS, and macOS. Do not claim a store release from a successful local build alone. Never commit keystores, provisioning files, credentials, generated databases, or private exports.

## Data and product safety

Treat translation, morphology, lexicon, and attribution changes as content correctness changes. Read the relevant source and coverage report before changing generated data. Keep the product positioned as an offline Bible reader, not a clinical or general-purpose app.

Use Git-backed branches and PRs. Include the exact database command, coverage result, platform checks, and attribution impact in PRs.

## The tip jar (2026-11-11)

Aleph has nothing to buy and stays that way. Settings has one row, **Support
Aleph**, which opens a sheet with three CONSUMABLE tips. They unlock nothing, and
the sheet says so before the buttons.

| Product | Price | Kind | Store state |
| --- | --- | --- | --- |
| `support_small` | 2.99 | CONSUMABLE | App Store: created, IAP version + en-US localization, needs a review screenshot |
| `support_medium` | 9.99 | CONSUMABLE | same |
| `support_large` | 24.99 | CONSUMABLE | same |
| all three | — | — | **Google Play: the products do not exist yet.** Create them in the Play Console (consumables, same ids and prices) before shipping: the Play publishing API refuses every IAP call with `403: migrate to the new publishing API` |

Code: `lib/core/support_service.dart` (products, pricing from the store, purchase
and completion handling) and `lib/features/settings/support_sheet.dart` (the
sheet). Entry points: the Settings row only. Nothing prompts, nothing nags, and
there is no restore button because a tip is consumable and can be given again.

Never do these: never gate a feature behind a tip, never add a subscription or
ads, never hardcode a price, never thank the reader before the store confirms
the payment, and never add a tip jar anywhere except Settings.

Before a store release of this change:

1. `flutter test`, `flutter analyze` and `ls`-check the generated l10n: the
   eleven support strings exist in all eight `lib/l10n/app_*.arb` files and the
   generated files under `lib/l10n/generated/` are committed (regenerate with
   `flutter gen-l10n` after any string change).
2. Build on the Mac; version is `1.0.7+30`, and build 30 is still free on App
   Store Connect, so keep it unless another upload took it.
3. Attach a review screenshot to each of the three IAP versions
   (`asc iap versions images create`), then add them to the same review
   submission as the app version (`asc iap versions submit`).
4. Run the existing `./scripts/validate_release.sh` and the full test suite; the
   support sheet tests are `test/support_test.dart`.
5. Store copy is already updated: `fastlane/metadata/en-US/description.txt`,
   `release_notes.txt` and `review_information/notes.txt` name the tip jar and
   explain that nothing is delivered and how to test a tip.
6. A real sandbox tip on both platforms before submitting. Play first, App Store
   second.

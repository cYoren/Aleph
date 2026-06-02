# Original Bible - Full Release Summary

## Project Status

Release candidate is valid only when all of these are true:
- `assets/bible.db` is rebuilt with `scripts/build_full_bible_db.py`
- `./scripts/validate_release.sh` passes full-corpus checks
- `flutter analyze` and `flutter test` pass

## Full-Release Data Contract

The release DB must include:
- `books` table with exactly 66 rows
- `verses` coverage for all 66 books
- At least 31,100 source-language verses
- At least 31,100 `KJV` translation verses (gap-filled to canonical zero-miss)
- At least 600,000 word rows
- At least 13,000 lexicon rows
- `KJV` canonical missing refs must be `0`
- Enabled translations count must be at least `8` (`KJV` + DE/RU/PT/ES/FR + ZH + KO rollout)
- Required enabled IDs: `KJV`, `LUTHER1912`, `SYNODAL`, `ALMEIDA`, `OSTERVALD`, `VALERA1909`, `CUVS`, `KOREAN`
- `KOUGO` must remain disabled for release UX

## Build and Validation Commands

```bash
python3 scripts/build_full_bible_db.py \
  --output assets/bible.db \
  --cache-dir /tmp/original_bible_db_cache \
  --strict-coverage \
  --fill-kjv-gaps \
  --emit-coverage-report build/coverage_report.json
./scripts/validate_release.sh
flutter analyze
flutter test
```

## Runtime Translation Behavior

- Onboarding maps locale defaults once:
  - `en -> KJV`, `de -> LUTHER1912`, `ru -> SYNODAL`, `pt -> ALMEIDA`, `es -> VALERA1909`, `fr -> OSTERVALD`, `zh -> CUVS`, `ko -> KOREAN`
- After onboarding, app language and translation are independent.
- If a selected translation yields no chapter data, reader retries with `KJV` and persists the normalized choice.
- If a saved translation is disabled/not enabled in DB, settings normalize to enabled default for current app language.

## Notes

- `assets/bible.db` stays out of git and is generated at build/release time.
- Source TSV and Open Bibles downloads are pinned to specific upstream commits in the builder script for reproducibility.

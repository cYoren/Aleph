# Project friction log

## Open

- [ ] Verify the legacy Flutter repository is not used by CI, release jobs, or local automation before quarantine.
      Confirmed still live: a `flutter run` on 2026-08-11 emitted `Stale file ... /Users/<user>/Documents/Coding/Original bible/lib/l10n/generated/...` warnings, so the legacy checkout is still being referenced by the local build.
- [ ] Keep generated database assets and coverage reports outside source-oriented paths.
- [ ] Cross-reference entry point is undiscoverable (unlabeled icon among four). Needs a count badge without adding a per-verse query to a scrolling list.
- [ ] Reader opens on Genesis 1 with no onboarding for someone who has never read Hebrew; the first run should teach the tap/long-press/recite affordances.

## Resolved

- [x] 2026-08-07: Added canonical workspace guidance and generated-asset rules.

## Rules

- Never claim a store release from a successful local build alone.

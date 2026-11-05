# Aleph: first reading and home refinement

## Product and scope

Audience: people learning to read Hebrew and Greek, including beginners who do
not yet recognize the script. The core outcome is understanding a word in its
original text, then continuing to read. Existing authority: ROADMAP.md,
lib/app/theme.dart, the bundled Gentium and EzraSIL fonts, and current screens.
Preserve the parchment/night palette, offline database, reading traditions,
all study destinations, translation provenance and existing AI consent behavior.

This is a scoped refinement of the current Flutter app, not a new visual world.
Impeccable owns Operate/Read craft. Revenue-Centric Design owns activation and
attention hierarchy. Taste-skill was read as requested; its explicit exclusion
of native app screens means no marketing-page direction draw, mandatory scroll
choreography or website inspector is applied to Flutter screens. There is no
public marketing page in this checkout; web/index.html is a Flutter bootstrap.

## Principles and exact moves

| Principle | Applied move | Verification |
| --- | --- | --- |
| Value first; active onboarding | Replace the six-page feature tour with a working dictionary lookup using actual Genesis 1:1 words before setup. | First-action widget test opens the real DefinitionSheet and resolves the entry. |
| Reduce time-to-value by reordering/removal | Keep the word experience and reading-tradition choice, plus AI privacy choice only when configured; finish directly in the reader. | Completion and skip tests check the reader route and saved completion flag. |
| Attention hierarchy | Give the current chapter a labeled, filled reading action; give learning tools readable list rows rather than equal icon cards. | Native Flutter screenshots at 390×844, 820×1180 and 1440×900. |
| Swiss Knife filter | Improve discovery of existing tools; add no monetization, tracking, notifications or extra study feature. | Source diff; existing destinations retained. |
| Impeccable: preserve the incumbent visual world | Retain the fonts, colors, RTL scripture, native navigation and theme roles; remove small uppercase home labels and decorative section rules. | Before/after screenshots, light and dark. |
| Impeccable: readable measure and resilient layouts | Reuse the 720 logical-pixel home measure; bound onboarding text and buttons, scroll long pages, respect text scaling and reduced motion. Keep tab names visible. | Enlarged German text, dark-mode captures, behavioral tests and analysis. |

Revenue-Centric Design sources (local reference material read in full):

- [Active onboarding](https://x.com/richardrx/status/2046959126245249288).
- [Reordering to reduce time-to-value](https://x.com/richardrx/status/2037583944283996418).
- [Attention hierarchy](https://x.com/richardrx/status/2039399756452057159).
- [Swiss Knife feature filter](https://x.com/richardrx/status/2059236567533650119).

These are applied design principles, not measured growth results for Aleph.
The activation hypothesis is that experiencing a word lookup before setup helps
new readers reach useful reading sooner. No conversion or retention uplift is
claimed and no analytics are added.

## Visual review

Initial weaknesses: the first useful interaction followed six introduction pages;
small uppercase home labels; equal-weight study tiles; unlabeled inactive tabs;
home and onboarding copy stretching across wide windows.

The first rendered pass exposed a Hebrew proclitic token as the first preview
word, which can lack a useful dictionary entry. The final pass uses the existing
proclitic filter to present three lexical words. It also exposed the AI sparkle
as an unsupported font glyph: render the actual reader icon inline and use its
localized action name for screen readers. Large-text pages scroll independently
of the persistent next/start action. All other existing claims/copy are preserved.

Capture command (local only; uses deterministic fixtures and bundled fonts):

```bash
cd /home/gustvmar/Documents/Coding/Aleph
flutter test --no-pub tool/capture/design_capture_test.dart --dart-define=PHASE=final --update-goldens
```

Screenshots are ignored under tool/capture/raw/design/. They are Flutter widget
renders on Linux, not browser, iOS Simulator, Android emulator or hardware
captures. Fixtures demonstrate layouts and states; they are not production
usage data. iOS/Android interaction, voice and performance verification remain
part of the normal native release process. No store release is performed.

## Validation

- Full suite: 308 passed, 2 existing opt-in tests skipped.
- Analysis: no issues; design detector returns no findings (Dart coverage is
  not a substitute for visual review).
- Rendered six states at each requested size: home, first-action introduction,
  tradition choice, configured AI privacy choice, dark home, and German tradition
  choice at 200% text size.
- Initial validation exposed an integration mismatch: the feature branch expected
  one syntax-tree row per verse, while the database already used 66 compressed
  book blocks. Integrating main restores the correct reader and validator. The
  decoded corpus has exactly 31,152 canonical verse records, with none missing
  or extra. The strengthened validator checks each record and its JSON.
- Database generation command: not run; existing assets reused. Translation
  coverage and content attribution are unchanged by this patch.

## Completion pass, 2026-11-04

Integrated the existing compressed-database reader, packed-only asset packaging
and Android edge-to-edge/shrinking fixes. Tablets and wide windows now use a
scrollable navigation rail. The initial language chooser scrolls as a whole,
including its heading, so landscape and large text cannot squeeze the list away.

Migrated Greek recitation to sherpa-onnx 2.0.1 and a generated corpus lexicon.
The same verified model is reused. eSpeak code and dictionaries no longer ship.
See [Greek speech migration](../tasks/greek-speech-2.md). New installs keep AI
off until explicitly enabled, while an existing saved choice is preserved.
Data, font and voice notices are accessible offline from Settings → Licenses.

An actual-platform integration runner now exercises first reading, dictionary
lookup, syntax, search, core routes, dark theme, native synthesis and muted
playback completion. Native results are recorded separately from fixture renders.

# Release 1.0.6: to-do for the release agent

Everything below is ready on `main`. These steps need Gus's accounts or Mac.
Do them in order, tick each box, and **delete this file in the last step**.

## Why this is urgent

Live iOS 1.0.5 (build 27) was built by CI without `assets/bible.db`: the 25 MB
IPA has no Bible text, so every fresh iOS install since about 2026-09-07 is
empty. The workflow is fixed and `pubspec.yaml` now names the file, so a build
without it fails instead of shipping empty.

## Steps

- [ ] **Fix GitHub Actions billing.** On 2026-09-25 macOS jobs were refused:
      "recent account payments have failed or your spending limit needs to be
      increased" (Settings, Billing & plans).
- [ ] **iOS build:** `gh workflow run ios-testflight.yml --ref main`.
      Check the IPA is large (the database alone is over 200 MB). If the
      Flutter build fails, look first at the notification setup
      (`ios/Runner/AppDelegate.swift`), which has never been compiled.
- [ ] **Store listing and screenshots:**
      `./scripts/push_store_listings.sh` (dry run), then `--apply`. It writes
      8-locale copy and 20 screenshots to the App Store 1.0.6 draft
      (app 6758858816) and the Play listing.
- [ ] **Submit iOS 1.0.6:** attach the new build to the 1.0.6 draft and submit
      for review.
- [ ] **Android:** power on the Mac and re-register its self-hosted runner
      (the repo shows none; it holds the release keystore at
      `~/Documents/Coding/Original bible/android/`). Then
      `gh workflow run android-production.yml --ref main`. First compile of
      the notification setup (core library desugaring, receivers in
      `AndroidManifest.xml`); fix there if it fails.
- [ ] **Optional, AI tutor:** deploy `proxy/` (`proxy/README.md`: wrangler
      login, `OPENROUTER_API_KEY` secret, deploy), then set the repository
      variable `ALEPH_AI_PROXY` to the worker URL and rebuild. Without it the
      tutor stays hidden; nothing breaks.
- [ ] **Launch posts:** use `docs/launch-kit.md` once the builds are live.
- [ ] **Clean up:** delete this file and commit
      (`git rm AGENT_TODO.md && git commit -m "chore: 1.0.6 released"`).

## Next version, not part of this release

Group and church codes (need server storage), share as video, human-recorded
audio, home-screen widget.

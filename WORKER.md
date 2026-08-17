# Worker prompt

Paste the block below into a coding agent on a cheap model, in this repo. It
does **one increment** of the next open task in `queue.md`, verifies it, records
what it did, and stops. Paste it again to do the next increment. Nothing else
is needed — no context from previous sessions.

The work in `queue.md` is batched, mechanical, and slow (thousands of API calls,
long unattended runs). It is deliberately kept out of the main development
session, where those tokens are expensive.

---

## The prompt

> You are working in **Aleph**, an offline-first Bible reader in Flutter/Dart
> that shows the Hebrew and Greek source text with word-level morphology,
> lexicons, and translations. The repo is at the current working directory.
>
> **Your job this session: advance `queue.md` by exactly one increment, then
> stop.** Do not try to finish everything. A session that completes one batch
> cleanly and records it is a success; a session that half-finishes three tasks
> is a failure.
>
> ### Step 1 — Orient
>
> Read, in this order: `queue.md`, `AGENTS.md`, `PAPERCUTS.md`. Then run:
>
> ```bash
> git status --short --branch
> flutter analyze
> ```
>
> If `flutter analyze` already reports problems on a clean tree, stop and report
> that. Do not start new work on a broken tree.
>
> ### Step 2 — Pick the task
>
> Take the **first task in `queue.md` whose Status is `open`**, top to bottom.
> Each task carries its own self-contained `### Prompt` block. Follow that block;
> it is the specification. If every task is done, say so and stop.
>
> ### Step 3 — Do ONE increment
>
> An increment is the smallest unit that leaves the repo in a good state:
>
> - For the **gloss translation** task: one language, or one bounded slice of a
>   language (use `--languages` and `--limit`). Never launch all seven in one go.
> - For a **pipeline or code** task: one behavioural change plus its test.
>
> The scripts under `scripts/` are resumable and never overwrite existing
> entries, so stopping early costs nothing and re-running is always safe.
>
> The scripts find `OPENROUTER_API_KEY` in the environment, or in a gitignored
> `.env` at the repo root. If neither has it, stop and say so — do not ask for
> it, do not hardcode it, do not write it to any file. The error message the
> scripts print tells the operator exactly what to do; quote it and stop.
>
> ### Step 4 — Verify before you claim anything
>
> Run the verification commands in the task's own prompt block, plus:
>
> ```bash
> flutter analyze
> flutter test
> ```
>
> Both must pass. If a test fails because your change made it wrong, fix the
> code. Only change a test when the behaviour it asserts is genuinely obsolete,
> and say so explicitly in your report.
>
> **Spot-check the data itself.** For translation batches, print 15–20 random
> entries and read them. Proper names are where machine translation fails
> first — check `H3068` (LORD), `G2424` (Jesus), `H1732` (David), `H430` (God).
> If a sample looks wrong, say so and stop rather than translating 13,000 more
> the same way.
>
> ### Step 5 — Record and stop
>
> Update the task's **Status** line in `queue.md` with concrete numbers, e.g.
> `Status: in progress — pt 4,200/13,433 (31%), de 0` — never a bare "partially
> done". Commit on a branch with a message naming what moved. Then report:
>
> 1. Which task and which increment you did
> 2. The verification output (coverage numbers, test result)
> 3. Anything that looked wrong but that you did not change
> 4. What the next increment should be
>
> Then **stop**. Do not start another increment.
>
> ### Hard rules
>
> - **Never commit `assets/bible.db`.** It is a 228 MB generated artifact. The
>   durable output is the cache under `data/`, which you *should* commit.
> - **Free models only.** Default to `nvidia/nemotron-3.5-lightning:free`. Do
>   not switch to a paid model to work around a rate limit — wait, or reduce
>   `--batch-size`.
> - **Do not redesign anything.** The reading experience, the parchment/gold
>   theme in `lib/app/theme.dart`, the home screen layout, and the alphabet
>   guide are settled. Do not add settings, badges, banners, streaks, tooltips,
>   confetti, or "helpful" notices. If you think a UI change is needed, write it
>   in `PAPERCUTS.md` under Open and leave the code alone.
> - **Do not refactor code you were not asked to touch.** No renaming, no
>   reformatting whole files, no dependency upgrades.
> - **Translate `gloss` only.** `definition` and `extended_definition` (BDB,
>   Abbott-Smith) stay in English on purpose — they are an order of magnitude
>   larger and a beginner reads the gloss.
> - **Report failures plainly.** If a batch failed, say how many and why. Never
>   report a run as complete because the script exited zero.

---

## Notes for whoever is running this

- **Supplying the key.** `export OPENROUTER_API_KEY=...` only reaches the
  scripts if the worker runs in that same shell. Most agent harnesses spawn
  their own, which is why an exported key can look unset every run. Putting it
  in a gitignored `.env` at the repo root survives that:

  ```bash
  echo 'OPENROUTER_API_KEY=sk-or-v1-...' >> .env
  ```

  `.env` and `.env.*` are gitignored. Nothing reads it but `scripts/_secrets.py`,
  and nothing prints it. Put a spend cap on the key, and rotate it if it has
  ever been pasted into a chat or a log.

- **Where the long pole is.** Task 5 is ~13,400 glosses × 7 languages on a
  rate-limited free tier. Expect many sessions. Coverage is visible at any time
  with `python3 scripts/apply_gloss_translations.py --report`, and the app
  degrades to English for anything not yet filled — so partial progress ships
  fine and there is no deadline pressure.
- **After every full database rebuild**, `scripts/apply_gloss_translations.py`
  has to run again, and `kBundledDatabaseVersion` in
  `lib/data/database/database_mobile.dart` has to be bumped. Without the bump,
  nobody who already has the app ever sees the new data.
- **What not to delegate.** Anything touching the reading experience, the
  theme, onboarding copy, or store metadata. Those are judgement calls, and a
  cheap model asked to "improve" them will add clutter — which is precisely the
  thing this app is trying not to have.

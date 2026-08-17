# Positioning: Aleph

## The name — decided

**The app is named Aleph**, with the tagline *Learn the Original Bible*. The
rename is applied through the code, the platform manifests and the fastlane
metadata; what is left is the listing prose and the icon (see below).

"Original Bible" was accurate and forgettable, and it collided in App Store
search with every listing containing both words — which is most of the category.
*Aleph* is the first letter of the first alphabet the app teaches: one word,
identical in all eight interface languages, and it carries the reverence the
parchment-and-gold design is reaching for. The searchable words live in the
subtitle, not in the name.

The shortlist it was chosen from is kept below, because the reasoning is the
useful part if the decision is ever revisited.

Two constraints worth stating before the list. **"OG Bible" is the fun one and
the risky one**: to anyone under about 35 it reads as *original gangster*,
which is either a memorable joke or an irreverence problem depending entirely
on who is downloading a Bible app — and that is a judgement about the audience,
not about the wording. And whatever wins, the **CNPJ-linked trade name in
Settings** (`AppIdentity.responsibleTradeName`) is a legal identifier, so it
changes only if the registration does.

| Name | The case for it | The case against |
|---|---|---|
| **OG Bible** | Rolls off the tongue, impossible to forget, and the joke *is* the explanation — "OG" already means "the original one". Cheap to say out loud, which is how apps actually spread. | Reads as slang to some, as disrespect to others. Hard to walk back once it is on the store. |
| **Aleph** | One word, the first letter of the first alphabet the app teaches. Quiet, confident, unmistakably about the source text. Pairs perfectly with the parchment-and-gold design. | Says nothing about "Bible" to someone who does not already know; leans on the icon and subtitle to carry meaning. |
| **In the Beginning** | *Bereshit* / *Ἐν ἀρχῇ* — the opening words of both testaments, in both source languages. Says "we start where the text starts". | Long for a home screen label; several books and albums already use it. |
| **Bereshit** | The actual first word of the Hebrew Bible. Maximum authenticity, and it teaches the user a word before they open the app. | Unpronounceable to most of the target audience on first sight, which is the opposite of rolling off the tongue. |

### What the rename covered, and what is left

Done: `AppIdentity.publicAppName`, the `appTitle` key in all eight ARB files,
iOS `CFBundleDisplayName`, Android `android:label` (which was still the raw
`original_bible`), the macOS `PRODUCT_NAME`, the OpenRouter `X-Title`
attribution headers, and the `fastlane/` metadata.

Left, and both need a human:

- [ ] **App Store / Play listings** — the fastlane text now says Aleph, but the
      description prose was written around the old name and reads like it. This
      is the job for the ASO pass, not a find-and-replace.
- [ ] **App icon** — drawn for the old name. An aleph (א) in gold leaf on the
      parchment ground would carry the whole identity in one glyph.

Bundle identifiers are unchanged and must stay unchanged
(`com.originalbible.originalBible`, `com.originalbible.original_bible`): they
are the store's identity for an app that already exists, and renaming them
creates a new app rather than renaming this one.

The trade name in Settings stays **Original Bible**: it is tied to the CNPJ and
changes only if the registration does. `AppIdentity.responsibleTradeName` is
deliberately no longer derived from the app name, so renaming again cannot
silently alter a legal identifier.

### Name and tagline as they ship

| Field | Value | Length |
|---|---|---|
| App Store name | `Aleph` | 5 / 30 |
| App Store subtitle | `Learn the Original Bible` | 24 / 30 |
| Play title | `Aleph` | 5 / 30 |
| Play short description | `Learn the Original Bible: read Hebrew and Greek, word by word.` | 62 / 80 |

"Aleph - Learn the Original Bible" reads well but is **32 characters**, and both
stores cap the name at 30. Splitting it is better than trimming it anyway: the
name field is for the brand, and the subtitle is where *learn*, *original* and
*Bible* actually earn their keep in search.

### On Catholic and Protestant editions

Protestant needs nothing — the app already ships the 66-book Protestant canon in
Protestant order with Protestant translations, so it is the default and always
has been.

Catholic is a data project, not a variant. The database has none of the
deuterocanonical books, and the standard tagged Septuagint (CATSS) forbids
commercial use, so this cannot be bought cheaply. See Task 6 in `queue.md` for
the full scope. **Do not market a Catholic edition until those books ship**; the
nearest honest step is a public-domain Catholic translation of the existing 66
(Figueiredo for Portuguese being the most valuable, since Almeida is Protestant
and Brazil is the largest Catholic-majority market the app targets).

## The one-line claim

**The Bible in Hebrew and Greek, with a tutor who explains what the translation
could not.**

## Why we can defend "the best AI for the biblical languages"

Marketing claims get tested by exactly the people most likely to write a
review. Here is what actually backs the claim, so nobody has to bluff:

1. **The AI can see what other Bible AIs cannot.** A general chatbot gets the
   verse as English text. Ours gets the pointed Hebrew or the Greek, the
   morphology of every word, the lemma, and the reader's chosen translation —
   because the app already has all of it offline. The question it answers is
   "what does the original say", not "what does this English sentence mean".
2. **The prompt is written to be checked.** It requires quoting the original
   word, transliterating it, and explaining any grammatical term on first use.
   It forbids inventing etymologies, forbids preaching, and requires admitting
   uncertainty. See `buildExplainSystemPrompt` in
   `lib/features/explain/explain_model.dart`.
3. **Quality is measured, not assumed.** `scripts/check_ai_health.py` runs four
   fixed passages through a model and grades the output for leaked reasoning,
   truncation, outline-instead-of-prose, and relevance. It is what decides
   whether a model ships.
4. **Degradation is visible.** Every call is scored in-app; Settings → AI
   diagnostics shows success rate, median latency, and how many answers came
   back unusable. A hosted model that quietly gets worse is caught in days, not
   after a wave of one-star reviews.

### Claims to avoid

- Do **not** say the AI is "accurate", "authoritative", or "scholar-verified".
  It is a strong tutor that is sometimes wrong, which is why the app says so on
  every answer.
- Do **not** imply theological authority or take a denominational side. The
  prompt explicitly refuses this and the marketing must match.
- Do **not** claim the app is fully offline without qualification once the AI
  is on. The honest line is: *everything works offline; the AI tutor is the one
  feature that uses the internet, and you can turn it off.*

## What makes the app itself distinctive

These are true today and verifiable in the code and data.

| Claim | What backs it |
|---|---|
| Read the actual Masoretic and Greek text | Word-level tokens with morphology, lemma, and Strong's, offline |
| Hear it read aloud in Hebrew and Greek | Continuous chapter recitation, verse highlighted as it is spoken |
| Learn to read in phrases, not word by word | Masoretic accents render as sense-unit spacing — validated across all 23,213 OT verses |
| See where the stress falls | Stress derived from the cantillation itself: `bə·rēʾ·ˈšîṯ` |
| Know what you can already read | Every book ranked by the share of its vocabulary you have mastered |
| Real dictionaries, not glosses | BDB and Abbott-Smith entries, 343,556 cross-references |
| Works with no signal at all | The entire app except the AI tutor |

## App Store description (draft)

**Short (170 chars)**

> Read the Bible in Hebrew and Greek. Tap any word for its meaning, hear the
> chapter read aloud, and ask a tutor what the original actually says.

**Long**

> Most Bible apps give you a translation. This one gives you the text the
> translators were working from.
>
> Read the Hebrew Old Testament and Greek New Testament with every word
> tappable: meaning first, then the dictionary form, pronunciation, and
> grammar. Long-press for a quick gloss without losing your place.
>
> **Hear it.** Play any chapter and listen to it read aloud in Hebrew or Greek,
> with the verse highlighted as it is spoken. Slow it right down while your ear
> catches up. It keeps playing with the screen off.
>
> **Read in phrases.** The Masoretes marked where the sense units fall, a
> thousand years ago. We render those marks as spacing, so a verse reads the
> way it was meant to be read — and show where the stress falls in each word.
>
> **Ask.** Tap ✨ on any verse and a tutor explains what the original carries
> that a translation cannot: an untranslated particle, a verb aspect, a pun, a
> word used in a way English flattens. Written for beginners, and honest when
> it is unsure.
>
> **See what you can read.** As you learn vocabulary, every book shows how much
> of it you can already handle, and suggests what to open next. Progress you can
> actually use, not a streak counter.
>
> Everything works offline. No ads, no account, no tracking. The AI tutor is
> the one feature that uses the internet, and you can switch it off.

## Free and paid

| | Free | Pro |
|---|---|---|
| The whole Bible, dictionaries, grammar, audio, vocabulary | Yes | Yes |
| AI tutor | 5 explanations a day | Unlimited |
| Model | Fast | Deeper analysis |

**Honest framing for the paywall:** the free tier is not crippled — the entire
Bible, every dictionary, all the audio and learning tools are free forever. The
paid tier buys more of the one thing that costs money to run.

**Do not** say the free model is "basic" or "limited quality". Both models are
held to the same health bar before shipping; the paid one simply reasons more
deeply and has no daily cap.

## Positioning against the field

- **YouVersion** — vastly more translations, social features, plans. It is not
  trying to teach anyone Hebrew. We do not compete on breadth.
- **Blue Letter Bible** — genuinely deep original-language tools, dated mobile
  experience. We compete directly here, on the reading experience.
- **Logos / Accordance** — professional-grade, expensive, built for people who
  already know the languages. We are the on-ramp, not the library.
- **ChatGPT with a Bible verse pasted in** — the real competitor for the AI
  feature, and the comparison we win on: it sees English, we see the pointed
  Hebrew with its morphology.

## Before launch

- [ ] App Store privacy disclosure must declare that verse text is sent to a
      third party when the AI tutor is on. It is on by default after onboarding,
      so this is not optional.
- [ ] Screenshots should lead with the reader and the recitation, not the AI —
      the offline depth is the durable differentiator; the AI is the hook.
- [ ] Run `python3 scripts/check_ai_health.py --compare` and record the result
      in the release notes.

# Positioning: Original Bible

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

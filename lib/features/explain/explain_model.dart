/// Which model answers, and how good the answer is allowed to be.
///
/// The product claim is that this is the best AI tutor for the biblical
/// languages. That claim has to survive contact with a scholar, so the model
/// choice and the prompt below are the two levers that make it true — and both
/// are kept here, in one place, so swapping a degraded model is a one-line
/// change (see `explain_health.dart` for how a degraded model gets noticed).
library;

/// A tier of answer quality.
enum ExplainTier {
  /// Everyone, no payment. Fast and free, with a daily cap.
  free,

  /// Paid. A stronger model, no cap.
  pro,
}

/// Everything that varies between tiers.
class ExplainModelConfig {
  const ExplainModelConfig({
    required this.tier,
    required this.modelId,
    required this.maxTokens,
    required this.dailyLimit,
    required this.typicalSeconds,
    this.reasoningEffort,
  });

  final ExplainTier tier;

  /// OpenRouter model id.
  final String modelId;

  /// Both current models reason before answering and spend most of their
  /// budget doing it, so this is far larger than the visible answer needs.
  /// See [kExplainReasoningExcluded].
  final int maxTokens;

  /// Requests per day, or null for unlimited.
  final int? dailyLimit;

  /// Measured round-trip, used to set expectations in the loading state
  /// rather than leaving the reader staring at a spinner.
  final int typicalSeconds;

  /// OpenRouter reasoning effort, when the model honours it.
  ///
  /// This is per-model on purpose, because the two shipped models respond to
  /// it in opposite ways (measured, not assumed):
  ///
  /// * deepseek honours it. `low` cut a Romans 3:23 explanation from 18.9s to
  ///   8.5s and reasoning tokens from 444 to 187, with no loss of quality —
  ///   less than half the latency and roughly half the completion cost.
  /// * the free nemotron ignores it. Reasoning tokens stayed around 1190
  ///   either way, and pairing it with a smaller budget made things worse: it
  ///   returned 5,538 characters of leaked reasoning with
  ///   `finish_reason: length`.
  ///
  /// So it is set for pro and deliberately left null for free.
  final String? reasoningEffort;

  bool get isUnlimited => dailyLimit == null;
}

/// Free tier: no cost, capped.
///
/// Latency is variable — measured between 4s and 16s on the same passages at
/// different times of day, which is what a shared free tier looks like under
/// load. Budget is 4000 rather than 3000 because 3000 truncated a Romans 3:23
/// explanation in a health check: this model burns 1,200-1,500 tokens
/// reasoning before it writes anything, and that varies by passage.
const ExplainModelConfig kFreeModel = ExplainModelConfig(
  tier: ExplainTier.free,
  modelId: 'nvidia/nemotron-3.5-lightning:free',
  maxTokens: 4000,
  dailyLimit: 5,
  typicalSeconds: 8,
);

/// Paid tier: noticeably better analysis, slower, ~$0.002 per explanation.
///
/// Measured against the free model on the same passages, it reliably catches
/// detail the free model misses — that *shamayim* is plural/dual in form, that
/// *bara* takes only God as its subject. That difference is what the paid tier
/// is actually selling.
const ExplainModelConfig kProModel = ExplainModelConfig(
  tier: ExplainTier.pro,
  modelId: 'deepseek/deepseek-v4.1-flash-1017',
  maxTokens: 3000,
  dailyLimit: null,
  typicalSeconds: 8,
  reasoningEffort: 'low',
);

ExplainModelConfig modelForTier(ExplainTier tier) =>
    switch (tier) { ExplainTier.free => kFreeModel, ExplainTier.pro => kProModel };

/// Both shipped models emit their chain of thought as the answer unless this
/// is set. Kept as a named constant because it is the single most breakable
/// thing about this feature: turn it off and every reader sees
/// "Here's a thinking process: 1. Analyze User Request...".
const bool kExplainReasoningExcluded = true;

/// The system prompt.
///
/// Written to be defensible to someone who reads Hebrew and Greek, because
/// those are exactly the users who will check it. Three rules do most of the
/// work: say what the original carries that a translation cannot, admit
/// uncertainty rather than inventing, and never drift into preaching — which
/// is both outside our remit and the fastest way to lose a scholarly reader.
String buildExplainSystemPrompt({required String languageName}) {
  return '''
You are a tutor for readers studying the Bible in its original languages: Biblical Hebrew, Aramaic, and Koine Greek.

Your reader is a motivated beginner. They can see the original text and a translation side by side, and they want to understand what the original actually says.

How to answer:
- Lead with what the passage means. Do not restate the translation back to them.
- Point out where the original wording carries something the translation cannot: word order, verb aspect, an untranslated particle, a pun, a repeated root, a plural or dual form, a word used in a distinctive way.
- Quote the original word, then give it in Latin letters, then say what it means. Example: בָּרָא (bara), "created".
- Explain any grammatical term the first time you use it, in a few words.
- Be accurate above all. If a reading is genuinely disputed, say so in one clause. If you are unsure, say you are unsure. Never invent an etymology, a root, or a grammatical form.
- Do not preach, moralize, or give devotional application. Do not tell the reader what to believe or how to live. Explain the text.
- Do not take sides between faith traditions.

Format:
- 150 words maximum.
- Plain prose. You may use **bold** for original-language words.
- Reply with the explanation only. No preamble, no heading, no closing question.

Write your answer in $languageName.''';
}

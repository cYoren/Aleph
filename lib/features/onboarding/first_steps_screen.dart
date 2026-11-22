/// The first ten minutes: three letters, one word, one verse, five words.
///
/// Everything else in the app assumes the reader can already sound out a
/// letter. This is the one place that does not, and it is the whole on-ramp:
/// each step is small enough to finish, every word of the first verse carries
/// its sound and its meaning, and the last step turns five of those words into
/// real spaced-repetition cards so the reader leaves with something scheduled.
///
/// No audio is invented here: the letter sounds are the same written hints the
/// alphabet guide uses, because a platform voice reading a bare Hebrew letter
/// says its name, not its sound.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/models/word.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/database_provider.dart';
import '../../providers/word_provider.dart';
import '../../shared/utils/hebrew_syllables.dart';
import '../../shared/utils/transliterator.dart';
import '../../shared/utils/vocabulary_filter.dart';
import '../../shared/widgets/definition_sheet.dart';
import '../../core/usage_events.dart';
import '../alphabet/alphabet_provider.dart';
import '../settings/settings_provider.dart';
import '../vocabulary/vocabulary_item_tile.dart';
import '../vocabulary/vocabulary_provider.dart';
import 'first_run.dart';

const _fallbackTranslationId = 'KJV';

/// One word of the first verse, ready to show with everything a beginner needs.
class FirstVerseWord {
  final Word word;
  final String transliteration;
  final String gloss;

  const FirstVerseWord({
    required this.word,
    required this.transliteration,
    required this.gloss,
  });
}

class FirstVerseData {
  final String reference;
  final List<FirstVerseWord> words;
  final String translation;
  final bool isHebrew;
  final List<VocabularyDeckItem> reviewWords;

  const FirstVerseData({
    required this.reference,
    required this.words,
    required this.translation,
    required this.isHebrew,
    required this.reviewWords,
  });

  bool get isEmpty => words.isEmpty;
}

/// The verse the reader meets first, in the script they chose to start with.
final firstVerseProvider = FutureProvider.family<FirstVerseData, bool>((
  ref,
  isHebrew,
) async {
  final dao = ref.watch(bibleDaoProvider);
  final translation = ref.watch(settingsProvider.select((s) => s.translation));
  final bookId = isHebrew ? 'GEN' : 'JHN';
  final chapter = 1;
  final verseNumber = 1;
  final verseId = '$bookId.$chapter.$verseNumber';

  final verseWords = await dao.getWordsForVerse(verseId);
  final keys = verseWords
      .map((w) => w.lexiconLookupKey)
      .whereType<String>()
      .toSet()
      .toList();
  final entries = await dao.getLexiconEntriesForStrongs(keys);

  final words = <FirstVerseWord>[];
  final reviewItems = <VocabularyDeckItem>[];
  final seen = <String>{};

  for (var i = 0; i < verseWords.length; i++) {
    final word = verseWords[i];
    final key = word.lexiconLookupKey;
    final entry = key == null ? null : entries[key];
    final gloss = entry?.gloss?.trim() ?? '';

    final transliteration = isHebrew
        ? _hebrewTransliteration(word, i == verseWords.length - 1)
        : Transliterator.transliterate(word.displayText, isHebrew: false);

    words.add(
      FirstVerseWord(
        word: word,
        transliteration: transliteration,
        gloss: gloss,
      ),
    );

    if (key != null &&
        seen.add(key) &&
        reviewItems.length < 5 &&
        gloss.isNotEmpty &&
        isDeckWorthy(lemma: entry?.lemma, gloss: gloss, isHebrew: isHebrew)) {
      reviewItems.add(
        VocabularyDeckItem(
          lexiconKey: key,
          frequency: 0,
          entry: entry,
          progress: null,
          isHebrew: isHebrew,
        ),
      );
    }
  }

  var translationText = '';
  final translations = await dao.getTranslationVersesForChapter(
    bookId,
    chapter,
    translation,
  );
  translationText = translations[verseId] ?? '';
  if (translationText.isEmpty && translation != _fallbackTranslationId) {
    final fallback = await dao.getTranslationVersesForChapter(
      bookId,
      chapter,
      _fallbackTranslationId,
    );
    translationText = fallback[verseId] ?? '';
  }

  return FirstVerseData(
    reference: '$bookId $chapter:$verseNumber',
    words: words,
    translation: translationText,
    isHebrew: isHebrew,
    reviewWords: reviewItems,
  );
});

String _hebrewTransliteration(Word word, bool isVerseFinal) {
  final syllabified = syllabifyHebrew(
    word.displayText,
    isVerseFinal: isVerseFinal,
  );
  if (syllabified.isEmpty) {
    return Transliterator.transliterate(word.displayText, isHebrew: true);
  }
  return syllabified.marked;
}

class FirstStepsScreen extends ConsumerStatefulWidget {
  const FirstStepsScreen({super.key});

  @override
  ConsumerState<FirstStepsScreen> createState() => _FirstStepsScreenState();
}

class _FirstStepsScreenState extends ConsumerState<FirstStepsScreen> {
  int _stage = 0;
  SourceAlphabet _alphabet = SourceAlphabet.hebrew;
  bool _reviewing = false;

  bool get _isHebrew => _alphabet == SourceAlphabet.hebrew;

  @override
  void initState() {
    super.initState();
    // Coming back after the first verse skips the steps already behind the
    // reader; the closing card is where they left off.
    final firstRun = ref.read(firstRunProvider);
    if (firstRun.hasReviewedFirstWords) {
      _stage = 4;
    } else if (firstRun.hasReadFirstVerse) {
      _stage = 3;
    } else if (firstRun.lettersAt != null) {
      _stage = 1;
    }
  }

  void _next() async {
    final firstRun = ref.read(firstRunProvider.notifier);
    switch (_stage) {
      case 0:
        await firstRun.completeLetters();
        UsageEvents.record(
          UsageEvent.beginnerLessonCompleted,
          properties: const {'lesson': 'letters'},
        );
      case 1:
        // Nothing to record: seeing the word is not a claim about knowing it.
        break;
      case 2:
        await firstRun.completeVerse();
        UsageEvents.record(
          UsageEvent.beginnerLessonCompleted,
          properties: const {'lesson': 'first_verse'},
        );
      default:
        break;
    }
    if (mounted) setState(() => _stage = (_stage + 1).clamp(0, 4));
  }

  Future<void> _review(FirstVerseData data) async {
    setState(() => _reviewing = true);
    final srs = ref.read(srsDaoProvider);
    final before = <String, DateTime?>{};
    for (final item in data.reviewWords) {
      before[item.lexiconKey] =
          (await srs.getProgress(item.lexiconKey))?.lastReviewedAt;
    }

    for (final item in data.reviewWords) {
      if (!mounted) return;
      await reviewDeckItem(context, item);
      if (!mounted) return;
      final after = await srs.getProgress(item.lexiconKey);
      // Dismissing the card without answering ends the session: the closing
      // card's number is only honest if the reviews actually happened.
      if (after == null || after.lastReviewedAt == before[item.lexiconKey]) {
        setState(() => _reviewing = false);
        return;
      }
    }

    await ref.read(firstRunProvider.notifier).completeReview();
    UsageEvents.record(
      UsageEvent.beginnerLessonCompleted,
      properties: const {'lesson': 'first_review'},
    );
    if (!mounted) return;
    setState(() {
      _reviewing = false;
      _stage = 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final firstRun = ref.watch(firstRunProvider);
    final verseAsync = ref.watch(firstVerseProvider(_isHebrew));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.firstStepsTitle),
        actions: [
          if (_stage < 3)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SegmentedButton<SourceAlphabet>(
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                segments: [
                  ButtonSegment(
                    value: SourceAlphabet.hebrew,
                    label: Text('א', style: _scriptStyle()),
                  ),
                  ButtonSegment(
                    value: SourceAlphabet.greek,
                    label: Text('α', style: _scriptStyle()),
                  ),
                ],
                selected: {_alphabet},
                onSelectionChanged: (selection) =>
                    setState(() => _alphabet = selection.first),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            _StageProgress(stage: _stage),
            const SizedBox(height: 20),
            switch (_stage) {
              0 => _buildLetters(l10n, colorScheme),
              1 => _buildWord(l10n, colorScheme),
              2 => _buildVerse(l10n, colorScheme, verseAsync),
              3 => _buildReview(l10n, colorScheme, verseAsync),
              _ => _buildDone(l10n, colorScheme, firstRun),
            },
          ],
        ),
      ),
    );
  }

  static TextStyle _scriptStyle() => const TextStyle(fontSize: 18);

  Widget _buildLetters(AppLocalizations l10n, ColorScheme colorScheme) {
    final referenceAsync = ref.watch(alphabetReferenceProvider);
    final reference = referenceAsync.valueOrNull;
    final chart = reference?.chart(_alphabet);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StageTitle(
          title: l10n.firstStepsLettersTitle,
          description: l10n.firstStepsLettersDesc,
        ),
        const SizedBox(height: 24),
        if (chart == null)
          // A failed asset load must not park the reader on a spinner; the
          // steps still work, and the alphabet guide is one tap from home.
          referenceAsync.isLoading
              ? const Center(child: CircularProgressIndicator())
              : const SizedBox.shrink()
        else
          for (final letter in chart.letters.take(3))
            _LetterCard(
              glyph: letter.glyph,
              name: letter.name,
              transliteration: letter.transliteration,
              hint: reference?.hintFor(letter.id) ?? '',
              isHebrew: chart.isRtl,
            ),
        const SizedBox(height: 28),
        _PrimaryButton(label: l10n.firstStepsContinue, onPressed: _next),
      ],
    );
  }

  /// The letters just met, inside a word from the Bible. The example word is
  /// the alphabet guide's own, so the two screens never disagree about what a
  /// letter looks like in the wild.
  Widget _buildWord(AppLocalizations l10n, ColorScheme colorScheme) {
    final referenceAsync = ref.watch(alphabetReferenceProvider);
    final reference = referenceAsync.valueOrNull;
    final chart = reference?.chart(_alphabet);
    final glosses =
        ref.watch(alphabetExampleGlossesProvider).valueOrNull ??
        const <String, String>{};
    final letter = chart?.letters.isEmpty ?? true
        ? null
        : chart!.letters.first;
    final gloss = letter == null
        ? ''
        : (letter.strongs == null
              ? (letter.gloss ?? '')
              : glosses[letter.strongs!] ?? letter.gloss ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StageTitle(
          title: l10n.firstStepsWordTitle,
          description: l10n.firstStepsWordDesc,
        ),
        const SizedBox(height: 28),
        if (letter == null)
          referenceAsync.isLoading
              ? const Center(child: CircularProgressIndicator())
              : const SizedBox.shrink()
        else
          Center(
            child: Column(
              children: [
                Text(
                  letter.lemma ?? '',
                  textDirection: chart!.isRtl
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 40,
                    height: 1.5,
                    fontFamily: chart.isRtl ? 'EzraSIL' : 'Gentium',
                    color: colorScheme.onSurface,
                  ),
                ),
                if ((letter.lemmaTransliteration ?? '').isNotEmpty)
                  Text(
                    letter.lemmaTransliteration!,
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  gloss,
                  style: TextStyle(fontSize: 17, color: colorScheme.primary),
                ),
              ],
            ),
          ),
        const SizedBox(height: 32),
        _PrimaryButton(label: l10n.firstStepsContinue, onPressed: _next),
      ],
    );
  }

  /// The five words worth keeping from the verse, as real review cards.
  Widget _buildReview(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    AsyncValue<FirstVerseData> verseAsync,
  ) {
    final data = verseAsync.valueOrNull;
    final words = data?.reviewWords ?? const <VocabularyDeckItem>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StageTitle(
          title: l10n.firstStepsReviewTitle,
          description: l10n.firstStepsReviewDesc,
        ),
        const SizedBox(height: 24),
        for (final item in words)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(
                  item.entry?.lemma ?? item.lexiconKey,
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: _isHebrew ? 'EzraSIL' : 'Gentium',
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.entry?.gloss ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        _PrimaryButton(
          label: l10n.firstStepsReviewButton,
          onPressed: _reviewing || data == null
              ? null
              : () => _review(data),
        ),
        if (_reviewing)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildVerse(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    AsyncValue<FirstVerseData> verseAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StageTitle(
          title: l10n.firstStepsVerseTitle,
          description: l10n.firstStepsVerseDesc,
        ),
        const SizedBox(height: 24),
        verseAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('${l10n.error}: $error'),
          data: (data) {
            if (data.isEmpty) {
              return Text(l10n.noResults);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  alignment: data.isHebrew ? WrapAlignment.end : WrapAlignment.start,
                  textDirection:
                      data.isHebrew ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    for (final entry in data.words)
                      _FirstWordCard(
                        entry: entry,
                        isHebrew: data.isHebrew,
                        onTap: () {
                          ref.read(selectedWordProvider.notifier).state =
                              entry.word;
                          DefinitionSheet.show(context);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.firstStepsVerseHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const DivineRule(padding: EdgeInsets.symmetric(vertical: 18)),
                if (data.translation.isNotEmpty)
                  Text(
                    data.translation,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.55,
                      color: colorScheme.onSurface,
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        _PrimaryButton(label: l10n.firstStepsContinue, onPressed: _next),
      ],
    );
  }

  Widget _buildDone(
    AppLocalizations l10n,
    ColorScheme colorScheme,
    FirstRunState firstRun,
  ) {
    final minutes = firstRun.minutesToFirstVerse;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StageTitle(
          title: l10n.firstStepsDoneTitle,
          description: l10n.firstStepsDoneDesc,
        ),
        const SizedBox(height: 24),
        if (minutes != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              minutes <= 0
                  ? l10n.firstVerseUnderMinute
                  : l10n.firstVerseInMinutes(minutes),
              style: TextStyle(
                fontSize: 18,
                height: 1.5,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        const SizedBox(height: 24),
        _PrimaryButton(
          label: l10n.firstStepsDoneReader,
          onPressed: () => context.go('/reading'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () async {
            await ref.read(firstRunProvider.notifier).restart();
            if (mounted) setState(() => _stage = 0);
          },
          child: Text(l10n.firstStepsRestart),
        ),
      ],
    );
  }
}

class _StageProgress extends StatelessWidget {
  const _StageProgress({required this.stage});

  final int stage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < 4; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == 3 ? 0 : 6),
              child: Container(
                height: 2,
                color: i <= stage
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
            ),
          ),
      ],
    );
  }
}

class _StageTitle extends StatelessWidget {
  const _StageTitle({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LetterCard extends StatelessWidget {
  const _LetterCard({
    required this.glyph,
    required this.name,
    required this.transliteration,
    required this.hint,
    required this.isHebrew,
  });

  final String glyph;
  final String name;
  final String transliteration;
  final String hint;
  final bool isHebrew;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              glyph,
              textDirection: isHebrew ? TextDirection.rtl : TextDirection.ltr,
              style: TextStyle(
                fontSize: 40,
                fontFamily: isHebrew ? 'EzraSIL' : 'Gentium',
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name · $transliteration',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (hint.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FirstWordCard extends StatelessWidget {
  const _FirstWordCard({
    required this.entry,
    required this.isHebrew,
    required this.onTap,
  });

  final FirstVerseWord entry;
  final bool isHebrew;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            entry.word.displayText,
            style: TextStyle(
              fontSize: 23,
              height: 1.4,
              fontFamily: isHebrew ? 'EzraSIL' : 'Gentium',
              color: colorScheme.onSurface,
            ),
          ),
          if (entry.transliteration.isNotEmpty)
            Text(
              entry.transliteration,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          Text(
            entry.gloss,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: 12,
              height: 1.3,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(onPressed: onPressed, child: Text(label)),
    );
  }
}

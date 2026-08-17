/// The way in for someone who has never seen these letters before.
///
/// Deliberately unhurried: one letter per row rather than a dense grid, each
/// with the sound it makes and one real word from the Bible that begins with
/// it. The example words are the bridge the rest of the app is built on — you
/// learn the letter here, then meet it in Genesis 1 and in the vocabulary
/// deck, rather than learning an alphabet in isolation and hoping it sticks.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../audio/widgets/recitation_bar.dart';
import 'alphabet_provider.dart';

class AlphabetScreen extends ConsumerStatefulWidget {
  const AlphabetScreen({super.key, this.initialAlphabet});

  /// Opens straight onto one script, for entry points that already know which
  /// one the reader is looking at.
  final SourceAlphabet? initialAlphabet;

  @override
  ConsumerState<AlphabetScreen> createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends ConsumerState<AlphabetScreen> {
  late SourceAlphabet _alphabet =
      widget.initialAlphabet ?? SourceAlphabet.hebrew;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final referenceAsync = ref.watch(alphabetReferenceProvider);
    final isHebrew = _alphabet == SourceAlphabet.hebrew;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.alphabetTitle)),
      body: referenceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('${l10n.error}: $err'),
          ),
        ),
        data: (reference) {
          final chart = reference.chart(_alphabet);
          // Empty until the lexicon read resolves; the asset's English gloss
          // carries the row in the meantime rather than leaving a gap.
          final glosses =
              ref.watch(alphabetExampleGlossesProvider).valueOrNull ??
              const <String, String>{};

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              SegmentedButton<SourceAlphabet>(
                segments: [
                  ButtonSegment(
                    value: SourceAlphabet.hebrew,
                    label: Text(l10n.hebrewLabel),
                  ),
                  ButtonSegment(
                    value: SourceAlphabet.greek,
                    label: Text(l10n.greekLabel),
                  ),
                ],
                selected: {_alphabet},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    setState(() => _alphabet = selection.first),
              ),
              const SizedBox(height: 20),
              Text(
                isHebrew ? l10n.alphabetHebrewIntro : l10n.alphabetGreekIntro,
                style: TextStyle(
                  height: 1.6,
                  fontSize: 15,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel(l10n.alphabetLettersSection),
              const SizedBox(height: 8),
              ...chart.letters.map(
                (letter) => _LetterRow(
                  letter: letter,
                  hint: reference.hintFor(letter.id),
                  gloss: glosses[letter.strongs] ?? letter.gloss,
                  fontFamily: chart.fontFamily,
                  isHebrew: isHebrew,
                  l10n: l10n,
                ),
              ),
              if (chart.vowels.isNotEmpty) ...[
                const SizedBox(height: 28),
                _SectionLabel(l10n.alphabetVowelsSection),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    l10n.alphabetVowelsIntro,
                    style: TextStyle(
                      height: 1.55,
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                ...chart.vowels.map(
                  (vowel) => _LetterRow(
                    letter: vowel,
                    hint: reference.hintFor(vowel.id),
                    gloss: null,
                    fontFamily: chart.fontFamily,
                    isHebrew: isHebrew,
                    l10n: l10n,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 1.6,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// One letter: the glyph, what it is called, what it sounds like, and a word
/// from the Bible that starts with it.
class _LetterRow extends StatelessWidget {
  const _LetterRow({
    required this.letter,
    required this.hint,
    required this.gloss,
    required this.fontFamily,
    required this.isHebrew,
    required this.l10n,
  });

  final AlphabetLetter letter;
  final String hint;

  /// Meaning of the example word, already resolved to the reader's language
  /// where a translated gloss exists.
  final String? gloss;
  final String fontFamily;
  final bool isHebrew;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 76,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      letter.glyph,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 34,
                        height: 1.25,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    // Five Hebrew letters change shape at the end of a word.
                    // Meeting the final form only mid-passage is a needless
                    // stumble for a beginner.
                    if (letter.finalForm != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${l10n.alphabetFinalForm}  ${letter.finalForm}',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            letter.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          letter.transliteration,
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    if (hint.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        hint,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (letter.numericValue != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '${letter.numericValue}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (letter.hasExample) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.alphabetExampleLabel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9.5,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              letter.lemma!,
                              textDirection: isHebrew
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              style: TextStyle(
                                fontFamily: fontFamily,
                                fontSize: 20,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                [
                                  letter.lemmaTransliteration,
                                  gloss,
                                ].whereType<String>().join('  ·  '),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SpeakWordButton(
                    text: letter.lemma!,
                    isHebrew: isHebrew,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

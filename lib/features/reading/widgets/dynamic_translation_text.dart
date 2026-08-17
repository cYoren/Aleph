import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/verse.dart';
import '../../../data/models/word.dart';
import '../../../providers/word_provider.dart';
import '../../settings/settings_provider.dart';
import '../../../shared/widgets/tappable_word.dart';
import '../../../shared/utils/transliterator.dart';
import 'srs_micro_quiz_sheet.dart';

class DynamicTranslationText extends ConsumerWidget {
  final Verse verse;
  final String translationText;
  final bool isOT;
  final double fontSize;

  const DynamicTranslationText({
    super.key,
    required this.verse,
    required this.translationText,
    required this.isOT,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Learning mode is language-agnostic now. It swaps a translated word for
    // the original by matching the lexicon gloss against the verse, and the
    // gloss already arrives in the reader's own language through
    // `BibleDAO.glossLanguage` — so the same matching works in Portuguese
    // against a Portuguese Bible.
    //
    // Where a gloss has not been translated yet, nothing matches and the verse
    // renders plainly. That silent fallback replaces the old apology ("learning
    // mode currently only supports English"), which told the reader about our
    // rollout schedule instead of doing anything for them.
    if (!settings.learningModeEnabled) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildPlainText(
          translationText,
          colorScheme,
          key: const ValueKey('plain_text_off'),
        ),
      );
    }

    // Load words to find potential replacements
    final wordsAsync = ref.watch(wordsForVerseProvider(verse.id));

    return wordsAsync.when(
      loading: () => _buildAnimatedWrapper(
        _buildPlainText(
          translationText,
          colorScheme,
          key: const ValueKey('plain_text_loading'),
        ),
      ),
      error: (err, stack) => _buildAnimatedWrapper(
        _buildPlainText(
          translationText,
          colorScheme,
          key: const ValueKey('plain_text_error'),
        ),
      ),
      data: (words) {
        if (words.isEmpty) {
          return _buildAnimatedWrapper(
            _buildPlainText(
              translationText,
              colorScheme,
              key: const ValueKey('plain_text_empty'),
            ),
          );
        }

        // Collect all lexicon keys in this verse (Strong's or lemma fallback)
        final strongsIds =
            words
                .map((w) => w.lexiconLookupKey)
                .where((s) => s != null && s.isNotEmpty)
                .cast<String>()
                .toSet()
                .toList()
              ..sort();

        // Build a stable string key for the Riverpod family provider
        final strongsKey = strongsIds.join(',');

        // Load lexicons for these Strong's numbers
        final lexiconsAsync = ref.watch(lexiconsForStrongsProvider(strongsKey));

        return lexiconsAsync.when(
          loading: () => _buildAnimatedWrapper(
            _buildPlainText(
              translationText,
              colorScheme,
              key: const ValueKey('plain_text_lex_loading'),
            ),
          ),
          error: (err, stack) => _buildAnimatedWrapper(
            _buildPlainText(
              translationText,
              colorScheme,
              key: const ValueKey('plain_text_lex_error'),
            ),
          ),
          data: (lexicons) {
            // Find the first word that has a gloss present in the translation text
            Word? wordToSwap;
            String? matchedWord;

            // Check whether any word's gloss appears as a whole word in the
            // translation on screen, in whatever language that translation is.
            for (final word in words) {
              final lookupKey = word.lexiconLookupKey;
              if (lookupKey == null) continue;
              final lexicon = lexicons[lookupKey];
              if (lexicon == null || lexicon.gloss == null) continue;

              // Simple matching: Split glosses (often comma separated)
              final glosses = lexicon.gloss!
                  .split(RegExp(r'[,;]'))
                  .map((g) => g.trim().toLowerCase())
                  .toList();

              for (final gloss in glosses) {
                if (gloss.isEmpty || gloss.length < 3) {
                  continue; // skip very short words like "to", "in", "a"
                }

                // RegExp to find whole word matches case-insensitively
                final regex = RegExp(
                  r'\b' + RegExp.escape(gloss) + r'\b',
                  caseSensitive: false,
                );
                final match = regex.firstMatch(translationText);
                if (match != null) {
                  wordToSwap = word;
                  matchedWord = translationText.substring(
                    match.start,
                    match.end,
                  );
                  break;
                }
              }
              if (wordToSwap != null) break;
            }

            if (wordToSwap == null || matchedWord == null) {
              return _buildAnimatedWrapper(
                _buildPlainText(
                  translationText,
                  colorScheme,
                  key: const ValueKey('plain_text_no_swap'),
                ),
              );
            }

            // Split the translation text around the word to swap
            final parts = translationText.split(matchedWord);

            // We found a word to swap!
            return _buildAnimatedWrapper(
              Wrap(
                key: ValueKey('swapped_${wordToSwap.id}'),
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    parts[0],
                    style: TextStyle(
                      fontSize: fontSize,
                      height: 1.6,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.85,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.15),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: TappableWord(
                        word: wordToSwap,
                        isOT: isOT,
                        fontSize: fontSize + 2,
                        transliteration: settings.showPronunciation
                            ? Transliterator.transliterate(
                                wordToSwap.displayText,
                                isHebrew: isOT,
                              )
                            : null,
                        colorOverride: colorScheme.onPrimaryContainer,
                        onTapOverride: () {
                          SrsMicroQuizSheet.show(
                            context,
                            originalWord: wordToSwap!,
                            translatedWord: matchedWord!,
                            isOT: isOT,
                          );
                        },
                      ),
                    ),
                  ),
                  if (parts.length > 1)
                    Text(
                      parts.sublist(1).join(matchedWord),
                      style: TextStyle(
                        fontSize: fontSize,
                        height: 1.6,
                        color: colorScheme.onSurface,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnimatedWrapper(Widget child) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutQuad,
      switchOutCurve: Curves.easeInQuad,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: 0.0,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildPlainText(String text, ColorScheme colorScheme, {Key? key}) {
    return Text(
      text,
      key: key,
      style: TextStyle(
        fontSize: fontSize,
        height: 1.6,
        color: colorScheme.onSurface,
      ),
    );
  }
}

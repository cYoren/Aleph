import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/verse.dart';
import '../../providers/word_provider.dart';
import '../../features/settings/settings_provider.dart';
import 'tappable_word.dart';

class VerseWithWords extends ConsumerWidget {
  final Verse verse;
  final bool isOT;
  final double fontSize;

  const VerseWithWords({
    super.key,
    required this.verse,
    required this.isOT,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(wordsForVerseProvider(verse.id));
    final transliterationsAsync = ref.watch(
      transliterationsForVerseProvider((verse.id, isOT)),
    );
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final showTransliteration = settings.showPronunciation;

    // Reader mode: inline glosses for rare, not-yet-mastered words
    final readerGlosses = settings.readerModeEnabled
        ? (ref.watch(readerGlossesProvider(verse.id)).valueOrNull ?? {})
        : const <int, String>{};

    return wordsAsync.when(
      loading: () => _buildPlainText(colorScheme),
      error: (err, stack) => _buildPlainText(colorScheme),
      data: (words) {
        if (words.isEmpty) {
          return _buildPlainText(colorScheme);
        }

        // Get transliterations (or empty map if still loading)
        final transliterations = transliterationsAsync.valueOrNull ?? {};

        // Build word widgets (explicit Widget type to allow RTL indicator)
        final List<Widget> wordWidgets = words.map<Widget>((word) {
          final transliteration = transliterations[word.id.toString()];

          return TappableWord(
            word: word,
            isOT: isOT,
            fontSize: fontSize,
            transliteration: transliteration,
            readerGloss: readerGlosses[word.id],
          );
        }).toList();

        // Add RTL indicator for Hebrew when transliteration is enabled
        if (isOT && showTransliteration) {
          // RTL indicator at the "end" (which is left side in RTL)
          wordWidgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                Icons.arrow_back,
                size: fontSize * 0.7,
                color: colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
          );
        }

        // Render each word as a tappable widget
        return Wrap(
          alignment: isOT ? WrapAlignment.end : WrapAlignment.start,
          textDirection: isOT ? TextDirection.rtl : TextDirection.ltr,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 10,
          children: wordWidgets,
        );
      },
    );
  }

  Widget _buildPlainText(ColorScheme colorScheme) {
    // Use EzraSIL for Hebrew (OT), Gentium for Greek (NT)
    final fontFamily = isOT ? 'EzraSIL' : 'Gentium';

    return Text(
      verse.textContent,
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        height: 1.8,
        color: colorScheme.onSurface,
      ),
      textAlign: isOT ? TextAlign.right : TextAlign.left,
      textDirection: isOT ? TextDirection.rtl : TextDirection.ltr,
    );
  }
}

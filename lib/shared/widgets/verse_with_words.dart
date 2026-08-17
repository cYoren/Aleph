import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/verse.dart';
import '../../data/models/word.dart';
import '../../providers/word_provider.dart';
import '../../features/settings/settings_provider.dart';
import '../utils/hebrew_display.dart';
import '../utils/cantillation.dart';
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

    // Reader mode: inline glosses for rare, not-yet-mastered words
    final readerGlosses = settings.readerModeEnabled
        ? (ref.watch(readerGlossesProvider(verse.id)).valueOrNull ?? {})
        : const <int, String>{};

    final hebrewDisplay = settings.hebrewTextDisplay;

    return wordsAsync.when(
      loading: () => _buildPlainText(colorScheme, hebrewDisplay),
      error: (err, stack) => _buildPlainText(colorScheme, hebrewDisplay),
      data: (words) {
        if (words.isEmpty) {
          return _buildPlainText(colorScheme, hebrewDisplay);
        }

        // Get transliterations (or empty map if still loading)
        final transliterations = transliterationsAsync.valueOrNull ?? {};

        // The disjunctive accents divide a verse into nested phrases. Spacing
        // the text at those breaks is what turns a row of words into something
        // that can be read — and chanted — in sense units.
        final Map<int, int> breakAfter =
            (isOT &&
                settings.showSenseUnits &&
                hebrewDisplay != HebrewTextDisplay.consonantal)
            ? _senseUnitBreaks(words)
            : const <int, int>{};

        // Build word widgets (explicit Widget type to allow RTL indicator)
        final List<Widget> wordWidgets = [];
        for (int i = 0; i < words.length; i++) {
          final word = words[i];
          final transliteration = transliterations[word.id.toString()];

          wordWidgets.add(
            TappableWord(
              word: word,
              isOT: isOT,
              fontSize: fontSize,
              transliteration: transliteration,
              readerGloss: readerGlosses[word.id],
            ),
          );

          final rank = breakAfter[i];
          if (rank != null && i < words.length - 1) {
            wordWidgets.add(SizedBox(width: _breakWidth(rank, fontSize)));
          }
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

  /// Maps the index of each phrase-final word to the strength of the break
  /// that follows it, using the Masoretic disjunctive accents.
  ///
  /// Clause level (rank 2) is the default: strong enough to shape the verse,
  /// loose enough not to fragment it.
  Map<int, int> _senseUnitBreaks(List<Word> words) {
    final units = senseUnits(
      words.map((w) => w.displayText).toList(),
      upToRank: 2,
    );

    final result = <int, int>{};
    for (final unit in units) {
      if (unit.isEmpty || unit.closingTaam == null) continue;
      result[unit.wordIndices.last] = unit.breakRank;
    }
    return result;
  }

  /// Gap that follows a phrase, scaled to how strong the break is: the great
  /// division of the verse at etnachta reads wider than a clause boundary.
  double _breakWidth(int rank, double fontSize) {
    switch (rank) {
      case 1:
        return fontSize * 1.1;
      case 2:
        return fontSize * 0.55;
      default:
        return fontSize * 0.3;
    }
  }

  Widget _buildPlainText(
    ColorScheme colorScheme,
    HebrewTextDisplay hebrewDisplay,
  ) {
    // Use EzraSIL for Hebrew (OT), Gentium for Greek (NT)
    final fontFamily = isOT ? 'EzraSIL' : 'Gentium';

    return Text(
      isOT
          ? applyHebrewDisplay(verse.textContent, hebrewDisplay)
          : verse.textContent,
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

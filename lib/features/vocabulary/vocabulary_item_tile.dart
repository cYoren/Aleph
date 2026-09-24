import 'package:flutter/material.dart';

import '../../data/models/word.dart';
import '../reading/widgets/srs_micro_quiz_sheet.dart';
import 'vocabulary_provider.dart';

/// One word in a deck: mastery ring, lemma, transliteration, gloss and count.
/// Tapping it runs a review; [onReviewed] fires afterwards so the caller can
/// refresh whatever list it came from.
class VocabularyItemTile extends StatelessWidget {
  const VocabularyItemTile({
    super.key,
    required this.item,
    required this.onReviewed,
  });

  final VocabularyDeckItem item;
  final VoidCallback onReviewed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entry = item.entry;
    final mastery = item.progress?.masteryScore ?? 0.0;
    final lemma = entry?.lemma ?? item.lexiconKey;
    final transliteration = entry?.transliteration;

    return ListTile(
      onTap: () => _openQuiz(context),
      leading: SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: mastery,
              strokeWidth: 3,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: colorScheme.primary,
            ),
            Text(
              '${(mastery * 100).round()}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          Text(
            lemma,
            style: TextStyle(
              fontSize: 20,
              fontFamily: item.isHebrew ? 'EzraSIL' : 'Gentium',
              color: colorScheme.onSurface,
            ),
          ),
          if (transliteration != null && transliteration.isNotEmpty) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                transliteration,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: entry?.gloss != null
          ? Text(entry!.gloss!, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: item.frequency > 0
          ? Text(
              '×${item.frequency}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
    );
  }

  Future<void> _openQuiz(BuildContext context) async {
    await reviewDeckItem(context, item);
    onReviewed();
  }
}

/// Runs one review of [item] in the quiz sheet.
Future<void> reviewDeckItem(BuildContext context, VocabularyDeckItem item) {
  final entry = item.entry;
  final pseudoWord = Word(
    id: -1,
    verseId: '',
    position: 0,
    displayText: entry?.lemma ?? item.lexiconKey,
    lemma: entry?.lemma,
    strongs: item.lexiconKey.startsWith('H') || item.lexiconKey.startsWith('G')
        ? item.lexiconKey
        : null,
    language: item.isHebrew ? 'heb' : 'grc',
  );

  return SrsMicroQuizSheet.show(
    context,
    originalWord: pseudoWord,
    translatedWord: entry?.gloss ?? '',
    isOT: item.isHebrew,
  );
}

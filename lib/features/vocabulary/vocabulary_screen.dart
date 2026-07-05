import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/word.dart';
import '../../l10n/generated/app_localizations.dart';
import '../reading/widgets/srs_micro_quiz_sheet.dart';
import 'vocabulary_provider.dart';

/// Frequency-ordered vocabulary decks plus the SRS review queue.
/// The most common words unlock the largest share of the text — the deck
/// header shows exactly how much.
class VocabularyScreen extends ConsumerStatefulWidget {
  const VocabularyScreen({super.key});

  @override
  ConsumerState<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends ConsumerState<VocabularyScreen> {
  String _language = 'heb';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final deckAsync = ref.watch(vocabularyDeckProvider(_language));
    final dueAsync = ref.watch(dueVocabularyProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.vocabularyTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Due for review
          ...dueAsync.when(
            loading: () => const [SizedBox.shrink()],
            error: (err, stack) => const [SizedBox.shrink()],
            data: (due) => due.isEmpty
                ? const [SizedBox.shrink()]
                : [
                    _sectionHeader(
                      l10n.dueForReviewSection,
                      colorScheme,
                      count: due.length,
                    ),
                    ...due.map((item) => _buildItemTile(item, colorScheme)),
                    const Divider(),
                  ],
          ),

          // Language selector for the frequency deck
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'heb', label: Text(l10n.hebrewLabel)),
                ButtonSegment(value: 'grc', label: Text(l10n.greekLabel)),
              ],
              selected: {_language},
              onSelectionChanged: (selection) {
                setState(() => _language = selection.first);
              },
            ),
          ),

          // Frequency deck
          deckAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('${l10n.error}: $err'),
            ),
            data: (deck) {
              if (deck.items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.noUsageDataAvailable),
                );
              }
              final percent = (deck.coverage * 100).toStringAsFixed(0);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(l10n.mostFrequentSection, colorScheme),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      l10n.vocabularyCoverage(percent),
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  ...deck.items.map(
                    (item) => _buildItemTile(item, colorScheme),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
    String title,
    ColorScheme colorScheme, {
    int? count,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        count != null ? '$title ($count)' : title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildItemTile(VocabularyDeckItem item, ColorScheme colorScheme) {
    final entry = item.entry;
    final mastery = item.progress?.masteryScore ?? 0.0;
    final lemma = entry?.lemma ?? item.lexiconKey;
    final transliteration = entry?.transliteration;

    return ListTile(
      onTap: () => _openQuiz(item),
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
          ? Text(
              entry!.gloss!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
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

  Future<void> _openQuiz(VocabularyDeckItem item) async {
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

    await SrsMicroQuizSheet.show(
      context,
      originalWord: pseudoWord,
      englishWord: entry?.gloss ?? '',
      isOT: item.isHebrew,
    );

    // Refresh mastery/due state after the review
    ref.invalidate(dueVocabularyProvider);
    ref.invalidate(vocabularyDeckProvider(_language));
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/lexicon_entry.dart';
import '../../data/models/srs_progress.dart';
import '../../providers/database_provider.dart';
import '../../shared/utils/vocabulary_filter.dart';

/// One row of the vocabulary deck: a word with its whole-Bible frequency,
/// lexicon entry, and the user's SRS progress (if any).
class VocabularyDeckItem {
  final String lexiconKey;
  final int frequency;
  final LexiconEntry? entry;
  final SrsProgress? progress;
  final bool isHebrew;

  const VocabularyDeckItem({
    required this.lexiconKey,
    required this.frequency,
    required this.entry,
    required this.progress,
    required this.isHebrew,
  });
}

class VocabularyDeck {
  final List<VocabularyDeckItem> items;

  /// Fraction of all tokens in this language covered by the deck's words.
  final double coverage;

  const VocabularyDeck({required this.items, required this.coverage});
}

/// Frequency-ordered deck for one language ('heb' or 'grc'): the most common
/// words first — the fastest route to reading fluency.
final vocabularyDeckProvider = FutureProvider.family<VocabularyDeck, String>((
  ref,
  language,
) async {
  final dao = ref.watch(bibleDaoProvider);
  final srsDao = ref.watch(srsDaoProvider);
  final isHebrew = language == 'heb';

  // Over-fetch, because the prefixes and entry-less ids removed below sit at
  // the very top of the raw frequency table.
  const deckSize = 100;
  final rows = await dao.getTopFrequencyWords(
    language: language,
    limit: deckSize * 4,
  );
  final keys = rows
      .map((r) => r['key']?.toString() ?? '')
      .where((k) => k.isNotEmpty)
      .toList();
  if (keys.isEmpty) {
    return const VocabularyDeck(items: [], coverage: 0);
  }

  final lexicon = await dao.getLexiconEntriesForStrongs(keys);
  final progress = await srsDao.getProgressForIds(keys);
  final totalTokens = await dao.getTotalWordCount(language);

  var coveredTokens = 0;
  final items = <VocabularyDeckItem>[];
  for (final row in rows) {
    if (items.length >= deckSize) break;

    final key = row['key']?.toString() ?? '';
    if (key.isEmpty) continue;

    // Drop bare prefixes and ids with no dictionary entry: neither is a word
    // a learner studies, and both used to head the deck.
    final entry = lexicon[key];
    if (!isDeckWorthy(
      lemma: entry?.lemma,
      gloss: entry?.gloss,
      isHebrew: isHebrew,
    )) {
      continue;
    }

    final frequency = (row['c'] as num?)?.toInt() ?? 0;
    coveredTokens += frequency;
    items.add(
      VocabularyDeckItem(
        lexiconKey: key,
        frequency: frequency,
        entry: entry,
        progress: progress[key],
        isHebrew: isHebrew,
      ),
    );
  }

  return VocabularyDeck(
    items: items,
    coverage: totalTokens > 0 ? coveredTokens / totalTokens : 0,
  );
});

/// Words due for SRS review right now, with their lexicon entries.
final dueVocabularyProvider =
    FutureProvider<List<VocabularyDeckItem>>((ref) async {
      final dao = ref.watch(bibleDaoProvider);
      final srsDao = ref.watch(srsDaoProvider);

      final due = await srsDao.getWordsDueForReview();
      if (due.isEmpty) return const [];

      final keys = due.map((p) => p.strongsId).toList();
      final lexicon = await dao.getLexiconEntriesForStrongs(keys);
      final frequencies = await dao.getFrequenciesForLexiconKeys(keys);

      return due.map((p) {
        final entry = lexicon[p.strongsId];
        final isHebrew = p.strongsId.startsWith('H')
            ? true
            : p.strongsId.startsWith('G')
            ? false
            : entry?.language == 'heb';
        return VocabularyDeckItem(
          lexiconKey: p.strongsId,
          frequency: frequencies[p.strongsId] ?? 0,
          entry: entry,
          progress: p,
          isHebrew: isHebrew,
        );
      }).toList();
    });

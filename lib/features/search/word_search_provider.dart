import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_provider.dart';
import '../../shared/utils/search_fold.dart';
import 'search_screen.dart' show searchQueryProvider;

/// One lexicon hit in word search.
class WordSearchResult {
  final String lemma;
  final String strongsId;
  final String? transliteration;
  final String? gloss;
  final bool isHebrew;

  const WordSearchResult({
    required this.lemma,
    required this.strongsId,
    required this.transliteration,
    required this.gloss,
    required this.isHebrew,
  });

  /// Key for concordance/lexicon lookups.
  String get lexiconKey => strongsId.isNotEmpty ? strongsId : lemma;
}

class _IndexedEntry {
  final WordSearchResult result;
  final String foldedLemma;
  final String foldedTranslit;
  final String foldedGloss;
  final String foldedStrongs;

  _IndexedEntry(this.result)
    : foldedLemma = foldForSearch(result.lemma),
      foldedTranslit = foldForSearch(result.transliteration ?? ''),
      foldedGloss = foldForSearch(result.gloss ?? ''),
      foldedStrongs = result.strongsId.toLowerCase();
}

/// In-memory folded lexicon index, built once per session.
final _lexiconIndexProvider = FutureProvider<List<_IndexedEntry>>((ref) async {
  final dao = ref.watch(bibleDaoProvider);
  final rows = await dao.getLexiconIndex();
  return rows
      .map(
        (row) => _IndexedEntry(
          WordSearchResult(
            lemma: row['lemma']?.toString() ?? '',
            strongsId: row['strongs_id']?.toString() ?? '',
            transliteration: row['transliteration']?.toString(),
            gloss: row['gloss']?.toString(),
            isHebrew: row['language']?.toString() != 'grc',
          ),
        ),
      )
      .where((e) => e.result.lemma.isNotEmpty)
      .toList();
});

const int _maxWordResults = 8;

/// Lexicon matches for the current search query: by Strong's id, lemma
/// (pointing/accent-insensitive), transliteration, or English gloss.
final wordSearchResultsProvider =
    FutureProvider.autoDispose<List<WordSearchResult>>((ref) async {
      final query = ref.watch(searchQueryProvider);
      final folded = foldForSearch(query);
      if (folded.length < 2) return const [];

      final index = await ref.watch(_lexiconIndexProvider.future);

      // Lower score = better match.
      final scored = <(int, _IndexedEntry)>[];
      for (final entry in index) {
        int? score;
        if (entry.foldedStrongs == folded) {
          score = 0;
        } else if (entry.foldedLemma == folded ||
            entry.foldedTranslit == folded) {
          score = 1;
        } else if (folded.length >= 3 &&
            (entry.foldedLemma.startsWith(folded) ||
                entry.foldedTranslit.startsWith(folded))) {
          score = 2;
        } else if (folded.length >= 3 && entry.foldedGloss == folded) {
          score = 3;
        } else if (folded.length >= 4 &&
            _containsWord(entry.foldedGloss, folded)) {
          score = 4;
        }
        if (score != null) {
          scored.add((score, entry));
        }
      }

      scored.sort((a, b) {
        final byScore = a.$1.compareTo(b.$1);
        if (byScore != 0) return byScore;
        return a.$2.result.lemma.compareTo(b.$2.result.lemma);
      });

      return scored.take(_maxWordResults).map((s) => s.$2.result).toList();
    });

bool _containsWord(String haystack, String needle) {
  var start = 0;
  while (true) {
    final idx = haystack.indexOf(needle, start);
    if (idx < 0) return false;
    final beforeOk = idx == 0 || !_isLetter(haystack.codeUnitAt(idx - 1));
    final endIdx = idx + needle.length;
    final afterOk =
        endIdx >= haystack.length || !_isLetter(haystack.codeUnitAt(endIdx));
    if (beforeOk && afterOk) return true;
    start = idx + 1;
  }
}

bool _isLetter(int codeUnit) {
  return (codeUnit >= 0x61 && codeUnit <= 0x7A) ||
      (codeUnit >= 0x41 && codeUnit <= 0x5A);
}

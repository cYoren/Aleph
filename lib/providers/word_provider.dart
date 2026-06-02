import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/word.dart';
import '../data/models/lexicon_entry.dart';
import '../shared/utils/transliterator.dart';
import 'database_provider.dart';

/// Currently selected word
final selectedWordProvider = StateProvider<Word?>((ref) => null);

/// Lexicon entry for the selected word
final selectedWordLexiconProvider = FutureProvider<LexiconEntry?>((ref) async {
  final word = ref.watch(selectedWordProvider);
  if (word == null) {
    return null;
  }

  final lookupKey = (word.strongs?.isNotEmpty ?? false)
      ? word.strongs!
      : (word.lemma?.isNotEmpty ?? false)
      ? word.lemma!
      : '';
  if (lookupKey.isEmpty) return null;

  final dao = ref.watch(bibleDaoProvider);
  return dao.getLexiconEntry(lookupKey);
});

/// Words for a specific verse
final wordsForVerseProvider = FutureProvider.family<List<Word>, String>((
  ref,
  verseId,
) async {
  final dao = ref.watch(bibleDaoProvider);
  return dao.getWordsForVerse(verseId);
});

/// Transliterations for a verse - word ID -> transliteration
/// Uses automatic transliteration from the word's display text
final transliterationsForVerseProvider =
    FutureProvider.family<Map<String, String>, (String, bool)>((
      ref,
      params,
    ) async {
      final (verseId, isHebrew) = params;

      // Get words for the verse
      final words = await ref.watch(wordsForVerseProvider(verseId).future);

      // Generate transliterations for each word
      final Map<String, String> result = {};
      for (final word in words) {
        final transliteration = Transliterator.transliterate(
          word.displayText,
          isHebrew: isHebrew,
        );
        if (transliteration.isNotEmpty) {
          result[word.id.toString()] = transliteration;
        }
      }

      return result;
    });

/// Top 5 books where a Strong's number is used
final strongsUsageFrequenciesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      strongs,
    ) async {
      final dao = ref.watch(bibleDaoProvider);
      return dao.getStrongsUsageFrequencies(strongs);
    });

/// Batch fetch lexicon entries for a list of Strong's IDs.
/// Key is a sorted, comma-joined string of all Strong's IDs so that Riverpod
/// can cache correctly (`List<String>` has no value equality).
final lexiconsForStrongsProvider =
    FutureProvider.family<Map<String, LexiconEntry>, String>((
      ref,
      strongsKey,
    ) async {
      if (strongsKey.isEmpty) return {};
      final ids = strongsKey.split(',').where((s) => s.isNotEmpty).toList();
      final dao = ref.watch(bibleDaoProvider);
      return dao.getLexiconEntriesForStrongs(ids);
    });

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/word.dart';
import '../data/models/verse.dart';
import '../data/models/lexicon_entry.dart';
import '../shared/utils/transliterator.dart';
import '../shared/utils/hebrew_syllables.dart';
import '../shared/utils/reader_mode.dart';
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

/// Lexicon entry for one key, for the long-press peek in the reader.
final lexiconEntryProvider = FutureProvider.family<LexiconEntry?, String>((
  ref,
  lexiconKey,
) async {
  if (lexiconKey.isEmpty) return null;
  final dao = ref.watch(bibleDaoProvider);
  return dao.getLexiconEntry(lexiconKey);
});

/// Words for a specific verse
final wordsForVerseProvider = FutureProvider.family<List<Word>, String>((
  ref,
  verseId,
) async {
  final dao = ref.watch(bibleDaoProvider);
  return dao.getWordsForVerse(verseId);
});

/// Transliterations for a verse - word ID -> transliteration.
///
/// Hebrew is syllabified and stress-marked from the cantillation (`bə·rēʾ·ˈšîṯ`)
/// so the reader can see how a word is actually spoken, not just which letters
/// it contains. Greek falls back to the plain letter-for-letter scheme.
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
      for (int i = 0; i < words.length; i++) {
        final word = words[i];
        final String transliteration;

        if (isHebrew) {
          // Silluq only ever falls on the last word of a verse, so the final
          // token is the one where U+05BD may mark stress rather than meteg.
          final syllabified = syllabifyHebrew(
            word.displayText,
            isVerseFinal: i == words.length - 1,
          );
          transliteration = syllabified.isEmpty
              ? Transliterator.transliterate(word.displayText, isHebrew: true)
              : syllabified.marked;
        } else {
          transliteration = Transliterator.transliterate(
            word.displayText,
            isHebrew: false,
          );
        }

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

/// Reader mode glosses for a verse: word.id -> short gloss, for words rare
/// enough (and not yet mastered) to deserve an inline translation.
final readerGlossesProvider = FutureProvider.family<Map<int, String>, String>((
  ref,
  verseId,
) async {
  final words = await ref.watch(wordsForVerseProvider(verseId).future);
  final keys = words
      .map((w) => w.lexiconLookupKey)
      .whereType<String>()
      .toSet()
      .toList();
  if (keys.isEmpty) return {};

  final dao = ref.watch(bibleDaoProvider);
  final srsDao = ref.watch(srsDaoProvider);
  final frequencies = await dao.getFrequenciesForLexiconKeys(keys);
  final progress = await srsDao.getProgressForIds(keys);
  final lexicon = await dao.getLexiconEntriesForStrongs(keys);

  return selectReaderGlosses(
    words: words,
    frequencies: frequencies,
    progress: progress,
    lexicon: lexicon,
  );
});

/// Concordance data for a lexicon key (Strong's id or lemma): total verse
/// count plus the occurrences themselves (capped in the DAO for very
/// frequent words).
final wordOccurrencesProvider =
    FutureProvider.family<({int total, List<Verse> verses}), String>((
      ref,
      lexiconKey,
    ) async {
      final dao = ref.watch(bibleDaoProvider);
      final total = await dao.countOccurrencesForLexiconKey(lexiconKey);
      final verses = await dao.getOccurrencesForLexiconKey(lexiconKey);
      return (total: total, verses: verses);
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/word.dart';
import '../data/models/verse.dart';
import '../data/models/lexicon_entry.dart';
import '../data/models/srs_progress.dart';
import '../data/models/lexicon_root.dart';
import '../data/models/lexicon_sense.dart';
import '../shared/utils/paradigm.dart';
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

/// The frequency bar this reader's audience should be glossed at.
///
/// Starts at the printed-reader convention (fewer than 30 occurrences) and
/// moves up as soon as the reader shows they are stuck on a more common word.
/// Recomputed when SRS state changes, not per verse.
final readerThresholdProvider = FutureProvider<int>((ref) async {
  final srsDao = ref.watch(srsDaoProvider);
  final dao = ref.watch(bibleDaoProvider);
  final inLearning = await srsDao.getProgressBelowMastery(
    kReaderModeMasterySuppression,
  );
  if (inLearning.isEmpty) return kReaderModeFrequencyThreshold;
  final frequencies = await dao.getFrequenciesForLexiconKeys(
    inLearning.map((p) => p.strongsId).toList(),
  );
  return adaptiveReaderThreshold(
    progress: {for (final p in inLearning) p.strongsId: p},
    frequencies: frequencies,
  );
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

  final threshold = await ref.watch(readerThresholdProvider.future);

  return selectReaderGlosses(
    words: words,
    frequencies: frequencies,
    progress: progress,
    lexicon: lexicon,
    threshold: threshold,
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

/// The reader's SRS progress for the selected word, if any.
final selectedWordProgressProvider = FutureProvider<SrsProgress?>((ref) async {
  final word = ref.watch(selectedWordProvider);
  final key = word?.lexiconLookupKey;
  if (key == null || key.isEmpty) return null;
  return ref.watch(srsDaoProvider).getProgress(key);
});

/// Numbered senses for one lexicon key (Strong's id, or a lemma).
final lexiconSensesProvider =
    FutureProvider.family<List<LexiconSense>, String>((ref, key) async {
      if (key.isEmpty) return const [];
      return ref.watch(bibleDaoProvider).getSensesForStrongs(key);
    });

/// Numbered senses for the selected word: what the definition sheet shows
/// above the flattened dictionary text.
final selectedWordSensesProvider = FutureProvider<List<LexiconSense>>((
  ref,
) async {
  final word = ref.watch(selectedWordProvider);
  if (word == null) return const [];
  final key = word.lexiconLookupKey;
  if (key == null || key.isEmpty) return const [];
  return ref.watch(lexiconSensesProvider(key).future);
});

/// The Hebrew root behind one lexicon key, or null for Greek.
final lexiconRootProvider = FutureProvider.family<LexiconRoot?, String>((
  ref,
  key,
) async {
  if (key.isEmpty) return null;
  return ref.watch(bibleDaoProvider).getRootForStrongs(key);
});

/// Every word built on a root (TWOT number), most frequent first.
final rootMembersProvider =
    FutureProvider.family<List<RootMember>, String>((ref, twot) async {
      if (twot.isEmpty) return const [];
      return ref.watch(bibleDaoProvider).getRootMembers(twot);
    });

/// Every verse containing a word built on a root.
final rootOccurrencesProvider =
    FutureProvider.family<({int total, List<Verse> verses}), String>((
      ref,
      twot,
    ) async {
      if (twot.isEmpty) return (total: 0, verses: const <Verse>[]);
      final dao = ref.watch(bibleDaoProvider);
      final total = await dao.countOccurrencesForRoot(twot);
      final verses = await dao.getOccurrencesForRoot(twot);
      return (total: total, verses: verses);
    });

/// Attested forms of one lemma, grouped the way a paradigm table is read.
///
/// Empty when the form does not occur in the corpus (a lexicon headword can be
/// unattested in its own spelling).
final attestedFormsProvider =
    FutureProvider.family<List<ParadigmGroup>, (String, bool)>((ref, params) async {
      final (lemma, isHebrew) = params;
      if (lemma.isEmpty) return const [];
      final dao = ref.watch(bibleDaoProvider);
      final rows = await dao.getAttestedForms(lemma);
      final entries = rows.map(
        (row) => (
          form: row['form']?.toString() ?? '',
          morph: row['morph']?.toString() ?? '',
          count: (row['count'] as num?)?.toInt() ?? 0,
        ),
      );
      return buildParadigmGroups(entries: entries, isHebrew: isHebrew);
    });

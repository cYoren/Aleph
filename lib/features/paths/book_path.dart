/// Book paths: "read Ruth in Hebrew" as a goal the app walks you to.
///
/// The reading map says how much of every book you can read. A path picks one
/// book and turns that into a plan: the book's own vocabulary, ordered by how
/// often each word appears *in that book*, so every word learned moves the
/// needle on the text you chose. Progress is measured over the book's
/// learnable vocabulary only: prefixes and suffix tokens (see
/// `BibleDAO.getGrammarLexiconKeys`) are over 40% of a Hebrew book, and
/// counting them would greet a beginner with "you can read 42% of Ruth".
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/book.dart';
import '../../data/models/srs_progress.dart';
import '../../providers/books_provider.dart';
import '../../providers/database_provider.dart';
import '../../shared/utils/reader_mode.dart';
import '../../shared/utils/vocabulary_filter.dart';
import '../vocabulary/vocabulary_provider.dart';

/// Short, complete books a beginner can actually finish, in the order offered.
const kStarterPathBooks = ['JON', 'RUT', '1JN', 'JHN', 'GEN', 'MRK'];

/// The milestone a path aims for: one unknown word in five is readable with
/// the glosses the reader already shows.
const double kPathGoalCoverage = 0.80;

const _activePathKey = 'activePathBook';

/// A word counts as "learning" once it has had one correct review.
bool _isLearning(SrsProgress? p) => p != null && p.repetitions >= 1;
bool _isKnown(SrsProgress? p) =>
    p != null && p.masteryScore >= kReaderModeMasterySuppression;

class BookPathStats {
  /// Share of the book's vocabulary tokens that are mastered words.
  final double knownCoverage;

  /// Same, also counting words that are being learned.
  final double learningCoverage;

  /// New words still to learn, most frequent first, to reach [goal].
  final int wordsToGoal;

  const BookPathStats({
    required this.knownCoverage,
    required this.learningCoverage,
    required this.wordsToGoal,
  });
}

/// Pure coverage arithmetic, separated from the database for testing.
///
/// [counts] maps each lexicon key to its token count in the book, most
/// frequent first. [studyable] are the keys that belong in a deck; everything
/// else (grammar, entry-less ids) is left out of the arithmetic entirely.
BookPathStats computePathStats({
  required Map<String, int> counts,
  required Set<String> studyable,
  required Map<String, SrsProgress> progress,
  double goal = kPathGoalCoverage,
}) {
  final vocab = {
    for (final MapEntry(:key, :value) in counts.entries)
      if (studyable.contains(key)) key: value,
  };
  final total = vocab.values.fold<int>(0, (a, b) => a + b);
  if (total == 0) {
    return const BookPathStats(
      knownCoverage: 0,
      learningCoverage: 0,
      wordsToGoal: 0,
    );
  }

  var known = 0;
  var learning = 0;
  for (final MapEntry(:key, :value) in vocab.entries) {
    if (_isKnown(progress[key])) {
      known += value;
    } else if (_isLearning(progress[key])) {
      learning += value;
    }
  }

  // Walk the untouched deck words by in-book frequency until the goal is met.
  var reached = known + learning;
  var wordsToGoal = 0;
  final target = goal * total;
  for (final MapEntry(:key, :value) in vocab.entries) {
    if (reached >= target) break;
    if (_isKnown(progress[key]) || _isLearning(progress[key])) continue;
    reached += value;
    wordsToGoal++;
  }

  return BookPathStats(
    knownCoverage: known / total,
    learningCoverage: (known + learning) / total,
    wordsToGoal: wordsToGoal,
  );
}

class BookPath {
  final Book book;
  final bool isHebrew;
  final BookPathStats stats;

  /// The book's vocabulary, most frequent in this book first. `frequency` is
  /// the in-book count.
  final List<VocabularyDeckItem> words;

  const BookPath({
    required this.book,
    required this.isHebrew,
    required this.stats,
    required this.words,
  });

  /// Deck words not yet started, in the order they should be learned.
  Iterable<VocabularyDeckItem> get nextWords =>
      words.where((w) => !_isLearning(w.progress) && !_isKnown(w.progress));
}

/// Grammar keys never change for a given database; computed once.
final grammarLexiconKeysProvider = FutureProvider<Set<String>>((ref) async {
  final keys = await ref.watch(bibleDaoProvider).getGrammarLexiconKeys();
  return keys.toSet();
});

final bookPathProvider = FutureProvider.family<BookPath?, String>((
  ref,
  bookId,
) async {
  final dao = ref.watch(bibleDaoProvider);
  final srsDao = ref.watch(srsDaoProvider);
  final books = await ref.watch(booksProvider.future);
  final book = books.where((b) => b.abbreviation == bookId).firstOrNull;
  if (book == null) return null;

  final isHebrew = book.testament == 'OT';
  final grammar = await ref.watch(grammarLexiconKeysProvider.future);
  final counts = await dao.getLexiconKeyCountsInBook(bookId);
  final keys = counts.keys.toList();
  final lexicon = await dao.getLexiconEntriesForStrongs(keys);
  final progress = await srsDao.getProgressForIds(keys);

  final words = <VocabularyDeckItem>[];
  for (final MapEntry(:key, :value) in counts.entries) {
    final entry = lexicon[key];
    if (grammar.contains(key) ||
        !isDeckWorthy(
          lemma: entry?.lemma,
          gloss: entry?.gloss,
          isHebrew: isHebrew,
        )) {
      continue;
    }
    words.add(
      VocabularyDeckItem(
        lexiconKey: key,
        frequency: value,
        entry: entry,
        progress: progress[key],
        isHebrew: isHebrew,
      ),
    );
  }

  return BookPath(
    book: book,
    isHebrew: isHebrew,
    words: words,
    stats: computePathStats(
      counts: counts,
      studyable: {for (final w in words) w.lexiconKey},
      progress: progress,
    ),
  );
});

/// The book the reader is working toward, or null before they pick one.
final activePathProvider = StateNotifierProvider<ActivePathNotifier, String?>(
  (ref) => ActivePathNotifier(),
);

class ActivePathNotifier extends StateNotifier<String?> {
  ActivePathNotifier() : super(null) {
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) state = prefs.getString(_activePathKey);
    });
  }

  Future<void> choose(String? bookId) async {
    state = bookId;
    final prefs = await SharedPreferences.getInstance();
    if (bookId == null) {
      await prefs.remove(_activePathKey);
    } else {
      await prefs.setString(_activePathKey, bookId);
    }
  }
}

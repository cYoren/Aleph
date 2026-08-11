/// How much of each book the reader can already read.
///
/// The vocabulary screen answers "which words do I know?". This answers the
/// question that actually motivates people: *what can I go and read now?*
/// Coverage is computed from the words the reader has mastered in the SRS
/// against the token counts of each book, which turns abstract vocabulary
/// progress into a concrete reading recommendation.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/book.dart';
import '../../providers/books_provider.dart';
import '../../providers/database_provider.dart';
import '../../shared/utils/reader_mode.dart';

/// Coverage at or above this reads comfortably: roughly one unknown word in
/// twenty, which is the level at which a text carries you rather than stopping
/// you every line.
const double kComfortableCoverage = 0.95;

/// Below this a book is mostly decoding rather than reading.
const double kWorkableCoverage = 0.80;

/// How readable one book is for this reader right now.
class BookReadability {
  final Book book;

  /// Fraction of this book's tokens the reader has mastered, 0..1.
  final double coverage;

  /// Total original-language tokens in the book.
  final int totalTokens;

  const BookReadability({
    required this.book,
    required this.coverage,
    required this.totalTokens,
  });

  bool get isComfortable => coverage >= kComfortableCoverage;
  bool get isWorkable => coverage >= kWorkableCoverage;

  /// Roughly how many words per chapter would still be unfamiliar.
  int get unknownPerChapter {
    final chapters = book.effectiveChapterCount;
    if (chapters <= 0 || totalTokens <= 0) return 0;
    return (((1 - coverage) * totalTokens) / chapters).round();
  }
}

class ReadabilityReport {
  /// Every book, most readable first.
  final List<BookReadability> books;

  /// The book worth opening next: the longest text the reader can already
  /// handle comfortably, or failing that the closest one to being readable.
  final BookReadability? recommendation;

  /// True when the reader has not learned enough words for the map to say
  /// anything useful yet.
  final bool isEmpty;

  const ReadabilityReport({
    required this.books,
    required this.recommendation,
    required this.isEmpty,
  });
}

/// Books ranked by how much of them this reader can already read.
final readabilityReportProvider = FutureProvider<ReadabilityReport>((
  ref,
) async {
  final dao = ref.watch(bibleDaoProvider);
  final srsDao = ref.watch(srsDaoProvider);
  final books = await ref.watch(booksProvider.future);

  if (books.isEmpty) {
    return const ReadabilityReport(
      books: [],
      recommendation: null,
      isEmpty: true,
    );
  }

  // Words the reader has mastered well enough to read without stopping.
  final mastered = await srsDao.getMasteredLexiconKeys(
    kReaderModeMasterySuppression,
  );

  final totals = await dao.getTokenCountsByBook();
  final known = mastered.isEmpty
      ? const <String, int>{}
      : await dao.getTokenCountsByBookForKeys(mastered);

  final entries = <BookReadability>[];
  for (final book in books) {
    final total = totals[book.abbreviation] ?? 0;
    if (total <= 0) continue;
    final knownCount = known[book.abbreviation] ?? 0;
    entries.add(
      BookReadability(
        book: book,
        coverage: (knownCount / total).clamp(0.0, 1.0),
        totalTokens: total,
      ),
    );
  }

  entries.sort((a, b) {
    final byCoverage = b.coverage.compareTo(a.coverage);
    if (byCoverage != 0) return byCoverage;
    return a.book.order.compareTo(b.book.order);
  });

  return ReadabilityReport(
    books: entries,
    recommendation: _pickRecommendation(entries),
    isEmpty: mastered.isEmpty,
  );
});

/// Chooses what to suggest reading next.
///
/// Among books the reader can already handle comfortably, the longest is the
/// most rewarding to open. If none qualify yet, point at whichever is closest,
/// so there is always a next step.
BookReadability? _pickRecommendation(List<BookReadability> entries) {
  if (entries.isEmpty) return null;

  final comfortable = entries.where((e) => e.isComfortable).toList();
  if (comfortable.isNotEmpty) {
    comfortable.sort((a, b) => b.totalTokens.compareTo(a.totalTokens));
    return comfortable.first;
  }

  return entries.first;
}

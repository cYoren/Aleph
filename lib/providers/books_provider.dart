import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/book.dart';
import 'database_provider.dart';

/// Provider for all books in the Bible
final booksProvider = FutureProvider<List<Book>>((ref) async {
  final dao = ref.watch(bibleDaoProvider);
  return dao.getBooks();
});

/// Provider for a specific book by abbreviation
final bookByAbbreviationProvider = Provider.family<Book?, String>((
  ref,
  abbreviation,
) {
  final booksAsync = ref.watch(booksProvider);
  return booksAsync.whenOrNull(
    data: (books) =>
        books.where((b) => b.abbreviation == abbreviation).firstOrNull,
  );
});

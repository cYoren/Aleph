/// Localized book names.
///
/// The bundled database stores only English names, so translated names live in
/// `assets/book_names.json` instead. Keeping them out of the database means a
/// wrong name can be corrected without regenerating and re-shipping a 200 MB
/// asset, and a locale can be filled in a book at a time.
///
/// Any locale or book absent from the file falls back to English, so a partly
/// translated file is always safe to ship.
library;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/book.dart';
import '../features/settings/settings_provider.dart';
import 'books_provider.dart';

const String _assetPath = 'assets/book_names.json';

/// locale -> (abbreviation -> name), as loaded from the asset.
final bookNameTableProvider =
    FutureProvider<Map<String, Map<String, String>>>((ref) async {
  try {
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as Map<String, dynamic>;

    final table = <String, Map<String, String>>{};
    for (final entry in decoded.entries) {
      // Keys beginning with an underscore are notes for maintainers.
      if (entry.key.startsWith('_')) continue;
      final value = entry.value;
      if (value is! Map) continue;

      table[entry.key] = {
        for (final name in value.entries)
          name.key.toString(): name.value.toString(),
      };
    }
    return table;
  } catch (_) {
    // A missing or malformed asset must not break the reader; English names
    // from the database still work.
    return const {};
  }
});

/// Looks up book names for the app's current language.
class BookNames {
  const BookNames(this._localized, this._english);

  final Map<String, String> _localized;
  final Map<String, String> _english;

  static const empty = BookNames({}, {});

  /// The name of [abbreviation] in the reader's language, falling back to
  /// English and finally to [fallback] (the database's own name).
  String nameFor(String abbreviation, {String? fallback}) {
    final localized = _localized[abbreviation];
    if (localized != null && localized.isNotEmpty) return localized;

    final english = _english[abbreviation];
    if (english != null && english.isNotEmpty) return english;

    return fallback ?? abbreviation;
  }

  /// Convenience for a [Book], whose `name` column is the English name.
  String of(Book book) => nameFor(book.abbreviation, fallback: book.name);
}

/// Book names for the currently selected app language.
final bookNamesProvider = Provider<BookNames>((ref) {
  final language = ref.watch(settingsProvider.select((s) => s.appLanguage));
  final table = ref.watch(bookNameTableProvider).valueOrNull ?? const {};

  return BookNames(
    table[language] ?? const {},
    table['en'] ?? const {},
  );
});

/// A book's display name in the reader's language.
final localizedBookNameProvider = Provider.family<String, String>((
  ref,
  abbreviation,
) {
  final names = ref.watch(bookNamesProvider);
  final book = ref.watch(bookByAbbreviationProvider(abbreviation));
  return names.nameFor(abbreviation, fallback: book?.name);
});

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/verse.dart';
import '../../providers/database_provider.dart';
import '../../data/database/daos/bible_dao.dart';
import '../settings/settings_provider.dart';

const _unsetError = Object();
const _fallbackTranslationId = 'KJV';

class ReadingState {
  final String bookId;
  final int chapter;
  final List<Verse> verses;
  final Map<String, String> translations; // verseId -> translated text
  final bool isLoading;
  final String? errorMessage;

  const ReadingState({
    this.bookId = 'GEN',
    this.chapter = 1,
    this.verses = const [],
    this.translations = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  ReadingState copyWith({
    String? bookId,
    int? chapter,
    List<Verse>? verses,
    Map<String, String>? translations,
    bool? isLoading,
    Object? errorMessage = _unsetError,
  }) {
    return ReadingState(
      bookId: bookId ?? this.bookId,
      chapter: chapter ?? this.chapter,
      verses: verses ?? this.verses,
      translations: translations ?? this.translations,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unsetError)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  /// Get translation for a specific verse
  String? getTranslation(String verseId) => translations[verseId];
}

class ReadingNotifier extends StateNotifier<ReadingState> {
  final BibleDAO _dao;
  final Ref _ref;
  int _loadRequestId = 0;

  ReadingNotifier(this._dao, this._ref) : super(const ReadingState()) {
    _loadLastRead();
  }

  Future<void> _loadLastRead() async {
    while (!_ref.read(settingsProvider).isLoaded) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    final settings = _ref.read(settingsProvider);
    await loadChapter(settings.lastReadBook, settings.lastReadChapter);
  }

  Future<void> loadChapter(String bookId, int chapter) async {
    final requestId = ++_loadRequestId;
    if (kDebugMode) {
      debugPrint('ReadingNotifier: loadChapter($bookId, $chapter)');
    }
    state = state.copyWith(
      isLoading: true,
      bookId: bookId,
      chapter: chapter,
      errorMessage: null,
    );

    try {
      // Fetch original verses
      final verses = await _dao.getVersesForChapter(bookId, chapter);

      // Fetch translations
      final settings = _ref.read(settingsProvider);
      final translations = await loadTranslationsWithFallback(
        dao: _dao,
        bookId: bookId,
        chapter: chapter,
        preferredTranslation: settings.translation,
        persistNormalizedTranslation: (normalized) async {
          await _ref
              .read(settingsProvider.notifier)
              .setTranslationFromSystem(normalized);
        },
      );

      if (kDebugMode) {
        debugPrint(
          'ReadingNotifier: Loaded ${verses.length} verses, ${translations.length} translations',
        );
      }

      if (requestId != _loadRequestId) {
        return;
      }

      state = state.copyWith(
        verses: verses,
        translations: translations,
        isLoading: false,
        errorMessage: null,
      );

      // Save reading progress
      _ref.read(settingsProvider.notifier).setLastRead(bookId, chapter);
    } catch (e) {
      if (requestId != _loadRequestId) {
        return;
      }
      if (kDebugMode) {
        debugPrint('ReadingNotifier ERROR: $e');
      }
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Reload current chapter with new translation
  Future<void> reloadWithTranslation(String translationCode) async {
    await loadChapter(state.bookId, state.chapter);
  }
}

@visibleForTesting
Future<Map<String, String>> loadTranslationsWithFallback({
  required BibleDAO dao,
  required String bookId,
  required int chapter,
  required String preferredTranslation,
  required Future<void> Function(String normalizedTranslation)
  persistNormalizedTranslation,
}) async {
  final normalizedPreferred = preferredTranslation.trim().toUpperCase().isEmpty
      ? _fallbackTranslationId
      : preferredTranslation.trim().toUpperCase();

  final preferred = await dao.getTranslationVersesForChapter(
    bookId,
    chapter,
    normalizedPreferred,
  );
  if (preferred.isNotEmpty) {
    return preferred;
  }

  if (normalizedPreferred == _fallbackTranslationId) {
    return {};
  }

  final fallback = await dao.getTranslationVersesForChapter(
    bookId,
    chapter,
    _fallbackTranslationId,
  );
  if (fallback.isNotEmpty) {
    await persistNormalizedTranslation(_fallbackTranslationId);
  }
  return fallback;
}

final readingProvider = StateNotifierProvider<ReadingNotifier, ReadingState>((
  ref,
) {
  final dao = ref.watch(bibleDaoProvider);
  return ReadingNotifier(dao, ref);
});

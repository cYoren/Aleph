import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/verse.dart';
import '../../providers/database_provider.dart';
import '../../data/database/daos/bible_dao.dart';
import '../settings/settings_provider.dart';

const _unsetError = Object();
const _fallbackTranslationId = 'KJV';

/// How many jumps back the reader can retrace.
const int _maxHistory = 20;

const Object _unsetVerse = Object();

/// Somewhere the reader has been, so they can get back to it.
class ReadingLocation {
  const ReadingLocation(this.bookId, this.chapter, [this.verse]);

  final String bookId;
  final int chapter;
  final int? verse;

  @override
  bool operator ==(Object other) =>
      other is ReadingLocation &&
      other.bookId == bookId &&
      other.chapter == chapter &&
      other.verse == verse;

  @override
  int get hashCode => Object.hash(bookId, chapter, verse);
}

class ReadingState {
  final String bookId;
  final int chapter;
  final List<Verse> verses;
  final Map<String, String> translations; // verseId -> translated text
  final bool isLoading;
  final String? errorMessage;

  /// The verse the reader asked for, when they arrived from a bookmark, a
  /// search result, a cross-reference or a concordance entry. The reader
  /// scrolls to it and marks it; otherwise a jump to Psalm 119:105 landed on
  /// Psalm 119:1 with 176 verses in between.
  final int? targetVerse;

  /// Where the reader was before the jumps that brought them here, most
  /// recent last. Following a chain of cross-references used to be one-way.
  final List<ReadingLocation> history;

  const ReadingState({
    this.bookId = 'GEN',
    this.chapter = 1,
    this.verses = const [],
    this.translations = const {},
    this.isLoading = false,
    this.errorMessage,
    this.targetVerse,
    this.history = const [],
  });

  bool get canGoBack => history.isNotEmpty;

  ReadingState copyWith({
    String? bookId,
    int? chapter,
    List<Verse>? verses,
    Map<String, String>? translations,
    bool? isLoading,
    Object? errorMessage = _unsetError,
    Object? targetVerse = _unsetVerse,
    List<ReadingLocation>? history,
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
      targetVerse: identical(targetVerse, _unsetVerse)
          ? this.targetVerse
          : targetVerse as int?,
      history: history ?? this.history,
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

  /// Opens a chapter, optionally at a particular verse.
  ///
  /// Pass [recordHistory] when the reader is jumping somewhere from a link —
  /// a bookmark, a search hit, a cross-reference — so the reader can come
  /// back. Chapter-to-chapter paging does not record, or the back button
  /// would just undo the last page turn.
  Future<void> loadChapter(
    String bookId,
    int chapter, {
    int? targetVerse,
    bool recordHistory = false,
  }) async {
    final requestId = ++_loadRequestId;
    if (kDebugMode) {
      debugPrint('ReadingNotifier: loadChapter($bookId, $chapter)');
    }

    var history = state.history;
    if (recordHistory && state.verses.isNotEmpty) {
      final from = ReadingLocation(
        state.bookId,
        state.chapter,
        state.targetVerse,
      );
      final to = ReadingLocation(bookId, chapter, targetVerse);
      if (from != to) {
        history = [...history, from];
        // A chase can be long; keep it bounded.
        if (history.length > _maxHistory) {
          history = history.sublist(history.length - _maxHistory);
        }
      }
    }

    state = state.copyWith(
      isLoading: true,
      bookId: bookId,
      chapter: chapter,
      errorMessage: null,
      targetVerse: targetVerse,
      history: history,
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

  /// Returns to wherever the reader jumped here from.
  Future<void> goBack() async {
    if (state.history.isEmpty) return;

    final previous = state.history.last;
    final remaining = state.history.sublist(0, state.history.length - 1);
    // Set the shortened history first so this move does not push onto it.
    state = state.copyWith(history: remaining);
    await loadChapter(
      previous.bookId,
      previous.chapter,
      targetVerse: previous.verse,
    );
  }

  /// Clears the marker on a verse the reader was sent to, once they have seen
  /// it — so it does not stay lit for the rest of the session.
  void clearTargetVerse() {
    if (state.targetVerse == null) return;
    state = state.copyWith(targetVerse: null);
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

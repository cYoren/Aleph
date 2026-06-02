import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/bookmark.dart';
import '../data/database/daos/user_data_dao.dart';

/// Provider for the UserDataDAO singleton
final userDataDaoProvider = Provider<UserDataDAO>((ref) {
  return UserDataDAO();
});

/// Provider for all bookmarks
final bookmarksProvider = FutureProvider<List<Bookmark>>((ref) async {
  final dao = ref.watch(userDataDaoProvider);
  return dao.getBookmarks();
});

/// Provider for bookmarked verse IDs (for quick lookup)
final bookmarkedVerseIdsProvider = FutureProvider<Set<String>>((ref) async {
  final dao = ref.watch(userDataDaoProvider);
  return dao.getBookmarkedVerseIds();
});

/// Provider to check if a specific verse is bookmarked
final isBookmarkedProvider = FutureProvider.family<bool, String>((
  ref,
  verseId,
) async {
  // Watch the bookmarked IDs set for reactivity
  final bookmarkedIds = await ref.watch(bookmarkedVerseIdsProvider.future);
  return bookmarkedIds.contains(verseId);
});

/// Provider for bookmark count
final bookmarkCountProvider = FutureProvider<int>((ref) async {
  final dao = ref.watch(userDataDaoProvider);
  return dao.getBookmarkCount();
});

/// Notifier for bookmark actions
class BookmarkNotifier extends StateNotifier<AsyncValue<void>> {
  final UserDataDAO _dao;
  final Ref _ref;

  BookmarkNotifier(this._dao, this._ref) : super(const AsyncValue.data(null));

  /// Toggle bookmark for a verse
  Future<bool> toggleBookmark(String verseId) async {
    state = const AsyncValue.loading();

    try {
      final result = await _dao.toggleBookmark(verseId);

      // Invalidate related providers to trigger refresh
      _ref.invalidate(bookmarksProvider);
      _ref.invalidate(bookmarkedVerseIdsProvider);
      _ref.invalidate(bookmarkCountProvider);

      state = const AsyncValue.data(null);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// Add a bookmark
  Future<void> addBookmark(String verseId, {String? collectionName}) async {
    state = const AsyncValue.loading();

    try {
      await _dao.addBookmark(verseId, collectionName: collectionName);

      _ref.invalidate(bookmarksProvider);
      _ref.invalidate(bookmarkedVerseIdsProvider);
      _ref.invalidate(bookmarkCountProvider);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Remove a bookmark
  Future<void> removeBookmark(String verseId) async {
    state = const AsyncValue.loading();

    try {
      await _dao.removeBookmark(verseId);

      _ref.invalidate(bookmarksProvider);
      _ref.invalidate(bookmarkedVerseIdsProvider);
      _ref.invalidate(bookmarkCountProvider);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Provider for bookmark actions
final bookmarkNotifierProvider =
    StateNotifierProvider<BookmarkNotifier, AsyncValue<void>>((ref) {
      final dao = ref.watch(userDataDaoProvider);
      return BookmarkNotifier(dao, ref);
    });

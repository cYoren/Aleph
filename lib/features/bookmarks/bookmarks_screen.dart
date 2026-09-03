import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../data/models/bookmark.dart';
import '../../providers/bookmarks_provider.dart';
import '../reading/reading_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../providers/book_names_provider.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarksProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bookmarks),
        actions: [
          // Bookmark count badge
          bookmarksAsync.when(
            data: (bookmarks) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${bookmarks.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: bookmarksAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (context, index) => const _BookmarkSkeletonCard(),
        ),
        error: (error, _) => ErrorState(
          message: l10n.errorGenericBody,
          onRetry: () => ref.invalidate(bookmarksProvider),
        ),
        data: (bookmarks) {
          if (bookmarks.isEmpty) {
            return NoBookmarksState(onExplore: () => context.go('/reading'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              final bookmark = bookmarks[index];
              return _BookmarkCard(
                bookmark: bookmark,
                onTap: () => _navigateToVerse(context, ref, bookmark),
                onDelete: () =>
                    _deleteBookmark(context, ref, bookmark.verseId, l10n),
              );
            },
          );
        },
      ),
    );
  }

  void _navigateToVerse(
    BuildContext context,
    WidgetRef ref,
    Bookmark bookmark,
  ) {
    // Load the chapter containing this verse
    ref
        .read(readingProvider.notifier)
        .loadChapter(
          bookmark.bookId,
          bookmark.chapter,
          targetVerse: bookmark.verseNumber,
          recordHistory: true,
        );
    context.go('/reading');
  }

  /// Removes the bookmark and offers to put it back.
  ///
  /// This used to animate the swipe, snap the card back, and then ask for
  /// confirmation in a modal — the card visibly un-deleting itself before the
  /// question. A bookmark is one tap to recreate, so undo is both fewer steps
  /// and more forgiving than a dialog.
  void _deleteBookmark(
    BuildContext context,
    WidgetRef ref,
    String verseId,
    AppLocalizations l10n,
  ) {
    final notifier = ref.read(bookmarkNotifierProvider.notifier);
    notifier.removeBookmark(verseId);

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.bookmarkRemoved),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => notifier.toggleBookmark(verseId),
        ),
      ),
    );
  }
}

class _BookmarkCard extends ConsumerWidget {
  final Bookmark bookmark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BookmarkCard({
    required this.bookmark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    // The reader's language, not the database's English column.
    final bookName = ref.watch(localizedBookNameProvider(bookmark.bookId));

    // Format time ago
    final l10n = AppLocalizations.of(context)!;
    final timeAgo = _formatTimeAgo(bookmark.createdAt, l10n);

    return Dismissible(
      key: Key(bookmark.verseId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete, color: colorScheme.onErrorContainer),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$bookName ${bookmark.chapter}:${bookmark.verseNumber}',
                        style: TextStyle(
                          fontSize: 13,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // The verse itself, which is what the reader saved. The old
                // card showed a bookmark icon, a reference and a timestamp —
                // three pieces of chrome and none of the text.
                _BookmarkVerseText(bookmark: bookmark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return l10n.bookmarkTimeYearsAgo(years);
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return l10n.bookmarkTimeMonthsAgo(months);
    } else if (difference.inDays > 0) {
      return l10n.bookmarkTimeDaysAgo(difference.inDays);
    } else if (difference.inHours > 0) {
      return l10n.bookmarkTimeHoursAgo(difference.inHours);
    } else if (difference.inMinutes > 0) {
      return l10n.bookmarkTimeMinutesAgo(difference.inMinutes);
    } else {
      return l10n.bookmarkTimeJustNow;
    }
  }
}

/// The saved verse, in the reader's translation.
///
/// Held to four lines: a favourites list is for recognising a verse at a
/// glance, and a full psalm in one card pushes the next bookmark off screen.
class _BookmarkVerseText extends ConsumerWidget {
  const _BookmarkVerseText({required this.bookmark});

  final Bookmark bookmark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textAsync = ref.watch(
      bookmarkPreviewProvider((
        bookmark.bookId,
        bookmark.chapter,
        bookmark.verseNumber,
      )),
    );

    return textAsync.when(
      // Reserve the space rather than letting the card jump a line taller once
      // the text arrives.
      loading: () => const LoadingSkeleton(width: double.infinity, height: 34),
      error: (err, stack) => const SizedBox.shrink(),
      data: (text) {
        if (text == null || text.trim().isEmpty) {
          return const SizedBox.shrink();
        }
        return Text(
          text,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: colorScheme.onSurface,
          ),
        );
      },
    );
  }
}

class _BookmarkSkeletonCard extends StatelessWidget {
  const _BookmarkSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            LoadingSkeleton(
              width: 44,
              height: 44,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingSkeleton(width: 120, height: 18),
                  SizedBox(height: 8),
                  LoadingSkeleton(width: 80, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

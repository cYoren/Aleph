import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/books_provider.dart';
import '../../providers/bookmarks_provider.dart';
import '../settings/settings_provider.dart';
import 'reading_provider.dart';
import '../../data/models/verse.dart';
import '../../shared/widgets/verse_with_words.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/empty_state.dart';
import 'widgets/visual_context_overlay.dart';
import 'widgets/dynamic_translation_text.dart';
import 'widgets/cross_references_sheet.dart';

class ReadingScreen extends ConsumerStatefulWidget {
  const ReadingScreen({super.key});

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readingState = ref.watch(readingProvider);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(readingProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Listen for translation changes and reload
    ref.listen<SettingsState>(settingsProvider, (previous, next) {
      if (previous?.translation != next.translation) {
        // Translation changed, reload current chapter with new translation
        notifier.loadChapter(readingState.bookId, readingState.chapter);
      }
    });

    // Get current book for chapter bounds
    final currentBook = ref.watch(
      bookByAbbreviationProvider(readingState.bookId),
    );
    final maxChapter = currentBook?.effectiveChapterCount ?? 999;

    return Scaffold(
      appBar: AppBar(
        // Tappable title to open book picker
        title: InkWell(
          onTap: () => context.push('/book-picker'),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${currentBook?.name ?? readingState.bookId} ${readingState.chapter}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 24),
              ],
            ),
          ),
        ),
        actions: [
          // Pronunciation toggle button
          IconButton(
            icon: Icon(
              settings.showPronunciation
                  ? Icons.record_voice_over
                  : Icons.record_voice_over_outlined,
              color: settings.showPronunciation ? colorScheme.primary : null,
            ),
            tooltip: l10n.pronunciation,
            onPressed: () {
              ref
                  .read(settingsProvider.notifier)
                  .setShowPronunciation(!settings.showPronunciation);
            },
          ),
          // Translation indicator chip
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Chip(
              label: Text(
                settings.translation.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              backgroundColor: colorScheme.secondaryContainer,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: l10n.previousChapter,
            onPressed: readingState.chapter > 1
                ? () => _navigateToChapter(
                    readingState.bookId,
                    readingState.chapter - 1,
                    notifier,
                  )
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: l10n.nextChapter,
            onPressed: readingState.chapter < maxChapter
                ? () => _navigateToChapter(
                    readingState.bookId,
                    readingState.chapter + 1,
                    notifier,
                  )
                : null,
          ),
        ],
      ),
      body: _buildBody(
        readingState,
        settings,
        notifier,
        colorScheme,
        maxChapter,
      ),
    );
  }

  void _navigateToChapter(
    String bookId,
    int chapter,
    ReadingNotifier notifier,
  ) {
    notifier.loadChapter(bookId, chapter);
    // Reset page controller to center
    if (_pageController.hasClients) {
      _pageController.jumpToPage(1);
    }
  }

  Widget _buildBody(
    ReadingState readingState,
    SettingsState settings,
    ReadingNotifier notifier,
    ColorScheme colorScheme,
    int maxChapter,
  ) {
    if (readingState.errorMessage != null) {
      return ErrorState(
        message: readingState.errorMessage!,
        onRetry: () =>
            notifier.loadChapter(readingState.bookId, readingState.chapter),
      );
    }

    // Show empty state if no book selected
    if (readingState.verses.isEmpty && !readingState.isLoading) {
      return SelectBookState(onSelectBook: () => context.push('/book-picker'));
    }

    // Show loading skeleton
    if (readingState.isLoading) {
      return const ChapterSkeleton(verseCount: 5);
    }

    // Determine if this is OT (Hebrew) or NT (Greek)
    final isOT = _isOldTestament(readingState.bookId);

    // Use PageView for swipe navigation
    return GestureDetector(
      // Capture horizontal swipes
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;

        // Swipe right (previous chapter)
        if (details.primaryVelocity! > 300 && readingState.chapter > 1) {
          _navigateToChapter(
            readingState.bookId,
            readingState.chapter - 1,
            notifier,
          );
        }
        // Swipe left (next chapter)
        else if (details.primaryVelocity! < -300 &&
            readingState.chapter < maxChapter) {
          _navigateToChapter(
            readingState.bookId,
            readingState.chapter + 1,
            notifier,
          );
        }
      },
      child: VisualContextOverlay(
        child: Stack(
          children: [
            // Main content
            ListView.builder(
              itemCount: readingState.verses.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (context, index) {
                final verse = readingState.verses[index];
                return _buildVerseCard(
                  verse,
                  readingState,
                  settings,
                  isOT,
                  colorScheme,
                );
              },
            ),
            // Swipe indicators
            _buildSwipeIndicators(readingState, maxChapter, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeIndicators(
    ReadingState readingState,
    int maxChapter,
    ColorScheme colorScheme,
  ) {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous indicator
          if (readingState.chapter > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.9,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chevron_left,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  Text(
                    '${readingState.chapter - 1}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          // Current chapter indicator
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${readingState.chapter}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          // Next indicator
          if (readingState.chapter < maxChapter)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.9,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${readingState.chapter + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerseCard(
    Verse verse,
    ReadingState readingState,
    SettingsState settings,
    bool isOT,
    ColorScheme colorScheme,
  ) {
    final translationText = readingState.getTranslation(verse.id);
    final l10n = AppLocalizations.of(context)!;

    // Get book name for the verse reference
    final currentBook = ref.watch(
      bookByAbbreviationProvider(readingState.bookId),
    );
    final bookName = currentBook?.name ?? readingState.bookId;
    final verseReference =
        '$bookName ${readingState.chapter}:${verse.verseNumber}';

    return GestureDetector(
      onLongPress: () => _showVerseOptionsMenu(
        context,
        verse,
        verseReference,
        translationText ?? verse.textContent,
        colorScheme,
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Verse number badge and bookmark button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${verse.verseNumber}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Cross-references button
                  IconButton(
                    icon: Icon(
                      Icons.link,
                      color: colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: l10n.crossReferencesTitle,
                    onPressed: () {
                      CrossReferencesSheet.show(
                        context,
                        bookId: readingState.bookId,
                        chapter: readingState.chapter,
                        verse: verse.verseNumber,
                        verseReference: verseReference,
                      );
                    },
                  ),
                  // Bookmark button
                  Consumer(
                    builder: (context, ref, _) {
                      final isBookmarkedAsync = ref.watch(
                        isBookmarkedProvider(verse.id),
                      );
                      final isBookmarked =
                          isBookmarkedAsync.valueOrNull ?? false;

                      return IconButton(
                        icon: Icon(
                          isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_outline,
                          color: isBookmarked
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          size: 22,
                        ),
                        visualDensity: VisualDensity.compact,
                        tooltip: isBookmarked
                            ? l10n.removeBookmark
                            : l10n.addBookmark,
                        onPressed: () {
                          ref
                              .read(bookmarkNotifierProvider.notifier)
                              .toggleBookmark(verse.id);
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Original Text (Hebrew RTL or Greek LTR)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOT
                        ? Colors.amber.withValues(alpha: 0.3)
                        : Colors.blue.withValues(alpha: 0.3),
                  ),
                ),
                child: VerseWithWords(
                  verse: verse,
                  isOT: isOT,
                  fontSize: settings.fontSize + 2,
                ),
              ),
              const SizedBox(height: 8),
              // Translation text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: translationText != null && translationText.isNotEmpty
                    ? DynamicTranslationText(
                        verse: verse,
                        translationText: translationText,
                        isOT: isOT,
                        fontSize: settings.fontSize,
                      )
                    : Text(
                        l10n.translationNotAvailable,
                        style: TextStyle(
                          fontSize: settings.fontSize - 2,
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVerseOptionsMenu(
    BuildContext context,
    Verse verse,
    String reference,
    String text,
    ColorScheme colorScheme,
  ) {
    final verseText = '"$text"\n— $reference';
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Reference header
              Text(
                reference,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              // Copy option
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(l10n.copyVerse),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: verseText));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.verseCopied),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              // Share option
              ListTile(
                leading: const Icon(Icons.share),
                title: Text(l10n.shareVerse),
                onTap: () {
                  Navigator.pop(context);
                  Share.share(verseText);
                },
              ),
              // Cinematic Export option
              ListTile(
                leading: const Icon(Icons.movie_creation_outlined),
                title: Text(l10n.createCinematicImage),
                onTap: () {
                  Navigator.pop(context);
                  context.push(
                    '/export',
                    extra: {
                      'verse': verse,
                      'translationText': text,
                      'reference': reference,
                      'isOT': _isOldTestament(verse.bookId),
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isOldTestament(String bookId) {
    const otBooks = {
      'GEN',
      'EXO',
      'LEV',
      'NUM',
      'DEU',
      'JOS',
      'JDG',
      'RUT',
      '1SA',
      '2SA',
      '1KI',
      '2KI',
      '1CH',
      '2CH',
      'EZR',
      'NEH',
      'EST',
      'JOB',
      'PSA',
      'PRO',
      'ECC',
      'SNG',
      'ISA',
      'JER',
      'LAM',
      'EZK',
      'DAN',
      'HOS',
      'JOL',
      'AMO',
      'OBA',
      'JON',
      'MIC',
      'NAM',
      'HAB',
      'ZEP',
      'HAG',
      'ZEC',
      'MAL',
    };
    return otBooks.contains(bookId);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/books_provider.dart';
import '../../providers/book_names_provider.dart';
import '../../providers/bookmarks_provider.dart';
import '../../providers/translations_provider.dart';
import '../settings/settings_provider.dart';
import 'reading_provider.dart';
import '../../data/models/verse.dart';
import '../../shared/widgets/verse_with_words.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/empty_state.dart';
import 'widgets/visual_context_overlay.dart';
import 'widgets/dynamic_translation_text.dart';
import 'widgets/cross_references_sheet.dart';
import 'widgets/textual_variants_pane.dart';
import '../audio/recitation_provider.dart';
import '../explain/explain_provider.dart';
import '../explain/widgets/explain_sheet.dart';
import '../audio/widgets/recitation_bar.dart';
import '../../shared/utils/readable_width.dart';
import '../../core/usage_events.dart';

class ReadingScreen extends ConsumerStatefulWidget {
  const ReadingScreen({super.key});

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen> {
  late PageController _pageController;

  /// Per-verse keys so the reader can scroll the verse being recited into
  /// view as the voice reaches it.
  final Map<int, GlobalKey> _verseKeys = {};

  /// The verse list itself, so playback can tell which verse the reader is
  /// actually looking at.
  final GlobalKey _verseListKey = GlobalKey();

  /// The last `book:chapter` counted, so a rebuild or a translation reload does
  /// not report the same chapter twice.
  String? _recordedChapter;

  /// One `chapter_read` per chapter the reader actually lands on, plus
  /// `first_value` the first time ever. The book is an enum id and the testament
  /// a two-letter tag; the chapter number and everything on screen stay home.
  void _recordChapterRead(ReadingState state, bool isOldTestament) {
    if (state.isLoading || state.verses.isEmpty) return;
    final key = '${state.bookId}:${state.chapter}';
    if (_recordedChapter == key) return;
    _recordedChapter = key;
    UsageEvents.recordChapterRead(
      bookId: state.bookId,
      isOldTestament: isOldTestament,
    );
  }

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

  GlobalKey _keyForVerse(int verseNumber) =>
      _verseKeys.putIfAbsent(verseNumber, () => GlobalKey());

  /// Brings the verse now being spoken into view.
  void _scrollToVerse(int verseNumber) {
    final context = _verseKeys[verseNumber]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.3,
    );
  }

  /// The topmost verse the reader can actually see right now.
  ///
  /// A verse scrolled almost entirely off the top is not where the reader is,
  /// so it only counts once a reasonable slice of it is still on screen.
  int? _firstVisibleVerseNumber() {
    final listObject = _verseListKey.currentContext?.findRenderObject();
    if (listObject is! RenderBox || !listObject.attached) return null;
    final listTop = listObject.localToGlobal(Offset.zero).dy;

    int? bestVerse;
    double bestTop = double.infinity;
    for (final entry in _verseKeys.entries) {
      final verseContext = entry.value.currentContext;
      if (verseContext == null) continue;
      final box = verseContext.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;

      final top = box.localToGlobal(Offset.zero).dy;
      if (top + box.size.height < listTop + 32) continue;
      if (top < bestTop) {
        bestTop = top;
        bestVerse = entry.key;
      }
    }
    return bestVerse;
  }

  /// Starts or stops reciting the chapter on screen.
  ///
  /// Playback begins at the verse in front of the reader, not at verse 1:
  /// someone who has scrolled to the middle of Psalm 119 and pressed play is
  /// asking to hear *this*, and restarting from the top made the button
  /// useless anywhere but the start of a chapter.
  Future<void> _toggleRecitation(
    ReadingState readingState,
    bool isOT, {
    int? startVerse,
  }) async {
    final notifier = ref.read(recitationProvider.notifier);
    final recitation = ref.read(recitationProvider);

    if (recitation.isActive) {
      await notifier.stop();
      return;
    }

    await notifier.startChapter(
      bookId: readingState.bookId,
      chapter: readingState.chapter,
      verses: readingState.verses,
      isHebrew: isOT,
      startVerse: startVerse ?? _firstVisibleVerseNumber(),
    );
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
    final isOT = _isOldTestament(readingState.bookId);

    _recordChapterRead(readingState, isOT);

    // Book names come from the localized asset, not the English-only database.
    final bookTitle = ref
        .watch(bookNamesProvider)
        .nameFor(readingState.bookId, fallback: currentBook?.name);

    // Follow the voice: scroll each verse into view as it starts sounding.
    ref.listen<RecitationState>(recitationProvider, (previous, next) {
      final verseNumber = next.currentVerseNumber;
      if (verseNumber == null) return;
      if (previous?.currentVerseNumber == verseNumber) return;
      if (next.bookId != readingState.bookId ||
          next.chapter != readingState.chapter) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToVerse(verseNumber);
      });
    });

    // Stop the voice when the reader moves to a different chapter.
    ref.listen<ReadingState>(readingProvider, (previous, next) {
      if (previous == null) return;
      final movedAway =
          previous.bookId != next.bookId || previous.chapter != next.chapter;
      final recitation = ref.read(recitationProvider);
      if (movedAway && recitation.isActive) {
        ref.read(recitationProvider.notifier).stop();
      }
    });

    final recitation = ref.watch(recitationProvider);

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
                  '$bookTitle ${readingState.chapter}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 24),
              ],
            ),
          ),
        ),
        actions: [
          // Recite the chapter aloud in its original language
          IconButton(
            icon: Icon(
              recitation.isActive
                  ? Icons.stop_circle_outlined
                  : Icons.play_circle_outline,
              color: recitation.isActive ? colorScheme.primary : null,
            ),
            tooltip: recitation.isActive ? l10n.stopReciting : l10n.reciteAloud,
            onPressed: readingState.verses.isEmpty
                ? null
                : () => _toggleRecitation(readingState, isOT),
          ),
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
                ref
                        .watch(translationsProvider)
                        .valueOrNull
                        ?.where((t) => t.id == settings.translation)
                        .firstOrNull
                        ?.abbreviation ??
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
      body: Column(
        children: [
          // Shown once, for anyone who tapped Skip during onboarding: the
          // three affordances that make the reader usable are otherwise not
          // discoverable on their own (long-press especially).
          if (!settings.hasSeenReadingHint && readingState.verses.isNotEmpty)
            _ReadingHintBanner(
              onDismiss: () =>
                  ref.read(settingsProvider.notifier).dismissReadingHint(),
            ),
          Expanded(
            child: _buildBody(
              readingState,
              settings,
              notifier,
              colorScheme,
              maxChapter,
            ),
          ),
          RecitationBar(
            reference: '$bookTitle ${readingState.chapter}',
            onStop: () => ref.read(recitationProvider.notifier).stop(),
          ),
        ],
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
        message: AppLocalizations.of(context)!.contentLoadError,
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
        child: ListView.builder(
          key: _verseListKey,
          itemCount: readingState.verses.length,
          padding: EdgeInsets.symmetric(
            horizontal: readableGutter(context),
            vertical: 8,
          ),
          itemBuilder: (context, index) {
            final verse = readingState.verses[index];
            final isBeingRecited = ref.watch(
              recitationProvider.select(
                (r) => r.isSpeaking(
                  readingState.bookId,
                  readingState.chapter,
                  verse.verseNumber,
                ),
              ),
            );
            return _buildVerseCard(
              verse,
              readingState,
              settings,
              isOT,
              colorScheme,
              isBeingRecited: isBeingRecited,
            );
          },
        ),
      ),
    );
  }

  Widget _buildVerseCard(
    Verse verse,
    ReadingState readingState,
    SettingsState settings,
    bool isOT,
    ColorScheme colorScheme, {
    bool isBeingRecited = false,
  }) {
    final translationText = readingState.getTranslation(verse.id);
    final l10n = AppLocalizations.of(context)!;

    // Get book name for the verse reference
    final currentBook = ref.watch(
      bookByAbbreviationProvider(readingState.bookId),
    );
    final bookName = ref
        .watch(bookNamesProvider)
        .nameFor(readingState.bookId, fallback: currentBook?.name);
    final verseReference =
        '$bookName ${readingState.chapter}:${verse.verseNumber}';

    return GestureDetector(
      key: _keyForVerse(verse.verseNumber),
      onLongPress: () => _showVerseOptionsMenu(
        context,
        verse,
        verseReference,
        translationText ?? verse.textContent,
        colorScheme,
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        // The verse currently being recited lifts off the page so the eye can
        // follow the voice.
        color: isBeingRecited
            ? colorScheme.primaryContainer.withValues(alpha: 0.35)
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isBeingRecited
                ? colorScheme.primary.withValues(alpha: 0.7)
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isBeingRecited ? 1.5 : 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 6, 14),
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
                  // AI explanation, only when a key was compiled in AND the
                  // reader switched it on. Hidden entirely otherwise, so an
                  // offline build shows no dead affordance.
                  if (ref.watch(explainAvailableProvider))
                    IconButton(
                      icon: Icon(
                        Icons.auto_awesome_outlined,
                        color: colorScheme.onSurfaceVariant,
                        size: 22,
                      ),
                      visualDensity: VisualDensity.compact,
                      tooltip: l10n.explainTitle,
                      onPressed: () => ExplainSheet.show(
                        context,
                        ref,
                        reference: verseReference,
                        request: ExplainRequest(
                          reference: verseReference,
                          originalText: verse.textContent,
                          translationText: translationText ?? verse.textContent,
                          isHebrew: isOT,
                        ),
                      ),
                    ),
                  // Cross-references button. Badged with the reference count,
                  // loaded once for the whole chapter: an unlabeled link icon
                  // among four others read as "not implemented" rather than
                  // "61 references behind this verse".
                  _CrossReferenceButton(
                    bookId: readingState.bookId,
                    chapter: readingState.chapter,
                    verseNumber: verse.verseNumber,
                    colorScheme: colorScheme,
                    l10n: l10n,
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
              // Original Text (Hebrew RTL or Greek LTR). No inner boxes: the
              // card already frames the verse, and nested frames cost a third
              // of the screen.
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: VerseWithWords(
                  verse: verse,
                  isOT: isOT,
                  fontSize: settings.fontSize + 2,
                ),
              ),
              Divider(
                height: 20,
                endIndent: 8,
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
              // Translation text
              Padding(
                padding: const EdgeInsets.only(right: 8),
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
              // Where another edition of the Greek New Testament reads
              // differently here. Absent for the Hebrew Bible and for verses
              // where the editions agree.
              if (!isOT)
                TextualVariantsPane(
                  bookId: readingState.bookId,
                  chapter: readingState.chapter,
                  verse: verse.verseNumber,
                  fontSize: settings.fontSize,
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
              // Start the voice here rather than at the top of the chapter.
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: Text(l10n.reciteFromHere),
                onTap: () {
                  Navigator.pop(context);
                  final readingState = ref.read(readingProvider);
                  ref
                      .read(recitationProvider.notifier)
                      .startChapter(
                        bookId: readingState.bookId,
                        chapter: readingState.chapter,
                        verses: readingState.verses,
                        isHebrew: _isOldTestament(readingState.bookId),
                        startVerse: verse.verseNumber,
                      );
                },
              ),
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

/// One-time hint teaching tap / long-press / recite, for readers who skipped
/// onboarding. Dismissing it is permanent, tracked in [SettingsState].
class _ReadingHintBanner extends StatelessWidget {
  const _ReadingHintBanner({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 20,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.readingHintTitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.readingHintBody,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSecondaryContainer,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onDismiss,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        foregroundColor: colorScheme.onSecondaryContainer,
                      ),
                      child: Text(l10n.readingHintDismiss),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cross-reference entry point for one verse, badged with how many related
/// passages it has.
///
/// The count comes from [crossReferenceCountsForChapterProvider], keyed by
/// chapter rather than by verse: every verse card in a chapter watches the
/// same provider instance, so opening a chapter costs one query total, not
/// one per visible verse.
class _CrossReferenceButton extends ConsumerWidget {
  const _CrossReferenceButton({
    required this.bookId,
    required this.chapter,
    required this.verseNumber,
    required this.colorScheme,
    required this.l10n,
    required this.onPressed,
  });

  final String bookId;
  final int chapter;
  final int verseNumber;
  final ColorScheme colorScheme;
  final AppLocalizations l10n;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref
        .watch(crossReferenceCountsForChapterProvider((bookId, chapter)))
        .valueOrNull;
    final count = counts?[verseNumber] ?? 0;

    final icon = Icon(
      Icons.link,
      color: colorScheme.onSurfaceVariant,
      size: 22,
    );

    return IconButton(
      icon: count > 0
          ? Badge(
              label: Text('$count'),
              backgroundColor: colorScheme.primary,
              textColor: colorScheme.onPrimary,
              child: icon,
            )
          : icon,
      visualDensity: VisualDensity.compact,
      tooltip: count > 0
          ? l10n.crossReferencesCount(count)
          : l10n.crossReferencesTitle,
      onPressed: onPressed,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/books_provider.dart';
import '../../providers/book_names_provider.dart';
import '../../data/models/book.dart';
import '../../shared/utils/reading_tradition.dart';
import '../settings/settings_provider.dart';
import 'reading_provider.dart';
import '../../shared/widgets/empty_state.dart';

class BookPickerScreen extends ConsumerStatefulWidget {
  const BookPickerScreen({super.key});

  @override
  ConsumerState<BookPickerScreen> createState() => _BookPickerScreenState();
}

class _BookPickerScreenState extends ConsumerState<BookPickerScreen> {
  Book? _selectedBook;
  final _filterController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  /// Books whose localized name or abbreviation contains what was typed.
  List<Book> _applyFilter(List<Book> books) {
    if (_filter.isEmpty) return books;
    final names = ref.read(bookNamesProvider);
    final needle = _filter.toLowerCase();
    return books
        .where(
          (book) =>
              names.of(book).toLowerCase().contains(needle) ||
              book.abbreviation.toLowerCase().contains(needle) ||
              book.name.toLowerCase().contains(needle),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final currentReading = ref.watch(readingProvider);
    final l10n = AppLocalizations.of(context)!;

    // The app bar's back arrow returns from the chapter grid to the book
    // list. Without this the Android back button and the iOS edge swipe
    // closed the picker outright — the same gesture doing two things.
    return PopScope(
      canPop: _selectedBook == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectedBook != null) {
          setState(() => _selectedBook = null);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _selectedBook == null
                ? l10n.books
                : '${ref.read(bookNamesProvider).of(_selectedBook!)} - ${l10n.selectChapter}',
          ),
          leading: _selectedBook != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _selectedBook = null),
                )
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => context.pop(),
                ),
        ),
        body: booksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => ErrorState(
            message: l10n.errorGenericBody,
            onRetry: () => ref.invalidate(booksProvider),
          ),
          data: (books) {
            if (_selectedBook != null) {
              return _buildChapterGrid(
                _selectedBook!,
                colorScheme,
                currentReading,
                l10n,
              );
            }
            return Column(
              children: [
                // Sixty-six books as wrapped chips is a scroll to reach
                // Zephaniah. Matching abbreviations too means "zep" works.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    controller: _filterController,
                    onChanged: (value) =>
                        setState(() => _filter = value.trim()),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: l10n.bookFilterHint,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _filter.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              tooltip: l10n.clearFilter,
                              onPressed: () {
                                _filterController.clear();
                                setState(() => _filter = '');
                              },
                            ),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildBookGrid(
                    books,
                    colorScheme,
                    currentReading,
                    l10n,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookGrid(
    List<Book> books,
    ColorScheme colorScheme,
    ReadingState currentReading,
    AppLocalizations l10n,
  ) {
    final visible = _applyFilter(books);
    final otBooks = visible.where((b) => b.testament == 'OT').toList();
    final ntBooks = visible.where((b) => b.testament == 'NT').toList();
    final tradition = ref.watch(settingsProvider.select((s) => s.tradition));

    if (tradition == ReadingTradition.jewish) {
      // Three divisions in the traditional order, and the New Testament kept
      // at the bottom under its own name rather than deleted — the Greek text
      // is in the app either way, and a Jewish reader is perfectly capable of
      // deciding whether to open it.
      final byAbbreviation = {
        for (final book in otBooks) book.abbreviation: book,
      };

      List<Book> section(TanakhSection division) => [
        for (final abbreviation in kTanakhOrder[division]!)
          if (byAbbreviation[abbreviation] != null)
            byAbbreviation[abbreviation]!,
      ];

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCanonSection(
            l10n.tanakhTorah,
            section(TanakhSection.torah),
            colorScheme,
            currentReading,
          ),
          const SizedBox(height: 24),
          _buildCanonSection(
            l10n.tanakhNeviim,
            section(TanakhSection.neviim),
            colorScheme,
            currentReading,
          ),
          const SizedBox(height: 24),
          _buildCanonSection(
            l10n.tanakhKetuvim,
            section(TanakhSection.ketuvim),
            colorScheme,
            currentReading,
          ),
          const SizedBox(height: 24),
          _buildCanonSection(
            l10n.newTestament,
            ntBooks,
            colorScheme,
            currentReading,
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCanonSection(
          l10n.oldTestament,
          otBooks,
          colorScheme,
          currentReading,
        ),
        const SizedBox(height: 24),
        _buildCanonSection(
          l10n.newTestament,
          ntBooks,
          colorScheme,
          currentReading,
        ),
      ],
    );
  }

  /// One division of the canon. The heading is a small-caps rule rather than a
  /// coloured pill: amber-for-OT / blue-for-NT was arbitrary, and it fought
  /// the palette.
  Widget _buildCanonSection(
    String title,
    List<Book> books,
    ColorScheme colorScheme,
    ReadingState currentReading,
  ) {
    if (books.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: books
              .map((book) => _buildBookChip(book, colorScheme, currentReading))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildBookChip(
    Book book,
    ColorScheme colorScheme,
    ReadingState currentReading,
  ) {
    final isCurrentBook = book.abbreviation == currentReading.bookId;

    return Material(
      color: isCurrentBook
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() => _selectedBook = book);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            ref.watch(bookNamesProvider).of(book),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isCurrentBook ? FontWeight.bold : FontWeight.normal,
              color: isCurrentBook
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChapterGrid(
    Book book,
    ColorScheme colorScheme,
    ReadingState currentReading,
    AppLocalizations l10n,
  ) {
    final chapterCount = book.effectiveChapterCount;
    final isCurrentBook = book.abbreviation == currentReading.bookId;

    return Column(
      children: [
        // Book info header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: colorScheme.surfaceContainerHighest,
          child: Text(
            '${ref.watch(bookNamesProvider).of(book)} - ${l10n.chapters(chapterCount)}',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: chapterCount,
            itemBuilder: (context, index) {
              final chapter = index + 1;
              final isCurrentChapter =
                  isCurrentBook && currentReading.chapter == chapter;

              // theme.dart's first rule: gold is an accent, never a fill —
              // "a large gold surface reads as gaudy". Psalms filled the
              // whole display with 150 gold tiles. The fill now marks the
              // one chapter you are in, which is the thing the grid was
              // failing to show anyway.
              return Material(
                color: isCurrentChapter
                    ? colorScheme.primaryContainer
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isCurrentChapter
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                    width: isCurrentChapter ? 1.4 : 0.8,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    ref
                        .read(readingProvider.notifier)
                        .loadChapter(book.abbreviation, chapter);
                    context.go('/reading');
                  },
                  child: Center(
                    child: Text(
                      '$chapter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isCurrentChapter
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isCurrentChapter
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

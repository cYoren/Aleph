import '../../shared/widgets/empty_state.dart';
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

class BookPickerScreen extends ConsumerStatefulWidget {
  const BookPickerScreen({super.key});

  @override
  ConsumerState<BookPickerScreen> createState() => _BookPickerScreenState();
}

class _BookPickerScreenState extends ConsumerState<BookPickerScreen> {
  Book? _selectedBook;

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final currentReading = ref.watch(readingProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
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
        error: (error, stack) => ErrorState(
          message: l10n.contentLoadError,
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
          return _buildBookGrid(books, colorScheme, currentReading, l10n);
        },
      ),
    );
  }

  Widget _buildBookGrid(
    List<Book> books,
    ColorScheme colorScheme,
    ReadingState currentReading,
    AppLocalizations l10n,
  ) {
    final otBooks = books.where((b) => b.testament == 'OT').toList();
    final ntBooks = books.where((b) => b.testament == 'NT').toList();
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

              return Material(
                color: isCurrentChapter
                    ? colorScheme.primary
                    : colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                elevation: isCurrentChapter ? 4 : 0,
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
                            ? colorScheme.onPrimary
                            : colorScheme.onPrimaryContainer,
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

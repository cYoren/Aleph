import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../settings/settings_provider.dart';
import '../../providers/books_provider.dart';
import '../../providers/database_provider.dart';
import '../../data/models/verse.dart';
import '../../shared/utils/transliterator.dart';

const _fallbackTranslationId = 'KJV';
const _oldTestamentBooks = {
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

bool _isOldTestamentBook(String bookId) {
  return _oldTestamentBooks.contains(bookId);
}

class VerseOfDayData {
  final Verse verse;
  final String translationText;
  final String pronunciation;
  final bool isOT;

  const VerseOfDayData({
    required this.verse,
    required this.translationText,
    required this.pronunciation,
    required this.isOT,
  });
}

// Verse of the day provider - picks a random verse from notable verses
final verseOfDayProvider = FutureProvider<VerseOfDayData?>((ref) async {
  final dao = ref.watch(bibleDaoProvider);
  final preferredTranslation = ref.watch(settingsProvider).translation;

  // List of well-known verse references to pick from randomly
  const notableVerses = [
    'GEN.1.1',
    'GEN.1.3',
    'JHN.1.1',
    'JHN.3.16',
    'PSA.23.1',
    'PSA.119.105',
    'PRO.3.5',
    'ISA.40.31',
    'JER.29.11',
    'ROM.8.28',
    'PHP.4.13',
    'HEB.11.1',
    'MAT.5.14',
    'MAT.6.33',
    'ROM.12.2',
  ];

  // Pick a random verse based on day of year for consistency
  final dayOfYear = DateTime.now()
      .difference(DateTime(DateTime.now().year, 1, 1))
      .inDays;
  final verseRef = notableVerses[dayOfYear % notableVerses.length];
  final parts = verseRef.split('.');

  if (parts.length >= 2) {
    final bookId = parts[0];
    final chapter = int.tryParse(parts[1]) ?? 1;
    final verses = await dao.getVersesForChapter(bookId, chapter);
    final verseNum = parts.length > 2 ? int.tryParse(parts[2]) ?? 1 : 1;
    final verse = verses.where((v) => v.verseNumber == verseNum).firstOrNull;
    if (verse == null) return null;

    final isOT = _isOldTestamentBook(bookId);
    final pronunciation = Transliterator.transliterate(
      verse.textContent,
      isHebrew: isOT,
    );

    String translationText = '';
    final preferredTranslations = await dao.getTranslationVersesForChapter(
      bookId,
      chapter,
      preferredTranslation,
    );
    translationText = preferredTranslations[verse.id] ?? '';

    if (translationText.isEmpty &&
        preferredTranslation != _fallbackTranslationId) {
      final fallbackTranslations = await dao.getTranslationVersesForChapter(
        bookId,
        chapter,
        _fallbackTranslationId,
      );
      translationText = fallbackTranslations[verse.id] ?? '';
    }

    return VerseOfDayData(
      verse: verse,
      translationText: translationText,
      pronunciation: pronunciation,
      isOT: isOT,
    );
  }
  return null;
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildContinueReadingCard(context, ref, colorScheme, l10n),
          const SizedBox(height: 16),
          _buildVerseOfDayCard(context, ref, colorScheme, l10n),
          const SizedBox(height: 16),
          _buildQuickAccessCard(context, colorScheme, l10n),
        ],
      ),
    );
  }

  Widget _buildContinueReadingCard(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final settings = ref.watch(settingsProvider);
    final booksAsync = ref.watch(booksProvider);

    // Get book name
    final bookName =
        booksAsync.whenOrNull(
          data: (books) => books
              .where((b) => b.abbreviation == settings.lastReadBook)
              .firstOrNull
              ?.name,
        ) ??
        settings.lastReadBook;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => context.go('/reading'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.menu_book,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.continueReading,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$bookName ${settings.lastReadChapter}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerseOfDayCard(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final verseAsync = ref.watch(verseOfDayProvider);
    final booksAsync = ref.watch(booksProvider);

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.verseOfDay,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            verseAsync.when(
              loading: () => const Center(
                child: SizedBox(height: 60, child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Text('${l10n.error}: $err'),
              data: (verseData) {
                if (verseData == null) {
                  return Text(l10n.noResults);
                }
                final verse = verseData.verse;

                // Get book name
                final parts = verse.id.split('.');
                final bookAbbrev = parts.isNotEmpty ? parts[0] : '';
                final chapterNum = parts.length > 1 ? parts[1] : '';
                final verseNum = parts.length > 2 ? parts[2] : '';

                final bookName =
                    booksAsync.whenOrNull(
                      data: (books) => books
                          .where((b) => b.abbreviation == bookAbbrev)
                          .firstOrNull
                          ?.name,
                    ) ??
                    bookAbbrev;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      verse.textContent,
                      style: TextStyle(
                        fontFamily: verseData.isOT ? 'EzraSIL' : null,
                        fontSize: 20,
                        height: 1.6,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: verseData.isOT
                          ? TextAlign.right
                          : TextAlign.left,
                      textDirection: verseData.isOT
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.pronunciationLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      verseData.pronunciation,
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.translation,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      verseData.translationText.isNotEmpty
                          ? verseData.translationText
                          : l10n.translationNotAvailable,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$bookName $chapterNum:$verseNum',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.quickAccess,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickButton(
                    context,
                    colorScheme,
                    Icons.library_books,
                    l10n.books,
                    () => context.push('/book-picker'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickButton(
                    context,
                    colorScheme,
                    Icons.search,
                    l10n.search,
                    () => context.go('/search'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickButton(
                    context,
                    colorScheme,
                    Icons.style,
                    l10n.vocabularyTitle,
                    () => context.push('/vocabulary'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickButton(
    BuildContext context,
    ColorScheme colorScheme,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

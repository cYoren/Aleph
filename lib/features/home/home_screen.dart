import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../settings/settings_provider.dart';
import '../../providers/books_provider.dart';
import '../../providers/database_provider.dart';
import '../../data/models/verse.dart';
import '../../shared/utils/transliterator.dart';
import '../../shared/utils/reading_tradition.dart';
import '../../app/theme.dart';

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
  final tradition = ref.watch(settingsProvider.select((s) => s.tradition));

  // Each tradition draws on its own passages. A Jewish reader being served
  // John 3:16 as "today's verse" is the whole problem in one card.
  final notableVerses = dailyVersesFor(tradition);

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

/// The opening page.
///
/// Deliberately short. It carries only what is *not* one tap away in the
/// navigation bar: where you left off, today's verse, and the three study
/// tools that have no bar destination of their own. The app's own name, a
/// settings shortcut, and duplicate Books/Search buttons were removed — a home
/// screen that mostly links to the bar directly beneath it is furniture.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            _buildContinueReadingCard(context, ref, colorScheme, l10n),
            const DivineRule(),
            _buildVerseOfDayCard(context, ref, colorScheme, l10n),
            const DivineRule(),
            _buildStudyRow(context, colorScheme, l10n),
          ],
        ),
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

    // No card, no border: the first thing on the page is a place, set like a
    // title page rather than boxed like a control.
    return InkWell(
      onTap: () => context.go('/reading'),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.continueReading.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$bookName ${settings.lastReadChapter}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: colorScheme.primary, size: 22),
          ],
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

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.verseOfDay.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          verseAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
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
                  // The original comes first and largest. This is the one
                  // screen in the app where the Hebrew or Greek is the point
                  // rather than a companion to the translation.
                  Text(
                    verse.textContent,
                    style: TextStyle(
                      fontFamily: verseData.isOT ? 'EzraSIL' : 'Gentium',
                      fontSize: 23,
                      height: 1.75,
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
                    verseData.pronunciation,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    verseData.translationText.isNotEmpty
                        ? verseData.translationText
                        : l10n.translationNotAvailable,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.55,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$bookName $chapterNum:$verseNum',
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// The three study tools that have no destination in the navigation bar.
  ///
  /// Books, Search and Settings used to sit here too; they are one tap away in
  /// the bar directly below, so repeating them only added weight.
  Widget _buildStudyRow(
    BuildContext context,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickAccess.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        // The order is the learning path: the letters, then the words, then
        // what those words let you read. Memorization used to sit here too and
        // no longer does — it asks you to recall a passage in a script you may
        // not be able to sound out yet, so it lives inside Vocabulary, which is
        // where someone who has started learning actually goes.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildStudyTile(
                  context,
                  colorScheme,
                  Icons.abc_outlined,
                  l10n.alphabetTitle,
                  () => context.push('/alphabet'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStudyTile(
                  context,
                  colorScheme,
                  Icons.style_outlined,
                  l10n.vocabularyTitle,
                  () => context.push('/vocabulary'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStudyTile(
                  context,
                  colorScheme,
                  Icons.insights_outlined,
                  l10n.readabilityTitle,
                  () => context.push('/readability'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudyTile(
    BuildContext context,
    ColorScheme colorScheme,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant, width: 0.8),
          ),
          child: Column(
            children: [
              Icon(icon, color: colorScheme.primary, size: 22),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.3,
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

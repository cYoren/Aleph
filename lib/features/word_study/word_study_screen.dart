import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/verse.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/books_provider.dart';
import '../../providers/word_provider.dart';
import '../reading/reading_provider.dart';

/// Concordance view: every verse where a word (Strong's id / lemma) occurs,
/// in canonical order. Tapping an occurrence jumps into the reader.
class WordStudyScreen extends ConsumerWidget {
  final String lexiconKey;
  final String displayWord;
  final bool isHebrew;

  const WordStudyScreen({
    super.key,
    required this.lexiconKey,
    required this.displayWord,
    required this.isHebrew,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final occurrencesAsync = ref.watch(wordOccurrencesProvider(lexiconKey));
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayWord,
              style: TextStyle(
                fontFamily: isHebrew ? 'EzraSIL' : 'Gentium',
                fontSize: 22,
              ),
            ),
            Text(
              l10n.wordStudyTitle,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: occurrencesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('${l10n.error}: $err')),
        data: (data) {
          if (data.verses.isEmpty) {
            return Center(
              child: Text(
                l10n.noUsageDataAvailable,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            );
          }

          final truncated = data.total > data.verses.length;

          // Occurrences arrive in canonical order; insert a book header
          // whenever the book changes.
          final items = <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Text(
                l10n.occurrencesTotal(data.total),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ];
          String? currentBook;
          for (final verse in data.verses) {
            if (verse.bookId != currentBook) {
              currentBook = verse.bookId;
              items.add(_BookHeader(bookId: verse.bookId));
            }
            items.add(_OccurrenceTile(verse: verse, isHebrew: isHebrew));
          }
          if (truncated) {
            items.add(
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.showingFirstOccurrences(data.verses.length),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: items,
          );
        },
      ),
    );
  }
}

class _BookHeader extends ConsumerWidget {
  final String bookId;

  const _BookHeader({required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final book = ref.watch(bookByAbbreviationProvider(bookId));

    return Container(
      width: double.infinity,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        book?.name ?? bookId,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _OccurrenceTile extends ConsumerWidget {
  final Verse verse;
  final bool isHebrew;

  const _OccurrenceTile({required this.verse, required this.isHebrew});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final book = ref.watch(bookByAbbreviationProvider(verse.bookId));
    final bookName = book?.name ?? verse.bookId;
    final reference = '$bookName ${verse.chapter}:${verse.verseNumber}';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          reference,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
        ),
      ),
      subtitle: Text(
        verse.textContent,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textDirection: isHebrew ? TextDirection.rtl : TextDirection.ltr,
        style: TextStyle(
          fontSize: 18,
          height: 1.6,
          fontFamily: isHebrew ? 'EzraSIL' : 'Gentium',
          color: colorScheme.onSurface,
        ),
      ),
      onTap: () {
        ref
            .read(readingProvider.notifier)
            .loadChapter(verse.bookId, verse.chapter);
        context.go('/reading');
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/empty_state.dart';
import '../../providers/book_names_provider.dart';
import '../reading/reading_provider.dart';
import 'readability_provider.dart';

/// Shows which books the reader can already read, ranked.
///
/// Progress here is capability rather than a streak: a book moves up the list
/// because the reader genuinely learned the words in it.
class ReadabilityScreen extends ConsumerWidget {
  const ReadabilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(readabilityReportProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.readabilityTitle)),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: l10n.contentLoadError,
          onRetry: () => ref.invalidate(readabilityReportProvider),
        ),
        data: (report) {
          if (report.books.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.readabilityNoText,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (report.isEmpty)
                const _GettingStartedCard()
              else if (report.recommendation != null)
                _RecommendationCard(entry: report.recommendation!),
              const SizedBox(height: 16),
              Text(
                l10n.readabilityAllBooks,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...report.books.map((entry) => _BookRow(entry: entry)),
            ],
          );
        },
      ),
    );
  }
}

/// Shown before the reader has learned enough words to rank anything.
class _GettingStartedCard extends StatelessWidget {
  const _GettingStartedCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.readabilityEmptyTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.readabilityEmptyBody,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => context.push('/vocabulary'),
              child: Text(l10n.openVocabulary),
            ),
          ],
        ),
      ),
    );
  }
}

/// The headline: the book worth opening next.
class _RecommendationCard extends ConsumerWidget {
  const _RecommendationCard({required this.entry});

  final BookReadability entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final percent = (entry.coverage * 100).round();

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withValues(alpha: 0.6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.isComfortable
                  ? l10n.readabilityCanReadNow
                  : l10n.readabilityClosest,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              ref.watch(bookNamesProvider).of(entry.book),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.readabilityCoverage(percent, entry.unknownPerChapter),
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                ref
                    .read(readingProvider.notifier)
                    .loadChapter(entry.book.abbreviation, 1);
                context.go('/reading');
              },
              child: Text(
                l10n.readBook(ref.watch(bookNamesProvider).of(entry.book)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One book's coverage, as a labelled bar.
class _BookRow extends ConsumerWidget {
  const _BookRow({required this.entry});

  final BookReadability entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = (entry.coverage * 100).round();

    final barColor = entry.isComfortable
        ? colorScheme.primary
        : entry.isWorkable
        ? colorScheme.tertiary
        : colorScheme.outline;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        ref
            .read(readingProvider.notifier)
            .loadChapter(entry.book.abbreviation, 1);
        context.go('/reading');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ref.watch(bookNamesProvider).of(entry.book),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: barColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: entry.coverage,
                minHeight: 6,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

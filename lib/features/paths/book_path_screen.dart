import '../../shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/book_names_provider.dart';
import '../../providers/database_provider.dart';
import '../../shared/widgets/share_card_dialog.dart';
import '../reading/reading_provider.dart';
import '../vocabulary/vocabulary_item_tile.dart';
import 'book_path.dart';
import 'daily_session.dart';
import '../../shared/utils/readable_width.dart';

/// How many new words one "learn next" session introduces.
const _sessionSize = 5;

class BookPathScreen extends ConsumerWidget {
  const BookPathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final active = ref.watch(activePathProvider);

    if (active == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.pathTitle)),
        body: const _BookChooser(),
      );
    }

    final pathAsync = ref.watch(bookPathProvider(active));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pathTitle),
        actions: [
          if ((pathAsync.valueOrNull?.stats.learningCoverage ?? 0) > 0)
            IconButton(
              tooltip: l10n.pathShare,
              icon: const Icon(Icons.ios_share),
              onPressed: () => _sharePath(
                context,
                pathAsync.valueOrNull!,
                ref.read(bookNamesProvider).of(pathAsync.valueOrNull!.book),
              ),
            ),
          IconButton(
            tooltip: l10n.pathChangeBook,
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => ref.read(activePathProvider.notifier).choose(null),
          ),
        ],
      ),
      body: pathAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorState(
          message: l10n.contentLoadError,
          onRetry: () => ref.invalidate(bookPathProvider(active)),
        ),
        data: (path) =>
            path == null ? const _BookChooser() : _PathBody(path: path),
      ),
    );
  }
}

class _BookChooser extends ConsumerWidget {
  const _BookChooser();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final names = ref.watch(bookNamesProvider);

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: readableGutter(context, minimum: 0),
        vertical: 8,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            l10n.pathChooseBook,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        for (final bookId in kStarterPathBooks)
          Consumer(
            builder: (context, ref, _) {
              final path = ref.watch(bookPathProvider(bookId)).valueOrNull;
              if (path == null) return const SizedBox.shrink();
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    path.isHebrew ? 'א' : 'α',
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: path.isHebrew ? 'EzraSIL' : 'Gentium',
                    ),
                  ),
                ),
                title: Text(names.of(path.book)),
                subtitle: Text(
                  '${path.isHebrew ? l10n.hebrewLabel : l10n.greekLabel} · '
                  '${l10n.pathWordsToGoal(path.stats.wordsToGoal)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    ref.read(activePathProvider.notifier).choose(bookId),
              );
            },
          ),
      ],
    );
  }
}

class _PathBody extends ConsumerWidget {
  const _PathBody({required this.path});

  final BookPath path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final bookName = ref.watch(bookNamesProvider).of(path.book);
    final stats = path.stats;
    final known = (stats.knownCoverage * 100).round();
    final learning = (stats.learningCoverage * 100).round();
    final next = path.nextWords.take(_sessionSize).toList();

    void refresh() => ref.invalidate(bookPathProvider(path.book.abbreviation));

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: readableGutter(context),
        vertical: 16,
      ),
      children: [
        Text(
          l10n.pathCoverage(known, bookName),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              LinearProgressIndicator(
                value: stats.learningCoverage,
                minHeight: 12,
                color: colorScheme.primary.withValues(alpha: 0.35),
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
              LinearProgressIndicator(
                value: stats.knownCoverage,
                minHeight: 12,
                color: colorScheme.primary,
                backgroundColor: Colors.transparent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.pathLearning(learning),
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          stats.wordsToGoal > 0
              ? l10n.pathWordsToGoal(stats.wordsToGoal)
              : l10n.pathGoalReached,
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        if (next.isNotEmpty)
          FilledButton.icon(
            icon: const Icon(Icons.school_outlined),
            label: Text(l10n.pathLearnNext),
            onPressed: () async {
              final srs = ref.read(srsDaoProvider);
              for (final item in next) {
                if (!context.mounted) break;
                await reviewDeckItem(context, item);
                // Dismissing the sheet without answering ends the session.
                if (await srs.getProgress(item.lexiconKey) == null) break;
              }
              refresh();
            },
          )
        else
          Text(l10n.pathAllLearned),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.menu_book_outlined),
          label: Text(l10n.readBook(bookName)),
          onPressed: () {
            ref
                .read(readingProvider.notifier)
                .loadChapter(path.book.abbreviation, 1);
            context.go('/reading');
          },
        ),
        const SizedBox(height: 24),
        Text(
          l10n.pathWordsInBook,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: colorScheme.primary,
          ),
        ),
        for (final item in path.words)
          VocabularyItemTile(item: item, onReviewed: refresh),
      ],
    );
  }
}

/// Home screen entry: the active path's progress, or an invitation to start.
class PathHomeCard extends ConsumerWidget {
  const PathHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final active = ref.watch(activePathProvider);
    final path = active == null
        ? null
        : ref.watch(bookPathProvider(active)).valueOrNull;

    final card = Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Icon(Icons.flag_outlined, color: colorScheme.primary),
        title: Text(
          path == null
              ? l10n.pathTitle
              : l10n.pathCoverage(
                  (path.stats.knownCoverage * 100).round(),
                  ref.watch(bookNamesProvider).of(path.book),
                ),
        ),
        subtitle: path == null
            ? Text(l10n.pathHomeStart)
            : Padding(
                padding: const EdgeInsets.only(top: 6),
                child: LinearProgressIndicator(
                  value: path.stats.learningCoverage,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/path'),
      ),
    );
    if (path == null) return card;

    final streak = ref.watch(streakProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        const SizedBox(height: 8),
        Row(
          children: [
            if (streak > 0)
              Text(
                l10n.streakDays(streak),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            const Spacer(),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.timer_outlined),
              label: Text(l10n.dailySessionStart),
              onPressed: () async {
                final done = await runDailySession(context, ref);
                if (done && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.dailySessionDone)),
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// "I've learned 43% of the words in Ruth, in Hebrew" as a share card.
Future<void> _sharePath(BuildContext context, BookPath path, String bookName) {
  final l10n = AppLocalizations.of(context)!;
  // Words learned, not mastered: mastery takes weeks, and a card worth
  // sharing should exist after the first session.
  final percent = (path.stats.learningCoverage * 100).round();
  return ShareCardDialog.show(
    context,
    glyph: path.isHebrew ? 'א' : 'Α',
    isHebrew: path.isHebrew,
    headline: '$percent%',
    line: path.isHebrew
        ? l10n.shareCardHebrew(percent, bookName)
        : l10n.shareCardGreek(percent, bookName),
  );
}

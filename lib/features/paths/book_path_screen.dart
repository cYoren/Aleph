import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/book_names_provider.dart';
import '../../providers/database_provider.dart';
import '../reading/reading_provider.dart';
import '../vocabulary/vocabulary_item_tile.dart';
import 'book_path.dart';

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
              onPressed: () => _ShareCardDialog.show(
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
        error: (e, _) => Center(child: Text('${l10n.error}: $e')),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
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
      padding: const EdgeInsets.all(16),
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

    return Card(
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
  }
}

/// A shareable card: "I can read 43% of Ruth in Hebrew".
class _ShareCardDialog extends StatefulWidget {
  const _ShareCardDialog({required this.path, required this.bookName});

  final BookPath path;
  final String bookName;

  static Future<void> show(BuildContext context, BookPath path, String name) {
    return showDialog(
      context: context,
      builder: (_) => _ShareCardDialog(path: path, bookName: name),
    );
  }

  @override
  State<_ShareCardDialog> createState() => _ShareCardDialogState();
}

class _ShareCardDialogState extends State<_ShareCardDialog> {
  final _key = GlobalKey();
  bool _sharing = false;

  Future<void> _share(String text) async {
    setState(() => _sharing = true);
    try {
      final boundary =
          _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('${(await getTemporaryDirectory()).path}/aleph.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      await Share.shareXFiles([XFile(file.path)], text: text);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Words learned, not mastered: mastery takes weeks, and a card worth
    // sharing should exist after the first session.
    final percent = (widget.path.stats.learningCoverage * 100).round();
    final line = widget.path.isHebrew
        ? l10n.shareCardHebrew(percent, widget.bookName)
        : l10n.shareCardGreek(percent, widget.bookName);
    // The first letter of the book's script, as the card's art.
    final glyph = widget.path.isHebrew ? 'א' : 'Α';

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            key: _key,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3B1F0E), Color(0xFF9C4A12)],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    glyph,
                    style: TextStyle(
                      fontSize: 72,
                      height: 1,
                      color: const Color(0xFFF3D9A4),
                      fontFamily: widget.path.isHebrew ? 'EzraSIL' : 'Gentium',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    line,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.35,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.shareCardFooter,
                    style: const TextStyle(
                      fontSize: 13,
                      letterSpacing: 1.2,
                      color: Color(0xFFF3D9A4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              icon: const Icon(Icons.ios_share),
              label: Text(l10n.pathShare),
              onPressed: _sharing ? null : () => _share(line),
            ),
          ),
        ],
      ),
    );
  }
}

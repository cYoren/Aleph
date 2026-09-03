import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/book.dart';
import '../../data/models/memorization_passage.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/books_provider.dart';
import 'memorization_provider.dart';
import '../../providers/book_names_provider.dart';
import '../../shared/widgets/empty_state.dart';

/// List of passages the user is memorizing, with SM-2 review scheduling.
class MemorizationScreen extends ConsumerWidget {
  const MemorizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final passagesAsync = ref.watch(memorizationPassagesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.memorizationTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPassageSheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: passagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: ErrorState(message: l10n.errorGenericBody)),
        data: (passages) {
          if (passages.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.psychology_outlined,
                      size: 56,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.memorizationEmpty,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          final now = DateTime.now();
          return ListView.separated(
            itemCount: passages.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final passage = passages[index];
              return _PassageTile(passage: passage, isDue: passage.isDue(now));
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddPassageSheet(BuildContext context, WidgetRef ref) async {
    final books = await ref.read(booksProvider.future);
    if (!context.mounted || books.isEmpty) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddPassageSheet(books: books),
    );
    ref.invalidate(memorizationPassagesProvider);
  }
}

class _PassageTile extends ConsumerWidget {
  final MemorizationPassage passage;
  final bool isDue;

  const _PassageTile({required this.passage, required this.isDue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final title =
        '${ref.watch(localizedBookNameProvider(passage.bookId))} ${passage.chapter}';
    final masteryPercent = (passage.masteryScore * 100).round();

    return ListTile(
      onTap: () async {
        await context.push('/memorization-practice', extra: passage);
        ref.invalidate(memorizationPassagesProvider);
      },
      leading: Icon(
        Icons.menu_book,
        color: isDue ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(l10n.masteryLabel(masteryPercent.toString())),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.dueNowLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          IconButton(
            tooltip: l10n.deletePassageTooltip,
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final id = passage.id;
              if (id != null) {
                await ref.read(memorizationDaoProvider).removePassage(id);
                ref.invalidate(memorizationPassagesProvider);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _AddPassageSheet extends ConsumerStatefulWidget {
  final List<Book> books;

  const _AddPassageSheet({required this.books});

  @override
  ConsumerState<_AddPassageSheet> createState() => _AddPassageSheetState();
}

class _AddPassageSheetState extends ConsumerState<_AddPassageSheet> {
  late Book _book;
  int _chapter = 1;

  @override
  void initState() {
    super.initState();
    // Psalms is the natural default for memorization.
    _book = widget.books.firstWhere(
      (b) => b.abbreviation == 'PSA',
      orElse: () => widget.books.first,
    );
  }

  int get _chapterCount => _book.chapterCount > 0
      ? _book.chapterCount
      : (Book.standardChapterCounts[_book.abbreviation] ?? 1);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.addPassageTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: _book.abbreviation,
                  decoration: InputDecoration(labelText: l10n.selectBookLabel),
                  items: widget.books
                      .map(
                        (b) => DropdownMenuItem(
                          value: b.abbreviation,
                          child: Text(b.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (abbr) {
                    final book = widget.books
                        .where((b) => b.abbreviation == abbr)
                        .firstOrNull;
                    if (book != null) {
                      setState(() {
                        _book = book;
                        _chapter = 1;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int>(
                  initialValue: _chapter,
                  decoration: InputDecoration(
                    labelText: l10n.selectChapterLabel,
                  ),
                  items: List.generate(_chapterCount, (i) => i + 1)
                      .map((c) => DropdownMenuItem(value: c, child: Text('$c')))
                      .toList(),
                  onChanged: (c) {
                    if (c != null) setState(() => _chapter = c);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(memorizationDaoProvider)
                  .addPassage(_book.abbreviation, _chapter);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l10n.addPassageButton),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/cross_reference.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/books_provider.dart';
import '../../../providers/database_provider.dart';
import '../../settings/settings_provider.dart';
import '../reading_provider.dart';

/// Cross-references for one verse, best-voted first (OpenBible.info data).
final crossReferencesProvider =
    FutureProvider.family<List<CrossReference>, (String, int, int)>((
      ref,
      args,
    ) async {
      final dao = ref.watch(bibleDaoProvider);
      return dao.getCrossReferencesForVerse(args.$1, args.$2, args.$3);
    });

/// Preview text of a referenced verse in the user's translation.
final crossReferencePreviewProvider =
    FutureProvider.family<String?, (String, int, int)>((ref, args) async {
      final dao = ref.watch(bibleDaoProvider);
      final translation = ref.watch(
        settingsProvider.select((s) => s.translation),
      );
      return dao.getVerseTextWithFallback(
        translationId: translation,
        bookId: args.$1,
        chapter: args.$2,
        verse: args.$3,
      );
    });

class CrossReferencesSheet extends ConsumerWidget {
  final String bookId;
  final int chapter;
  final int verse;
  final String verseReference;

  const CrossReferencesSheet({
    super.key,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.verseReference,
  });

  static void show(
    BuildContext context, {
    required String bookId,
    required int chapter,
    required int verse,
    required String verseReference,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CrossReferencesSheet(
        bookId: bookId,
        chapter: chapter,
        verse: verse,
        verseReference: verseReference,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final refsAsync = ref.watch(
      crossReferencesProvider((bookId, chapter, verse)),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.25,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      l10n.crossReferencesTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      verseReference,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: refsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) =>
                      Center(child: Text('${l10n.error}: $err')),
                  data: (refs) {
                    if (refs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l10n.noCrossReferences,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      itemCount: refs.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) =>
                          _CrossReferenceTile(reference: refs[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CrossReferenceTile extends ConsumerWidget {
  final CrossReference reference;

  const _CrossReferenceTile({required this.reference});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final book = ref.watch(bookByAbbreviationProvider(reference.toBook));
    final bookName = book?.name ?? reference.toBook;
    final label = reference.isRange
        ? '$bookName ${reference.toChapter}:${reference.toVerseStart}–${reference.toVerseEnd}'
        : '$bookName ${reference.toChapter}:${reference.toVerseStart}';
    final previewAsync = ref.watch(
      crossReferencePreviewProvider(
        (reference.toBook, reference.toChapter, reference.toVerseStart),
      ),
    );

    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
      subtitle: previewAsync.when(
        loading: () => const SizedBox(height: 16),
        error: (err, stack) => const SizedBox.shrink(),
        data: (text) => text == null
            ? const SizedBox.shrink()
            : Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
      onTap: () {
        Navigator.of(context).pop();
        ref
            .read(readingProvider.notifier)
            .loadChapter(reference.toBook, reference.toChapter);
        context.go('/reading');
      },
    );
  }
}

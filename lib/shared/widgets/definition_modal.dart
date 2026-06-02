import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/word.dart';
import '../../data/models/lexicon_entry.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/database_provider.dart';

final selectedWordProvider = StateProvider<Word?>((ref) => null);
final lexiconEntryProvider = FutureProvider.autoDispose<LexiconEntry?>((
  ref,
) async {
  final word = ref.watch(selectedWordProvider);
  if (word == null || word.strongs == null) return null;

  final dao = ref.watch(bibleDaoProvider);
  return dao.getLexiconEntry(word.strongs!);
});

void showDefinitionModal(BuildContext context, WidgetRef ref, Word word) {
  ref.read(selectedWordProvider.notifier).state = word;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const DefinitionSheet(),
  );
}

class DefinitionSheet extends ConsumerWidget {
  const DefinitionSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final word = ref.watch(selectedWordProvider);
    final lexiconAsync = ref.watch(lexiconEntryProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (word == null) return const SizedBox.shrink();

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Word display
                    Center(
                      child: Text(
                        word.displayText,
                        style: TextStyle(
                          fontFamily: 'EzraSIL',
                          fontSize: 36,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Strong's number
                    Center(
                      child: Text(
                        word.strongs ?? l10n.noStrongsAvailable,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    // Morphology
                    if (word.morphCode != null)
                      Center(
                        child: Text(
                          word.morphCode!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    // Lexicon entry
                    lexiconAsync.when(
                      data: (entry) {
                        if (entry == null) {
                          return Center(
                            child: Text(
                              l10n.noLexiconEntry,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Lemma
                            Text(
                              entry.lemma,
                              style: TextStyle(
                                fontFamily: 'EzraSIL',
                                fontSize: 28,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            if (entry.transliteration != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '/${entry.transliteration}/',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            // Gloss
                            if (entry.gloss != null) ...[
                              Text(
                                l10n.quickMeaning,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                entry.gloss!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            // Definition
                            if (entry.definition != null) ...[
                              Text(
                                l10n.fullDefinition,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                entry.definition!,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Text('${l10n.error}: $err'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

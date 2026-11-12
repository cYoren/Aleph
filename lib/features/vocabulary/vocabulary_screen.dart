import '../../shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/review_reminder.dart';
import '../../l10n/generated/app_localizations.dart';
import 'vocabulary_item_tile.dart';
import 'vocabulary_provider.dart';

/// Frequency-ordered vocabulary decks plus the SRS review queue.
/// The most common words unlock the largest share of the text — the deck
/// header shows exactly how much.
class VocabularyScreen extends ConsumerStatefulWidget {
  const VocabularyScreen({super.key});

  @override
  ConsumerState<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends ConsumerState<VocabularyScreen> {
  String _language = 'heb';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final deckAsync = ref.watch(vocabularyDeckProvider(_language));
    final dueAsync = ref.watch(dueVocabularyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.vocabularyTitle),
        actions: [
          IconButton(
            tooltip: l10n.parsingQuizTitle,
            icon: const Icon(Icons.quiz_outlined),
            onPressed: () => context.push('/parsing-quiz', extra: _language),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Due for review
          ...dueAsync.when(
            loading: () => const [SizedBox.shrink()],
            error: (err, stack) => [
              ErrorState(
                message: l10n.contentLoadError,
                onRetry: () => ref.invalidate(dueVocabularyProvider),
              ),
            ],
            data: (due) => due.isEmpty
                ? const [SizedBox.shrink()]
                : [
                    _sectionHeader(
                      l10n.dueForReviewSection,
                      colorScheme,
                      count: due.length,
                    ),
                    // Offered here, next to the words it is about; the same
                    // switch lives in Settings once this row is gone.
                    if (!ref.watch(reviewReminderProvider))
                      SwitchListTile(
                        secondary: const Icon(Icons.notifications_outlined),
                        title: Text(l10n.reviewReminderSetting),
                        subtitle: Text(l10n.reviewReminderSettingSubtitle),
                        value: false,
                        onChanged: (value) => ref
                            .read(reviewReminderProvider.notifier)
                            .set(value),
                      ),
                    ...due.map(
                      (item) =>
                          VocabularyItemTile(item: item, onReviewed: _refresh),
                    ),
                    const Divider(),
                  ],
          ),

          // Language selector for the frequency deck
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'heb', label: Text(l10n.hebrewLabel)),
                ButtonSegment(value: 'grc', label: Text(l10n.greekLabel)),
              ],
              selected: {_language},
              onSelectionChanged: (selection) {
                setState(() => _language = selection.first);
              },
            ),
          ),

          // Frequency deck
          deckAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => ErrorState(
              message: l10n.contentLoadError,
              onRetry: () => ref.invalidate(vocabularyDeckProvider(_language)),
            ),
            data: (deck) {
              if (deck.items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.noUsageDataAvailable),
                );
              }
              final percent = (deck.coverage * 100).toStringAsFixed(0);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(l10n.mostFrequentSection, colorScheme),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      l10n.vocabularyCoverage(percent),
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  ...deck.items.map(
                    (item) =>
                        VocabularyItemTile(item: item, onReviewed: _refresh),
                  ),
                ],
              );
            },
          ),

          // Memorization sits at the end of this screen rather than on the home
          // page. Reciting a passage from memory is the last step of learning a
          // script, not the first, and offering it to someone who cannot yet
          // sound out a letter is how a learning app makes people feel stupid.
          const Divider(),
          ListTile(
            leading: const Icon(Icons.psychology_outlined),
            title: Text(l10n.memorizationTitle),
            subtitle: Text(l10n.memorizationSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/memorization'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _refresh() {
    ref.invalidate(dueVocabularyProvider);
    ref.invalidate(vocabularyDeckProvider(_language));
  }

  Widget _sectionHeader(String title, ColorScheme colorScheme, {int? count}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        count != null ? '$title ($count)' : title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/word_provider.dart';
import '../utils/morphology_decoder.dart';
import '../../features/audio/widgets/recitation_bar.dart';
import '../../features/settings/settings_provider.dart';
import '../utils/reading_tradition.dart';
import '../../providers/book_names_provider.dart';
import 'empty_state.dart';

class DefinitionSheet extends ConsumerWidget {
  const DefinitionSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DefinitionSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final word = ref.watch(selectedWordProvider);
    final lexiconAsync = ref.watch(selectedWordLexiconProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (word == null) {
      return const SizedBox.shrink();
    }

    // Determine if Hebrew (OT) based on Strong's number prefix
    final isHebrew = word.strongs?.startsWith('H') ?? word.language == 'heb';
    final usageLookupKey = word.lexiconLookupKey;

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.2,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header with word
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            word.displayText,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              fontFamily: isHebrew ? 'EzraSIL' : 'Gentium',
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (word.strongs != null)
                                _buildStrongsChip(
                                  word.strongs!,
                                  colorScheme,
                                  l10n,
                                ),
                              if (word.morphCode != null) ...[
                                const SizedBox(width: 8),
                                _buildPartOfSpeechChip(
                                  word.morphCode!,
                                  isHebrew,
                                  colorScheme,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    SpeakWordButton(
                      text: word.displayText,
                      isHebrew: isHebrew,
                      size: 24,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        ref.read(selectedWordProvider.notifier).state = null;
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: lexiconAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) =>
                      Center(child: ErrorState(message: l10n.errorGenericBody)),
                  data: (lexicon) {
                    if (lexicon == null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 48,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noLexiconEntry,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        // The meaning comes first. Someone who taps a word
                        // wants to know what it means; the dictionary form,
                        // pronunciation, and grammar are what they read next,
                        // not what they should have to scroll past.
                        if (lexicon.gloss != null)
                          _buildSection(
                            l10n.quickMeaning,
                            lexicon.gloss!,
                            colorScheme,
                          ),

                        if (lexicon.definition != null)
                          _buildSection(
                            l10n.fullDefinition,
                            lexicon.definition!,
                            colorScheme,
                          ),

                        // Lemma with proper font
                        _buildLemmaSection(
                          lexicon.lemma,
                          lexicon.transliteration,
                          isHebrew,
                          colorScheme,
                          l10n,
                        ),

                        // Pronunciation guide
                        if (lexicon.pronunciation != null &&
                            lexicon.pronunciation!.isNotEmpty)
                          _buildPronunciationSection(
                            lexicon.pronunciation!,
                            colorScheme,
                            l10n,
                          ),

                        // Scholarly lexicon entry (BDB / Abbott-Smith)
                        if (lexicon.extendedDefinition != null &&
                            lexicon.extendedDefinition!.isNotEmpty)
                          _ExpandableSection(
                            title: lexicon.extendedSource == 'BDB'
                                ? 'BDB (Brown–Driver–Briggs)'
                                : (lexicon.extendedSource ?? ''),
                            content: lexicon.extendedDefinition!,
                            showMoreLabel: l10n.showMore,
                            showLessLabel: l10n.showLess,
                          ),

                        // Decoded morphology
                        if (word.morphCode != null)
                          _buildMorphologySection(
                            word.morphCode!,
                            isHebrew,
                            colorScheme,
                            l10n,
                          ),

                        // Visual Context Engine: Top usage books graph
                        if (usageLookupKey != null)
                          _buildTopBooksGraph(
                            usageLookupKey,
                            ref,
                            colorScheme,
                            l10n,
                          ),

                        // Concordance: all occurrences of this word
                        if (usageLookupKey != null)
                          _buildSeeAllUsesButton(
                            context,
                            ref,
                            usageLookupKey,
                            word.displayText,
                            isHebrew,
                            colorScheme,
                            l10n,
                          ),

                        // Syntax Tree entry point
                        if (word.morphCode != null)
                          _buildSyntaxTreeButton(
                            context,
                            ref,
                            word,
                            isHebrew,
                            colorScheme,
                            l10n,
                          ),

                        // Language info
                        _buildLanguageInfo(isHebrew, ref, colorScheme, l10n),
                      ],
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

  Widget _buildStrongsChip(
    String strongs,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    // Format Strong's number more friendly
    final isHebrew = strongs.startsWith('H');
    final number = strongs.substring(1);
    final label = isHebrew
        ? l10n.strongsHebrewLabel(number)
        : l10n.strongsGreekLabel(number);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  Widget _buildPartOfSpeechChip(
    String morphCode,
    bool isHebrew,
    ColorScheme colorScheme,
  ) {
    final decoded = MorphologyDecoder.decode(morphCode, isHebrew: isHebrew);
    final parts = decoded.split(', ');
    final pos = parts.isNotEmpty ? parts.first : '';

    final posColor = Color(
      MorphologyDecoder.getPartOfSpeechColor(morphCode, isHebrew: isHebrew),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: posColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: posColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        pos,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: posColor,
        ),
      ),
    );
  }

  Widget _buildLemmaSection(
    String lemma,
    String? transliteration,
    bool isHebrew,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.lemmaDictionaryForm.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lemma,
              style: TextStyle(
                fontSize: 24,
                fontFamily: isHebrew ? 'EzraSIL' : 'Gentium',
                color: colorScheme.onSurface,
              ),
            ),
            if (transliteration != null && transliteration.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                transliteration,
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMorphologySection(
    String morphCode,
    bool isHebrew,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final decoded = MorphologyDecoder.decode(morphCode, isHebrew: isHebrew);
    final parts = decoded.split(', ').where((p) => p.isNotEmpty).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.grammar.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '($morphCode)',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: parts.map((part) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  part,
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPronunciationSection(
    String pronunciation,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.record_voice_over, size: 20, color: colorScheme.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.pronunciationLabel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.tertiary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pronunciation,
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageInfo(
    bool isHebrew,
    WidgetRef ref,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    // "Hebrew • Old Testament" is a Christian name for the Hebrew Bible, and
    // the wrong thing to tell a reader who chose the Tanakh.
    final jewish =
        ref.watch(settingsProvider.select((s) => s.tradition)) ==
        ReadingTradition.jewish;
    final label = isHebrew
        ? (jewish ? l10n.hebrewBibleLabel : l10n.hebrewOT)
        : l10n.greekNT;

    // Gold for Hebrew, lapis for Greek — the palette's own two accents rather
    // than raw amber and blue.
    final accent = isHebrew ? colorScheme.primary : colorScheme.secondary;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHebrew ? Icons.menu_book : Icons.auto_stories,
            size: 16,
            color: accent,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBooksGraph(
    String strongs,
    WidgetRef ref,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final usageAsync = ref.watch(strongsUsageFrequenciesProvider(strongs));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                l10n.topUsageByBook.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: usageAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (err, stack) => Text(
                l10n.failedToLoadFrequencyData,
                style: TextStyle(color: colorScheme.error, fontSize: 12),
              ),
              data: (data) {
                if (data.isEmpty) {
                  return Text(
                    l10n.noUsageDataAvailable,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  );
                }

                // Find max count to scale the bars
                int maxCount = 0;
                for (final row in data) {
                  final count = (row['count'] as num?)?.toInt() ?? 0;
                  if (count > maxCount) maxCount = count;
                }

                return Column(
                  children: data.map((row) {
                    final bookId = row['book_id']?.toString() ?? '';
                    final count = (row['count'] as num?)?.toInt() ?? 0;
                    final proportion = maxCount > 0 ? count / maxCount : 0.0;

                    // Look up the full book name
                    final bookName = ref.watch(
                      localizedBookNameProvider(bookId),
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              bookName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: proportion,
                                minHeight: 8,
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 32,
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeeAllUsesButton(
    BuildContext context,
    WidgetRef ref,
    String lexiconKey,
    String displayWord,
    bool isHebrew,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: OutlinedButton.icon(
        onPressed: () {
          ref.read(selectedWordProvider.notifier).state = null;
          Navigator.of(context).pop(); // close the definition sheet
          context.push(
            '/word-study',
            extra: {
              'lexiconKey': lexiconKey,
              'displayWord': displayWord,
              'isHebrew': isHebrew,
            },
          );
        },
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(Icons.manage_search, color: colorScheme.primary),
        label: Text(
          l10n.seeAllUses,
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSyntaxTreeButton(
    BuildContext context,
    WidgetRef ref,
    dynamic word,
    bool isHebrew,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: OutlinedButton.icon(
        onPressed: () async {
          // Load words for this verse
          final words = await ref.read(
            wordsForVerseProvider(word.verseId).future,
          );
          if (!context.mounted) return;

          // Build verse reference label
          final verseRef = word.verseId.toString();

          Navigator.of(context).pop(); // close the definition sheet
          context.push(
            '/syntax-tree',
            extra: {
              'words': words,
              'isOT': isHebrew,
              'verseReference': verseRef,
            },
          );
        },
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(Icons.account_tree_outlined, color: colorScheme.primary),
        label: Text(
          l10n.viewSyntaxTree,
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Long scholarly lexicon entry, collapsed to a preview with a toggle.
class _ExpandableSection extends StatefulWidget {
  final String title;
  final String content;
  final String showMoreLabel;
  final String showLessLabel;

  const _ExpandableSection({
    required this.title,
    required this.content,
    required this.showMoreLabel,
    required this.showLessLabel,
  });

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  static const int _previewLength = 320;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final needsToggle = widget.content.length > _previewLength;
    final text = _expanded || !needsToggle
        ? widget.content
        : '${widget.content.substring(0, _previewLength)}…';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: colorScheme.onSurface,
              height: 1.5,
            ),
          ),
          if (needsToggle)
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _expanded ? widget.showLessLabel : widget.showMoreLabel,
                style: const TextStyle(fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

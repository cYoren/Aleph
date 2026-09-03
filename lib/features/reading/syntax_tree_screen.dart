import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/real_syntax_node.dart';
import '../../data/models/word.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/database_provider.dart';
import '../../providers/word_provider.dart';
import '../../shared/utils/syntax_tree_parser.dart';
import '../../shared/utils/morphology_decoder.dart';
import '../../shared/widgets/definition_sheet.dart';
import 'widgets/real_syntax_tree_view.dart';
import 'widgets/syntax_tree_view.dart';
import '../../providers/book_names_provider.dart';

/// Resolves a verse identifier (verses-table row id, or "GEN.1.1") to
/// (bookId, chapter, verse).
final verseRefForIdProvider =
    FutureProvider.family<(String, int, int)?, String>((ref, verseId) async {
      final parts = verseId.split('.');
      if (parts.length >= 3) {
        final chapter = int.tryParse(parts[1]);
        final verse = int.tryParse(parts[2]);
        if (chapter != null && verse != null) {
          return (parts[0], chapter, verse);
        }
      }
      final rowId = int.tryParse(verseId);
      if (rowId == null) return null;
      final dao = ref.watch(bibleDaoProvider);
      return dao.getVerseRefByRowId(rowId);
    });

/// Real MACULA sentence trees for a verse ([] when unavailable).
final realSyntaxTreesProvider =
    FutureProvider.family<List<RealSyntaxNode>, String>((ref, verseId) async {
      final verseRef = await ref.watch(verseRefForIdProvider(verseId).future);
      if (verseRef == null) return const [];
      final dao = ref.watch(bibleDaoProvider);
      final raw = await dao.getSyntaxTreesForVerse(
        verseRef.$1,
        verseRef.$2,
        verseRef.$3,
      );
      if (raw == null) return const [];
      return RealSyntaxNode.parseTreesJson(raw);
    });

class SyntaxTreeScreen extends ConsumerWidget {
  final List<Word> words;
  final bool isOT;
  final String verseReference;

  const SyntaxTreeScreen({
    super.key,
    required this.words,
    required this.isOT,
    required this.verseReference,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final realTreesAsync = ref.watch(realSyntaxTreesProvider(verseReference));

    // Human-readable reference for the app bar (falls back to the raw id).
    final resolvedRef = ref
        .watch(verseRefForIdProvider(verseReference))
        .valueOrNull;
    String displayReference = verseReference;
    if (resolvedRef != null) {
      displayReference =
          '${ref.watch(localizedBookNameProvider(resolvedRef.$1))} ${resolvedRef.$2}:${resolvedRef.$3}';
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.syntaxTreeTitle,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              displayReference,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          // Language badge
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              label: Text(
                isOT ? l10n.hebrewLabel : l10n.greekLabel,
                style: const TextStyle(fontSize: 11),
              ),
              avatar: Icon(
                isOT ? Icons.menu_book : Icons.auto_stories,
                size: 16,
                color: isOT ? colorScheme.primary : colorScheme.secondary,
              ),
              backgroundColor:
                  (isOT ? colorScheme.primary : colorScheme.secondary)
                      .withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
      body: realTreesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _buildHeuristicBody(colorScheme, l10n),
        data: (trees) => trees.isNotEmpty
            ? _buildRealTreeBody(context, ref, trees, colorScheme, l10n)
            : _buildHeuristicBody(colorScheme, l10n),
      ),
    );
  }

  /// Real MACULA sentence trees: indented outline per sentence, with the
  /// CC BY attribution the license requires.
  Widget _buildRealTreeBody(
    BuildContext context,
    WidgetRef ref,
    List<RealSyntaxNode> trees,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            l10n.syntaxSourceMacula,
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            l10n.syntaxTreeTapHint,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: trees.length,
            separatorBuilder: (context, index) => const Divider(height: 32),
            itemBuilder: (context, index) => RealSyntaxTreeView(
              root: trees[index],
              isHebrew: isOT,
              onLeafTap: (leaf) => _openLeafDefinition(context, ref, leaf),
            ),
          ),
        ),
      ],
    );
  }

  /// Opens the definition sheet for a tapped tree word by matching its
  /// surface text against this verse's words. Sentences can span verses, so
  /// leaves from a neighboring verse simply do not match (no-op). Duplicate
  /// surface forms within one verse share the same lexeme, so first-match is
  /// safe.
  void _openLeafDefinition(
    BuildContext context,
    WidgetRef ref,
    RealSyntaxNode leaf,
  ) {
    final text = leaf.text;
    if (text == null || text.isEmpty) return;
    final match = words.where((w) => w.displayText == text).firstOrNull;
    if (match == null) return;

    ref.read(selectedWordProvider.notifier).state = match;
    DefinitionSheet.show(context);
  }

  /// Fallback for DBs without the syntax_trees table: the POS-ordering
  /// sketch, clearly labeled as such.
  Widget _buildHeuristicBody(ColorScheme colorScheme, AppLocalizations l10n) {
    final root = SyntaxTreeParser.parse(words, isHebrew: isOT);

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.syntaxTreeHeuristicNotice,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Legend bar
        _buildLegend(colorScheme, l10n),
        // Hint text
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            l10n.syntaxTreeTapHint,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const Divider(height: 1),
        // Tree view
        Expanded(
          child: words.isEmpty
              ? Center(
                  child: Text(
                    l10n.noMorphologicalData,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: ClipRect(
                    child: SyntaxTreeView(root: root, isOT: isOT),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLegend(ColorScheme colorScheme, AppLocalizations l10n) {
    final posList = isOT
        ? [
            ('V', l10n.posVerb),
            ('N', l10n.posNoun),
            ('A', l10n.posAdjectiveShort),
            ('P', l10n.posPronoun),
            ('R', l10n.posPrepositionShort),
            ('C', l10n.posConjunctionShort),
          ]
        : [
            ('V', l10n.posVerb),
            ('N', l10n.posNoun),
            ('A', l10n.posAdjectiveShort),
            ('P', l10n.posPronoun),
            ('R', l10n.posPrepositionShort),
            ('C', l10n.posConjunctionShort),
          ];

    return Container(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: posList.map((entry) {
          final (posChar, label) = entry;
          final color = Color(
            MorphologyDecoder.getPartOfSpeechColor(posChar, isHebrew: isOT),
          );
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurface),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

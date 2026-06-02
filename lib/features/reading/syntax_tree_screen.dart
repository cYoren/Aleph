import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/word.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/utils/syntax_tree_parser.dart';
import '../../shared/utils/morphology_decoder.dart';
import 'widgets/syntax_tree_view.dart';

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
    final root = SyntaxTreeParser.parse(words, isHebrew: isOT);

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
              verseReference,
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
                color: isOT ? Colors.amber.shade700 : Colors.blue.shade700,
              ),
              backgroundColor: isOT
                  ? Colors.amber.withValues(alpha: 0.15)
                  : Colors.blue.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
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
      ),
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

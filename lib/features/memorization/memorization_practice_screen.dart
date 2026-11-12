import '../../shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/memorization_passage.dart';
import '../../data/models/verse.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/books_provider.dart';
import '../../shared/utils/hebrew_display.dart';
import '../../shared/utils/memorization.dart';
import '../settings/settings_provider.dart';
import 'memorization_provider.dart';

/// Cloze-deletion practice for one passage: words are hidden by difficulty
/// level; tap a hidden word to reveal it, then self-grade to feed SM-2.
class MemorizationPracticeScreen extends ConsumerStatefulWidget {
  final MemorizationPassage passage;

  const MemorizationPracticeScreen({super.key, required this.passage});

  @override
  ConsumerState<MemorizationPracticeScreen> createState() =>
      _MemorizationPracticeScreenState();
}

class _MemorizationPracticeScreenState
    extends ConsumerState<MemorizationPracticeScreen> {
  late MemorizationLevel _level;

  /// Revealed hidden words, keyed as "verseIndex:wordIndex".
  final Set<String> _revealed = {};

  @override
  void initState() {
    super.initState();
    _level = defaultLevelForRepetitions(widget.passage.repetitions);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final passage = widget.passage;
    final book = ref.watch(bookByAbbreviationProvider(passage.bookId));
    final isOT = book == null || book.testament != 'NT';
    final versesAsync = ref.watch(
      practiceVersesProvider((passage.bookId, passage.chapter)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${book?.name ?? passage.bookId} ${passage.chapter}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<MemorizationLevel>(
              segments: [
                ButtonSegment(
                  value: MemorizationLevel.warmUp,
                  label: Text(l10n.levelWarmUp),
                ),
                ButtonSegment(
                  value: MemorizationLevel.challenge,
                  label: Text(l10n.levelChallenge),
                ),
                ButtonSegment(
                  value: MemorizationLevel.firstLetters,
                  label: Text(l10n.levelFirstLetters),
                ),
              ],
              selected: {_level},
              onSelectionChanged: (selection) {
                setState(() {
                  _level = selection.first;
                  _revealed.clear();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              l10n.tapHiddenWordHint,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: versesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => ErrorState(
                message: l10n.contentLoadError,
                onRetry: () => ref.invalidate(
                  practiceVersesProvider((passage.bookId, passage.chapter)),
                ),
              ),
              data: (verses) => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: verses.length,
                itemBuilder: (context, index) =>
                    _buildVerse(verses[index], index, isOT, colorScheme),
              ),
            ),
          ),
          const Divider(height: 1),
          _buildGradeBar(l10n, colorScheme),
        ],
      ),
    );
  }

  Widget _buildVerse(
    Verse verse,
    int verseIndex,
    bool isOT,
    ColorScheme colorScheme,
  ) {
    final settings = ref.watch(settingsProvider);
    final displayText = isOT
        ? applyHebrewDisplay(verse.textContent, settings.hebrewTextDisplay)
        : verse.textContent;
    final tokens = tokenizeVerse(displayText);
    final hidden = selectHiddenWordIndices(
      wordCount: tokens.length,
      level: _level,
      seed: verse.verseNumber * 31 + verse.chapter,
    );
    final fontFamily = isOT ? 'EzraSIL' : 'Gentium';
    final fontSize = settings.fontSize;

    final wordWidgets = <Widget>[
      Text(
        '${verse.verseNumber} ',
        style: TextStyle(
          fontSize: fontSize * 0.6,
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
      for (var i = 0; i < tokens.length; i++)
        _buildToken(
          tokens[i],
          isHidden: hidden.contains(i) && !_revealed.contains('$verseIndex:$i'),
          revealKey: '$verseIndex:$i',
          fontFamily: fontFamily,
          fontSize: fontSize,
          colorScheme: colorScheme,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        alignment: isOT ? WrapAlignment.end : WrapAlignment.start,
        textDirection: isOT ? TextDirection.rtl : TextDirection.ltr,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 8,
        children: wordWidgets,
      ),
    );
  }

  Widget _buildToken(
    String token, {
    required bool isHidden,
    required String revealKey,
    required String fontFamily,
    required double fontSize,
    required ColorScheme colorScheme,
  }) {
    if (!isHidden) {
      return Text(
        token,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,
          color: colorScheme.onSurface,
        ),
      );
    }

    final hint = _level == MemorizationLevel.firstLetters
        ? firstLetterHint(token)
        : null;

    return GestureDetector(
      onTap: () => setState(() => _revealed.add(revealKey)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Text(
          hint ?? '•••',
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: hint != null ? fontSize : fontSize * 0.7,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildGradeBar(AppLocalizations l10n, ColorScheme colorScheme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.howDidItGo,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _grade(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.struggledButton),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _grade(true),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.gotItButton),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _grade(bool wasSuccessful) async {
    final updated = await ref
        .read(memorizationDaoProvider)
        .recordPractice(widget.passage, wasSuccessful: wasSuccessful);
    ref.invalidate(memorizationPassagesProvider);

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final interval = updated.nextReviewAt.difference(DateTime.now());
    final message = interval.inDays >= 1
        ? l10n.nextReviewInDays(interval.inDays)
        : l10n.nextReviewInHours(interval.inHours.clamp(1, 23));

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

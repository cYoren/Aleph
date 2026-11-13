import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../data/models/lexicon_entry.dart';
import '../../../data/models/word.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/word_provider.dart';
import '../../../providers/database_provider.dart';
import '../../settings/settings_provider.dart';
import '../../../shared/utils/transliterator.dart';
import '../../../core/review_prompt_service.dart';

class SrsMicroQuizSheet extends ConsumerStatefulWidget {
  final Word originalWord;
  final String translatedWord;
  final bool isOT;

  const SrsMicroQuizSheet({
    super.key,
    required this.originalWord,
    required this.translatedWord,
    required this.isOT,
  });

  static Future<void> show(
    BuildContext context, {
    required Word originalWord,
    required String translatedWord,
    required bool isOT,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SrsMicroQuizSheet(
        originalWord: originalWord,
        translatedWord: translatedWord,
        isOT: isOT,
      ),
    );
  }

  @override
  ConsumerState<SrsMicroQuizSheet> createState() => _SrsMicroQuizSheetState();
}

class _SrsMicroQuizSheetState extends ConsumerState<SrsMicroQuizSheet> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;

    // Look the entry up by this word's own key. Deck review cards all share
    // the sentinel id -1, so the shared selectedWordProvider could not tell
    // them apart: every card after the first kept showing the first word's
    // lexicon entry (the Hebrew object marker's "(et)") instead of its own.
    final lookupKey = widget.originalWord.lexiconLookupKey;
    final lexiconAsync = lookupKey == null
        ? const AsyncValue<LexiconEntry?>.data(null)
        : ref.watch(lexiconEntryProvider(lookupKey));
    final secondaryGloss = _secondaryGloss(lexiconAsync.valueOrNull);

    final fontFamily = widget.isOT ? 'EzraSIL' : 'Gentium';
    final transliteration = Transliterator.transliterate(
      widget.originalWord.displayText,
      isHebrew: widget.isOT,
    );

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24.0),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.school, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.learningMode,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Question context
            Text(
              l10n.srsQuestionPrompt,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // The original word
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  if (settings.showPronunciation && transliteration.isNotEmpty)
                    Text(
                      transliteration,
                      style: TextStyle(
                        fontSize: 18,
                        color: colorScheme.primary.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    widget.originalWord.displayText,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: 48,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Reveal or Answer area
            if (!_revealed)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _revealed = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.visibility),
                label: Text(
                  l10n.revealAnswer,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              )
            else ...[
              // The translation
              Text(
                '${l10n.translation}:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.translatedWord,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

              if (secondaryGloss != null) ...[
                const SizedBox(height: 16),
                Text(
                  secondaryGloss,
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await _recordSrs(false);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.didntKnow),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _recordSrs(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.knewIt),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// The lexicon gloss shown under the translation, when it adds anything.
  ///
  /// For a deck card the translation already is the lexicon gloss, so
  /// repeating it would print the same word twice.
  String? _secondaryGloss(LexiconEntry? entry) {
    final gloss = entry?.gloss?.trim() ?? '';
    if (gloss.isEmpty || gloss == widget.translatedWord.trim()) return null;
    return gloss;
  }

  Future<void> _recordSrs(bool isCorrect) async {
    final lookupKey = widget.originalWord.lexiconLookupKey;
    if (lookupKey != null) {
      try {
        await ref
            .read(srsDaoProvider)
            .recordReview(lookupKey, isCorrect: isCorrect);
        // The reader's edge moved, so the gloss bar and every verse's glosses
        // are stale: a word just learned should stop being explained.
        ref.invalidate(readerThresholdProvider);
        ref.invalidate(readerGlossesProvider);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('SRS review recording failed: $e');
        }
      }
    }

    // Only a correct recall is a moment worth asking on. Getting a word wrong
    // is a normal part of spaced repetition, so it records nothing rather than
    // suppressing — but it must never be the moment we ask on.
    if (isCorrect) {
      unawaited(ReviewPromptService.record(ReviewMoment.routine));
    }

    if (!mounted) return;
    Navigator.pop(context);

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isCorrect ? l10n.srsPositiveFeedback : l10n.srsNegativeFeedback,
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/word.dart';
import '../../providers/word_provider.dart';
import '../../features/settings/settings_provider.dart';
import '../../providers/visual_context_provider.dart';
import 'definition_sheet.dart';

class TappableWord extends ConsumerStatefulWidget {
  final Word word;
  final bool isOT;
  final double fontSize;
  final String? transliteration; // Latin alphabet transliteration
  final Color? colorOverride;
  final VoidCallback? onTapOverride;

  const TappableWord({
    super.key,
    required this.word,
    required this.isOT,
    required this.fontSize,
    this.transliteration,
    this.colorOverride,
    this.onTapOverride,
  });

  @override
  ConsumerState<TappableWord> createState() => _TappableWordState();
}

class _TappableWordState extends ConsumerState<TappableWord> {
  final GlobalKey _wordKey = GlobalKey();
  late final VisibleWordCoordinatesNotifier _visibleWordCoordinatesNotifier;

  @override
  void initState() {
    super.initState();
    _visibleWordCoordinatesNotifier = ref.read(
      visibleWordCoordinatesProvider.notifier,
    );
    // Register position after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reportCoordinates();
    });
  }

  @override
  void didUpdateWidget(TappableWord oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the word changed, report coordinates again
    if (oldWidget.word.id != widget.word.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _reportCoordinates();
      });
    }
  }

  @override
  void dispose() {
    final wordId = widget.word.id.toString();
    Future<void>.microtask(() {
      _visibleWordCoordinatesNotifier.unregisterWord(wordId);
    });
    super.dispose();
  }

  void _reportCoordinates() {
    if (!mounted) return;
    final lookupKey = widget.word.lexiconLookupKey;
    if (lookupKey == null) {
      _visibleWordCoordinatesNotifier.unregisterWord(widget.word.id.toString());
      return;
    }
    _visibleWordCoordinatesNotifier.registerWord(
      widget.word.id.toString(),
      lookupKey,
      _wordKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedWord = ref.watch(selectedWordProvider);
    final settings = ref.watch(settingsProvider);

    // Check if THIS word is selected
    final isSelected = selectedWord?.id == widget.word.id;

    // Check if the current ACTIVE STRONG'S context matches this word
    final activeStrongs = ref.watch(activeStrongsProvider);
    final lookupKey = widget.word.lexiconLookupKey;
    final isContextActive =
        activeStrongs != null &&
        lookupKey != null &&
        lookupKey == activeStrongs;

    // Show transliteration if enabled AND we have one
    final showTransliteration =
        settings.showPronunciation &&
        widget.transliteration != null &&
        widget.transliteration!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (widget.onTapOverride != null) {
          widget.onTapOverride!();
          return;
        }

        // Handle normal definition selection
        ref.read(selectedWordProvider.notifier).state = widget.word;

        // Handle visual context engine
        // If they tap a word with a lexicon key, activate it across the screen.
        if (lookupKey != null) {
          ref.read(activeStrongsProvider.notifier).state = lookupKey;
        } else {
          ref.read(activeStrongsProvider.notifier).state = null;
        }

        DefinitionSheet.show(context);
      },
      child: Container(
        key: _wordKey,
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.5)
              : isContextActive
              ? colorScheme.secondaryContainer.withValues(alpha: 0.3)
              : null,
          borderRadius: BorderRadius.circular(4),
          border: isContextActive && !isSelected
              ? Border.all(color: colorScheme.secondary.withValues(alpha: 0.5))
              : null,
        ),
        child: showTransliteration
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Latin transliteration above
                  Text(
                    widget.transliteration!,
                    style: TextStyle(
                      fontSize: widget.fontSize * 0.6,
                      color: colorScheme.primary.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 1),
                  // Original text
                  _buildWordText(colorScheme),
                ],
              )
            : _buildWordText(colorScheme),
      ),
    );
  }

  Widget _buildWordText(ColorScheme colorScheme) {
    // Use EzraSIL for Hebrew (OT), Gentium for Greek (NT)
    final fontFamily = widget.isOT ? 'EzraSIL' : 'Gentium';

    final color =
        widget.colorOverride ??
        (widget.word.lexiconLookupKey != null
            ? colorScheme.primary
            : colorScheme.onSurface.withValues(alpha: 0.85));

    return Text(
      widget.word.displayText,
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: widget.fontSize,
        color: color,
        fontWeight: widget.word.lexiconLookupKey != null
            ? FontWeight.w500
            : FontWeight.normal,
      ),
    );
  }
}

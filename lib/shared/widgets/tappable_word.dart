import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/word.dart';
import '../../providers/word_provider.dart';
import '../../features/settings/settings_provider.dart';
import '../../providers/visual_context_provider.dart';
import '../utils/hebrew_display.dart';
import 'definition_sheet.dart';
import '../../l10n/generated/app_localizations.dart';

class TappableWord extends ConsumerStatefulWidget {
  final Word word;
  final bool isOT;
  final double fontSize;
  final String? transliteration; // Latin alphabet transliteration
  final String? readerGloss; // Reader-mode inline gloss shown under the word
  final Color? colorOverride;
  final VoidCallback? onTapOverride;

  const TappableWord({
    super.key,
    required this.word,
    required this.isOT,
    required this.fontSize,
    this.transliteration,
    this.readerGloss,
    this.colorOverride,
    this.onTapOverride,
  });

  @override
  ConsumerState<TappableWord> createState() => _TappableWordState();
}

/// How long a peeked gloss stays on screen before fading out on its own.
/// Long enough to read a gloss in a second language, which 2.6s was not.
const Duration _kPeekDuration = Duration(milliseconds: 6000);

/// Width of the peek bubble, clamped to the screen so a word at the edge of a
/// right-to-left line does not get a bubble running off the display.
const double _kPeekWidth = 220;

class _TappableWordState extends ConsumerState<TappableWord> {
  final GlobalKey _wordKey = GlobalKey();
  late final VisibleWordCoordinatesNotifier _visibleWordCoordinatesNotifier;

  /// Anchors the peek bubble to this word so it tracks scrolling.
  final LayerLink _peekLink = LayerLink();
  OverlayEntry? _peekEntry;
  Timer? _peekTimer;

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
    _removePeek();
    final wordId = widget.word.id.toString();
    Future<void>.microtask(() {
      _visibleWordCoordinatesNotifier.unregisterWord(wordId);
    });
    super.dispose();
  }

  void _removePeek() {
    _peekTimer?.cancel();
    _peekTimer = null;
    _peekEntry?.remove();
    _peekEntry = null;
  }

  /// Shows the gloss inline without opening the definition sheet.
  ///
  /// Tapping a word to read its entry costs you your place in the line; a
  /// long-press answers "what does that one mean?" and leaves the reading
  /// rhythm intact.
  Future<void> _showPeek() async {
    final lookupKey = widget.word.lexiconLookupKey;
    if (lookupKey == null) return;

    final entry = await ref.read(lexiconEntryProvider(lookupKey).future);
    if (!mounted) return;

    // Falling back to the headword means the gesture always answers. Silently
    // doing nothing left the reader unable to tell "no entry" from "my
    // long-press didn't register".
    final rawGloss = entry?.gloss?.trim();
    final fallback = entry?.lemma.trim();
    final gloss = (rawGloss != null && rawGloss.isNotEmpty)
        ? rawGloss
        : (fallback ?? '');
    if (gloss.isEmpty) return;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _removePeek();

    final colorScheme = Theme.of(context).colorScheme;
    _peekEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: math.min(_kPeekWidth, MediaQuery.sizeOf(context).width - 32),
        child: CompositedTransformFollower(
          link: _peekLink,
          showWhenUnlinked: false,
          // Sit just above the word, horizontally centred on it.
          targetAnchor: Alignment.topCenter,
          followerAnchor: Alignment.bottomCenter,
          offset: const Offset(0, -6),
          child: Semantics(
            liveRegion: true,
            label: gloss,
            child: GestureDetector(
              onTap: _removePeek,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.inverseSurface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          gloss,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onInverseSurface,
                          ),
                        ),
                        if (widget.transliteration != null &&
                            widget.transliteration!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.transliteration!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: colorScheme.onInverseSurface.withValues(
                                alpha: 0.75,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_peekEntry!);
    _peekTimer = Timer(_kPeekDuration, _removePeek);
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

    // Named for a screen reader, which otherwise read a bare Hebrew string
    // with no indication that it was tappable or what it meant.
    return Semantics(
      button: true,
      label: widget.readerGloss?.isNotEmpty == true
          ? '${widget.word.displayText}, ${widget.readerGloss}'
          : widget.word.displayText,
      hint: widget.onTapOverride == null ? _l10nHint(context) : null,
      child: GestureDetector(
        onLongPress: _showPeek,
        onTap: () {
          _removePeek();

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
        child: CompositedTransformTarget(
          link: _peekLink,
          child: Container(
            key: _wordKey,
            // The primary interaction of the whole app, and it carries two
            // gestures. 3x2 gave roughly a 26x24 pt target against a 44 pt
            // minimum; the Wrap's own runSpacing absorbs most of the extra
            // height, so the line does not visibly loosen.
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                  : isContextActive
                  ? colorScheme.secondaryContainer.withValues(alpha: 0.3)
                  : null,
              borderRadius: BorderRadius.circular(4),
              border: isContextActive && !isSelected
                  ? Border.all(
                      color: colorScheme.secondary.withValues(alpha: 0.5),
                    )
                  : null,
            ),
            child: ExcludeSemantics(
              child: _buildWordStack(colorScheme, showTransliteration),
            ),
          ),
        ),
      ),
    );
  }

  /// What the two gestures on a word actually do.
  String _l10nHint(BuildContext context) =>
      AppLocalizations.of(context)!.wordGestureHint;

  Widget _buildWordStack(ColorScheme colorScheme, bool showTransliteration) {
    final hasGloss =
        widget.readerGloss != null && widget.readerGloss!.isNotEmpty;

    if (!showTransliteration && !hasGloss) {
      return _buildWordText(colorScheme);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTransliteration) ...[
          // Latin transliteration above
          Text(
            widget.transliteration!,
            style: TextStyle(
              fontSize: widget.fontSize * 0.6,
              // Full strength: at 80% this measured 3.07:1 on parchment, and
              // it is set at 0.6x the body size, so it needs the contrast most.
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 1),
        ],
        // Original text
        _buildWordText(colorScheme),
        if (hasGloss) ...[
          const SizedBox(height: 1),
          // Reader-mode gloss below, always LTR (target-language text)
          Text(
            widget.readerGloss!,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: widget.fontSize * 0.55,
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
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

    final displayText = widget.isOT
        ? applyHebrewDisplay(
            widget.word.displayText,
            ref.watch(settingsProvider.select((s) => s.hebrewTextDisplay)),
          )
        : widget.word.displayText;

    return Text(
      displayText,
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

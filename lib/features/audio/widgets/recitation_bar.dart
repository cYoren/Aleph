import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../recitation_provider.dart';
import '../recitation_service.dart';
import '../recitation_text.dart';

/// Transport controls shown while a chapter is being recited.
///
/// Sits above the reader rather than over it, so the highlighted verse stays
/// visible while the voice moves through the chapter.
class RecitationBar extends ConsumerWidget {
  const RecitationBar({
    super.key,
    required this.reference,
    required this.onStop,
  });

  /// Human-readable chapter reference, e.g. "Genesis 1".
  final String reference;

  final VoidCallback onStop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recitationProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (state.status == RecitationStatus.idle ||
        state.status == RecitationStatus.finished) {
      return const SizedBox.shrink();
    }

    if (state.status == RecitationStatus.failed) {
      return _FailureNotice(failure: state.failure, onDismiss: onStop);
    }

    final isPreparing = state.status == RecitationStatus.preparing;

    return Material(
      elevation: 3,
      color: colorScheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            children: [
              if (isPreparing)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.graphic_eq, color: colorScheme.primary, size: 24),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      reference,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isPreparing
                          ? l10n.recitationPreparing
                          : state.currentVerseNumber != null
                          ? l10n.recitationVerse(state.currentVerseNumber!)
                          : '',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              _RateSelector(rate: state.rate),

              IconButton(
                icon: const Icon(Icons.stop_rounded),
                tooltip: l10n.recitationStop,
                color: colorScheme.onSurfaceVariant,
                onPressed: onStop,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cycles through the available reading paces.
class _RateSelector extends ConsumerWidget {
  const _RateSelector({required this.rate});

  final double rate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextButton(
      onPressed: () {
        final index = kRecitationRates.indexOf(rate);
        final next = kRecitationRates[(index + 1) % kRecitationRates.length];
        ref.read(recitationProvider.notifier).setRate(next);
      },
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 36),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(
        '${rate}x',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

/// Explains why nothing is being spoken, which on Android is usually a missing
/// voice download rather than anything the app can fix.
class _FailureNotice extends StatelessWidget {
  const _FailureNotice({required this.failure, required this.onDismiss});

  final VoiceAvailability? failure;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final message = switch (failure) {
      VoiceAvailability.voiceMissing => l10n.voiceMissing,
      VoiceAvailability.unsupported => l10n.voiceUnsupported,
      _ => l10n.recitationFailed,
    };

    return Material(
      elevation: 3,
      color: colorScheme.errorContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              Icon(
                Icons.volume_off_outlined,
                size: 20,
                color: colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: colorScheme.onErrorContainer,
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small speaker button that reads one word aloud.
///
/// Used from the definition sheet, where hearing the word matters more than
/// any transport control.
class SpeakWordButton extends ConsumerStatefulWidget {
  const SpeakWordButton({
    super.key,
    required this.text,
    required this.isHebrew,
    this.size = 22,
  });

  final String text;
  final bool isHebrew;
  final double size;

  @override
  ConsumerState<SpeakWordButton> createState() => _SpeakWordButtonState();
}

class _SpeakWordButtonState extends ConsumerState<SpeakWordButton> {
  bool _speaking = false;

  Future<void> _speak() async {
    if (_speaking) return;
    setState(() => _speaking = true);

    final ok = await ref
        .read(recitationProvider.notifier)
        .speakWord(widget.text, isHebrew: widget.isHebrew);

    if (!mounted) return;
    setState(() => _speaking = false);

    if (!ok) {
      final tradition = widget.isHebrew
          ? PronunciationTradition.modernIsraeli
          : PronunciationTradition.modernGreek;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.voiceMissingFor(tradition.label),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _speaking ? Icons.volume_up : Icons.volume_up_outlined,
        size: widget.size,
      ),
      tooltip: AppLocalizations.of(context)!.hearItRead,
      color: Theme.of(context).colorScheme.primary,
      onPressed: widget.text.trim().isEmpty ? null : _speak,
    );
  }
}
